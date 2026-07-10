-- Name Duet comparison engine: starter catalog, adaptive pairing, Elo voting, rankings.

insert into public.names (display_name, source) values
  ('Aurelia','discussion'),('Maya','discussion'),('Molly','discussion'),('Sabina','discussion'),
  ('Sabine','discussion'),('Sabrina','discussion'),('Claire','discussion'),('Corinne','discussion'),
  ('Ramona','discussion'),('Ruby','discussion'),('Lucille','discussion'),('Marina','discussion'),
  ('Leona','discussion'),('Caledonia','discussion'),('Calliope','discussion'),('Euroletta','discussion'),
  ('Celia','discussion'),('Phoebe','discussion'),('Skye','discussion'),('Summer','discussion'),
  ('Helena','discussion'),('Denise','discussion'),('Iris','discussion'),('Luna','discussion'),
  ('Sadie','discussion'),('Liza','discussion'),('Shea','discussion'),('Faye','discussion'),
  ('Clara','curated'),('Alice','curated'),('Violet','curated'),('Eliza','curated'),
  ('Juliet','curated'),('Cecilia','curated'),('Sylvie','curated'),('Margot','curated'),
  ('Daphne','curated'),('Maeve','curated'),('Nina','curated'),('Nora','curated'),
  ('Louisa','curated'),('Georgia','curated'),('Thea','curated'),('Ada','curated'),
  ('Rose','curated'),('June','curated'),('Willa','curated'),('Eloise','curated'),
  ('Matilda','curated'),('Naomi','curated'),('Esme','curated'),('Simone','curated'),
  ('Cora','curated'),('Diana','curated'),('Fiona','curated'),('Flora','curated'),
  ('Greer','curated'),('Ingrid','curated'),('Josephine','curated'),('Adelaide','curated')
on conflict (display_name) do update set source = excluded.source;

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
    ln.display_name,
    r2.name_id,
    rn.display_name,
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

create or replace function public.record_vote(
  p_access_token uuid,
  p_left_id bigint,
  p_right_id bigint,
  p_winner_id bigint
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_participant public.participants;
  left_row public.rankings;
  right_row public.rankings;
  left_score numeric;
  right_score numeric;
  expected_left numeric;
  expected_right numeric;
  k_factor numeric := 28;
begin
  if p_left_id = p_right_id or p_winner_id not in (p_left_id, p_right_id) then
    raise exception 'Invalid vote';
  end if;

  select * into target_participant
  from public.participants
  where access_token = p_access_token;

  if target_participant.id is null then
    raise exception 'Invalid participant token';
  end if;

  insert into public.rankings (participant_id, name_id)
  values (target_participant.id, p_left_id), (target_participant.id, p_right_id)
  on conflict (participant_id, name_id) do nothing;

  select * into left_row from public.rankings
  where participant_id = target_participant.id and name_id = p_left_id
  for update;

  select * into right_row from public.rankings
  where participant_id = target_participant.id and name_id = p_right_id
  for update;

  left_score := case when p_winner_id = p_left_id then 1 else 0 end;
  right_score := 1 - left_score;
  expected_left := 1 / (1 + power(10, (right_row.rating - left_row.rating) / 400));
  expected_right := 1 - expected_left;

  update public.rankings
  set rating = round((left_row.rating + k_factor * (left_score - expected_left))::numeric, 2),
      wins = wins + case when left_score = 1 then 1 else 0 end,
      losses = losses + case when left_score = 0 then 1 else 0 end,
      comparisons = comparisons + 1
  where participant_id = target_participant.id and name_id = p_left_id;

  update public.rankings
  set rating = round((right_row.rating + k_factor * (right_score - expected_right))::numeric, 2),
      wins = wins + case when right_score = 1 then 1 else 0 end,
      losses = losses + case when right_score = 0 then 1 else 0 end,
      comparisons = comparisons + 1
  where participant_id = target_participant.id and name_id = p_right_id;

  insert into public.votes (participant_id, left_name_id, right_name_id, winner_name_id)
  values (target_participant.id, p_left_id, p_right_id, p_winner_id);
end;
$$;

create or replace function public.get_my_rankings(p_access_token uuid, p_limit integer default 12)
returns table(
  rank_position bigint,
  name_id bigint,
  display_name text,
  rating numeric,
  wins integer,
  losses integer,
  comparisons integer
)
language sql
security definer
set search_path = public
as $$
  select
    row_number() over (order by r.rating desc, r.comparisons desc, n.display_name)::bigint,
    n.id,
    n.display_name,
    r.rating,
    r.wins,
    r.losses,
    r.comparisons
  from public.participants p
  join public.rankings r on r.participant_id = p.id
  join public.names n on n.id = r.name_id
  where p.access_token = p_access_token
    and r.comparisons > 0
  order by r.rating desc, r.comparisons desc, n.display_name
  limit greatest(1, least(coalesce(p_limit, 12), 50));
$$;

grant execute on function public.get_next_pair(uuid) to anon, authenticated;
grant execute on function public.record_vote(uuid, bigint, bigint, bigint) to anon, authenticated;
grant execute on function public.get_my_rankings(uuid, integer) to anon, authenticated;
