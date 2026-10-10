-- Indici trigram per la ricerca del selettore specie (ilike '%testo%' su 212k righe andava in timeout per `anon`, limite 3 s).
-- Rollback: scripts/nomi-italiani/rollback_indici_ricerca.sql
create extension if not exists pg_trgm with schema extensions;

create index if not exists specie_nome_trgm_idx on public.specie using gin (nome extensions.gin_trgm_ops);
create index if not exists specie_nome_scientifico_trgm_idx on public.specie using gin (nome_scientifico extensions.gin_trgm_ops);
create index if not exists specie_nomi_alternativi_trgm_idx on public.specie using gin (nomi_alternativi extensions.gin_trgm_ops);
create index if not exists specie_sinonimi_botanici_trgm_idx on public.specie using gin (sinonimi_botanici extensions.gin_trgm_ops);
