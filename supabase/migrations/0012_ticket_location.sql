-- ====================================================================
-- 0012_ticket_location.sql — where in the building the fault is
-- (free-text label: a floor number, the lobby, parking, roof, etc.)
-- ====================================================================

ALTER TABLE tickets ADD COLUMN IF NOT EXISTS location VARCHAR(100);
