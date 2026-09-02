-- Ticket fault category (icon key chosen by the reporter).
ALTER TABLE tickets
  ADD COLUMN IF NOT EXISTS category VARCHAR(40) NOT NULL DEFAULT 'other';
