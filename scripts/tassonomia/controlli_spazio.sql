-- Misure di spazio per i caricamenti del modello tassonomico (fasi 2-4). Sola lettura.
-- Con le variabili psql soglia_mb e soglia_wal_mb (sempre insieme) si ferma con un errore se la somma dei database
-- o il WAL le superano: oltre 500 MB il database va in sola lettura e il disco di Supabase è di 1 GB (specifica,
-- "Decisioni sullo spazio").
\pset tuples_only on
\pset format unaligned
select 'somma_db_mb ' || round(sum(pg_database_size(datname)) / 1e6, 1) from pg_database;
select 'wal_mb ' || round(coalesce(sum(size), 0) / 1e6, 1) from pg_ls_waldir();
select 'taxa_mb ' || round(pg_total_relation_size('public.taxa') / 1e6, 1);
\if :{?soglia_mb}
  \echo 'soglia_mb' :soglia_mb 'soglia_wal_mb' :soglia_wal_mb
  select (select sum(pg_database_size(datname)) from pg_database) > :soglia_mb::numeric * 1e6
      or (select coalesce(sum(size), 0) from pg_ls_waldir()) > :soglia_wal_mb::numeric * 1e6 as spazio_insufficiente \gset
  \if :spazio_insufficiente
    do $$ begin raise exception 'spazio insufficiente per caricare'; end $$;
  \endif
\endif
