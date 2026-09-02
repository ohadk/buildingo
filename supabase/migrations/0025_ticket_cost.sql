-- Vaad can record the repair cost + receipt on a resolved ticket.
-- Tenants see the amount and receipt on the ticket; the cost is also
-- mirrored as a building expense so it shows up in finances.
ALTER TABLE tickets
  ADD COLUMN IF NOT EXISTS cost_amount NUMERIC(12, 2),
  ADD COLUMN IF NOT EXISTS receipt_path TEXT;

ALTER TABLE expenses
  ADD COLUMN IF NOT EXISTS ticket_id UUID REFERENCES tickets(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_expenses_ticket
  ON expenses (ticket_id)
  WHERE ticket_id IS NOT NULL;
