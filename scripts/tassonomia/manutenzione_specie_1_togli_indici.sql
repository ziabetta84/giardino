-- Fase 1b, passo 1: toglie i 4 indici trigram di specie, così il picco di spazio della compattazione resta
-- sotto 500 MB (circa 465 invece di 537). Si esegue con psql -1; il passo 3 li ricrea.
-- lock_timeout di 2 s: mentre aspetta il blocco, le letture dell'app si mettono in coda dietro questa richiesta, e
-- per la chiave pubblica scadono dopo 3 s; se l'app sta leggendo specie, ci si ritira prima.
set local lock_timeout = '2s';
drop index public.specie_nome_trgm_idx;
drop index public.specie_nome_scientifico_trgm_idx;
drop index public.specie_nomi_alternativi_trgm_idx;
drop index public.specie_sinonimi_botanici_trgm_idx;
