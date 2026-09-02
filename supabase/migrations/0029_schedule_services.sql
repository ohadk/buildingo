-- ====================================================================
-- 0029_schedule_services.sql — recurring building services metadata
--   * monthly_cost / provider_name on schedule events
--   * quarterly + yearly recurrence
--   * extra event types for onboarding presets
-- ====================================================================

ALTER TABLE schedule_events
    ADD COLUMN IF NOT EXISTS monthly_cost NUMERIC(10, 2),
    ADD COLUMN IF NOT EXISTS provider_name VARCHAR(255);

ALTER TABLE schedule_events
    DROP CONSTRAINT IF EXISTS schedule_events_recurrence_check;

ALTER TABLE schedule_events
    ADD CONSTRAINT schedule_events_recurrence_check
    CHECK (recurrence IN (
        'once', 'daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'yearly'
    ));

-- Drop and recreate the recurrence shape check to include quarterly/yearly.
ALTER TABLE schedule_events
    DROP CONSTRAINT IF EXISTS schedule_events_check;

ALTER TABLE schedule_events
    ADD CONSTRAINT schedule_events_check CHECK (
        (recurrence = 'once' AND specific_date IS NOT NULL)
        OR (recurrence = 'daily')
        OR (recurrence IN ('weekly', 'biweekly') AND day_of_week IS NOT NULL)
        OR (recurrence IN ('monthly', 'quarterly', 'yearly') AND day_of_month IS NOT NULL)
    );

-- New enum values (safe to re-run if already present).
DO $$ BEGIN
    ALTER TYPE schedule_event_type ADD VALUE IF NOT EXISTS 'gardening';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TYPE schedule_event_type ADD VALUE IF NOT EXISTS 'pest';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TYPE schedule_event_type ADD VALUE IF NOT EXISTS 'water_tank';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

COMMENT ON COLUMN schedule_events.monthly_cost IS
    'Optional fixed monthly cost for this recurring service (₪)';
COMMENT ON COLUMN schedule_events.provider_name IS
    'Optional vendor / municipality name for the service';
