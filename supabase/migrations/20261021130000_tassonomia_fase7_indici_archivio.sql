-- Fase 7 del modello tassonomico: l'app non cerca più nell'archivio specie, quindi si tolgono i suoi 4 indici trigram
-- (circa 31 MB, approvato dall'utente il 20/10/2026). I dati non cambiano. Rollback, se un giorno servisse cercare di
-- nuovo nell'archivio (circa 10 s):
--   psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/manutenzione_specie_3_ricrea_indici.sql
drop index if exists public.specie_nome_trgm_idx;
drop index if exists public.specie_nome_scientifico_trgm_idx;
drop index if exists public.specie_nomi_alternativi_trgm_idx;
drop index if exists public.specie_sinonimi_botanici_trgm_idx;
