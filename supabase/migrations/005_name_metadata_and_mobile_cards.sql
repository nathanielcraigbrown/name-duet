-- Add concise origin/meaning metadata and return it with comparison pairs.

alter table public.names add column if not exists origin text;
alter table public.names add column if not exists meaning text;

update public.names n
set origin = v.origin,
    meaning = v.meaning
from (values
  ('Aurelia','Latin','golden'),
  ('Maya','Sanskrit / Greek','illusion; good mother'),
  ('Molly','English / Irish','beloved'),
  ('Sabina','Latin','Sabine woman'),
  ('Sabine','French / Latin','of the Sabines'),
  ('Sabrina','Celtic / Latin','of the River Severn'),
  ('Claire','French / Latin','bright, clear'),
  ('Corinne','Greek','maiden'),
  ('Ramona','Spanish / Germanic','wise protector'),
  ('Ruby','Latin','red gemstone'),
  ('Lucille','French / Latin','light'),
  ('Marina','Latin','of the sea'),
  ('Leona','Latin','lioness'),
  ('Caledonia','Latin / Scottish','Scotland'),
  ('Calliope','Greek','beautiful voice'),
  ('Euroletta','Literary','rare historic name'),
  ('Celia','Latin','heavenly'),
  ('Phoebe','Greek','bright, radiant'),
  ('Skye','Scottish','Isle of Skye'),
  ('Summer','English','summer season'),
  ('Helena','Greek','shining light'),
  ('Denise','French / Greek','devoted to Dionysus'),
  ('Iris','Greek','rainbow'),
  ('Luna','Latin','moon'),
  ('Sadie','Hebrew / English','princess'),
  ('Liza','English / Hebrew','pledged to God'),
  ('Shea','Irish','stately, fortunate'),
  ('Faye','English','fairy'),
  ('Clara','Latin','bright, clear'),
  ('Alice','Germanic','noble'),
  ('Violet','Latin','purple flower'),
  ('Eliza','English / Hebrew','pledged to God'),
  ('Juliet','Latin / French','youthful'),
  ('Cecilia','Latin','blind; musical patron'),
  ('Sylvie','French / Latin','of the forest'),
  ('Margot','French / Greek','pearl'),
  ('Daphne','Greek','laurel tree'),
  ('Maeve','Irish','intoxicating'),
  ('Nina','International','little girl; grace'),
  ('Nora','Irish / Latin','honor; light'),
  ('Louisa','Germanic','renowned warrior'),
  ('Georgia','Greek','farmer, earth-worker'),
  ('Thea','Greek','goddess'),
  ('Ada','Germanic','noble'),
  ('Rose','Latin','rose flower'),
  ('June','Latin','of Juno'),
  ('Willa','Germanic','resolute protector'),
  ('Eloise','French / Germanic','healthy; wide'),
  ('Matilda','Germanic','battle-mighty'),
  ('Naomi','Hebrew','pleasantness'),
  ('Esme','French / Persian','esteemed; beloved'),
  ('Simone','French / Hebrew','heard'),
  ('Cora','Greek','maiden'),
  ('Diana','Roman','divine; moon goddess'),
  ('Fiona','Scottish','fair, white'),
  ('Flora','Latin','flower; spring goddess'),
  ('Greer','Scottish','watchful'),
  ('Ingrid','Norse','beautiful, beloved'),
  ('Josephine','French / Hebrew','God will add'),
  ('Adelaide','Germanic','noble nature')
) as v(display_name, origin, meaning)
where n.display_name = v.display_name;

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
    concat_ws(E'\n', ln.display_name, nullif(trim(concat_ws(' · ', ln.origin, ln.meaning)), '')),
    r2.name_id,
    concat_ws(E'\n', rn.display_name, nullif(trim(concat_ws(' · ', rn.origin, rn.meaning)), '')),
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
