-- ====================================================================
-- 0010_join_docs.sql
-- Join-request documents, round two:
--  * Tenants are asked for an Arnona bill (shows the apartment's sqm,
--    which drives per-sqm Vaad fees) and a proof of residence
--    (rent/purchase agreement). Stored separately so the Vaad knows
--    which is which.
--  * The Vaad can make these uploads mandatory for their building.
-- ====================================================================

ALTER TABLE buildings
    ADD COLUMN IF NOT EXISTS require_join_docs BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE join_requests
    ADD COLUMN IF NOT EXISTS arnona_doc_path TEXT;
