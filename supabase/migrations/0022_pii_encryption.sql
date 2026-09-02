-- Field-level PII protection: HMAC hash columns for indexed lookups,
-- encrypted columns for display. Plaintext columns remain during
-- migration; backfill via `npm run backfill:pii` then clear plaintext.

-- users
ALTER TABLE users ALTER COLUMN phone_number DROP NOT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_number_hash TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_number_enc TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS full_name_enc TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_hash TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_enc TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone_hash
    ON users(phone_number_hash) WHERE phone_number_hash IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_email_hash
    ON users(email_hash) WHERE email_hash IS NOT NULL;

-- super_admins (phone allowlist)
ALTER TABLE super_admins ALTER COLUMN phone_number DROP NOT NULL;
ALTER TABLE super_admins ADD COLUMN IF NOT EXISTS phone_number_hash TEXT;
ALTER TABLE super_admins ADD COLUMN IF NOT EXISTS phone_number_enc TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_super_admins_phone_hash
    ON super_admins(phone_number_hash) WHERE phone_number_hash IS NOT NULL;

-- invitations
ALTER TABLE invitations ADD COLUMN IF NOT EXISTS phone_number_hash TEXT;
ALTER TABLE invitations ADD COLUMN IF NOT EXISTS phone_number_enc TEXT;

CREATE INDEX IF NOT EXISTS idx_invitations_phone_hash
    ON invitations(phone_number_hash) WHERE status = 'pending';

-- tenancies (historical occupancy snapshots)
ALTER TABLE tenancies ADD COLUMN IF NOT EXISTS phone_number_hash TEXT;
ALTER TABLE tenancies ADD COLUMN IF NOT EXISTS phone_number_enc TEXT;
ALTER TABLE tenancies ADD COLUMN IF NOT EXISTS full_name_enc TEXT;

-- join_requests
ALTER TABLE join_requests ADD COLUMN IF NOT EXISTS full_name_enc TEXT;
ALTER TABLE join_requests ADD COLUMN IF NOT EXISTS email_hash TEXT;
ALTER TABLE join_requests ADD COLUMN IF NOT EXISTS email_enc TEXT;

-- contact_requests (public form submissions)
ALTER TABLE contact_requests ADD COLUMN IF NOT EXISTS phone_hash TEXT;
ALTER TABLE contact_requests ADD COLUMN IF NOT EXISTS phone_enc TEXT;
ALTER TABLE contact_requests ADD COLUMN IF NOT EXISTS email_hash TEXT;
ALTER TABLE contact_requests ADD COLUMN IF NOT EXISTS email_enc TEXT;
ALTER TABLE contact_requests ADD COLUMN IF NOT EXISTS name_enc TEXT;
