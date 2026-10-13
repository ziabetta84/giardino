-- Modello tassonomico, fase 1: tabelle nuove e vuote (spec docs/superpowers/specs/2026-10-13-modello-tassonomico-design.md).
-- Non tocca specie né generi; aggiunge a piante due colonne facoltative (taxon_id, cultivar_id).
-- Permessi scritti in modo esplicito: lettura pubblica senza le colonne interne (la fonte non si mostra mai),
-- nessuna scrittura per anon e authenticated, mappa_specie non leggibile dai client.
-- Si applica con: psql -1 -v ON_ERROR_STOP=1 -f <questo file>. Rollback: psql -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase1.sql
-- Prove: bash scripts/tassonomia/prova_fase1.sh

-- ===== taxa: nomi scientifici e gerarchia da Catalogue of Life (origine col) più i taxon locali =====
create table public.taxa (
  id uuid primary key default gen_random_uuid(),
  origine text not null default 'col' check (origine in ('col', 'locale')),
  col_id text unique,
  versione_col text,
  -- vocabolario dei ranghi di ChecklistBank (api.checklistbank.org/vocab/rank), senza cultivar, cultivar group e grex (stanno in cultivar)
  rango text not null check (rango in ('superdomain', 'domain', 'subdomain', 'infradomain', 'empire', 'realm', 'subrealm',
    'superkingdom', 'kingdom', 'subkingdom', 'infrakingdom', 'superphylum', 'phylum', 'subphylum', 'infraphylum', 'parvphylum',
    'microphylum', 'nanophylum', 'claudius', 'gigaclass', 'megaclass', 'superclass', 'class', 'subclass', 'infraclass',
    'subterclass', 'parvclass', 'superdivision', 'division zoology', 'subdivision', 'infradivision', 'superlegion', 'legion',
    'sublegion', 'infralegion', 'megacohort', 'supercohort', 'cohort', 'subcohort', 'infracohort', 'gigaorder', 'magnorder',
    'grandorder', 'mirorder', 'superorder', 'order', 'nanorder', 'hypoorder', 'minorder', 'suborder', 'infraorder', 'parvorder',
    'supersection zoology', 'section zoology', 'subsection zoology', 'superseries zoology', 'series zoology',
    'subseries zoology', 'falanx', 'gigafamily', 'megafamily', 'grandfamily', 'superfamily', 'epifamily', 'family',
    'subfamily', 'infrafamily', 'supertribe', 'tribe', 'subtribe', 'infratribe', 'suprageneric name', 'supergenus', 'genus',
    'subgenus', 'infragenus', 'division botany', 'supersection botany', 'section botany', 'subsection botany',
    'superseries botany', 'series botany', 'subseries botany', 'infrageneric name', 'species aggregate', 'species',
    'infraspecific name', 'klepton', 'subspecies', 'convariety', 'infrasubspecific name', 'proles', 'natio', 'aberration',
    'morph', 'supervariety', 'variety', 'subvariety', 'superform', 'form', 'subform', 'pathovar', 'biovar', 'chemovar',
    'morphovar', 'phagovar', 'serovar', 'chemoform', 'forma specialis', 'lusus', 'mutatio', 'strain', 'other', 'unranked')),
  nome_scientifico text not null check (btrim(nome_scientifico) <> ''),
  autore text,
  notho text check (notho in ('generic', 'infrageneric', 'specific', 'infraspecific')),
  ibrido boolean generated always as (notho is not null or nome_scientifico like '%×%') stored,
  stato text not null check (stato in ('accepted', 'provisionally accepted', 'synonym', 'ambiguous synonym', 'misapplied', 'bare name')),
  accettato_id uuid,
  padre_id uuid,
  nota text,
  importato_il timestamptz not null default now(),
  constraint taxa_col_ha_id check ((origine = 'col') = (col_id is not null)),
  constraint taxa_col_ha_versione check ((origine = 'col') = (versione_col is not null)),
  constraint taxa_accettato_solo_sinonimi check (accettato_id is null or stato in ('synonym', 'ambiguous synonym', 'misapplied')),
  constraint taxa_non_se_stesso check (accettato_id <> id and padre_id <> id),
  constraint taxa_accettato_fk foreign key (accettato_id) references public.taxa (id) on delete restrict deferrable initially deferred,
  constraint taxa_padre_fk foreign key (padre_id) references public.taxa (id) on delete restrict deferrable initially deferred
);
create index taxa_padre_id_idx on public.taxa (padre_id);
create index taxa_accettato_id_idx on public.taxa (accettato_id);
create index taxa_nome_scientifico_trgm_idx on public.taxa using gin (nome_scientifico extensions.gin_trgm_ops);

alter table public.taxa enable row level security;
create policy "taxa: lettura pubblica" on public.taxa for select using (true);
revoke all on public.taxa from anon, authenticated, service_role;
grant select, insert, update, delete on public.taxa to service_role;
grant select (id, rango, nome_scientifico, autore, notho, ibrido, stato, accettato_id, padre_id) on public.taxa to anon, authenticated;

-- ===== nomi_comuni: un nome per riga, con le fonti (interne) =====
create table public.nomi_comuni (
  id uuid primary key default gen_random_uuid(),
  taxon_id uuid not null references public.taxa (id) on delete restrict,
  lingua text not null check (lingua ~ '^[a-z]{2}$'),
  nome text not null check (btrim(nome) <> ''),
  preferito boolean not null default false,
  fonti text[] not null check (cardinality(fonti) > 0),
  nota text,
  creato_il timestamptz not null default now(),
  constraint nomi_comuni_unico unique (taxon_id, lingua, nome)
);
create unique index nomi_comuni_preferito_idx on public.nomi_comuni (taxon_id, lingua) where preferito;
create index nomi_comuni_nome_trgm_idx on public.nomi_comuni using gin (nome extensions.gin_trgm_ops);

alter table public.nomi_comuni enable row level security;
create policy "nomi_comuni: lettura pubblica" on public.nomi_comuni for select using (true);
revoke all on public.nomi_comuni from anon, authenticated, service_role;
grant select, insert, update, delete on public.nomi_comuni to service_role;
grant select (id, taxon_id, lingua, nome, preferito) on public.nomi_comuni to anon, authenticated;

-- ===== cultivar: dati nostri (RHS), assegnate al taxon più basso noto (ICNCP) =====
create table public.cultivar (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  taxon_id uuid not null references public.taxa (id) on delete restrict,
  categoria text not null default 'cultivar' check (categoria in ('cultivar', 'gruppo', 'grex')),
  epiteto text not null check (btrim(epiteto) <> '' and left(epiteto, 1) <> '''' and right(epiteto, 1) <> ''''),
  gruppo text,
  nome_commerciale text,
  fonti text[] not null check (cardinality(fonti) > 0),
  vecchia_specie_id uuid unique,
  creata_il timestamptz not null default now()
);
create index cultivar_taxon_id_idx on public.cultivar (taxon_id);
create index cultivar_epiteto_trgm_idx on public.cultivar using gin (epiteto extensions.gin_trgm_ops);
create index cultivar_nome_commerciale_trgm_idx on public.cultivar using gin (nome_commerciale extensions.gin_trgm_ops);

alter table public.cultivar enable row level security;
create policy "cultivar: lettura pubblica" on public.cultivar for select using (true);
revoke all on public.cultivar from anon, authenticated, service_role;
grant select, insert, update, delete on public.cultivar to service_role;
grant select (id, slug, taxon_id, categoria, epiteto, gruppo, nome_commerciale) on public.cultivar to anon, authenticated;
