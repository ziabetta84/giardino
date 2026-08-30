-- Fase 5: zone/sottozone/piante diventano tabelle relazionali multi-tenant
-- (prima JSON su GitHub, senza scoping per utente). FK a UUID invece di
-- stringhe libere: rinominare una zona/sottozona non richiede più
-- aggiornare a mano le piante che la referenziano. `piante.id` resta testo
-- (stesso formato "slug-timestamp" generato client-side) per compatibilità
-- con la struttura cartelle della gallery foto.

create table zone (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  nome text not null,
  descrizione text,
  esposizione text[],
  microclima text,
  criticita text,
  manutenzione text,
  tipo text,
  unique (owner_id, nome)
);

create table sottozone (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  zona_id uuid not null references zone(id) on delete cascade,
  nome text not null,
  descrizione text,
  esposizione text[],
  microclima text,
  criticita text,
  manutenzione text,
  tipo text,
  unique (zona_id, nome)
);

create table piante (
  id text primary key,
  owner_id uuid not null references auth.users default auth.uid(),
  specie text not null references specie(slug),
  zona_id uuid not null references zone(id) on delete restrict,
  sottozona_id uuid references sottozone(id) on delete set null,
  varieta text,
  impianto text,
  impianto_circa text,
  note text,
  coltivato_in text,
  ultima_cura jsonb not null default '{}'::jsonb
);

alter table zone enable row level security;
alter table sottozone enable row level security;
alter table piante enable row level security;

create policy "zone: proprietario" on zone for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "sottozone: proprietario" on sottozone for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "piante: proprietario" on piante for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
