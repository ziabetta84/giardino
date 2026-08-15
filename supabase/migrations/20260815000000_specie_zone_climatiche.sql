-- Prima migrazione: il catalogo condiviso (specie, zone_climatiche).
-- Nessuno scoping per utente: letto da chiunque, scritto da nessun client pubblico.
-- Vedi piano di migrazione: https://claude.ai/code/artifact/d3dc5ab6-5f2c-4109-82bd-769e9694b5f4

create table zone_climatiche (
  id                    uuid primary key default gen_random_uuid(),
  codice                text unique not null,   -- 'nord' | 'nord-montana' | 'centro' | 'centro-montana' | 'sud' | 'sud-montana' | 'insulare' | 'insulare-montana'
  nome                  text not null,
  gelata_media_ultima   text,   -- 'MM-DD'
  gelata_media_prima    text,   -- 'MM-DD'
  hardiness_usda        text    -- riferimento incrociato, indicativo
);

alter table zone_climatiche enable row level security;

create policy "zone_climatiche: lettura pubblica"
  on zone_climatiche for select
  using (true);

create table specie (
  id                          uuid primary key default gen_random_uuid(),
  nome                        text unique not null,
  famiglia_botanica           text,
  descrizione                 text,
  esigenze                    jsonb,   -- luce/acqua/terreno, come oggi
  alert                       text[],  -- note pratiche, come oggi
  manutenzione                jsonb,   -- irrigazione/concimazione/potatura/npk/calcio per stagione, come oggi
  ciclo_colturale             jsonb,   -- semina/trapianto/raccolta, offset dalla gelata
  vaso                        jsonb,   -- modificatori per coltivazione in contenitore
  consociazioni_favorevoli    text[],
  consociazioni_sfavorevoli   text[],
  fonti                       text[],  -- riferimenti consultati per questa scheda
  stato_verifica              text not null default 'bozza'
                              check (stato_verifica in ('bozza', 'verificato')),
  verificata_il               timestamptz,
  verificata_da               text,
  aggiornata_il               timestamptz not null default now()
);

alter table specie enable row level security;

create policy "specie: lettura pubblica"
  on specie for select
  using (true);
