-- Fase 4a: le righe di cultivar da caricare (col.cultivar_proposte) e le righe di mappa_specie delle cultivar che non
-- diventano cultivar (col.cultivar_mappa), sulla copia locale con COL completo (schema col). Regole: specifica,
-- "Decisioni per la fase 4", punti 5 e 15-19.
-- - taxon_id = il taxon più basso noto (ICNCP art. 21.1-21.2): il nome trovato della madre in mappa_specie, anche se
--   sinonimo; per le cultivar di specie la cui madre è una riga "Genere spp." (difetto dell'import) la specie del nome,
--   accettata o sinonimo, presa da taxa o, se manca, da COL (taxon_col_id, da importare); per le orfane la riga madre
--   mancata (stesso nome, senza apici); mai sopra il genere: in quel caso il genere scritto nel nome;
-- - grex: righe non cultivar della fase 3 (nota "grex…" o Genere + nome maiuscolo sotto un notogenere locale), epiteto
--   = nome senza genere e senza "gx" (art. 16.3, 23.1); Brachyglottis Dunedin Hybrids = gruppo "Dunedin Group" (art. 3,
--   Nota 1, Es. 7); le cultivar figlie di un grex hanno grex_id (art. 6.5);
-- - righe fuse da più cultivar RHS o senza epiteto leggibile: nessuna cultivar, una riga di mappa (esito ambiguo);
-- - cultivar doppie cancellate (dati/fase4_cultivar_doppie.tsv): una riga di mappa verso la cultivar gemella.
-- Standard input: il TSV di cultivar_estrai.py. Lanciare dalla radice del repository.
set statement_timeout = 0;
drop table if exists col.cultivar_estratte, col.cultivar_doppie, col.cultivar_proposte, col.cultivar_mappa;
create table col.cultivar_estratte (id uuid primary key, caso text not null, epiteto text, categoria text not null, gruppo text,
                                    nome_commerciale text, grex text, segnalazioni text, titoli text);
\copy col.cultivar_estratte from pstdin with (format csv, delimiter E'\t', header)
create table col.cultivar_doppie (vecchia_specie_id uuid primary key, vecchio_slug text not null, vecchio_nome_scientifico text not null,
                                  gemella_specie_id uuid not null);
\copy col.cultivar_doppie from 'scripts/tassonomia/dati/fase4_cultivar_doppie.tsv' with (format csv, delimiter E'\t', header)

-- nome normalizzato per i confronti: segno d'ibrido tolto (COL scrive Camellia × williamsii, RHS Camellia williamsii)
create or replace function col.nome_norm(n text) returns text language sql immutable parallel safe as $$
  select lower(regexp_replace(btrim(regexp_replace(replace(n, '×', ' '), '(^|\s)x\s', ' ', 'g')), '\s+', ' ', 'g'))
$$;

do $$
declare n bigint;
begin
  select count(*) into n from public.specie s where s.nome_scientifico like '%''%'
     and not exists (select 1 from col.cultivar_estratte e where e.id = s.id);
  if n > 0 then raise exception 'righe cultivar di specie senza estrazione: %', n; end if;
  select count(*) into n from col.cultivar_estratte e where not exists (select 1 from public.specie s where s.id = e.id);
  if n > 0 then raise exception 'estrazioni per righe che non sono in specie: %', n; end if;
end $$;

create temp table cv as
select s.id, s.slug, s.nome_scientifico as ns, s.specie_padre_id, s.fonti,
       btrim(split_part(s.nome_scientifico, '''', 1)) as base,
       e.caso, e.epiteto, e.categoria, nullif(e.gruppo, '') as gruppo, nullif(e.nome_commerciale, '') as nome_commerciale,
       e.titoli, p.nome_scientifico as madre_ns, mp.taxon_id as madre_taxon
  from public.specie s
  join col.cultivar_estratte e on e.id = s.id
  left join public.specie p on p.id = s.specie_padre_id
  left join public.mappa_specie mp on mp.vecchia_specie_id = s.specie_padre_id;
alter table cv add column forma text, add column origine_taxon text, add column taxon_id uuid, add column taxon_col_id text;
update cv set forma = case
  when base ~ '^[A-Z][a-z-]+$' then 'G'
  when base ~ '^(× )?[A-Z][a-z-]+ (× )?[a-z][a-z-]+$' then 'G s'
  when base ~ '^(× )?[A-Z][a-z-]+ [A-Z]' then 'grex'
  else 'altro' end;
update cv set origine_taxon = case
  when specie_padre_id is null then 'orfana'
  when madre_ns ~ '\sspp\.?$' and forma = 'G s' then 'genere spp.'
  else 'madre' end;

-- taxa per nome normalizzato: l'accettato prima dei sinonimi (il nome trovato, come nella fase 3)
create temp table nome_taxa as
select distinct on (col.nome_norm(t.nome_scientifico), t.rango) col.nome_norm(t.nome_scientifico) as nome, t.rango, t.id
  from public.taxa t where t.rango in ('genus', 'species')
 order by col.nome_norm(t.nome_scientifico), t.rango, (t.stato in ('accepted', 'provisionally accepted')) desc,
          (t.stato = 'accepted') desc, t.id;
create index on nome_taxa (nome, rango);

update cv set taxon_id = madre_taxon where origine_taxon = 'madre';
update cv set taxon_id = n.id from nome_taxa n
 where cv.origine_taxon = 'genere spp.' and n.nome = col.nome_norm(cv.base) and n.rango = 'species';
-- orfane: la riga madre mancata (stesso nome, senza apici), altrimenti il nome base in taxa
update cv set taxon_id = mp.taxon_id from public.specie m join public.mappa_specie mp on mp.vecchia_specie_id = m.id
 where cv.origine_taxon = 'orfana' and m.specie_padre_id is null and m.nome_scientifico = cv.base;
update cv set taxon_id = n.id from nome_taxa n
 where cv.origine_taxon = 'orfana' and cv.taxon_id is null and n.nome = col.nome_norm(cv.base)
   and n.rango = case when cv.forma = 'G' then 'genus' else 'species' end;

-- specie del nome che mancano da taxa: da COL, in Plantae (per un sinonimo il regno è quello dell'accettato), niente
-- segnaposto "Genere spp"; l'accettato prima dei sinonimi
create temp table da_cercare as
select distinct col.nome_norm(base) as nome, lower(split_part(regexp_replace(base, '^× ', ''), ' ', 1)) as genere
  from cv where origine_taxon = 'genere spp.' and taxon_id is null;
create temp table col_trovati as
select distinct on (col.nome_norm(u.nome)) col.nome_norm(u.nome) as nome, u.id
  from col.nome_uso u
  left join col.nome_uso a on a.id = u.parent_id and u.status in ('synonym', 'ambiguous synonym')
 where u.rango = 'species' and lower(split_part(regexp_replace(u.nome, '^× ', ''), ' ', 1)) in (select genere from da_cercare)
   and col.nome_norm(u.nome) in (select nome from da_cercare)
   and u.status in ('accepted', 'provisionally accepted', 'synonym', 'ambiguous synonym')
   and coalesce(nullif(u.regno, ''), a.regno) = 'Plantae' and u.nome !~ '\sspp?\.?\s*$'
 order by col.nome_norm(u.nome), (u.status = 'accepted') desc, (u.status = 'provisionally accepted') desc,
          (u.status = 'synonym') desc, u.id;
update cv set taxon_col_id = c.id from col_trovati c
 where cv.origine_taxon = 'genere spp.' and cv.taxon_id is null and c.nome = col.nome_norm(cv.base);

-- mai sopra il genere (ICNCP art. 21.2): madri finite su una tribù o una famiglia nella fase 3 -> il genere del nome
update cv set taxon_id = n.id, origine_taxon = origine_taxon || ', genere del nome'
  from public.taxa t, nome_taxa n
 where t.id = cv.taxon_id and t.rango not in ('genus', 'species', 'subspecies', 'variety', 'form')
   and n.nome = col.nome_norm(split_part(regexp_replace(cv.base, '^× ', ''), ' ', 1)) and n.rango = 'genus';

-- righe grex e il Gruppo Dunedin, dalle righe non cultivar della fase 3
create temp table grex as
select mp.vecchia_specie_id as id, s.slug, s.fonti, mp.taxon_id,
       case when s.nome_scientifico ~ '\sHybrids$' then 'gruppo' else 'grex' end as categoria,
       case when s.nome_scientifico ~ '\sHybrids$'
            then regexp_replace(regexp_replace(s.nome_scientifico, '^(× )?[A-Z][a-z-]+ ', ''), ' Hybrids$', ' Group')
            else regexp_replace(s.nome_scientifico, '^(× )?[A-Z][a-z-]+ ', '') end as epiteto
  from public.mappa_specie mp join public.specie s on s.id = mp.vecchia_specie_id
 where mp.origine = 'specie' and s.nome_scientifico ~ '^(× )?[A-Z][a-z-]+ [A-Z]' and s.nome_scientifico !~ ''''
   and (mp.nota ilike 'grex%' or mp.esito in ('ibrido', 'rango superiore'));

create table col.cultivar_proposte (
  id uuid primary key default gen_random_uuid(), vecchia_specie_id uuid not null unique, slug text not null unique,
  taxon_id uuid, taxon_col_id text, categoria text not null, epiteto text not null, gruppo text, nome_commerciale text,
  grex_id uuid, fonti text[] not null, origine_taxon text not null, caso text not null);
insert into col.cultivar_proposte (vecchia_specie_id, slug, taxon_id, categoria, epiteto, fonti, origine_taxon, caso)
select id, slug, taxon_id, categoria, epiteto, fonti, 'riga ' || categoria || ' della fase 3', 'riga non cultivar' from grex;
insert into col.cultivar_proposte (vecchia_specie_id, slug, taxon_id, taxon_col_id, categoria, epiteto, gruppo, nome_commerciale,
                                   fonti, origine_taxon, caso)
select id, slug, taxon_id, taxon_col_id, categoria, epiteto, gruppo, nome_commerciale, fonti, origine_taxon, caso
  from cv where caso not in ('fusa: nessun titolo con questo epiteto', 'senza epiteto leggibile');
-- cultivar figlie di una riga grex
update col.cultivar_proposte c set grex_id = g.id
  from public.specie s, col.cultivar_proposte g
 where s.id = c.vecchia_specie_id and g.vecchia_specie_id = s.specie_padre_id and g.categoria = 'grex';

create table col.cultivar_mappa (
  vecchia_specie_id uuid primary key, vecchio_slug text not null unique, vecchio_nome_scientifico text not null,
  origine text not null, taxon_id uuid, taxon_col_id text, cultivar_id uuid, esito text not null, nota text not null);
insert into col.cultivar_mappa
select id, slug, ns, 'specie', taxon_id, taxon_col_id, null, 'ambiguo',
       case when caso = 'senza epiteto leggibile' then 'cultivar senza un epiteto leggibile nel nome né nei titoli RHS'
            else 'riga nata da più cultivar RHS (' || titoli || '): nessuna cultivar, collegata al taxon' end
  from cv where caso in ('fusa: nessun titolo con questo epiteto', 'senza epiteto leggibile');
insert into col.cultivar_mappa
select d.vecchia_specie_id, d.vecchio_slug, d.vecchio_nome_scientifico, 'rollback', null, null, c.id, 'deciso dall''utente',
       'cultivar doppia cancellata il 13/10/2026 (migration 20261013110000): la stessa cultivar sotto la specie'
  from col.cultivar_doppie d join col.cultivar_proposte c on c.vecchia_specie_id = d.gemella_specie_id;

\pset tuples_only on
\pset format unaligned
select 'cultivar ' || count(*) || ' (grex ' || count(*) filter (where categoria = 'grex') || ', gruppi '
       || count(*) filter (where categoria = 'gruppo') || ', con grex_id ' || count(grex_id) || ')' from col.cultivar_proposte;
select 'taxon: ' || origine_taxon || ' ' || count(*) from col.cultivar_proposte group by origine_taxon order by count(*) desc;
select 'specie da importare da COL ' || count(distinct taxon_col_id) || ' (' || count(*) || ' cultivar)' from col.cultivar_proposte
 where taxon_col_id is not null;
select 'righe di mappa delle cultivar ' || count(*) from col.cultivar_mappa;
