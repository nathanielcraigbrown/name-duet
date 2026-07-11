-- Add Laura's exact suggestion "Fey" and enrich comparison-card metadata.
-- Existing rankings are preserved; the new name is added lazily to each participant.

begin;

insert into public.names (display_name, source, origin, meaning)
values ('Fey', 'curated', 'English / French', 'fairy; variant spelling of Faye')
on conflict (display_name) do update
set source = 'curated',
    origin = excluded.origin,
    meaning = excluded.meaning;

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
        case when ln.ssa_rank is not null then 'SSA #' || ln.ssa_rank::text else 'CURATED' end,
        concat_ws(' — ', ln.origin, ln.meaning)
      )
    ),
    r2.name_id,
    concat_ws(
      E'\n',
      rn.display_name,
      concat_ws(
        ' · ',
        case when rn.ssa_rank is not null then 'SSA #' || rn.ssa_rank::text else 'CURATED' end,
        concat_ws(' — ', rn.origin, rn.meaning)
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

select display_name, ssa_rank, source, origin, meaning
from public.names
where display_name in ('Fey','Faye','Maya','Molly','Sadie','Autumn','Myla','Sabine','Shea','Liza')
order by display_name;