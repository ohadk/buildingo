-- ====================================================================
-- 0001_schema.sql
-- Multi-Tenant Building Management Platform — Core DDL (PostgreSQL)
-- Auth: Firebase (phone OTP). DB: Supabase Postgres.
-- ====================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- --------------------------------------------------------------------
-- ENUM TYPES
-- --------------------------------------------------------------------
CREATE TYPE user_role AS ENUM ('super_admin', 'vaad', 'tenant');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'overdue');
CREATE TYPE ticket_status AS ENUM ('open', 'approved', 'in_progress', 'resolved', 'rejected');
CREATE TYPE invite_status AS ENUM ('pending', 'accepted', 'expired', 'revoked');
CREATE TYPE agent_execution_status AS ENUM ('idle', 'triggered', 'communicating', 'resolved', 'failed');
CREATE TYPE dispatch_channel AS ENUM ('email', 'sms', 'whatsapp');

-- --------------------------------------------------------------------
-- updated_at bookkeeping
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------------------------
-- 1. BUILDINGS
-- --------------------------------------------------------------------
CREATE TABLE buildings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    bank_name VARCHAR(100),
    bank_branch VARCHAR(50),
    bank_account_number VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER trg_buildings_updated BEFORE UPDATE ON buildings
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- --------------------------------------------------------------------
-- 2. APARTMENTS
-- --------------------------------------------------------------------
CREATE TABLE apartments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    apartment_number INT NOT NULL,
    floor INT NOT NULL,
    parking_spot VARCHAR(50),
    monthly_fee NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (building_id, apartment_number)
);
CREATE INDEX idx_apartments_building ON apartments(building_id);

-- --------------------------------------------------------------------
-- 3. USERS (app profiles keyed to Firebase Auth UID)
-- --------------------------------------------------------------------
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid VARCHAR(128) UNIQUE NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL DEFAULT '',
    role user_role NOT NULL DEFAULT 'tenant',
    building_id UUID REFERENCES buildings(id) ON DELETE SET NULL,
    apartment_id UUID REFERENCES apartments(id) ON DELETE SET NULL,
    num_occupants INT NOT NULL DEFAULT 1 CHECK (num_occupants >= 1),
    lease_contract_path TEXT, -- storage object path in the "leases" bucket
    onboarded_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_building ON users(building_id);
CREATE TRIGGER trg_users_updated BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- --------------------------------------------------------------------
-- 4. SUPER ADMINS (platform operators; allowlist keyed by phone)
-- --------------------------------------------------------------------
CREATE TABLE super_admins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    label VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- --------------------------------------------------------------------
-- 5. INVITATIONS (Vaad invites a phone number into a specific unit)
-- --------------------------------------------------------------------
CREATE TABLE invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    apartment_id UUID NOT NULL REFERENCES apartments(id) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL,
    role user_role NOT NULL DEFAULT 'tenant',
    invite_code VARCHAR(64) UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(24), 'hex'),
    status invite_status NOT NULL DEFAULT 'pending',
    created_by UUID NOT NULL REFERENCES users(id),
    accepted_by UUID REFERENCES users(id),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_invitations_code ON invitations(invite_code);
CREATE INDEX idx_invitations_phone ON invitations(phone_number) WHERE status = 'pending';

-- --------------------------------------------------------------------
-- 6. PAYMENTS (monthly dues ledger, one row per apartment per month)
-- --------------------------------------------------------------------
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    apartment_id UUID NOT NULL REFERENCES apartments(id) ON DELETE CASCADE,
    month INT NOT NULL CHECK (month BETWEEN 1 AND 12),
    year INT NOT NULL CHECK (year >= 2020),
    amount NUMERIC(10, 2) NOT NULL,
    status payment_status NOT NULL DEFAULT 'pending',
    payment_date DATE,
    receipt_path TEXT, -- storage object path in the "receipts" bucket
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (apartment_id, month, year)
);
CREATE INDEX idx_payments_building ON payments(building_id);
CREATE TRIGGER trg_payments_updated BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- --------------------------------------------------------------------
-- 7. EXPENSES (manual building outflows entered by the Vaad)
-- --------------------------------------------------------------------
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL, -- 'gardening' | 'electricity' | 'elevator' | ...
    amount NUMERIC(10, 2) NOT NULL,
    expense_date DATE NOT NULL,
    receipt_path TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_expenses_building ON expenses(building_id);

