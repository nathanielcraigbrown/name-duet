-- Verified etymology metadata for the active 145-name pool.
-- Run migration 010 first. This updates metadata only.

begin;

create temporary table verified_name_metadata (
  display_name text primary key,
  origin text not null,
  meaning text not null
) on commit drop;

insert into verified_name_metadata (display_name, origin, meaning) values
  ('Olivia','English / Latin','olive; Shakespearean form'),
  ('Charlotte','French / Germanic','free person'),
  ('Emma','Germanic','whole, universal'),
  ('Amelia','Germanic / Latinized','work'),
  ('Sophia','Greek','wisdom'),
  ('Mia','Scandinavian / Italian','mine; diminutive of Maria'),
  ('Isabella','Italian / Hebrew','my God is an oath'),
  ('Evelyn','English / Norman French','desired; historically a surname form'),
  ('Sofia','Greek','wisdom'),
  ('Eliana','Hebrew / Italian','my God has answered; also feminine of Eliano'),
  ('Ava','Germanic / Persian / modern English','possibly desired; voice or sound in Persian'),
  ('Eleanor','Old French / Greek','meaning uncertain; traditionally linked to Helen'),
  ('Violet','English / Latin','violet flower'),
  ('Ailany','Modern American / Hawaiian-influenced','modern form; exact derivation uncertain'),
  ('Aurora','Latin','dawn'),
  ('Harper','English','harp player'),
  ('Elizabeth','Hebrew','my God is an oath'),
  ('Lily','English / Latin','lily flower'),
  ('Camila','Spanish / Portuguese / Latin','young ceremonial attendant'),
  ('Nora','Irish / English / Latin','honor; light'),
  ('Hazel','English','hazel tree'),
  ('Penelope','Greek','meaning uncertain; traditionally associated with weaving'),
  ('Chloe','Greek','green shoot'),
  ('Ellie','English','short form of Eleanor, Ellen, Elizabeth and related names'),
  ('Lucy','English / Latin','light'),
  ('Aria','Italian / Hebrew / Persian','air or melody; lioness; noble'),
  ('Luna','Latin','moon'),
  ('Isla','Scottish / Spanish','island; also a Scottish river name'),
  ('Ella','Germanic / English','other; also a short form of several names'),
  ('Lainey','English','bright, shining one'),
  ('Zoe','Greek','life'),
  ('Scarlett','English','scarlet cloth or color'),
  ('Gianna','Italian / Hebrew','God is gracious'),
  ('Emily','English / Latin','rival; emulating'),
  ('Valentina','Latin','strong, healthy'),
  ('Layla','Arabic','night'),
  ('Avery','English / Germanic','elf ruler'),
  ('Grace','English / Latin','grace, favor'),
  ('Ivy','English','ivy plant'),
  ('Madison','English','son of Maud or Matthew'),
  ('Abigail','Hebrew','my father is joy'),
  ('Elena','Greek / Romance','torch; shining light'),
  ('Mila','Slavic','gracious, dear'),
  ('Willow','English','willow tree'),
  ('Emilia','Latin','rival; emulating'),
  ('Nova','Latin / English','new; a star that suddenly brightens'),
  ('Naomi','Hebrew','pleasantness'),
  ('Riley','Irish / English','descendant of Raghallach; rye clearing'),
  ('Eloise','French / Germanic','healthy; wide'),
  ('Sadie','English / Hebrew','princess'),
  ('Delilah','Hebrew','delicate, languishing'),
  ('Stella','Latin','star'),
  ('Josephine','French / Hebrew','God will add'),
  ('Victoria','Latin','victory'),
  ('Sophie','French / Greek','wisdom'),
  ('Hannah','Hebrew','favor, grace'),
  ('Lillian','English / Latin','lily'),
  ('Leah','Hebrew','meaning uncertain; traditionally weary'),
  ('Adeline','French / Germanic','noble'),
  ('Leilani','Hawaiian','heavenly flowers; royal child'),
  ('Iris','Greek','rainbow'),
  ('Maya','Multiple origins','illusion; good mother; water'),
  ('Clara','Latin','bright, clear'),
  ('Ruby','English / Latin','red gemstone'),
  ('Alice','French / Germanic','noble'),
  ('Genesis','Greek','origin, birth'),
  ('Paisley','Scottish / English','from the Scottish place and textile pattern'),
  ('Claire','French / Latin','bright, clear'),
  ('Zoey','English / Greek','life'),
  ('Eden','Hebrew','delight'),
  ('Madelyn','English / French / Hebrew','from Magdala'),
  ('Vivian','Latin','alive'),
  ('Millie','English','gentle strength; work; or industrious'),
  ('Emery','English / Germanic','brave, powerful'),
  ('Daisy','English','daisy flower; day''s eye'),
  ('Maeve','Irish','intoxicating'),
  ('Ayla','Turkish / Hebrew','moonlight or halo; oak tree'),
  ('Liliana','Latin / European','lily'),
  ('Melody','English / Greek','song, melody'),
  ('Lyla','English / Arabic-influenced','night; modern variant of Lila or Layla'),
  ('Madeline','English / French / Hebrew','from Magdala'),
  ('Josie','English / Hebrew','God will add'),
  ('Lucia','Latin','light'),
  ('Addison','English','son of Adam'),
  ('Kennedy','Irish','descendant of Cennétig; helmeted or misshapen head'),
  ('Audrey','English / Anglo-Saxon','noble strength'),
  ('Maria','Hebrew via Greek and Latin','meaning uncertain; traditionally beloved or bitter'),
  ('Autumn','English','autumn season'),
  ('Natalie','French / Latin','Christmas Day; birth'),
  ('Sarah','Hebrew','princess'),
  ('Everly','English','wild-boar clearing; transferred surname'),
  ('Lydia','Greek','woman from Lydia'),
  ('Kinsley','English','king''s clearing or royal meadow'),
  ('Sienna','Italian place / color','from Siena; reddish-brown earth pigment'),
  ('Jade','Spanish / English','jade gemstone; stone of the side'),
  ('Caroline','French / Germanic','free person'),
  ('Quinn','Irish','descendant of Conn; chief or wisdom'),
  ('Amara','Multiple origins','grace; eternal; bitter'),
  ('Georgia','Greek','farmer, earth-worker'),
  ('Juniper','English / Latin','juniper tree'),
  ('Aurelia','Latin','golden'),
  ('Molly','English / Irish','meaning of Mary uncertain; traditionally beloved'),
  ('Sabina','Latin','Sabine woman'),
  ('Sabine','French / German / Latin','of the Sabines'),
  ('Sabrina','Latinized Celtic / Welsh','name of the River Severn'),
  ('Corinne','French / Greek','maiden'),
  ('Ramona','Spanish / Germanic','wise protector'),
  ('Lucille','French / Latin','light'),
  ('Marina','Latin','of the sea'),
  ('Leona','Latin','lioness'),
  ('Caledonia','Latin / Scottish place name','Scotland; land of the Caledonians'),
  ('Calliope','Greek','beautiful voice'),
  ('Euroletta','Rare literary / American usage','rare historic name; etymology unverified'),
  ('Celia','Latin / English','heavenly; also a literary short form'),
  ('Phoebe','Greek','bright, radiant'),
  ('Skye','Scottish place name','Isle of Skye; exact place-name origin disputed'),
  ('Summer','English','summer season'),
  ('Helena','Greek','torch; shining light'),
  ('Denise','French / Greek','follower of Dionysus'),
  ('Liza','English / Hebrew','my God is an oath'),
  ('Shea','Irish','hawk-like; fortunate or stately interpretations vary'),
  ('Faye','English / French','fairy'),
  ('Eliza','English / Hebrew','my God is an oath'),
  ('Juliet','English / French / Latin','youthful; of the Julian family'),
  ('Cecilia','Latin','of the Caecilius family; traditionally blind'),
  ('Sylvie','French / Latin','of the forest'),
  ('Margot','French / Greek','pearl'),
  ('Daphne','Greek','laurel'),
  ('Nina','Multiple origins','little girl; grace; meaning varies'),
  ('Louisa','Germanic / English','renowned warrior'),
  ('Thea','Greek / Germanic','goddess; also short form of Dorothea or Theodora'),
  ('Ada','Germanic / Hebrew','noble; ornament'),
  ('Rose','English / Latin','rose flower'),
  ('June','English / Latin','June; associated with Juno'),
  ('Willa','Germanic / English','resolute protector'),
  ('Matilda','Germanic','strength in battle'),
  ('Esme','French / Persian','esteemed; beloved'),
  ('Simone','French / Hebrew','he has heard'),
  ('Cora','Greek','maiden'),
  ('Diana','Latin / Roman','divine, heavenly'),
  ('Fiona','Scottish / Gaelic','fair, white'),
  ('Flora','Latin','flower'),
  ('Greer','Scottish / Greek','watchful, alert'),
  ('Ingrid','Old Norse','Ing is beautiful or beloved'),
  ('Adelaide','Germanic','noble nature');

