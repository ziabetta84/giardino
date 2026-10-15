-- Fase 1b: controllo dopo la manutenzione di public.specie. Sola lettura.
-- Errore se mancano indici, se un indice non è valido o se la tabella non è compattata
-- (attesi circa 153 MB dopo la compattazione, 351 MB prima: docs/ricerche/2026-10-14-stima-spazio.md).
do $$
declare
  n_indici int;
  n_validi int;
  n_trgm int;
  dim bigint;
  somma bigint;
begin
  select count(*), count(*) filter (where indisvalid and indisready)
    into n_indici, n_validi
    from pg_index where indrelid = 'public.specie'::regclass;
  if n_indici <> 9 or n_validi <> 9 then
    raise exception 'indici di specie: % presenti, % validi (attesi 9 e 9)', n_indici, n_validi;
  end if;
  select count(*) into n_trgm from pg_indexes
   where schemaname = 'public' and tablename = 'specie'
     and indexname in ('specie_nome_trgm_idx', 'specie_nome_scientifico_trgm_idx',
                       'specie_nomi_alternativi_trgm_idx', 'specie_sinonimi_botanici_trgm_idx');
  if n_trgm <> 4 then
    raise exception 'indici trigram di specie: % su 4', n_trgm;
  end if;
  dim := pg_total_relation_size('public.specie');
  if dim > 175000000 then
    raise exception 'specie ancora da compattare: % MB (attesi circa 153)', round(dim / 1e6);
  end if;
  select sum(pg_database_size(datname)) into somma from pg_database;
  raise notice 'specie % MB, somma dei database % MB', round(dim / 1e6, 1), round(somma / 1e6, 1);
end $$;
