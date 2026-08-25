-- ====================================================================
-- 0007_realtime_broadcast.sql
-- Live updates: whenever a row in a building-scoped table changes,
-- broadcast a lightweight "changed" event on the building's Realtime
-- topic (building:<uuid>). The mobile app listens on this public
-- channel and re-fetches the affected data through the authenticated
-- API — the broadcast payload itself carries no row data, only the
-- table name, so nothing sensitive travels over the public channel.
-- ====================================================================

CREATE OR REPLACE FUNCTION notify_building_change() RETURNS trigger AS $$
DECLARE
    bid TEXT;
BEGIN
    bid := COALESCE(
        to_jsonb(NEW) ->> 'building_id',
        to_jsonb(OLD) ->> 'building_id'
    );
    IF bid IS NOT NULL THEN
        PERFORM realtime.send(
            jsonb_build_object('table', TG_TABLE_NAME, 'action', TG_OP),
            'changed',              -- event name the app listens for
            'building:' || bid,     -- one topic per building
            false                   -- public channel (no row data inside)
        );
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- realtime.send never raises, but keep triggers AFTER so a broadcast
-- hiccup can't interfere with the write itself.
DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'tickets', 'ticket_events', 'announcements', 'payments',
        'documents', 'meetings', 'votes', 'vote_ballots',
        'join_requests', 'users', 'vendor_agents', 'expenses'
    ] LOOP
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
