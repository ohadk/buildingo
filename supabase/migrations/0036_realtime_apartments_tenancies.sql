-- ====================================================================
-- 0036_realtime_apartments_tenancies.sql
-- Broadcast apartment / tenancy changes so the Residents directory
-- refreshes when a join request is approved (user attach + tenancy).
-- ====================================================================

DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['apartments', 'tenancies'] LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS trg_%I_notify ON %I', t, t
        );
        EXECUTE format(
            'CREATE TRIGGER trg_%I_notify
                 AFTER INSERT OR UPDATE OR DELETE ON %I
                 FOR EACH ROW EXECUTE FUNCTION notify_building_change()',
            t, t
        );
    END LOOP;
END $$;
