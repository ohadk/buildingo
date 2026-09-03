-- ====================================================================
-- 0031_building_address_hash.sql
-- Unique building identity = country + city + street address (w/ number).
-- Store an MD5 hash of the normalized triple for O(1) exact lookups and
-- a partial unique index on active buildings.
-- Keep in sync with apps/web/src/lib/building-address.ts
-- ====================================================================

ALTER TABLE buildings
    ADD COLUMN IF NOT EXISTS address_hash CHAR(32);

-- Normalize helpers (mirror of TS normalizeAddressPart / normalizeCountry).
CREATE OR REPLACE FUNCTION dira_normalize_address_part(value TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT lower(trim(both FROM regexp_replace(coalesce(value, ''), '\s+', ' ', 'g')));
$$;

CREATE OR REPLACE FUNCTION dira_normalize_country(value TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE
        WHEN dira_normalize_address_part(value) IN (
            'israel', 'il', 'ישראל', 'state of israel', ''
        ) THEN 'ישראל'
        ELSE dira_normalize_address_part(value)
    END;
$$;

CREATE OR REPLACE FUNCTION dira_building_address_hash(
    country TEXT,
    city TEXT,
    address TEXT
)
RETURNS CHAR(32)
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT md5(
        dira_normalize_country(country)
        || E'\n'
        || dira_normalize_address_part(city)
        || E'\n'
        || dira_normalize_address_part(address)
    );
$$;

CREATE OR REPLACE FUNCTION buildings_set_address_hash()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.address_hash := dira_building_address_hash(
        NEW.country,
        NEW.city,
        NEW.address
    );
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_buildings_address_hash ON buildings;
CREATE TRIGGER trg_buildings_address_hash
    BEFORE INSERT OR UPDATE OF address, city, country
    ON buildings
    FOR EACH ROW
    EXECUTE FUNCTION buildings_set_address_hash();

-- Backfill existing rows.
UPDATE buildings
SET address_hash = dira_building_address_hash(country, city, address)
WHERE address_hash IS NULL
   OR address_hash <> dira_building_address_hash(country, city, address);

-- If active duplicates already exist, keep the oldest and deactivate the rest
-- so the unique index can be created.
WITH ranked AS (
    SELECT id,
           address_hash,
           ROW_NUMBER() OVER (
               PARTITION BY address_hash
               ORDER BY created_at ASC NULLS LAST, id ASC
           ) AS rn
    FROM buildings
    WHERE is_active
)
UPDATE buildings b
SET is_active = FALSE
FROM ranked r
WHERE b.id = r.id
  AND r.rn > 1;

ALTER TABLE buildings
    ALTER COLUMN address_hash SET NOT NULL;

-- Prefer the hash unique index; drop the older (city, address) one.
DROP INDEX IF EXISTS uq_buildings_active_address;

CREATE UNIQUE INDEX IF NOT EXISTS uq_buildings_active_address_hash
    ON buildings (address_hash)
    WHERE is_active;

COMMENT ON COLUMN buildings.address_hash IS
    'MD5 of normalized country\\ncity\\naddress — unique among active buildings';
