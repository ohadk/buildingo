-- ====================================================================
-- 0030_parking_spots.sql — apartments can have multiple parking spots
-- ====================================================================

-- apartments.parking_spot (varchar) → parking_spots (text[])
ALTER TABLE apartments
  ADD COLUMN IF NOT EXISTS parking_spots TEXT[] NOT NULL DEFAULT '{}';

UPDATE apartments
SET parking_spots = ARRAY[btrim(parking_spot)]
WHERE parking_spot IS NOT NULL
  AND btrim(parking_spot) <> ''
  AND (parking_spots IS NULL OR parking_spots = '{}');

ALTER TABLE apartments DROP COLUMN IF EXISTS parking_spot;

-- join_requests.parking_spot → parking_spots
ALTER TABLE join_requests
  ADD COLUMN IF NOT EXISTS parking_spots TEXT[] NOT NULL DEFAULT '{}';

UPDATE join_requests
SET parking_spots = ARRAY[btrim(parking_spot)]
WHERE parking_spot IS NOT NULL
  AND btrim(parking_spot) <> ''
  AND (parking_spots IS NULL OR parking_spots = '{}');

ALTER TABLE join_requests DROP COLUMN IF EXISTS parking_spot;
