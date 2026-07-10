-- Import the official 2025 SSA Top 1,000 girl names.
-- This migration fetches the SSA birth-year ranking table directly from the
-- Social Security Administration, parses the girl-name column, and aborts
-- unless exactly 1,000 ranked names are found.

create extension if not exists http with schema extensions;

create temporary table ssa_2025_girls (
  ssa_rank integer primary key,
  display_name text not null unique
) on commit drop;

do $$
declare
  response extensions.http_response;
  page_html text;
  row_match text[];
  imported_count integer;
begin
  response := extensions.http_post(
    'https://www.ssa.gov/cgi-bin/popularnames.cgi',
    'year=2025&top=1000&number=n',
    'application/x-www-form-urlencoded'
  );

  if response.status <> 200 then
    raise exception 'SSA import failed: HTTP status %', response.status;
  end if;

  page_html := response.content;

  -- The SSA result table is rank, boy name, girl name. Allow attributes and
  -- whitespace in the table markup so minor presentation changes do not break
  -- the import.
  for row_match in
    select regexp_matches(
      page_html,
      '<tr[^>]*>[[:space:]]*<td[^>]*>[[:space:]]*([0-9]{1,4})[[:space:]]*</td>[[:space:]]*<td[^>]*>[[:space:]]*([^<]+?)[[:space:]]*</td>[[:space:]]*<td[^>]*>[[:space:]]*([^<]+?)[[:space:]]*</td>',
      'gi'
    )
  loop
    if row_match[1]::integer between 1 and 1000 then
      insert into ssa_2025_girls(ssa_rank, display_name)
      values (
        row_match[1]::integer,
        initcap(lower(trim(regexp_replace(row_match[3], '&amp;', '&', 'g'))))
      )
      on conflict do nothing;
    end if;
  end loop;

  select count(*) into imported_count from ssa_2025_girls;

  if imported_count <> 1000 then
    raise exception 'SSA import parsed % names instead of 1000; no names were changed', imported_count;
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

  -- Clear stale SSA ranks from any prior release while preserving discussion
  -- and curated names that sit outside the current Top 1,000.
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

-- Existing participants receive the newly imported names lazily the next time
-- get_next_pair runs, because that function inserts any missing ranking rows.

-- Verification helper: after running this migration, this query should return
-- 1000 for ranked_ssa_names and a larger number for total_names.
select
  count(*) filter (where ssa_rank between 1 and 1000) as ranked_ssa_names,
  count(*) as total_names
from public.names;
