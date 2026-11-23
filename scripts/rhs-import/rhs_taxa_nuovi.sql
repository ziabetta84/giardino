-- Taxon di COL da aggiungere a public.taxa per le pagine RHS senza taxon (controllo del 18/11/2026, abbinamento a COL
-- del 23/11/2026, scripts/rhs-import/dati/col_abbinamenti_rhs_assenti.tsv). Copia locale con lo schema col (COL26.9 XR
-- completo, col_carica_locale.sh) e public.taxa identica al reale (stesse chiavi: impronta controllata).
-- Semi: i nomi trovati con esito accettato o sinonimo il cui accettato non è ancora in taxa (col.rhs_semi, caricata da
-- rhs_taxa_nuovi.sh). Poi le stesse regole della fase 2 e di mappa_nuovi_taxa.sql: i loro accettati, la catena dei padri
-- fino a un taxon già presente, i sinonimi degli accettati e dei generi nuovi; niente segnaposto "Genere spp" (un nome
-- che in COL porta solo a un segnaposto resta fuori, come nella fase 2); i misapplied non entrano (l'abbinamento li ha
-- esclusi e i titoli RHS «misapplied» non sono tra i semi).
set statement_timeout = 0;
drop table if exists col.rhs_nuovi;
create temp table semi as
select distinct s.col_id as id from col.rhs_semi s
  join col.nome_uso u on u.id = s.col_id
  join col.nome_uso a on a.id = case when u.status in ('accepted', 'provisionally accepted') then u.id else u.parent_id end
 where u.status <> 'misapplied' and a.nome !~ '\sspp?\.?\s*$' and u.nome !~ '\sspp?\.?\s*$'
   and not exists (select 1 from public.taxa t where t.col_id = a.id);
create temp table acc as
select distinct case when u.status in ('accepted', 'provisionally accepted') then u.id else u.parent_id end as id
  from semi s join col.nome_uso u on u.id = s.id;
create temp table catena as
with recursive c(id) as (
  select id from acc
  union
  select u.parent_id from col.nome_uso u join c on u.id = c.id
   where u.parent_id <> '' and not exists (select 1 from public.taxa t where t.col_id = u.parent_id))
select id from c;
create temp table sin as
select u.id from col.nome_uso u
 where u.status in ('synonym', 'ambiguous synonym') and u.nome !~ '\sspp?\.?\s*$'
   and u.parent_id in (select id from catena c
                        where exists (select 1 from col.nome_uso g where g.id = c.id and (c.id in (select id from acc) or g.rango = 'genus')));
create table col.rhs_nuovi (col_id text primary key, id uuid not null unique default gen_random_uuid(), origine text not null);
insert into col.rhs_nuovi (col_id, origine)
  select id, min(o) from (select id, '1 accettato' o from acc
                          union all select id, '2 padre' from catena where id not in (select id from acc)
                          union all select id, '3 sinonimo' from sin union all select id, '3 sinonimo' from semi) x
   where not exists (select 1 from public.taxa t where t.col_id = x.id)
   group by id;
do $$
declare n bigint;
begin
  -- chiusura: il padre di ogni nuovo accettato e l'accettato di ogni nuovo sinonimo sono in taxa o tra i nuovi
  select count(*) into n from col.rhs_nuovi m join col.nome_uso u on u.id = m.col_id
   where u.parent_id <> '' and not exists (select 1 from col.rhs_nuovi x where x.col_id = u.parent_id)
     and not exists (select 1 from public.taxa t where t.col_id = u.parent_id);
  if n > 0 then raise exception 'nuovi taxon con il padre o l''accettato mancante: %', n; end if;
  -- solo Plantae: ogni catena risale a un taxon già in taxa (che è tutto sotto Plantae o nella catena fino a Eukaryota)
  select count(*) into n from col.rhs_nuovi m join col.nome_uso u on u.id = m.col_id where u.rango = 'kingdom';
  if n > 0 then raise exception 'regni nuovi: %', n; end if;
end $$;
\pset tuples_only on
\pset format unaligned
select 'semi ' || (select count(*) from semi) || ', accettati dei semi ' || (select count(*) from acc);
select origine || ' ' || count(*) from col.rhs_nuovi group by origine order by origine;
select 'nuovi taxon COL ' || count(*) from col.rhs_nuovi;
