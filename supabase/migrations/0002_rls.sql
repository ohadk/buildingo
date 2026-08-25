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
