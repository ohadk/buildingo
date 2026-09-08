-- ====================================================================
-- 0037_user_account_status.sql
-- User account lifecycle:
--   account_status on users  → fast auth gate (active/suspended/deleted)
--   user_status_events       → full history for super-admin audit
-- Building billing block stays on buildings.plan_status / is_active.
-- Soft-deleted accounts keep the row; active-only unique indexes free
-- phone / Firebase UID for a fresh sign-up.
-- ====================================================================

DO $$ BEGIN
  CREATE TYPE user_account_status AS ENUM ('active', 'suspended', 'deleted');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS account_status user_account_status NOT NULL DEFAULT 'active';

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS status_reason TEXT;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS status_changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

COMMENT ON COLUMN users.account_status IS
  'active = normal; suspended = admin pause (can sign in, sees blocker); deleted = user-initiated soft delete';
COMMENT ON COLUMN users.status_reason IS
  'Human-readable reason shown on the blocker / admin history';
COMMENT ON COLUMN users.deleted_at IS
  'Set when account_status becomes deleted (App Store account deletion)';

-- Backfill from legacy is_active boolean (before soft-delete existed).
UPDATE users
SET
  account_status = 'suspended',
  status_reason = COALESCE(status_reason, 'Migrated from is_active=false'),
  status_changed_at = COALESCE(status_changed_at, NOW()),
  is_active = false
WHERE is_active = false
  AND account_status = 'active'
  AND deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS user_status_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status user_account_status NOT NULL,
  reason TEXT,
  changed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_status_events_user
  ON user_status_events (user_id, created_at DESC);

ALTER TABLE user_status_events ENABLE ROW LEVEL SECURITY;

-- Seed history for already-suspended rows (idempotent-ish: only if no events).
INSERT INTO user_status_events (user_id, status, reason, changed_by)
SELECT u.id, u.account_status, u.status_reason, NULL
FROM users u
WHERE u.account_status = 'suspended'
  AND NOT EXISTS (
    SELECT 1 FROM user_status_events e WHERE e.user_id = u.id
  );

-- Original table uniques block re-registration after soft delete.
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_phone_number_key;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_firebase_uid_key;

DROP INDEX IF EXISTS idx_users_phone_hash;
DROP INDEX IF EXISTS idx_users_firebase_uid;
DROP INDEX IF EXISTS idx_users_phone_hash_active;
DROP INDEX IF EXISTS uq_users_phone_active;
DROP INDEX IF EXISTS uq_users_firebase_uid_active;

-- phone_number_hash only exists after 0022_pii_encryption; skip if absent.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'users'
      AND column_name = 'phone_number_hash'
  ) THEN
    EXECUTE $i$
      CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone_hash_active
        ON users (phone_number_hash)
        WHERE phone_number_hash IS NOT NULL AND account_status <> 'deleted'
    $i$;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_users_phone_active
  ON users (phone_number)
  WHERE phone_number IS NOT NULL AND account_status <> 'deleted';

CREATE UNIQUE INDEX IF NOT EXISTS uq_users_firebase_uid_active
  ON users (firebase_uid)
  WHERE account_status <> 'deleted';

CREATE INDEX IF NOT EXISTS idx_users_account_status
  ON users (account_status);

CREATE INDEX IF NOT EXISTS idx_users_deleted_at
  ON users (deleted_at)
  WHERE deleted_at IS NOT NULL;
