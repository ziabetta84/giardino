-- ATTESO: relation "taxa" already exists
-- Review Focus 5: una seconda applicazione deve fallire subito, senza lasciare nulla a metà
-- (in produzione psql -1 annulla l'intera migration). Transazione mai confermata.
begin;
\i supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql
\i supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql
select 'NON DOVEVA ARRIVARE QUI';
rollback;