-- --------------------------------------------------------------------
-- 8. VENDOR AGENTS (Claude agent configuration per vendor contract)
-- --------------------------------------------------------------------
CREATE TABLE vendor_agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    vendor_name VARCHAR(255) NOT NULL,
    service_type VARCHAR(100) NOT NULL, -- 'elevator' | 'plumbing' | 'gates' | ...
    vendor_email VARCHAR(255),
    vendor_phone VARCHAR(50),
    preferred_channels dispatch_channel[] NOT NULL DEFAULT '{email}',
    contract_details TEXT,
    ai_instructions TEXT, -- extra prompt instructions merged into the dispatch prompt
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_vendor_agents_building ON vendor_agents(building_id);

-- --------------------------------------------------------------------
-- 9. TICKETS (maintenance / fault reports)
-- --------------------------------------------------------------------
CREATE TABLE tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    apartment_id UUID REFERENCES apartments(id) ON DELETE SET NULL,
    reported_by UUID NOT NULL REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    image_path TEXT,
    location VARCHAR(100),
    status ticket_status NOT NULL DEFAULT 'open',
    assigned_vendor_agent_id UUID REFERENCES vendor_agents(id),
    agent_status agent_execution_status NOT NULL DEFAULT 'idle',
    agent_log JSONB NOT NULL DEFAULT '[]'::jsonb, -- raw Claude I/O transcript
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_tickets_building ON tickets(building_id);
CREATE TRIGGER trg_tickets_updated BEFORE UPDATE ON tickets
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Timeline events power the "Reported → Approved → Agent Dispatched →
-- Resolved" progress UI on the tenant home screen.
CREATE TABLE ticket_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    label VARCHAR(255) NOT NULL,   -- e.g. 'Agent Contacted Vendor'
    detail TEXT,                   -- e.g. 'Email sent to service@schindler.com'
    actor UUID REFERENCES users(id), -- NULL when the actor is the AI agent
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_ticket_events_ticket ON ticket_events(ticket_id);

-- --------------------------------------------------------------------
-- 10. DOCUMENTS (digital vault; building-wide or tied to one unit)
-- --------------------------------------------------------------------
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    apartment_id UUID REFERENCES apartments(id) ON DELETE CASCADE, -- NULL = building-wide
    title VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL, -- storage object path in the "documents" bucket
    file_type VARCHAR(50),
    uploaded_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_documents_building ON documents(building_id);
CREATE INDEX idx_documents_apartment ON documents(apartment_id);

-- --------------------------------------------------------------------
-- 11. MEETINGS & ASSEMBLIES
-- --------------------------------------------------------------------
CREATE TABLE meetings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    agenda TEXT NOT NULL,
    meeting_date TIMESTAMPTZ NOT NULL,
    location VARCHAR(255),
    summary_doc_path TEXT, -- generated recap stored in the "documents" bucket
    is_closed BOOLEAN NOT NULL DEFAULT FALSE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_meetings_building ON meetings(building_id);

-- --------------------------------------------------------------------
-- 12. VOTES (polls attached to a meeting)
-- --------------------------------------------------------------------
CREATE TABLE votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    meeting_id UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    options JSONB NOT NULL, -- e.g. ["Yes", "No", "Abstain"]
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_votes_building ON votes(building_id);

-- --------------------------------------------------------------------
-- 13. VOTE BALLOTS (exactly one ballot per apartment per poll)
-- --------------------------------------------------------------------
CREATE TABLE vote_ballots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vote_id UUID NOT NULL REFERENCES votes(id) ON DELETE CASCADE,
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    apartment_id UUID NOT NULL REFERENCES apartments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    selected_option VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (vote_id, apartment_id)
);

