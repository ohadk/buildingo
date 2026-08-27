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
