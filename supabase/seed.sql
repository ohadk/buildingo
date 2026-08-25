-- ====================================================================
-- seed.sql — one-time bootstrap
-- Add the platform operator's phone number to the super-admin allowlist.
-- On their first phone-OTP sign-in, the token exchange assigns the
-- super_admin role automatically.
-- ====================================================================

INSERT INTO super_admins (phone_number, label)
VALUES ('+972500000000', 'Platform owner') -- TODO: replace with your phone (E.164)
ON CONFLICT (phone_number) DO NOTHING;