-- --------------------------------------------------------------------
-- 14. ANNOUNCEMENTS (community board / building bulletin)
-- --------------------------------------------------------------------
CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    attachment_path TEXT, -- e.g. generated meeting summary PDF
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_announcements_building ON announcements(building_id);
-- ====================================================================
-- 0002_rls.sql — Row Level Security: multi-tenant isolation by
-- building_id + role-based permissions (super_admin / vaad / tenant).
--
-- How identity reaches Postgres:
--   * Server routes (Next.js) use the service_role key, which BYPASSES
--     RLS; those routes verify the Firebase session cookie and enforce
--     tenancy in application code. RLS below is defense-in-depth and
--     enables safe direct client reads.
--   * For direct client access, register Firebase as a Third-Party Auth
--     provider in Supabase (Dashboard → Authentication → Third-Party →
--     Firebase, project id: buildingo-6ff54). Supabase then accepts the
--     Firebase ID token as the request JWT, and auth.jwt()->>'sub' is
--     the Firebase UID.
-- ====================================================================

-- --------------------------------------------------------------------
-- Identity helper functions
-- SECURITY DEFINER so they can read `users` without tripping the RLS
-- policies on `users` itself (avoids infinite recursion).
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION request_firebase_uid()
RETURNS TEXT AS $$
    SELECT COALESCE(auth.jwt() ->> 'sub', '')
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION app_user_id()
RETURNS UUID AS $$
    SELECT id FROM public.users WHERE firebase_uid = request_firebase_uid() LIMIT 1
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION app_user_role()
RETURNS user_role AS $$
    SELECT role FROM public.users WHERE firebase_uid = request_firebase_uid() LIMIT 1
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION app_user_building()
RETURNS UUID AS $$
    SELECT building_id FROM public.users WHERE firebase_uid = request_firebase_uid() LIMIT 1
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION app_user_apartment()
RETURNS UUID AS $$
    SELECT apartment_id FROM public.users WHERE firebase_uid = request_firebase_uid() LIMIT 1
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS BOOLEAN AS $$
    SELECT app_user_role() = 'super_admin'
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION is_vaad_of(b UUID)
RETURNS BOOLEAN AS $$
    SELECT app_user_role() = 'vaad' AND app_user_building() = b
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION in_building(b UUID)
RETURNS BOOLEAN AS $$
    SELECT app_user_building() = b
$$ LANGUAGE sql STABLE;

-- --------------------------------------------------------------------
-- Enable RLS everywhere (deny-by-default)
-- --------------------------------------------------------------------
ALTER TABLE buildings      ENABLE ROW LEVEL SECURITY;
ALTER TABLE apartments     ENABLE ROW LEVEL SECURITY;
ALTER TABLE users          ENABLE ROW LEVEL SECURITY;
ALTER TABLE super_admins   ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments       ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses       ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_agents  ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets        ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_events  ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents      ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetings       ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes          ENABLE ROW LEVEL SECURITY;
ALTER TABLE vote_ballots   ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements  ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------------------
-- BUILDINGS
-- --------------------------------------------------------------------
CREATE POLICY superadmin_all_buildings ON buildings FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY view_own_building ON buildings FOR SELECT
    USING (in_building(id));

CREATE POLICY vaad_update_building ON buildings FOR UPDATE
    USING (is_vaad_of(id)) WITH CHECK (is_vaad_of(id));

-- --------------------------------------------------------------------
-- APARTMENTS
-- --------------------------------------------------------------------
CREATE POLICY superadmin_all_apartments ON apartments FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY view_building_apartments ON apartments FOR SELECT
    USING (in_building(building_id)); -- directory feature

CREATE POLICY vaad_manage_apartments ON apartments FOR ALL
    USING (is_vaad_of(building_id)) WITH CHECK (is_vaad_of(building_id));

