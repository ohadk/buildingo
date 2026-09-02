-- Apartment size (from Arnona bill) captured during tenant onboarding.
ALTER TABLE join_requests
    ADD COLUMN IF NOT EXISTS size_sqm NUMERIC(8, 2);

COMMENT ON COLUMN join_requests.size_sqm IS
    'Sqm from Arnona bill; copied to apartments.size_sqm on approval when per_sqm fees apply.';
