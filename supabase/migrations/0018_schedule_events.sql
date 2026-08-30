-- Building schedule: garbage collection, cleaning, bulk waste, etc.

CREATE TYPE schedule_event_type AS ENUM ('garbage', 'cleaning', 'bulk_waste', 'other');

CREATE TABLE schedule_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    event_type schedule_event_type NOT NULL DEFAULT 'other',
    title VARCHAR(255) NOT NULL,
    notes TEXT,
    recurrence TEXT NOT NULL DEFAULT 'weekly'
        CHECK (recurrence IN ('once', 'daily', 'weekly', 'biweekly', 'monthly')),
    day_of_week SMALLINT CHECK (day_of_week IS NULL OR (day_of_week BETWEEN 0 AND 6)),
    day_of_month SMALLINT CHECK (day_of_month IS NULL OR (day_of_month BETWEEN 1 AND 31)),
    specific_date DATE,
    time_of_day TIME,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (
        (recurrence = 'once' AND specific_date IS NOT NULL)
        OR (recurrence = 'daily')
        OR (recurrence IN ('weekly', 'biweekly') AND day_of_week IS NOT NULL)
        OR (recurrence = 'monthly' AND day_of_month IS NOT NULL)
    )
);

CREATE INDEX idx_schedule_events_building ON schedule_events(building_id);

ALTER TABLE schedule_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY superadmin_all_schedule_events ON schedule_events FOR ALL
    USING (is_super_admin()) WITH CHECK (is_super_admin());

CREATE POLICY view_building_schedule_events ON schedule_events FOR SELECT
    USING (in_building(building_id));

CREATE POLICY vaad_manage_schedule_events ON schedule_events FOR ALL
    USING (is_vaad_of(building_id)) WITH CHECK (is_vaad_of(building_id));

CREATE TRIGGER trg_schedule_events_notify
    AFTER INSERT OR UPDATE OR DELETE ON schedule_events
    FOR EACH ROW EXECUTE FUNCTION notify_building_change();
