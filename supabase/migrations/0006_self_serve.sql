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
