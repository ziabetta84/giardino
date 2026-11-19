-- Cancella l'archivio public.specie (non più letto dall'app dalla fase 6; chiuso ai client dal 21/10/2026)
-- per liberare spazio su Supabase, su richiesta di Roberta del 19/11/2026.
-- generi resta. Backup verificato prima: backups/archivio/specie_archivio_20261119_100000.dump.age
-- (specie 212.066 righe + generi; ripristino descritto in backups/archivio/LEGGIMI.txt).
drop table public.specie;
