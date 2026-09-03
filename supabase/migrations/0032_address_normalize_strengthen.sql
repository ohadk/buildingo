-- ====================================================================
-- 0032_address_normalize_strengthen.sql
-- Strengthen address_hash normalization so "רח מייזנר 17" ≡ "מייזנר 17"
-- and common city aliases (פתח תקוה → פתח תקווה) share one hash.
-- Keep in sync with apps/web/src/lib/building-address.ts
-- ====================================================================

CREATE OR REPLACE FUNCTION dira_normalize_address_part(value TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT lower(trim(both FROM regexp_replace(coalesce(value, ''), '\s+', ' ', 'g')));
$$;

CREATE OR REPLACE FUNCTION dira_normalize_city(value TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE dira_normalize_address_part(value)
        WHEN 'פתח תקוה' THEN 'פתח תקווה'
        WHEN 'פתח-תקווה' THEN 'פתח תקווה'
        WHEN 'פתח-תקוה' THEN 'פתח תקווה'
        WHEN 'petah tikva' THEN 'פתח תקווה'
        WHEN 'petah tiqwa' THEN 'פתח תקווה'
        WHEN 'petach tikva' THEN 'פתח תקווה'
        WHEN 'תל אביב' THEN 'תל אביב - יפו'
        WHEN 'תל אביב יפו' THEN 'תל אביב - יפו'
        WHEN 'תל-אביב' THEN 'תל אביב - יפו'
        WHEN 'tel aviv' THEN 'תל אביב - יפו'
        WHEN 'tel aviv-yafo' THEN 'תל אביב - יפו'
        WHEN 'ראשלצ' THEN 'ראשון לציון'
        ELSE dira_normalize_address_part(value)
    END;
$$;

CREATE OR REPLACE FUNCTION dira_normalize_street_address(value TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
    WITH base AS (
        SELECT dira_normalize_address_part(value) AS s
    ),
    stripped AS (
        SELECT regexp_replace(
            s,
            '^(רחוב|רח''|רח׳|רח|street|st\.?|שדרות|שד''|שד׳|שד|avenue|ave\.?|סמטת|סמטה|סמ''|סמ׳|סמ|alley)[[:space:]]+',
            '',
            'i'
        ) AS s
        FROM base
    )
    SELECT trim(both FROM regexp_replace(
        regexp_replace(s, '^(רחוב|רח''|רח׳|רח|street|st\.?|שדרות|שד''|שד׳|שד|avenue|ave\.?|סמטת|סמטה|סמ''|סמ׳|סמ|alley)[[:space:]]+', '', 'i'),
        '^["''׳״]+|["''׳״]+$',
        '',
        'g'
    ))
    FROM stripped;
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
        || dira_normalize_city(city)
        || E'\n'
        || dira_normalize_street_address(address)
    );
$$;

-- Recompute hashes with the stronger normalizer.
UPDATE buildings
SET address_hash = dira_building_address_hash(country, city, address);

-- Collapse any new collisions: keep oldest active row.
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

CREATE UNIQUE INDEX IF NOT EXISTS uq_buildings_active_address_hash
    ON buildings (address_hash)
    WHERE is_active;
