-- ====================================================================
-- 0028_building_onboarding_meta.sql — Vaad onboarding fields
--   * district / region on address
--   * entrances (codes) + elevator count
--   * billing day + typical apartment size for per-sqm fee preview
-- ====================================================================

ALTER TABLE buildings
    ADD COLUMN IF NOT EXISTS district VARCHAR(100),
    ADD COLUMN IF NOT EXISTS elevator_count INT NOT NULL DEFAULT 0
        CHECK (elevator_count >= 0 AND elevator_count <= 50),
    ADD COLUMN IF NOT EXISTS entrances JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS billing_day INT NOT NULL DEFAULT 1
        CHECK (billing_day BETWEEN 1 AND 28),
    ADD COLUMN IF NOT EXISTS typical_apartment_sqm NUMERIC(8, 2);

COMMENT ON COLUMN buildings.entrances IS
    'Array of {name, code} entrance objects from Vaad onboarding';
COMMENT ON COLUMN buildings.typical_apartment_sqm IS
    'Default apartment size used until each unit has size_sqm set';
