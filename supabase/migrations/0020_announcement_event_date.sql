-- Optional calendar date on community announcements (shown on building schedule).

ALTER TABLE announcements
  ADD COLUMN IF NOT EXISTS event_date DATE;

CREATE INDEX IF NOT EXISTS idx_announcements_event_date
  ON announcements(building_id, event_date)
  WHERE event_date IS NOT NULL;
