-- Completamento Fase 5: progetti/tappe, concimi, settings diventano
-- tabelle relazionali multi-tenant (prima JSON su GitHub, senza scoping
-- per utente). tappe è una tabella a parte, non un campo jsonb dentro
-- progetti: oggi esistono due percorsi di scrittura indipendenti sulle
-- tappe (ProgettoView riscrive l'intero form, AttivitaView aggiorna una
-- singola tappa per id da "registraTappa") — una riga per tappa rende
-- ogni scrittura atomica, senza il rischio di un UPDATE su un intero
-- campo jsonb che sovrascrive silenziosamente una modifica concorrente.

create table progetti (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  titolo text not null,
  descrizione text,
  zona text,
  stato text not null default 'aperto'
    check (stato in ('aperto','in_corso','completato','fallito','cancellato')),
  creato date not null default current_date
);

create table tappe (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  progetto_id uuid not null references progetti(id) on delete cascade,
  data date not null,
  descrizione text not null,
  esito text not null default 'atteso'
    check (esito in ('atteso','riuscito','fallito','saltato'))
);

create table concimi (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  nome text not null,
  npk jsonb not null default '{"n":0,"p":0,"k":0}'::jsonb,
  disponibile boolean not null default true,
  descrizione text
);

create table settings (
  owner_id uuid primary key references auth.users default auth.uid(),
  location jsonb,
  units jsonb not null default '{"temperature":"celsius","wind":"kmh","precipitation":"mm"}'::jsonb,
  meteo jsonb not null default '{"provider":"open-meteo","days":3}'::jsonb,
  ui jsonb not null default '{"theme":"auto"}'::jsonb,
  zona_climatica_id uuid references zone_climatiche(id)
);

alter table progetti enable row level security;
alter table tappe enable row level security;
alter table concimi enable row level security;
alter table settings enable row level security;

create policy "progetti: proprietario" on progetti for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "tappe: proprietario" on tappe for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "concimi: proprietario" on concimi for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "settings: proprietario" on settings for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
