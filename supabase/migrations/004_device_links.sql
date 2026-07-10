-- One-time cross-device links for restoring an existing participant profile.

create table if not exists public.device_links (
  id uuid primary key default gen_random_uuid(),
  participant_id uuid not null references public.participants(id) on delete cascade,
  code text not null unique default upper(substr(encode(gen_random_bytes(8), 'hex'), 1, 12)),
  expires_at timestamptz not null default (now() + interval '30 minutes'),
  created_at timestamptz not null default now()
);

alter table public.device_links enable row level security;

create or replace function public.create_device_link(p_access_token uuid)
returns table(device_code text)
language plpgsql
security definer
set search_path = public
as $$
declare
  target_participant public.participants;
  new_code text;
begin
  select * into target_participant
  from public.participants
  where access_token = p_access_token;

  if target_participant.id is null then
    raise exception 'Invalid participant token';
  end if;

  delete from public.device_links
  where participant_id = target_participant.id
     or expires_at < now();

  insert into public.device_links(participant_id)
  values (target_participant.id)
  returning code into new_code;

  return query select new_code;
end;
$$;

create or replace function public.redeem_device_link(p_room_token text, p_device_code text)
returns table(room_token text, participant_token uuid, participant_name text)
language plpgsql
security definer
set search_path = public
as $$
declare
  target_link public.device_links;
  target_participant public.participants;
  target_room public.rooms;
begin
  select dl.* into target_link
  from public.device_links dl
  join public.participants p on p.id = dl.participant_id
  join public.rooms r on r.id = p.room_id
  where dl.code = upper(trim(p_device_code))
    and dl.expires_at > now()
    and r.token = upper(trim(p_room_token));

  if target_link.id is null then
    raise exception 'Device link is invalid or expired';
  end if;

  select * into target_participant from public.participants where id = target_link.participant_id;
  select * into target_room from public.rooms where id = target_participant.room_id;

  delete from public.device_links where id = target_link.id;

  return query select target_room.token, target_participant.access_token, target_participant.display_name;
end;
$$;

grant execute on function public.create_device_link(uuid) to anon, authenticated;
grant execute on function public.redeem_device_link(text, text) to anon, authenticated;
