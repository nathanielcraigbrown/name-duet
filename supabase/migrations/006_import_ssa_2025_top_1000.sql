-- Import the official 2025 SSA Top 1,000 girl names.
-- SSA blocks server-side requests with HTTP 403, so this migration reads a
-- published mirror of the same SSA ranking. It aborts unless exactly 1,000
-- consecutively ranked names are parsed, so a partial page cannot alter data.

create extension if not exists http with schema extensions;

create temporary table ssa_2025_girls (
  ssa_rank integer primary key,
  display_name text not null unique
) on commit drop;

do $$
declare
  response extensions.http_response;
  page_text text;
  row_match text[];
  imported_count integer;
  min_rank integer;
  max_rank integer;
begin
  response := extensions.http((
    'GET',
    'https://www.parents.com/top-1000-baby-girl-names-2757832',
    array[
      extensions.http_header('User-Agent', 'Mozilla/5.0 NameDuet/1.0'),
      extensions.http_header('Accept', 'text/html,application/xhtml+xml')
    ],
    null,
    null
  )::extensions.http_request);

  if response.status <> 200 then
    raise exception 'Name-list import failed: HTTP status %', response.status;
  end if;

  -- Convert the article HTML to plain text, then normalize common entities.
  page_text := regexp_replace(response.content, '<script[^>]*>.*?</script>', ' ', 'gis');
  page_text := regexp_replace(page_text, '<style[^>]*>.*?</style>', ' ', 'gis');
  page_text := regexp_replace(page_text, '<[^>]+>', ' ', 'g');
  page_text := replace(page_text, '&nbsp;', ' ');
  page_text := replace(page_text, '&#39;', '''');
  page_text := replace(page_text, '&amp;', '&');
  page_text := regexp_replace(page_text, '[[:space:]]+', ' ', 'g');

  -- The article prints every entry as "rank. Name". Restrict ranks to 1-1000.
  for row_match in
    select regexp_matches(
      page_text,
      '(^|[[:space:]])([0-9]{1,4})\.[[:space:]]+([[:alpha:]][[:alpha:]''-]*)',
      'g'
    )
  loop
    if row_match[2]::integer between 1 and 1000 then
      insert into ssa_2025_girls(ssa_rank, display_name)
      values (row_match[2]::integer, initcap(lower(trim(row_match[3]))))
      on conflict do nothing;
    end if;
  end loop;

  select count(*), min(ssa_rank), max(ssa_rank)
  into imported_count, min_rank, max_rank
  from ssa_2025_girls;

  if imported_count <> 1000 or min_rank <> 1 or max_rank <> 1000 then
    raise exception '2025 import parsed % names (rank range %-%), expected exactly ranks 1-1000; no names were changed',
      imported_count, min_rank, max_rank;
  end if;

  insert into public.names(display_name, ssa_rank, source)
  select display_name, ssa_rank, 'ssa_2025'
  from ssa_2025_girls
  order by ssa_rank
  on conflict (display_name) do update
  set ssa_rank = excluded.ssa_rank,
      source = case
        when public.names.source = 'discussion' then public.names.source
        else 'ssa_2025'
      end;

  update public.names n
  set ssa_rank = null
  where n.ssa_rank is not null
    and not exists (
      select 1
      from ssa_2025_girls s
      where s.display_name = n.display_name
    );
end;
$$;

select
  count(*) filter (where ssa_rank between 1 and 1000) as ranked_ssa_names,
  count(*) as total_names
from public.names;