-- --------------------------------------------------------------------
-- USERS
-- --------------------------------------------------------------------
CREATE POLICY superadmin_all_users ON users FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY view_building_directory ON users FOR SELECT
    USING (in_building(building_id) OR firebase_uid = request_firebase_uid());

CREATE POLICY update_own_profile ON users FOR UPDATE
    USING (firebase_uid = request_firebase_uid())
    WITH CHECK (
        firebase_uid = request_firebase_uid()
        -- privilege-escalation guard: a user cannot change their own
        -- role/building/apartment through a direct update
        AND role = app_user_role()
        AND building_id IS NOT DISTINCT FROM app_user_building()
        AND apartment_id IS NOT DISTINCT FROM app_user_apartment()
    );

-- --------------------------------------------------------------------
-- SUPER ADMINS (allowlist readable only by super admins; managed via
-- service role / SQL console)
-- --------------------------------------------------------------------
CREATE POLICY superadmin_read_super_admins ON super_admins FOR SELECT
    USING (is_super_admin());

-- --------------------------------------------------------------------
-- INVITATIONS (created and tracked by the Vaad; acceptance happens
-- through the server API with the service role after OTP verification)
-- --------------------------------------------------------------------
CREATE POLICY superadmin_all_invitations ON invitations FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY vaad_manage_invitations ON invitations FOR ALL
    USING (is_vaad_of(building_id)) WITH CHECK (is_vaad_of(building_id));

-- --------------------------------------------------------------------
-- PAYMENTS
-- --------------------------------------------------------------------
CREATE POLICY superadmin_all_payments ON payments FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY vaad_manage_payments ON payments FOR ALL
    USING (is_vaad_of(building_id)) WITH CHECK (is_vaad_of(building_id));

CREATE POLICY tenant_view_own_payments ON payments FOR SELECT
    USING (in_building(building_id) AND apartment_id = app_user_apartment());

-- --------------------------------------------------------------------
-- EXPENSES (building balance is transparent to all residents)
-- --------------------------------------------------------------------
CREATE POLICY superadmin_all_expenses ON expenses FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY view_building_expenses ON expenses FOR SELECT
    USING (in_building(building_id));

CREATE POLICY vaad_manage_expenses ON expenses FOR ALL
    USING (is_vaad_of(building_id)) WITH CHECK (is_vaad_of(building_id));

-- --------------------------------------------------------------------
-- VENDOR AGENTS (contract & contact data: Vaad-only)
-- --------------------------------------------------------------------
CREATE POLICY superadmin_all_vendor_agents ON vendor_agents FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY vaad_manage_vendor_agents ON vendor_agents FOR ALL
    USING (is_vaad_of(building_id)) WITH CHECK (is_vaad_of(building_id));

-- --------------------------------------------------------------------
-- TICKETS
-- --------------------------------------------------------------------
CREATE POLICY superadmin_all_tickets ON tickets FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY building_view_tickets ON tickets FOR SELECT
    USING (in_building(building_id));

CREATE POLICY tenant_create_ticket ON tickets FOR INSERT
    WITH CHECK (
        in_building(building_id)
        AND reported_by = app_user_id()
    );

CREATE POLICY vaad_manage_tickets ON tickets FOR UPDATE
    USING (is_vaad_of(building_id)) WITH CHECK (is_vaad_of(building_id));

-- Ticket timeline
CREATE POLICY superadmin_all_ticket_events ON ticket_events FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY building_view_ticket_events ON ticket_events FOR SELECT
    USING (in_building(building_id));

CREATE POLICY vaad_insert_ticket_events ON ticket_events FOR INSERT
    WITH CHECK (is_vaad_of(building_id));

