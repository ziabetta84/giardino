-- Fase 2: sceglie in COL XR (schema col della copia locale) i taxon che servono e assegna loro la chiave definitiva.
-- Semi: i nomi delle righe di specie senza apici (non cultivar) e di generi, confrontati con col.chiave, che ignora il
-- segno d'ibrido (× o x, COL scrive "Mentha × piperita" ma "Fatshedera" senza segno) e " spp."; solo in Plantae
-- (Prunella è anche un genere di uccelli; per i sinonimi il regno è quello del loro accettato). Dai semi: i loro
-- accettati, la catena dei padri fino alla radice (Eukaryota), i sinonimi degli accettati e dei generi della catena.
-- I misapplied entrano solo se sono il nome stesso di una nostra riga. Il resto di COL non entra.
-- COL contiene segnaposto "Genere spp" (rango species, es. "Abies spp" accettato sotto il genere): non sono specie.
-- Non entrano da nessuna strada: non corrispondono ai nostri generi (" spp." si toglie solo dai nostri nomi), un
-- sinonimo che in COL porta solo a un segnaposto (es. un omonimo di Rosa moschata → "Rosa spp") resta non trovato, e
-- i sinonimi chiamati "X spp" non entrano (revisione del 15/10/2026).
-- Si rilancia senza danni: ricrea le tabelle col.* e assegna chiavi nuove (i lotti vanno rigenerati).
-- Uso: psql URL_COPIA -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/col_selezione.sql
set statement_timeout = 0;
create or replace function col.chiave(n text) returns text language sql immutable parallel safe as $$
  select btrim(regexp_replace(
           regexp_replace(
             regexp_replace(n, '\s+spp\.?\s*$', ''),
             '(^|\s)[×x](\s+|(?=[A-Z]))', ' ', 'g'),
           '\s+', ' ', 'g'))
$$;
-- l'indice dipende dal corpo della funzione: si ricrea a ogni esecuzione (circa 80 secondi)
drop index if exists col.nome_uso_chiave_idx;
create index nome_uso_chiave_idx on col.nome_uso (col.chiave(nome));
analyze col.nome_uso;

drop table if exists col.nostri, col.corrispondenze, col.accettati, col.catena, col.sinonimi, col.selezione;
create table col.nostri as
  select distinct col.chiave(nome_scientifico) as chiave from public.specie where nome_scientifico !~ ''''
  union select col.chiave(nome_scientifico) from public.generi;
create table col.corrispondenze as
  select u.id, u.status, u.parent_id, n.chiave
    from col.nostri n
    join col.nome_uso u on col.chiave(u.nome) = n.chiave
    left join col.nome_uso p on p.id = u.parent_id and u.status in ('synonym', 'ambiguous synonym', 'misapplied')
   where coalesce(nullif(u.regno, ''), p.regno) = 'Plantae'
     and u.nome !~ '\sspp?\.?\s*$' and coalesce(p.nome, '') !~ '\sspp?\.?\s*$';
create index corrispondenze_chiave_idx on col.corrispondenze (chiave);
create table col.accettati as
  select distinct case when status in ('accepted', 'provisionally accepted') then id else parent_id end as id
    from col.corrispondenze;
create table col.catena as
  with recursive c(id) as (
    select id from col.accettati
    union
    select u.parent_id from col.nome_uso u join c on u.id = c.id where u.parent_id <> '')
  select id from c;
create table col.sinonimi as
  select u.id from col.nome_uso u
   where u.status in ('synonym', 'ambiguous synonym') and u.nome !~ '\sspp?\.?\s*$'
     and u.parent_id in (select id from col.accettati
                         union
                         select c.id from col.catena c join col.nome_uso g on g.id = c.id where g.rango = 'genus');
create table col.selezione (col_id text primary key, id uuid not null unique default gen_random_uuid());
insert into col.selezione (col_id)
  select id from col.catena union select id from col.corrispondenze union select id from col.sinonimi;
analyze col.selezione;

\pset tuples_only on
\pset format unaligned
select 'nomi ' || count(*) from col.nostri;
select 'nomi_trovati ' || count(distinct chiave) from col.corrispondenze;
select 'accettati ' || count(*) from col.selezione s join col.nome_uso u on u.id = s.col_id
 where u.status in ('accepted', 'provisionally accepted');
select 'sinonimi ' || count(*) from col.selezione s join col.nome_uso u on u.id = s.col_id
 where u.status not in ('accepted', 'provisionally accepted');
select 'selezione ' || count(*) from col.selezione;
