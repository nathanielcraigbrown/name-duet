-- Add the 2025 SSA girls ranked 101-200 to the existing pool.
-- Existing names are preserved and only have their SSA rank/source refreshed.
-- Votes, Elo ratings, rooms, and participants are not reset.

insert into public.names (display_name, ssa_rank, source)
values
  ('Aaliyah', 101, 'SSA 2025'),
  ('Margot', 102, 'SSA 2025'),
  ('Allison', 103, 'SSA 2025'),
  ('Hailey', 104, 'SSA 2025'),
  ('Gabriella', 105, 'SSA 2025'),
  ('Parker', 106, 'SSA 2025'),
  ('Anna', 107, 'SSA 2025'),
  ('Cecilia', 108, 'SSA 2025'),
  ('Athena', 109, 'SSA 2025'),
  ('Juliette', 110, 'SSA 2025'),
  ('Catalina', 111, 'SSA 2025'),
  ('Margaret', 112, 'SSA 2025'),
  ('Cora', 113, 'SSA 2025'),
  ('Rose', 114, 'SSA 2025'),
  ('Eliza', 115, 'SSA 2025'),
  ('Raelynn', 116, 'SSA 2025'),
  ('Alaia', 117, 'SSA 2025'),
  ('Brooklyn', 118, 'SSA 2025'),
  ('Esther', 119, 'SSA 2025'),
  ('Hallie', 120, 'SSA 2025'),
  ('Hadley', 121, 'SSA 2025'),
  ('Emerson', 122, 'SSA 2025'),
  ('Elsie', 123, 'SSA 2025'),
  ('Magnolia', 124, 'SSA 2025'),
  ('Mary', 125, 'SSA 2025'),
  ('Scottie', 126, 'SSA 2025'),
  ('Valerie', 127, 'SSA 2025'),
  ('Ariana', 128, 'SSA 2025'),
  ('Serenity', 129, 'SSA 2025'),
  ('Alina', 130, 'SSA 2025'),
  ('Julia', 131, 'SSA 2025'),
  ('Amira', 132, 'SSA 2025'),
  ('Charlie', 133, 'SSA 2025'),
  ('Eva', 134, 'SSA 2025'),
  ('Savannah', 135, 'SSA 2025'),
  ('Bella', 136, 'SSA 2025'),
  ('Rylee', 137, 'SSA 2025'),
  ('Emersyn', 138, 'SSA 2025'),
  ('Elliana', 139, 'SSA 2025'),
  ('Alana', 140, 'SSA 2025'),
  ('Sloane', 141, 'SSA 2025'),
  ('Melanie', 142, 'SSA 2025'),
  ('Brielle', 143, 'SSA 2025'),
  ('Natalia', 144, 'SSA 2025'),
  ('Remi', 145, 'SSA 2025'),
  ('Aubrey', 146, 'SSA 2025'),
  ('Evangeline', 147, 'SSA 2025'),
  ('Genevieve', 148, 'SSA 2025'),
  ('Kehlani', 149, 'SSA 2025'),
  ('June', 150, 'SSA 2025'),
  ('Samantha', 151, 'SSA 2025'),
  ('Summer', 152, 'SSA 2025'),
  ('Oaklynn', 153, 'SSA 2025'),
  ('Ember', 154, 'SSA 2025'),
  ('Piper', 155, 'SSA 2025'),
  ('Oakley', 156, 'SSA 2025'),
  ('Phoebe', 157, 'SSA 2025'),
  ('Arya', 158, 'SSA 2025'),
  ('Wrenley', 159, 'SSA 2025'),
  ('Sage', 160, 'SSA 2025'),
  ('Alani', 161, 'SSA 2025'),
  ('Valeria', 162, 'SSA 2025'),
  ('Anastasia', 163, 'SSA 2025'),
  ('Ashley', 164, 'SSA 2025'),
  ('Nevaeh', 165, 'SSA 2025'),
  ('Isabelle', 166, 'SSA 2025'),
  ('Skylar', 167, 'SSA 2025'),
  ('Ailani', 168, 'SSA 2025'),
  ('Blair', 169, 'SSA 2025'),
  ('Gemma', 170, 'SSA 2025'),
  ('Rosalie', 171, 'SSA 2025'),
  ('Vivienne', 172, 'SSA 2025'),
  ('Ruth', 173, 'SSA 2025'),
  ('Ariella', 174, 'SSA 2025'),
  ('Callie', 175, 'SSA 2025'),
  ('Freya', 176, 'SSA 2025'),
  ('Isabel', 177, 'SSA 2025'),
  ('Daphne', 178, 'SSA 2025'),
  ('Lilah', 179, 'SSA 2025'),
  ('Amaya', 180, 'SSA 2025'),
  ('Sutton', 181, 'SSA 2025'),
  ('Annie', 182, 'SSA 2025'),
  ('Ximena', 183, 'SSA 2025'),
  ('Adalynn', 184, 'SSA 2025'),
  ('Kaylani', 185, 'SSA 2025'),
  ('Katherine', 186, 'SSA 2025'),
  ('Lila', 187, 'SSA 2025'),
  ('Celeste', 188, 'SSA 2025'),
  ('Tatum', 189, 'SSA 2025'),
  ('Haven', 190, 'SSA 2025'),
  ('Blakely', 191, 'SSA 2025'),
  ('Reese', 192, 'SSA 2025'),
  ('Kaia', 193, 'SSA 2025'),
  ('Everleigh', 194, 'SSA 2025'),
  ('Alora', 195, 'SSA 2025'),
  ('Molly', 196, 'SSA 2025'),
  ('Olive', 197, 'SSA 2025'),
  ('Sara', 198, 'SSA 2025'),
  ('Peyton', 199, 'SSA 2025'),
  ('Lia', 200, 'SSA 2025')
on conflict (display_name) do update
set ssa_rank = excluded.ssa_rank,
    source = excluded.source;

-- Confirm the full rank block is represented after the upsert.
do $$
declare
  represented integer;
begin
  select count(*) into represented
  from public.names
  where ssa_rank between 101 and 200;

  if represented <> 100 then
    raise exception 'Expected all 100 SSA ranks from 101-200; found %', represented;
  end if;
end $$;

select display_name, ssa_rank
from public.names
where ssa_rank between 101 and 200
order by ssa_rank;
