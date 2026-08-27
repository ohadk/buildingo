-- ====================================================================
-- 0017_user_avatar.sql — profile pictures
-- avatars/  {user_id}/{filename}   (private; served via signed URLs
-- from the API, which is also the only writer — service role).
-- ====================================================================

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS avatar_path TEXT;

INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', false)
ON CONFLICT (id) DO NOTHING;