-- --------------------------------------------------------------------
-- DOCUMENTS (tenants see building-wide docs + their own unit's vault)
-- --------------------------------------------------------------------
CREATE POLICY superadmin_all_documents ON documents FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY vaad_manage_documents ON documents FOR ALL
    USING (is_vaad_of(building_id)) WITH CHECK (is_vaad_of(building_id));

CREATE POLICY tenant_view_own_documents ON documents FOR SELECT
    USING (
        in_building(building_id)
        AND (apartment_id IS NULL OR apartment_id = app_user_apartment())
    );

-- --------------------------------------------------------------------
-- MEETINGS
-- --------------------------------------------------------------------
CREATE POLICY superadmin_all_meetings ON meetings FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY view_building_meetings ON meetings FOR SELECT
    USING (in_building(building_id));

CREATE POLICY vaad_manage_meetings ON meetings FOR ALL
    USING (is_vaad_of(building_id)) WITH CHECK (is_vaad_of(building_id));

-- --------------------------------------------------------------------
-- VOTES
-- --------------------------------------------------------------------
CREATE POLICY superadmin_all_votes ON votes FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY view_building_votes ON votes FOR SELECT
    USING (in_building(building_id));

CREATE POLICY vaad_manage_votes ON votes FOR ALL
    USING (is_vaad_of(building_id)) WITH CHECK (is_vaad_of(building_id));

-- --------------------------------------------------------------------
-- VOTE BALLOTS — one ballot per apartment (unique index) and voters
-- can only cast for their own apartment
-- --------------------------------------------------------------------
CREATE POLICY superadmin_all_ballots ON vote_ballots FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY view_building_ballots ON vote_ballots FOR SELECT
    USING (in_building(building_id));

CREATE POLICY cast_own_apartment_ballot ON vote_ballots FOR INSERT
    WITH CHECK (
        in_building(building_id)
        AND apartment_id = app_user_apartment()
        AND user_id = app_user_id()
    );

-- --------------------------------------------------------------------
-- ANNOUNCEMENTS (community board)
-- --------------------------------------------------------------------
CREATE POLICY superadmin_all_announcements ON announcements FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY view_building_announcements ON announcements FOR SELECT
    USING (in_building(building_id));

CREATE POLICY vaad_manage_announcements ON announcements FOR ALL
    USING (is_vaad_of(building_id)) WITH CHECK (is_vaad_of(building_id));
-- ====================================================================
-- 0003_storage.sql — Supabase Storage buckets + object policies
--
-- Bucket layout (all private; access via signed URLs from the server,
-- policies below additionally allow direct authenticated reads):
--   leases/     {building_id}/{apartment_id}/{filename}
--   receipts/   {building_id}/{apartment_id}/{filename}
--   documents/  {building_id}/{apartment_id|building}/{filename}
-- ====================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('leases', 'leases', false),
       ('receipts', 'receipts', false),
       ('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;

-- Path helpers: first folder = building_id, second folder = apartment_id
CREATE OR REPLACE FUNCTION storage_path_building(object_name TEXT)
RETURNS UUID AS $$
    SELECT NULLIF((storage.foldername(object_name))[1], '')::uuid
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION storage_path_apartment(object_name TEXT)
RETURNS UUID AS $$
    SELECT CASE
        WHEN (storage.foldername(object_name))[2] ~ '^[0-9a-f-]{36}$'
        THEN (storage.foldername(object_name))[2]::uuid
        ELSE NULL
    END
$$ LANGUAGE sql IMMUTABLE;

-- Vaad: full management of all three buckets within their building
CREATE POLICY vaad_manage_storage ON storage.objects FOR ALL
    USING (
        bucket_id IN ('leases', 'receipts', 'documents')
        AND is_vaad_of(storage_path_building(name))
    )
    WITH CHECK (
        bucket_id IN ('leases', 'receipts', 'documents')
        AND is_vaad_of(storage_path_building(name))
    );

-- Tenants: read files scoped to their own apartment (or building-wide docs)
CREATE POLICY tenant_read_own_unit_files ON storage.objects FOR SELECT
    USING (
        bucket_id IN ('leases', 'receipts', 'documents')
        AND in_building(storage_path_building(name))
        AND (
            storage_path_apartment(name) IS NULL
            OR storage_path_apartment(name) = app_user_apartment()
        )
    );

-- Tenants: upload their own lease during onboarding
CREATE POLICY tenant_upload_own_lease ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'leases'
        AND in_building(storage_path_building(name))
        AND storage_path_apartment(name) = app_user_apartment()
    );
-- ====================================================================
-- 0004_building_fees.sql — richer building address + fee model
--   * country / postal_code on buildings
--   * fee method: fixed amount per apartment, or price per square meter
--   * apartment size (sqm) for per-meter billing
-- Building name is generated by the app as "<address>, <city>".
-- ====================================================================

CREATE TYPE fee_method AS ENUM ('fixed', 'per_sqm');

ALTER TABLE buildings
    ADD COLUMN country VARCHAR(100) NOT NULL DEFAULT 'ישראל',
    ADD COLUMN postal_code VARCHAR(20),
    ADD COLUMN fee_method fee_method NOT NULL DEFAULT 'fixed',
    ADD COLUMN fixed_monthly_fee NUMERIC(10, 2),
    ADD COLUMN price_per_sqm NUMERIC(10, 2);

ALTER TABLE apartments
    ADD COLUMN size_sqm NUMERIC(8, 2);

COMMENT ON COLUMN buildings.fee_method IS
    'fixed = every apartment pays fixed_monthly_fee; per_sqm = apartment pays size_sqm * price_per_sqm';
-- ====================================================================
-- 0005_building_access.sql — platform-level access control
-- Super admins can suspend a whole building (e.g. unpaid subscription).
-- Individual users already have users.is_active.
-- ====================================================================

ALTER TABLE buildings
    ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN buildings.is_active IS
    'FALSE = building suspended by platform admin; all tenant/vaad API access is blocked';
-- ====================================================================
-- 0006_self_serve.sql
-- Self-service flows: a Vaad can create their own building from the
-- app, share a join link (join_code), and approve tenants who ask to
-- join an existing building (join_requests).
-- ====================================================================

ALTER TABLE buildings
    ADD COLUMN IF NOT EXISTS join_code VARCHAR(16) UNIQUE NOT NULL
        DEFAULT encode(gen_random_bytes(5), 'hex'),
    ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_buildings_join_code ON buildings(join_code);

-- Tenant-initiated "let me in" requests, pending Vaad approval.
DO $$ BEGIN
    CREATE TYPE join_request_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS join_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    apartment_number INT,
    full_name VARCHAR(255) NOT NULL DEFAULT '',
    status join_request_status NOT NULL DEFAULT 'pending',
    decided_by UUID REFERENCES users(id),
    decided_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_join_requests_building
    ON join_requests(building_id) WHERE status = 'pending';
-- A user can only have one open request at a time.
CREATE UNIQUE INDEX IF NOT EXISTS uq_join_requests_pending_user
    ON join_requests(user_id) WHERE status = 'pending';

-- All access goes through the service role (like the rest of the API).
ALTER TABLE join_requests ENABLE ROW LEVEL SECURITY;
-- ====================================================================
-- seed.sql — one-time bootstrap
-- Add the platform operator's phone number to the super-admin allowlist.
-- On their first phone-OTP sign-in, the token exchange assigns the
-- super_admin role automatically.
-- ====================================================================

INSERT INTO super_admins (phone_number, label)
VALUES ('+972500000000', 'Platform owner') -- TODO: replace with your phone (E.164)
ON CONFLICT (phone_number) DO NOTHING;
-- ====================================================================
-- 0007_realtime_broadcast.sql
-- Live updates: whenever a row in a building-scoped table changes,
-- broadcast a lightweight "changed" event on the building's Realtime
-- topic (building:<uuid>). The mobile app listens on this public
-- channel and re-fetches the affected data through the authenticated
-- API — the broadcast payload itself carries no row data, only the
-- table name, so nothing sensitive travels over the public channel.
-- ====================================================================

CREATE OR REPLACE FUNCTION notify_building_change() RETURNS trigger AS $$
DECLARE
    bid TEXT;
BEGIN
    bid := COALESCE(
        to_jsonb(NEW) ->> 'building_id',
        to_jsonb(OLD) ->> 'building_id'
    );
    IF bid IS NOT NULL THEN
        PERFORM realtime.send(
            jsonb_build_object('table', TG_TABLE_NAME, 'action', TG_OP),
            'changed',              -- event name the app listens for
            'building:' || bid,     -- one topic per building
            false                   -- public channel (no row data inside)
        );
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- realtime.send never raises, but keep triggers AFTER so a broadcast
-- hiccup can't interfere with the write itself.
DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'tickets', 'ticket_events', 'announcements', 'payments',
        'documents', 'meetings', 'votes', 'vote_ballots',
        'join_requests', 'users', 'vendor_agents', 'expenses'
    ] LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS trg_%I_notify ON %I', t, t
        );
        EXECUTE format(
            'CREATE TRIGGER trg_%I_notify
                 AFTER INSERT OR UPDATE OR DELETE ON %I
                 FOR EACH ROW EXECUTE FUNCTION notify_building_change()',
            t, t
        );
    END LOOP;
