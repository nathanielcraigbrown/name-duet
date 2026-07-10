-- Shared room consensus dashboard for two participants.

create or replace function public.get_room_consensus(
  p_access_token uuid,
  p_limit integer default 20
)
returns table(
  name_id bigint,
  display_name text,
  participant_one_name text,
  participant_two_name text,
  participant_one_rank bigint,
  participant_two_rank bigint,
  participant_one_rating numeric,
  participant_two_rating numeric,
  participant_one_comparisons integer,
  participant_two_comparisons integer,
  consensus_score numeric,
  rank_gap integer
)
language sql
security definer
set search_path = public
as $$
  with requester as (
    select room_id
    from public.participants
    where access_token = p_access_token
  ), room_people as (
    select p.id, p.display_name,
           row_number() over (order by p.created_at, p.id) as person_number
    from public.participants p
    join requester q on q.room_id = p.room_id
    order by p.created_at, p.id
    limit 2
  ), ranked as (
    select
      rp.person_number,
      rp.display_name as participant_name,
      n.id as name_id,
      n.display_name,
      r.rating,
      r.comparisons,
      row_number() over (
        partition by rp.person_number
        order by r.rating desc, r.comparisons desc, n.display_name
      ) as rank_position
    from room_people rp
    join public.rankings r on r.participant_id = rp.id
    join public.names n on n.id = r.name_id
    where r.comparisons > 0
  ), combined as (
    select
      coalesce(a.name_id, b.name_id) as name_id,
      coalesce(a.display_name, b.display_name) as display_name,
      (select display_name from room_people where person_number = 1) as participant_one_name,
      (select display_name from room_people where person_number = 2) as participant_two_name,
      a.rank_position as participant_one_rank,
      b.rank_position as participant_two_rank,
      a.rating as participant_one_rating,
      b.rating as participant_two_rating,
      coalesce(a.comparisons, 0) as participant_one_comparisons,
      coalesce(b.comparisons, 0) as participant_two_comparisons,
      round((
        (coalesce(a.rating, 1450) + coalesce(b.rating, 1450)) / 2
        - abs(coalesce(a.rating, 1450) - coalesce(b.rating, 1450)) * 0.35
        - case when least(coalesce(a.comparisons, 0), coalesce(b.comparisons, 0)) < 2 then 35 else 0 end
      )::numeric, 2) as consensus_score,
      abs(coalesce(a.rank_position, 999) - coalesce(b.rank_position, 999))::integer as rank_gap
    from (select * from ranked where person_number = 1) a
    full outer join (select * from ranked where person_number = 2) b using (name_id)
  )
  select *
  from combined
  where participant_two_name is not null
  order by consensus_score desc, rank_gap asc, display_name
  limit greatest(1, least(coalesce(p_limit, 20), 50));
$$;

grant execute on function public.get_room_consensus(uuid, integer) to anon, authenticated;
