-- Aggiunge la colonna "icona" a zone e sottozone: selezionabile in
-- creazione/modifica dal set di icone "acquerellate" dedicate (i-zona-*
-- in IconDefs.vue), tutte nello stesso azzurro dell'icona "Zone" nel
-- menu. Nullable, nessun backfill: le zone/sottozone esistenti restano
-- senza icona e mostrano il fallback generico "pin" in UI.
alter table zone add column icona text;
alter table sottozone add column icona text;
