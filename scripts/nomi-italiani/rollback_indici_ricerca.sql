-- Rollback degli indici di ricerca (l'estensione pg_trgm resta installata).
drop index if exists public.specie_nome_trgm_idx;
drop index if exists public.specie_nome_scientifico_trgm_idx;
drop index if exists public.specie_nomi_alternativi_trgm_idx;
drop index if exists public.specie_sinonimi_botanici_trgm_idx;
