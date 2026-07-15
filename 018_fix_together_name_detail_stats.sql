-- Fixes Together-mode name details for participant schemas without participant_name.
-- Safely derives the participant label from the row JSON.

create or replace function public.get_together_name_detail_stats(
  p_access_token uuid,
  p_display_name text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  requester public.participants;
  target_name public.names;
  participant_rows jsonb;
  combined_matchups jsonb;
  combined_wins integer;
  combined_losses integer;
  combined_comparisons integer;
  agreement_count integer;
  disagreement_count integer;
begin
  select * into requester
  from public.participants
  where access_token = p_access_token;

  if requester.id is null then
    raise exception 'Invalid participant token';
  end if;

  select * into target_name
  from public.names
  where display_name = p_display_name
  limit 1;

  if target_name.id is null then
    raise exception 'Name not found';
  end if;

  with room_participants as (
    select
      p.id,
      coalesce(
        nullif(to_jsonb(p)->>'participant_name', ''),
        nullif(to_jsonb(p)->>'display_name', ''),
        nullif(to_jsonb(p)->>'name', ''),
        'Participant'
      ) as participant_name
    from public.participants p
    where p.room_id = requester.room_id
  ), ranked as (
    select
      r.participant_id,
      r.name_id,
      dense_rank() over (
        partition by r.participant_id
        order by round(r.rating - 1500) desc
      )::integer as display_rank
    from public.rankings r
    join room_participants rp on rp.id = r.participant_id
  ), participant_stats as (
    select
      rp.id as participant_id,
      rp.participant_name,
      rr.display_rank,
      round(r.rating - 1500)::integer as preference_score,
      r.wins,
      r.losses,
      r.comparisons,
      case when r.comparisons > 0
        then round((r.wins::numeric / r.comparisons::numeric) * 100, 1)
        else 0
      end as win_rate
    from room_participants rp
    left join public.rankings r
      on r.participant_id = rp.id and r.name_id = target_name.id
    left join ranked rr
      on rr.participant_id = rp.id and rr.name_id = target_name.id
  ), participant_matchups as (
    select
      rp.id as participant_id,
      case when v.left_name_id = target_name.id then v.right_name_id else v.left_name_id end as opponent_id,
      sum(case when v.winner_name_id = target_name.id then 1 else 0 end)::integer as wins,
      sum(case when v.winner_name_id <> target_name.id then 1 else 0 end)::integer as losses,
      count(*)::integer as total
    from room_participants rp
    left join public.votes v
      on v.participant_id = rp.id
     and (v.left_name_id = target_name.id or v.right_name_id = target_name.id)
    where v.id is not null
    group by rp.id, 2
  ), participant_json as (
    select jsonb_build_object(
      'participant_id', ps.participant_id,
      'participant_name', ps.participant_name,
      'display_rank', ps.display_rank,
      'preference_score', coalesce(ps.preference_score, 0),
      'wins', coalesce(ps.wins, 0),
      'losses', coalesce(ps.losses, 0),
      'comparisons', coalesce(ps.comparisons, 0),
      'win_rate', coalesce(ps.win_rate, 0),
      'matchups', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'opponent_name', n.display_name,
            'wins', pm.wins,
            'losses', pm.losses,
            'total', pm.total,
            'opponent_score', round(coalesce(orank.rating, 1500) - 1500)
          ) order by pm.total desc, n.display_name
        )
        from participant_matchups pm
        join public.names n on n.id = pm.opponent_id
        left join public.rankings orank
          on orank.participant_id = ps.participant_id
         and orank.name_id = pm.opponent_id
        where pm.participant_id = ps.participant_id
      ), '[]'::jsonb)
    ) as payload
    from participant_stats ps
  )
  select coalesce(jsonb_agg(payload order by payload->>'participant_name'), '[]'::jsonb)
  into participant_rows
  from participant_json;

  with room_votes as (
    select v.*
    from public.votes v
    join public.participants p on p.id = v.participant_id
    where p.room_id = requester.room_id
      and (v.left_name_id = target_name.id or v.right_name_id = target_name.id)
  ), combined as (
    select
      case when left_name_id = target_name.id then right_name_id else left_name_id end as opponent_id,
      sum(case when winner_name_id = target_name.id then 1 else 0 end)::integer as wins,
      sum(case when winner_name_id <> target_name.id then 1 else 0 end)::integer as losses,
      count(*)::integer as total
    from room_votes
    group by 1
  )
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'opponent_name', n.display_name,
      'wins', c.wins,
      'losses', c.losses,
      'total', c.total,
      'opponent_score', 0
    ) order by c.total desc, n.display_name
  ), '[]'::jsonb)
  into combined_matchups
  from combined c
  join public.names n on n.id = c.opponent_id;

  select
    coalesce(sum(case when v.winner_name_id = target_name.id then 1 else 0 end), 0)::integer,
    coalesce(sum(case when v.winner_name_id <> target_name.id then 1 else 0 end), 0)::integer,
    count(*)::integer
  into combined_wins, combined_losses, combined_comparisons
  from public.votes v
  join public.participants p on p.id = v.participant_id
  where p.room_id = requester.room_id
    and (v.left_name_id = target_name.id or v.right_name_id = target_name.id);

  with choices as (
    select
      v.participant_id,
      case when v.left_name_id = target_name.id then v.right_name_id else v.left_name_id end as opponent_id,
      case when v.winner_name_id = target_name.id then 1 else 0 end as chose_target
    from public.votes v
    join public.participants p on p.id = v.participant_id
    where p.room_id = requester.room_id
      and (v.left_name_id = target_name.id or v.right_name_id = target_name.id)
  ), paired as (
    select opponent_id,
           count(distinct participant_id) as people,
           min(chose_target) as min_choice,
           max(chose_target) as max_choice
    from choices
    group by opponent_id
  )
  select
    count(*) filter (where people > 1 and min_choice = max_choice)::integer,
    count(*) filter (where people > 1 and min_choice <> max_choice)::integer
  into agreement_count, disagreement_count
  from paired;

  return jsonb_build_object(
    'display_name', target_name.display_name,
    'ssa_rank', target_name.ssa_rank,
    'origin', target_name.origin,
    'meaning', target_name.meaning,
    'participants', participant_rows,
    'combined', jsonb_build_object(
      'wins', combined_wins,
      'losses', combined_losses,
      'comparisons', combined_comparisons,
      'win_rate', case when combined_comparisons > 0
        then round((combined_wins::numeric / combined_comparisons::numeric) * 100, 1)
        else 0
      end,
      'agreement_count', coalesce(agreement_count, 0),
      'disagreement_count', coalesce(disagreement_count, 0),
      'matchups', combined_matchups
    )
  );
end;
$$;

grant execute on function public.get_together_name_detail_stats(uuid, text) to anon, authenticated;
