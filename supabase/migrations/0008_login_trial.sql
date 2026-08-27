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
