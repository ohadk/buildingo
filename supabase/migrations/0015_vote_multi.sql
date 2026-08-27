-- ====================================================================
-- 0015_vote_multi.sql — WhatsApp-style polls
--
-- Votes get custom answer options (already JSONB) plus an
-- allow_multiple flag. Ballots become one row per selected option so a
-- multi-answer poll stores each pick; single-answer polls are enforced
-- by the API. The apartment-level "already voted" check now spans all
-- of the unit's ballot rows.
-- ====================================================================

ALTER TABLE votes ADD COLUMN IF NOT EXISTS allow_multiple BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE vote_ballots DROP CONSTRAINT IF EXISTS vote_ballots_vote_id_apartment_id_key;
ALTER TABLE vote_ballots DROP CONSTRAINT IF EXISTS vote_ballots_vote_apartment_option_key;
ALTER TABLE vote_ballots
    ADD CONSTRAINT vote_ballots_vote_apartment_option_key
    UNIQUE (vote_id, apartment_id, selected_option);
