-- Fase 1b, passo 3: ricrea i 4 indici trigram di specie, identici a
-- supabase/migrations/20261010100000_specie_indici_ricerca.sql. Si esegue con psql -1.
-- È anche il ripristino se la manutenzione si è interrotta dopo il passo 1: si può rieseguire senza danni.
-- Nessun lock_timeout: se una compattazione rimasta attiva sul server tiene ancora specie, si aspetta che finisca.
set local statement_timeout = 0;
create index if not exists specie_nome_trgm_idx on public.specie using gin (nome extensions.gin_trgm_ops);
create index if not exists specie_nome_scientifico_trgm_idx on public.specie using gin (nome_scientifico extensions.gin_trgm_ops);
create index if not exists specie_nomi_alternativi_trgm_idx on public.specie using gin (nomi_alternativi extensions.gin_trgm_ops);
create index if not exists specie_sinonimi_botanici_trgm_idx on public.specie using gin (sinonimi_botanici extensions.gin_trgm_ops);
