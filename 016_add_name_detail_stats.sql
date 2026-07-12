-- Adds a secure RPC used by the expandable name-detail panels.
-- This does not modify votes, rankings, names, rooms, or participants.

create or replace function public.get_name_detail_stats(
  p_access_token uuid,
  p_display_name text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_participant public.participants;
  target_name public.names;
  target_ranking public.rankings;
  rank_number integer;
  total_ranked integer;
  matchup_rows jsonb;
  best_win_name text;
  nemesis_name text;
  dominance_name text;
begin
  select * into target_participant
  from public.participants
  where access_token = p_access_token;

  if target_participant.id is null then
    raise exception 'Invalid participant token';
  end if;

  select * into target_name
  from public.names
  where display_name = p_display_name
  limit 1;

  if target_name.id is null then
    raise exception 'Name not found';
  end if;

  select * into target_ranking
  from public.rankings
  where participant_id = target_participant.id
    and name_id = target_name.id;

  if target_ranking.name_id is null then
    raise exception 'No ranking found for this participant and name';
  end if;

  with ordered as (
    select
      r.name_id,
      dense_rank() over (order by round(r.rating - 1500) desc) as display_rank
    from public.rankings r
    where r.participant_id = target_participant.id
  )
  select o.display_rank::integer,
         (select count(*)::integer from ordered)
  into rank_number, total_ranked
  from ordered o
  where o.name_id = target_name.id;

  with matchup_summary as (
    select
      case
        when v.left_name_id = target_name.id then v.right_name_id
        else v.left_name_id
      end as opponent_id,
      sum(case when v.winner_name_id = target_name.id then 1 else 0 end)::integer as wins,
      sum(case when v.winner_name_id <> target_name.id then 1 else 0 end)::integer as losses,
      count(*)::integer as total
    from public.votes v
    where v.participant_id = target_participant.id
      and (v.left_name_id = target_name.id or v.right_name_id = target_name.id)
    group by 1
  ), enriched as (
    select
      ms.opponent_id,
      n.display_name as opponent_name,
      ms.wins,
      ms.losses,
      ms.total,
      coalesce(r.rating, 1500) as opponent_rating
    from matchup_summary ms
    join public.names n on n.id = ms.opponent_id
    left join public.rankings r
      on r.participant_id = target_participant.id
     and r.name_id = ms.opponent_id
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'opponent_name', opponent_name,
        'wins', wins,
        'losses', losses,
        'total', total,
        'opponent_score', round(opponent_rating - 1500)
      )
      order by total desc, opponent_name
    ),
    '[]'::jsonb
  )
  into matchup_rows
  from enriched;

  with matchup_summary as (
    select
      case when v.left_name_id = target_name.id then v.right_name_id else v.left_name_id end as opponent_id,
      sum(case when v.winner_name_id = target_name.id then 1 else 0 end)::integer as wins,
      sum(case when v.winner_name_id <> target_name.id then 1 else 0 end)::integer as losses
    from public.votes v
    where v.participant_id = target_participant.id
      and (v.left_name_id = target_name.id or v.right_name_id = target_name.id)
    group by 1
  )
  select n.display_name
  into best_win_name
  from matchup_summary ms
  join public.names n on n.id = ms.opponent_id
  left join public.rankings r
    on r.participant_id = target_participant.id
   and r.name_id = ms.opponent_id
  where ms.wins > 0
  order by coalesce(r.rating, 1500) desc, ms.wins desc
  limit 1;

  with matchup_summary as (
    select
      case when v.left_name_id = target_name.id then v.right_name_id else v.left_name_id end as opponent_id,
      sum(case when v.winner_name_id = target_name.id then 1 else 0 end)::integer as wins,
      sum(case when v.winner_name_id <> target_name.id then 1 else 0 end)::integer as losses
    from public.votes v
    where v.participant_id = target_participant.id
      and (v.left_name_id = target_name.id or v.right_name_id = target_name.id)
    group by 1
  )
  select n.display_name
  into nemesis_name
  from matchup_summary ms
  join public.names n on n.id = ms.opponent_id
  where ms.losses > 0
  order by ms.losses desc, ms.wins asc, n.display_name
  limit 1;

  with matchup_summary as (
    select
      case when v.left_name_id = target_name.id then v.right_name_id else v.left_name_id end as opponent_id,
      sum(case when v.winner_name_id = target_name.id then 1 else 0 end)::integer as wins,
      sum(case when v.winner_name_id <> target_name.id then 1 else 0 end)::integer as losses
    from public.votes v
    where v.participant_id = target_participant.id
      and (v.left_name_id = target_name.id or v.right_name_id = target_name.id)
    group by 1
  )
  select n.display_name
  into dominance_name
  from matchup_summary ms
  join public.names n on n.id = ms.opponent_id
  where ms.wins > 0
  order by ms.wins desc, ms.losses asc, n.display_name
  limit 1;

  return jsonb_build_object(
    'display_name', target_name.display_name,
    'ssa_rank', target_name.ssa_rank,
    'origin', target_name.origin,
    'meaning', target_name.meaning,
    'display_rank', rank_number,
    'total_ranked', total_ranked,
    'preference_score', round(target_ranking.rating - 1500),
    'wins', target_ranking.wins,
    'losses', target_ranking.losses,
    'comparisons', target_ranking.comparisons,
    'win_rate', case
      when target_ranking.comparisons > 0
      then round((target_ranking.wins::numeric / target_ranking.comparisons::numeric) * 100, 1)
      else 0
    end,
    'best_win', best_win_name,
    'nemesis', nemesis_name,
    'most_beaten', dominance_name,
    'matchups', matchup_rows
  );
end;
$$;

grant execute on function public.get_name_detail_stats(uuid, text) to anon, authenticated;
