-- Fase 1b: misure prima e dopo la manutenzione di specie. Sola lettura.
-- orfani_mb = spazio del database non attribuito a nessuna relazione: deve restare uguale prima e dopo. Se cresce,
-- una compattazione interrotta da un riavvio del server ha lasciato file orfani, che contano nel limite.
-- Con le variabili psql soglia_mb e soglia_wal_mb (sempre insieme) si ferma con un errore se la somma dei database
-- o il WAL le superano: la compattazione affianca per qualche minuto una seconda copia di specie (circa 120 MB) e
-- scrive circa 140 MB di WAL; oltre 500 MB il database va in sola lettura, e il disco di Supabase è di 1 GB.
\pset tuples_only on
\pset format unaligned
select 'somma_db_mb ' || round(sum(pg_database_size(datname)) / 1e6, 1) from pg_database;
select 'specie_mb ' || round(pg_total_relation_size('public.specie') / 1e6, 1);
select 'wal_mb ' || round(coalesce(sum(size), 0) / 1e6, 1) from pg_ls_waldir();
select 'orfani_mb ' || round((pg_database_size(current_database())
         - (select sum(pg_relation_size(c.oid, 'main') + pg_relation_size(c.oid, 'fsm')
                       + pg_relation_size(c.oid, 'vm') + pg_relation_size(c.oid, 'init'))
              from pg_class c
             where c.relkind in ('r', 'i', 't', 'm', 'S') and c.reltablespace = 0 and not c.relisshared)) / 1e6, 1);
\if :{?soglia_mb}
  \echo 'soglia_mb' :soglia_mb 'soglia_wal_mb' :soglia_wal_mb
  select (select sum(pg_database_size(datname)) from pg_database) > :soglia_mb::numeric * 1e6
      or (select coalesce(sum(size), 0) from pg_ls_waldir()) > :soglia_wal_mb::numeric * 1e6 as spazio_insufficiente \gset
  \if :spazio_insufficiente
    do $$ begin raise exception 'spazio insufficiente per la compattazione'; end $$;
  \endif
\endif
