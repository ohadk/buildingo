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
