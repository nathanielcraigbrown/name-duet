-- Remove the mistakenly added curated name Fey.
-- Safe to run whether or not migration 012 was previously applied.

begin;

delete from public.rankings
where name_id in (select id from public.names where display_name = 'Fey');

delete from public.votes
where left_name_id in (select id from public.names where display_name = 'Fey')
   or right_name_id in (select id from public.names where display_name = 'Fey')
   or winner_name_id in (select id from public.names where display_name = 'Fey');

delete from public.names
where display_name = 'Fey';

commit;

select count(*) as fey_rows_remaining
from public.names
where display_name = 'Fey';