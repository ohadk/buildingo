-- ====================================================================
-- 0011_expense_details.sql
-- Richer expense records: free-text description and the provider
-- (vendor) the expense was paid to.
-- ====================================================================

ALTER TABLE expenses
    ADD COLUMN IF NOT EXISTS description TEXT,
    ADD COLUMN IF NOT EXISTS provider VARCHAR(255);
