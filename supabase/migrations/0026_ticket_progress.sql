-- Progress details while a ticket is in progress (provider opened, parts
-- ordered, scheduled fix date, free-text note). Visible to all residents.
ALTER TABLE tickets
  ADD COLUMN IF NOT EXISTS progress_note TEXT,
  ADD COLUMN IF NOT EXISTS fix_date DATE;