END $$;
-- ====================================================================
-- 0008_login_trial.sql
-- Login/onboarding revamp + monetization:
--  * users.email (optional but recommended)
--  * join_requests carry the tenant's full profile so the Vaad can
--    review everything (occupants, floor, parking, email, document)
--    before approving.
--  * buildings get a subscription: self-created buildings start on a
--    14-day trial; the super admin activates (paid), blocks, or
--    extends. Expired trials lose data access.
-- ====================================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255);

ALTER TABLE join_requests
    ADD COLUMN IF NOT EXISTS email VARCHAR(255),
    ADD COLUMN IF NOT EXISTS num_occupants INT,
    ADD COLUMN IF NOT EXISTS floor INT,
    ADD COLUMN IF NOT EXISTS parking_spot VARCHAR(50),
    ADD COLUMN IF NOT EXISTS doc_path TEXT;

DO $$ BEGIN
    CREATE TYPE plan_status AS ENUM ('trial', 'active', 'blocked');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE buildings
    ADD COLUMN IF NOT EXISTS plan_status plan_status NOT NULL DEFAULT 'trial',
    ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMPTZ
        NOT NULL DEFAULT (NOW() + INTERVAL '14 days');

-- Buildings that already exist were provisioned by the super admin —
-- treat them as paid so nothing breaks for current users.
UPDATE buildings SET plan_status = 'active' WHERE plan_status = 'trial';
-- ====================================================================
-- 0009_contact_requests.sql
-- "Contact us" requests (e.g. a Vaad wanting to subscribe after the
-- 14-day trial). Stored in the DB so nothing is lost even when the
-- outgoing email provider isn't configured.
-- ====================================================================

