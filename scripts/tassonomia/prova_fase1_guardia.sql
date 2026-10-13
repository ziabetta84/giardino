-- ATTESO: Rollback fase 1 rifiutato: le tabelle nuove contengono dati
-- Review Focus 4: con dati nelle tabelle nuove il rollback deve fermarsi. La transazione non viene mai confermata:
-- l'errore chiude psql (ON_ERROR_STOP) e la connessione annulla tutto.
begin;
\i supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql
insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'genus', 'Prova guardia', 'accepted');
-- come in autocommit: i controlli differiti delle FK vengono eseguiti subito, così il rollback non fallisce per altri motivi
set constraints all immediate;
\i scripts/tassonomia/rollback_fase1.sql
select 'NON DOVEVA ARRIVARE QUI';
rollback;
