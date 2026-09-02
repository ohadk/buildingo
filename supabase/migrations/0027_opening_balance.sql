-- Opening bank balance set by the Vaad during building onboarding.
-- Cash position = opening_balance + paid dues − expenses.
ALTER TABLE buildings
  ADD COLUMN IF NOT EXISTS opening_balance NUMERIC(12, 2) NOT NULL DEFAULT 0;

COMMENT ON COLUMN buildings.opening_balance IS
  'Starting bank/cash balance when the building joined Buildingo; used as the baseline for יתרת בניין.';
