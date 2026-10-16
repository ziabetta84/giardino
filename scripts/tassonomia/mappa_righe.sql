-- Fase 3: righe da abbinare = righe non cultivar di specie + madri recuperate dai rollback.
-- Lo standard input è il TSV delle madri recuperate (psql ... -f mappa_righe.sql < rollback_madri.tsv).
set statement_timeout = 0;
drop table if exists col.mappa_righe, col.mappa_rollback;
create table col.mappa_rollback (id uuid primary key, slug text not null, nome_scientifico text not null, famiglia_botanica text);
\copy col.mappa_rollback from pstdin with (format csv, delimiter E'\t', header)
create table col.mappa_righe as
  select id, slug, nome_scientifico, famiglia_botanica, 'specie'::text as origine
    from public.specie where nome_scientifico !~ '''' and specie_padre_id is null
  union all
  select id, slug, nome_scientifico, famiglia_botanica, 'rollback' from col.mappa_rollback;
alter table col.mappa_righe add primary key (id);
alter table col.mappa_righe add column chiave text, add column nome text, add column rango_atteso text;
update col.mappa_righe set
  nome = btrim(regexp_replace(nome_scientifico, '\s+', ' ', 'g')),
  chiave = col.chiave(nome_scientifico),
  rango_atteso = case
    when nome_scientifico ~ '\s(subsp|ssp)\.\s' then 'subspecies'
    when nome_scientifico ~ '\svar\.\s' then 'variety'
    when nome_scientifico ~ '\sf\.\s' then 'form'
    when col.chiave(nome_scientifico) !~ ' ' then 'genus'
    when col.chiave(nome_scientifico) ~ '^[A-Z][^ ]* [a-z][^ ]*$' then 'species'
    else 'altro' end;
create index on col.mappa_righe (chiave);
analyze col.mappa_righe;
\pset tuples_only on
\pset format unaligned
select 'righe ' || count(*) || ' (specie ' || count(*) filter (where origine = 'specie') || ', rollback ' || count(*) filter (where origine = 'rollback') || ')' from col.mappa_righe;
select 'con corrispondenza esatta ' || count(*) from col.mappa_righe r where exists (select 1 from col.corrispondenze c where c.chiave = r.chiave);
