-- Irrigazione automatica: programma "ogni N giorni" configurabile in
-- cascata (giardino → zona → pianta). zona_id e pianta_id entrambi null =
-- livello giardino (default per l'utente); zona_id valorizzato = livello
-- zona; pianta_id valorizzato = livello pianta. Mai entrambi valorizzati
-- (vedi check): la cascata è determinata da quale colonna è compilata, non
-- da un campo "livello" separato che potrebbe disallinearsi da essa.
create table programmi_irrigazione (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  zona_id uuid references zone(id) on delete cascade,
  pianta_id text references piante(id) on delete cascade,
  ogni_giorni integer not null check (ogni_giorni > 0),
  check (zona_id is null or pianta_id is null),
  unique (zona_id),
  unique (pianta_id)
);

-- Un solo programma "giardino" (zona_id e pianta_id entrambi null) per
-- utente: un vincolo unique su (zona_id, pianta_id) non basterebbe, perché
-- in Postgres NULL non è mai uguale a NULL in un vincolo unique.
create unique index programmi_irrigazione_giardino_uniq on programmi_irrigazione (owner_id)
  where zona_id is null and pianta_id is null;

alter table programmi_irrigazione enable row level security;

create policy "programmi_irrigazione: proprietario" on programmi_irrigazione for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
