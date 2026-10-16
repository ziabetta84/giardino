-- Fase 3: taxon da aggiungere a public.taxa per le proposte decise (copia locale). Dai nomi proposti che non sono ancora
-- in taxa: i loro accettati, la catena dei padri fino a un taxon già presente, i sinonimi degli accettati e dei generi
-- nuovi (stesse regole della fase 2, niente segnaposto "Genere spp"). Poi i taxon locali (notogeneri assenti da COL)
-- sotto la famiglia della riga, che deve essere un taxon accettato già in taxa.
set statement_timeout = 0;
drop table if exists col.mappa_nuovi, col.mappa_locali;
create temp table semi as
select distinct p.col_id as id from col.mappa_proposte p
 where p.col_id is not null and not exists (select 1 from public.taxa t where t.col_id = p.col_id);
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
create table col.mappa_nuovi (col_id text primary key, id uuid not null unique default gen_random_uuid());
insert into col.mappa_nuovi (col_id)
  select id from semi union select id from catena union select id from sin
  except select col_id from public.taxa where col_id is not null;

create table col.mappa_locali (nome text primary key, id uuid not null unique default gen_random_uuid(), padre_id uuid);
insert into col.mappa_locali (nome, padre_id)
  select p.taxon_locale, (select min(f.id::text)::uuid from public.taxa f
                           where f.nome_scientifico = min(p.famiglia_locale) and f.rango = 'family' and f.stato = 'accepted')
    from col.mappa_proposte p where p.taxon_locale is not null group by p.taxon_locale;
do $$
declare n bigint;
begin
  select count(*) into n from col.mappa_locali where padre_id is null;
  if n > 0 then raise exception 'taxon locali senza una famiglia accettata in taxa: %', n; end if;
  -- chiusura: il padre di ogni nuovo accettato e l'accettato di ogni nuovo sinonimo sono in taxa o tra i nuovi
  select count(*) into n from col.mappa_nuovi m join col.nome_uso u on u.id = m.col_id
   where u.parent_id <> '' and not exists (select 1 from col.mappa_nuovi x where x.col_id = u.parent_id)
     and not exists (select 1 from public.taxa t where t.col_id = u.parent_id);
  if n > 0 then raise exception 'nuovi taxon con il padre o l''accettato mancante: %', n; end if;
end $$;
\pset tuples_only on
\pset format unaligned
select 'nuovi taxon COL ' || count(*) from col.mappa_nuovi;
select 'taxon locali ' || count(*) from col.mappa_locali;
