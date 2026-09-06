-- Optional label for community-board cards (icon + color on home).
ALTER TABLE announcements
  ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'update'
    CHECK (category IN ('update', 'meeting', 'maintenance', 'tip', 'other'));

CREATE INDEX IF NOT EXISTS idx_announcements_category
  ON announcements(building_id, category);
