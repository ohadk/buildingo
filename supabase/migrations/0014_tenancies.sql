-- ====================================================================
-- 0014_tenancies.sql — apartment occupancy history (rentals)
--
-- Buildings have rental units whose holders change over time. Each
-- tenancy row is one holding period: who held the apartment, as owner
-- or renter, from when to when. Ending a tenancy records what was
-- decided about open debts. History survives the user leaving.
-- status: active  — current holder
--         pending — incoming holder who hasn't completed details yet
--         ended   — past holder (ended_at set)
-- ====================================================================

CREATE TABLE IF NOT EXISTS tenancies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    apartment_id UUID NOT NULL REFERENCES apartments(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    full_name VARCHAR(255),
    phone_number VARCHAR(20),
    holder_type VARCHAR(10) NOT NULL DEFAULT 'renter', -- owner | renter
    num_occupants INT,
    started_at DATE NOT NULL DEFAULT CURRENT_DATE,
    ended_at DATE,
    -- keep_with_outgoing | transfer_to_owner | closed
    end_debt_policy VARCHAR(30),
    status VARCHAR(12) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tenancies_apartment
    ON tenancies (apartment_id, started_at DESC);

ALTER TABLE tenancies ENABLE ROW LEVEL SECURITY;
-- Server-only table: the API uses the service key and scopes access.

-- Live updates on the building topic.
DROP TRIGGER IF EXISTS trg_tenancies_notify ON tenancies;
CREATE TRIGGER trg_tenancies_notify
    AFTER INSERT OR UPDATE OR DELETE ON tenancies
    FOR EACH ROW EXECUTE FUNCTION notify_building_change();

-- Backfill: every resident currently attached to an apartment becomes
-- an open tenancy that started when their profile was created.
INSERT INTO tenancies (building_id, apartment_id, user_id, full_name, phone_number, num_occupants, started_at, status)
SELECT u.building_id, u.apartment_id, u.id, u.full_name, u.phone_number,
       u.num_occupants, u.created_at::date, 'active'
FROM users u
WHERE u.apartment_id IS NOT NULL
  AND u.building_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM tenancies t
      WHERE t.user_id = u.id AND t.apartment_id = u.apartment_id
  );
