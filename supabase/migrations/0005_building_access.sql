-- ====================================================================
-- 0005_building_access.sql — platform-level access control
-- Super admins can suspend a whole building (e.g. unpaid subscription).
-- Individual users already have users.is_active.
-- ====================================================================

ALTER TABLE buildings
    ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN buildings.is_active IS
    'FALSE = building suspended by platform admin; all tenant/vaad API access is blocked';
