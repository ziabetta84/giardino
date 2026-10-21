-- Rollback di 20261021140000_tassonomia_archivio_chiuso.sql: rimette permessi e policy di prima (lettura pubblica,
-- tutti i privilegi di tabella ad anon, authenticated e service_role, fermati dall'RLS).
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_archivio_chiuso.sql
grant all on public.specie, public.generi to anon, authenticated, service_role;
create policy "specie: lettura pubblica" on public.specie for select using (true);
create policy "generi: lettura pubblica" on public.generi for select using (true);
