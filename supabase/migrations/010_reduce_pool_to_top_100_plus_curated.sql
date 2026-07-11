-- Reduce the active candidate pool to the 2025 SSA Top 100 girls' names
-- plus the existing curated name list from migration 005.
-- This intentionally resets all votes and rankings so the Elo results reflect
-- only the final candidate pool.

begin;

create temporary table desired_curated_names (
  display_name text primary key
) on commit drop;

insert into desired_curated_names (display_name) values
  ('Aurelia'),
  ('Maya'),
  ('Molly'),
  ('Sabina'),
  ('Sabine'),
  ('Sabrina'),
  ('Claire'),
  ('Corinne'),
  ('Ramona'),
  ('Ruby'),
  ('Lucille'),
  ('Marina'),
  ('Leona'),
  ('Caledonia'),
  ('Calliope'),
  ('Euroletta'),
  ('Celia'),
  ('Phoebe'),
  ('Skye'),
  ('Summer'),
  ('Helena'),
  ('Denise'),
  ('Iris'),
  ('Luna'),
  ('Sadie'),
  ('Liza'),
  ('Shea'),
  ('Faye'),
  ('Clara'),
  ('Alice'),
  ('Violet'),
  ('Eliza'),
  ('Juliet'),
  ('Cecilia'),
  ('Sylvie'),
  ('Margot'),
  ('Daphne'),
  ('Maeve'),
  ('Nina'),
  ('Nora'),
  ('Louisa'),
  ('Georgia'),
  ('Thea'),
  ('Ada'),
  ('Rose'),
  ('June'),
  ('Willa'),
  ('Eloise'),
  ('Matilda'),
  ('Naomi'),
  ('Esme'),
  ('Simone'),
  ('Cora'),
  ('Diana'),
  ('Fiona'),
  ('Flora'),
  ('Greer'),
  ('Ingrid'),
  ('Josephine'),
  ('Adelaide');

-- Ensure every curated name exists even if a prior import was incomplete.
insert into public.names (display_name, source)
select d.display_name, 'curated'
from desired_curated_names d
on conflict (display_name) do nothing;

create temporary table desired_name_ids (
  id bigint primary key
) on commit drop;

insert into desired_name_ids (id)
select n.id
from public.names n
where n.ssa_rank between 1 and 100
   or exists (
     select 1
     from desired_curated_names d
     where d.display_name = n.display_name
   );

-- Votes reference names without ON DELETE CASCADE, so clear results first.
delete from public.votes;
delete from public.rankings;

delete from public.names n
where not exists (
  select 1
  from desired_name_ids d
  where d.id = n.id
);

-- Keep source labeling clear for curated names outside the SSA Top 100.
update public.names n
set source = 'curated'
where exists (
  select 1
  from desired_curated_names d
  where d.display_name = n.display_name
)
and (n.ssa_rank is null or n.ssa_rank > 100);

-- Validation: 100 SSA names plus 45 unique curated additions = 145 total.
do $$
declare
  total_names integer;
  top_100_names integer;
  curated_names_present integer;
begin
  select count(*) into total_names from public.names;
  select count(*) into top_100_names
  from public.names
  where ssa_rank between 1 and 100;
  select count(*) into curated_names_present
  from desired_curated_names d
  where exists (
    select 1 from public.names n where n.display_name = d.display_name
  );

  if top_100_names <> 100 then
    raise exception 'Expected 100 SSA names, found %', top_100_names;
  end if;

  if curated_names_present <> 60 then
    raise exception 'Expected all 60 curated names, found %', curated_names_present;
  end if;

  if total_names <> 145 then
    raise exception 'Expected 145 total unique names, found %', total_names;
  end if;
end
$$;

commit;

select
  count(*) as total_names,
  count(*) filter (where ssa_rank between 1 and 100) as ssa_top_100,
  count(*) filter (where source = 'curated') as curated_labeled
from public.names;