do $$
declare
  metadata_count integer;
  active_count integer;
  missing_count integer;
  extra_count integer;
begin
  select count(*) into metadata_count from verified_name_metadata;
  select count(*) into active_count from public.names;
  select count(*) into missing_count
  from verified_name_metadata v
  where not exists (select 1 from public.names n where n.display_name = v.display_name);
  select count(*) into extra_count
  from public.names n
  where not exists (select 1 from verified_name_metadata v where v.display_name = n.display_name);

  if metadata_count <> 145 then
    raise exception 'Expected 145 metadata rows, found %', metadata_count;
  end if;
  if active_count <> 145 then
    raise exception 'Expected 145 active names, found %. Run migration 010 first.', active_count;
  end if;
  if missing_count <> 0 or extra_count <> 0 then
    raise exception 'Pool mismatch: % metadata names missing and % active names unexpected', missing_count, extra_count;
  end if;
end
$$;

update public.names n
set origin = v.origin,
    meaning = v.meaning
from verified_name_metadata v
where n.display_name = v.display_name;

do $$
declare
  populated_count integer;
begin
  select count(*) into populated_count
  from public.names
  where nullif(btrim(origin), '') is not null
    and nullif(btrim(meaning), '') is not null;
  if populated_count <> 145 then
    raise exception 'Expected 145 populated names, found %', populated_count;
  end if;
end
$$;

select
  count(*) as active_names,
  count(*) filter (where nullif(btrim(origin), '') is not null) as names_with_origin,
  count(*) filter (where nullif(btrim(meaning), '') is not null) as names_with_meaning
from public.names;

commit;
