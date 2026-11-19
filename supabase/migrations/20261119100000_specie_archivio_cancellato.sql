-- Toglie dal database l'archivio public.specie (19/11/2026, richiesta di Roberta: liberare spazio sul piano gratuito).
--
-- Dalla fase 6 del modello tassonomico l'app legge solo taxa, nomi_comuni, cultivar e schede; dalla fase 7
-- l'archivio era chiuso ai client (20261021140000_tassonomia_archivio_chiuso.sql). Nessuna tabella, vista o
-- funzione dipende da specie (controllato il 19/11/2026: solo la chiave verso se stessa e quella verso generi).
-- 212.066 righe, circa 116 MB. public.generi resta.
--
-- Copia prima della cancellazione, sul Mac di Roberta, fuori rotazione e cifrata:
--   backups/archivio/specie_archivio_20261119_100000.dump.age (15 MB; voce in backups/archivio/LEGGIMI.txt)  (pg_dump -Fc di public.specie e public.generi)
-- Ripristino:
--   age -d -i ~/.config/giardino/backup-age.key FILE.dump.age > /tmp/specie.dump
--   pg_restore -d "$SUPABASE_DB_URL" --no-owner -t specie /tmp/specie.dump
--   poi rieseguire le righe revoke/grant di 20261021140000_tassonomia_archivio_chiuso.sql.
-- Gli script storici di scripts/tassonomia/ e scripts/nomi-italiani/ che leggono specie funzionano solo
-- dopo un ripristino (o su una copia locale presa da un backup precedente).

drop table public.specie;
