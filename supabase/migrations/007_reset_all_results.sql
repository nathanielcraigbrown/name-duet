-- Reset all ranking results while preserving the app setup.
-- This deletes every recorded vote and every Elo/ranking row for all participants.
-- It intentionally preserves:
--   * rooms and room tokens
--   * participants and participant access tokens
--   * device links
--   * the full name catalog and metadata
-- Rankings will be recreated automatically at the default rating the next time
-- each participant requests a comparison pair.

begin;

-- Votes reference rankings conceptually, so clear vote history first.
delete from public.votes;

-- Remove all accumulated Elo ratings, wins, losses, and comparison counts.
delete from public.rankings;

commit;

-- Verification: both values should be zero.
select
  (select count(*) from public.votes) as remaining_votes,
  (select count(*) from public.rankings) as remaining_rankings;
