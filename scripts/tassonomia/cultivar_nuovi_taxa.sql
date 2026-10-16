-- Fase 4a: taxon di COL da aggiungere a public.taxa per le cultivar (copia locale): le specie scritte nel nome di
-- cultivar agganciate per errore a una riga "Genere spp." che mancano da taxa (taxon_col_id di col.cultivar_proposte e
-- col.cultivar_mappa), i loro accettati, la catena dei padri fino a un taxon già presente e i sinonimi degli accettati e
-- dei generi nuovi: stesse regole della fase 2 e di mappa_nuovi_taxa.sql, niente segnaposto "Genere spp".
set statement_timeout = 0;
drop table if exists col.cultivar_nuovi;
create temp table semi as
select distinct x.id from (select taxon_col_id as id from col.cultivar_proposte union select taxon_col_id from col.cultivar_mappa) x
 where x.id is not null and not exists (select 1 from public.taxa t where t.col_id = x.id);
create temp table acc as
select distinct case when u.status in ('accepted', 'provisionally accepted') then u.id else u.parent_id end as id
  from semi s join col.nome_uso u on u.id = s.id;
create temp table catena as
with recursive c(id) as (
  select id from acc
  union
  select u.parent_id from col.nome_uso u join c on u.id = c.id
   where u.parent_id <> '' and not exists (select 1 from public.taxa t where t.col_id = u.id))
select id from c;
create temp table sin as
select u.id from col.nome_uso u
 where u.status in ('synonym', 'ambiguous synonym') and u.nome !~ '\sspp?\.?\s*$'
   and u.parent_id in (select id from acc
                       union select c.id from catena c join col.nome_uso g on g.id = c.id where g.rango = 'genus');
create table col.cultivar_nuovi (col_id text primary key, id uuid not null unique default gen_random_uuid());
insert into col.cultivar_nuovi (col_id)
  select id from semi union select id from catena union select id from sin
  except select col_id from public.taxa where col_id is not null;
do $$
declare n bigint;
begin
  -- chiusura: il padre di ogni nuovo accettato e l'accettato di ogni nuovo sinonimo sono in taxa o tra i nuovi
  select count(*) into n from col.cultivar_nuovi m join col.nome_uso u on u.id = m.col_id
   where u.parent_id <> '' and not exists (select 1 from col.cultivar_nuovi x where x.col_id = u.parent_id)
     and not exists (select 1 from public.taxa t where t.col_id = u.parent_id);
  if n > 0 then raise exception 'nuovi taxon con il padre o l''accettato mancante: %', n; end if;
end $$;
\pset tuples_only on
\pset format unaligned
select 'specie cercate ' || (select count(*) from semi) || ', nuovi taxon COL ' || count(*) from col.cultivar_nuovi;
