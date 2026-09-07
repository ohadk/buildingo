-- Ensure join_requests.size_sqm exists (was missing on some prod DBs →
-- PostgREST "schema cache" errors on join with Arnona sqm).
-- Reset join docs to optional by default for all buildings.

ALTER TABLE join_requests
    ADD COLUMN IF NOT EXISTS size_sqm NUMERIC(8, 2);

COMMENT ON COLUMN join_requests.size_sqm IS
    'Sqm from Arnona bill; copied to apartments.size_sqm on approval when per_sqm fees apply.';

ALTER TABLE buildings
    ALTER COLUMN require_join_docs SET DEFAULT FALSE;

UPDATE buildings
SET require_join_docs = FALSE
WHERE require_join_docs IS DISTINCT FROM FALSE;
