-- Reduce the active candidate pool to the 2025 SSA Top 100 girls' names
-- plus the existing curated name list from migration 005.
-- This intentionally resets all votes and rankings so the Elo results reflect
-- only the final candidate pool.
--
-- Important repair: earlier SSA imports did not always backfill ssa_rank onto
-- names that already existed as curated rows. This migration explicitly
-- reapplies the canonical Top 100 ranks before calculating the union.

begin;

create temporary table desired_ssa_top_100 (
  ssa_rank integer primary key,
  display_name text not null unique
) on commit drop;

insert into desired_ssa_top_100 (ssa_rank, display_name) values
  (1,'Olivia'),
  (2,'Charlotte'),
  (3,'Emma'),
  (4,'Amelia'),
  (5,'Sophia'),
  (6,'Mia'),
  (7,'Isabella'),
  (8,'Evelyn'),
  (9,'Sofia'),
  (10,'Eliana'),
  (11,'Ava'),
  (12,'Eleanor'),
  (13,'Violet'),
  (14,'Ailany'),
  (15,'Aurora'),
  (16,'Harper'),
  (17,'Elizabeth'),
  (18,'Lily'),
  (19,'Camila'),
  (20,'Nora'),
  (21,'Hazel'),
  (22,'Penelope'),
  (23,'Chloe'),
  (24,'Ellie'),
  (25,'Lucy'),
  (26,'Aria'),
  (27,'Luna'),
  (28,'Isla'),
  (29,'Ella'),
  (30,'Lainey'),
  (31,'Zoe'),
  (32,'Scarlett'),
  (33,'Gianna'),
  (34,'Emily'),
  (35,'Valentina'),
  (36,'Layla'),
  (37,'Avery'),
  (38,'Grace'),
  (39,'Ivy'),
  (40,'Madison'),
  (41,'Abigail'),
  (42,'Elena'),
  (43,'Mila'),
  (44,'Willow'),
  (45,'Emilia'),
  (46,'Nova'),
  (47,'Naomi'),
  (48,'Riley'),
  (49,'Eloise'),
  (50,'Sadie'),
  (51,'Delilah'),
  (52,'Stella'),
  (53,'Josephine'),
  (54,'Victoria'),
  (55,'Sophie'),
  (56,'Hannah'),
  (57,'Lillian'),
  (58,'Leah'),
  (59,'Adeline'),
  (60,'Leilani'),
  (61,'Iris'),
  (62,'Maya'),
  (63,'Clara'),
  (64,'Ruby'),
  (65,'Alice'),
  (66,'Genesis'),
  (67,'Paisley'),
  (68,'Claire'),
  (69,'Zoey'),
  (70,'Eden'),
  (71,'Madelyn'),
  (72,'Vivian'),
  (73,'Millie'),
  (74,'Emery'),
  (75,'Daisy'),
  (76,'Maeve'),
  (77,'Ayla'),
  (78,'Liliana'),
  (79,'Melody'),
  (80,'Lyla'),
  (81,'Madeline'),
  (82,'Josie'),
  (83,'Lucia'),
  (84,'Addison'),
  (85,'Kennedy'),
  (86,'Audrey'),
  (87,'Maria'),
  (88,'Autumn'),
  (89,'Natalie'),
  (90,'Sarah'),
  (91,'Everly'),
  (92,'Lydia'),
  (93,'Kinsley'),
  (94,'Sienna'),
  (95,'Jade'),
  (96,'Caroline'),
  (97,'Quinn'),
  (98,'Amara'),
  (99,'Georgia'),
  (100,'Juniper');

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

insert into public.names (display_name, ssa_rank, source)
select t.display_name, t.ssa_rank, 'ssa_2025'
from desired_ssa_top_100 t
on conflict (display_name) do update
set ssa_rank = excluded.ssa_rank,
    source = 'ssa_2025';

insert into public.names (display_name, source)
select d.display_name, 'curated'
from desired_curated_names d
on conflict (display_name) do nothing;

update public.names n
set ssa_rank = null
where not exists (
  select 1
  from desired_ssa_top_100 t
  where t.display_name = n.display_name
);

update public.names n
set ssa_rank = t.ssa_rank,
    source = 'ssa_2025'
from desired_ssa_top_100 t
where n.display_name = t.display_name;

create temporary table desired_name_ids (
  id bigint primary key
) on commit drop;

insert into desired_name_ids (id)
select n.id
from public.names n
where exists (
    select 1 from desired_ssa_top_100 t where t.display_name = n.display_name
  )
   or exists (
    select 1 from desired_curated_names d where d.display_name = n.display_name
  );

delete from public.votes;
delete from public.rankings;

delete from public.names n
where not exists (
  select 1
  from desired_name_ids d
  where d.id = n.id
);

update public.names n
set source = 'curated'
where exists (
  select 1
  from desired_curated_names d
  where d.display_name = n.display_name
)
and not exists (
  select 1
  from desired_ssa_top_100 t
  where t.display_name = n.display_name
);

do $$
declare
  total_names integer;
  top_100_names integer;
  curated_names_present integer;
  overlap_names integer;
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

  select count(*) into overlap_names
  from desired_curated_names d
  join desired_ssa_top_100 t using (display_name);

  if top_100_names <> 100 then
    raise exception 'Expected 100 SSA names, found %', top_100_names;
  end if;

  if curated_names_present <> 60 then
    raise exception 'Expected all 60 curated names, found %', curated_names_present;
  end if;

  if overlap_names <> 15 then
    raise exception 'Expected 15 SSA/curated overlaps, found %', overlap_names;
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
  count(*) filter (where source = 'curated') as curated_only
from public.names;