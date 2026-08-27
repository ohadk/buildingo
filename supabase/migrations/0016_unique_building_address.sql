-- ====================================================================
-- 0016_unique_building_address.sql
-- One building per physical address: a case/whitespace-insensitive
-- unique index on (city, address) for active buildings. Guarantees a
-- single canonical UUID per address — address search can only ever
-- resolve to that one row. Deactivated buildings are excluded so an
-- address can be re-registered after the old building is archived.
-- ====================================================================

CREATE UNIQUE INDEX IF NOT EXISTS uq_buildings_active_address
    ON buildings (lower(trim(city)), lower(trim(address)))
    WHERE is_active;
