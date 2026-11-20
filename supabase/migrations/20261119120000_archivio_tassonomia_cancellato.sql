-- Cancella gli ultimi resti dell'archivio del vecchio catalogo, su richiesta di Roberta del 19/11/2026
-- («togliamo tutte e tre le tabelle… così manteniamo il db aggiornato e pulito»).
-- Nessuna parte dell'app, di Zorba o delle funzioni del database le legge; servivano solo agli
-- script e ai rollback delle fasi della tassonomia, che senza public.specie non funzionano più.
--   piante_vecchie_specie: slug delle piante prima della fase 7 (solo per rollback_fase7.sql)
--   mappa_specie: righe della vecchia specie → taxon/cultivar (fasi 3-4)
--   generi: archivio dei generi (già nel backup di specie)
-- Backup verificato prima: backups/archivio/tassonomia_archivio_20261119_*.dump.age
-- (pg_dump in formato custom delle tre tabelle, cifrato con age; ripristino con
--  age -d -i ~/.config/giardino/backup-age.key FILE | pg_restore -d "$SUPABASE_DB_URL").
drop table public.piante_vecchie_specie;
drop table public.mappa_specie;
drop table public.generi;
