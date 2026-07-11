-- Backfill 2025 SSA ranks for every active name that appears in the full Top 1,000.
-- Names absent from the Top 1,000 remain NULL and display as SSA N/A.
-- Also removes the mistakenly added Fey entry if it still exists.

begin;

-- Remove mistaken Fey safely and idempotently.
delete from public.rankings
where name_id in (select id from public.names where display_name = 'Fey');

delete from public.votes
where left_name_id in (select id from public.names where display_name = 'Fey')
   or right_name_id in (select id from public.names where display_name = 'Fey')
   or winner_name_id in (select id from public.names where display_name = 'Fey');

delete from public.names where display_name = 'Fey';

create temporary table active_ssa_rank_backfill (
  display_name text primary key,
  ssa_rank integer
) on commit drop;

insert into active_ssa_rank_backfill (display_name, ssa_rank) values
  ('Aurelia',290),
  ('Molly',196),
  ('Sabina',null),
  ('Sabine',null),
  ('Sabrina',321),
  ('Corinne',null),
  ('Ramona',731),
  ('Lucille',239),
  ('Marina',600),
  ('Leona',427),
  ('Caledonia',null),
  ('Calliope',449),
  ('Euroletta',null),
  ('Celia',772),
  ('Phoebe',157),
  ('Skye',530),
  ('Summer',152),
  ('Helena',361),
  ('Denise',null),
  ('Liza',null),
  ('Shea',null),
  ('Faye',513),
  ('Eliza',115),
  ('Juliet',274),
  ('Cecilia',108),
  ('Sylvie',282),
  ('Margot',102),
  ('Daphne',178),
  ('Nina',324),
  ('Louisa',695),
  ('Thea',351),
  ('Ada',219),
  ('Rose',114),
  ('June',150),
  ('Willa',420),
  ('Matilda',363),
  ('Esme',298),
  ('Simone',996),
  ('Cora',113),
  ('Diana',244),
  ('Fiona',468),
  ('Flora',605),
  ('Greer',null),
  ('Ingrid',null),
  ('Adelaide',289);

update public.names n
set ssa_rank = b.ssa_rank
from active_ssa_rank_backfill b
where n.display_name = b.display_name;

create or replace function public.get_next_pair(p_access_token uuid)
returns table(
  left_id bigint,
  left_name text,
  right_id bigint,
  right_name text,
  comparison_count integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  target_participant public.participants;
  first_choice public.rankings;
begin
  select * into target_participant
  from public.participants
  where access_token = p_access_token;

  if target_participant.id is null then
    raise exception 'Invalid participant token';
  end if;

  insert into public.rankings (participant_id, name_id)
  select target_participant.id, n.id
  from public.names n
  on conflict (participant_id, name_id) do nothing;

  select r.* into first_choice
  from public.rankings r
  where r.participant_id = target_participant.id
  order by r.comparisons asc, random()
  limit 1;

  return query
  select
    first_choice.name_id,
    concat_ws(
      E'\n',
      ln.display_name,
      concat_ws(
        ' · ',
        case when ln.ssa_rank is not null then 'SSA #' || ln.ssa_rank::text else 'SSA N/A' end,
        concat_ws(' ◆ ', ln.origin, ln.meaning)
      )
    ),
    r2.name_id,
    concat_ws(
      E'\n',
      rn.display_name,
      concat_ws(
        ' · ',
        case when rn.ssa_rank is not null then 'SSA #' || rn.ssa_rank::text else 'SSA N/A' end,
        concat_ws(' ◆ ', rn.origin, rn.meaning)
      )
    ),
    (select count(*)::integer from public.votes v where v.participant_id = target_participant.id)
  from public.rankings r2
  join public.names ln on ln.id = first_choice.name_id
  join public.names rn on rn.id = r2.name_id
  where r2.participant_id = target_participant.id
    and r2.name_id <> first_choice.name_id
  order by r2.comparisons asc,
           abs(r2.rating - first_choice.rating) asc,
           random()
  limit 1;
end;
$$;

grant execute on function public.get_next_pair(uuid) to anon, authenticated;

commit;

select display_name, ssa_rank,
       case when ssa_rank is null then 'SSA N/A' else 'SSA #' || ssa_rank::text end as rank_label
from public.names
order by coalesce(ssa_rank, 100000), display_name;