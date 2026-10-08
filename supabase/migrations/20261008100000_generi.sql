-- Generi come entità propria: tabella `generi` + `specie.genere_id`.
-- Rollback: scripts/nomi-italiani/rollback_generi_schema.sql
create table generi (
  id uuid primary key default gen_random_uuid(),
  nome_scientifico text not null unique,
  nome text not null unique,
  specie_gbif integer,
  gbif_key bigint,
  gbif_rilevato_il date,
  creato_il timestamptz not null default now()
);

alter table generi enable row level security;
create policy "generi: lettura pubblica" on generi for select using (true);

insert into generi (nome_scientifico, nome)
select g, g from (
  select distinct split_part(nome_scientifico, ' ', 1) as g
  from specie where nome_scientifico ~ '^[A-Z][a-z]+( |$)'
) t;

alter table specie add column genere_id uuid references generi(id);
create index specie_genere_id_idx on specie (genere_id);

update specie s set genere_id = g.id
from generi g
where s.nome_scientifico ~ '^[A-Z][a-z]+( |$)'
  and g.nome_scientifico = split_part(s.nome_scientifico, ' ', 1);
