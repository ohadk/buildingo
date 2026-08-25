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