CREATE TABLE IF NOT EXISTS contact_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID REFERENCES buildings(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    email VARCHAR(255),
    message TEXT NOT NULL,
    topic VARCHAR(50) NOT NULL DEFAULT 'subscription',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE contact_requests ENABLE ROW LEVEL SECURITY;
-- Only the service role (API) touches this table; no user policies.
-- ====================================================================
-- 0010_join_docs.sql
-- Join-request documents, round two:
--  * Tenants are asked for an Arnona bill (shows the apartment's sqm,
--    which drives per-sqm Vaad fees) and a proof of residence
--    (rent/purchase agreement). Stored separately so the Vaad knows
--    which is which.
--  * The Vaad can make these uploads mandatory for their building.
-- ====================================================================

ALTER TABLE buildings
    ADD COLUMN IF NOT EXISTS require_join_docs BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE join_requests
    ADD COLUMN IF NOT EXISTS arnona_doc_path TEXT;
-- ====================================================================
-- 0011_expense_details.sql
-- Richer expense records: free-text description and the provider
-- (vendor) the expense was paid to.
-- ====================================================================

ALTER TABLE expenses
    ADD COLUMN IF NOT EXISTS description TEXT,
    ADD COLUMN IF NOT EXISTS provider VARCHAR(255);
-- ====================================================================
-- 0013_audit_log.sql — building activity trail
--
-- One row per meaningful action (tenant joined, vote cast, meeting
-- created, payment marked, ...). Written server-side by the API with
-- the service key; read via GET /api/audit-logs (Vaad sees their
-- building, super admin sees everything).
-- action  = stable machine key, localized by the clients
-- details = small JSON blob with action-specific context
-- ====================================================================

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID REFERENCES buildings(id) ON DELETE CASCADE,
    actor_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(60) NOT NULL,
    entity_type VARCHAR(40),
    entity_id UUID,
    details JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_building
    ON audit_logs (building_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created
    ON audit_logs (created_at DESC);

-- Server-only table: no client RLS policies; the API uses the service
-- key and scopes reads itself.
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Live updates on the building topic, same as other scoped tables.
DROP TRIGGER IF EXISTS trg_audit_logs_notify ON audit_logs;
CREATE TRIGGER trg_audit_logs_notify
    AFTER INSERT ON audit_logs
    FOR EACH ROW EXECUTE FUNCTION notify_building_change();
-- ====================================================================
-- 0014_tenancies.sql — apartment occupancy history (rentals)
--
-- Buildings have rental units whose holders change over time. Each
-- tenancy row is one holding period: who held the apartment, as owner
-- or renter, from when to when. Ending a tenancy records what was
-- decided about open debts. History survives the user leaving.
-- status: active  — current holder
--         pending — incoming holder who hasn't completed details yet
--         ended   — past holder (ended_at set)
-- ====================================================================

CREATE TABLE IF NOT EXISTS tenancies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    apartment_id UUID NOT NULL REFERENCES apartments(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    full_name VARCHAR(255),
    phone_number VARCHAR(20),
    holder_type VARCHAR(10) NOT NULL DEFAULT 'renter', -- owner | renter
    num_occupants INT,
    started_at DATE NOT NULL DEFAULT CURRENT_DATE,
    ended_at DATE,
    -- keep_with_outgoing | transfer_to_owner | closed
    end_debt_policy VARCHAR(30),
    status VARCHAR(12) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tenancies_apartment
    ON tenancies (apartment_id, started_at DESC);

ALTER TABLE tenancies ENABLE ROW LEVEL SECURITY;
-- Server-only table: the API uses the service key and scopes access.

-- Live updates on the building topic.
DROP TRIGGER IF EXISTS trg_tenancies_notify ON tenancies;
CREATE TRIGGER trg_tenancies_notify
    AFTER INSERT OR UPDATE OR DELETE ON tenancies
    FOR EACH ROW EXECUTE FUNCTION notify_building_change();

-- Backfill: every resident currently attached to an apartment becomes
-- an open tenancy that started when their profile was created.
INSERT INTO tenancies (building_id, apartment_id, user_id, full_name, phone_number, num_occupants, started_at, status)
SELECT u.building_id, u.apartment_id, u.id, u.full_name, u.phone_number,
       u.num_occupants, u.created_at::date, 'active'
FROM users u
WHERE u.apartment_id IS NOT NULL
  AND u.building_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM tenancies t
      WHERE t.user_id = u.id AND t.apartment_id = u.apartment_id
  );
-- ====================================================================
-- 0015_vote_multi.sql — WhatsApp-style polls
--
-- Votes get custom answer options (already JSONB) plus an
-- allow_multiple flag. Ballots become one row per selected option so a
-- multi-answer poll stores each pick; single-answer polls are enforced
-- by the API. The apartment-level "already voted" check now spans all
-- of the unit's ballot rows.
-- ====================================================================

ALTER TABLE votes ADD COLUMN IF NOT EXISTS allow_multiple BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE vote_ballots DROP CONSTRAINT IF EXISTS vote_ballots_vote_id_apartment_id_key;
ALTER TABLE vote_ballots DROP CONSTRAINT IF EXISTS vote_ballots_vote_apartment_option_key;
ALTER TABLE vote_ballots
    ADD CONSTRAINT vote_ballots_vote_apartment_option_key
    UNIQUE (vote_id, apartment_id, selected_option);
