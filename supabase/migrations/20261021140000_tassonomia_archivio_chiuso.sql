-- Archivio del vecchio catalogo chiuso ai client (dopo la fase 7 del modello tassonomico): l'app legge solo il catalogo
-- nuovo, quindi anon e authenticated non hanno più nessun permesso su specie e generi (oggi avevano tutto, TRUNCATE
-- compreso, e con la policy di lettura pubblica la colonna fonti era leggibile con la chiave pubblica); service_role
-- tiene solo la lettura. postgres (migration, script, /zorbadice via MCP) non cambia. I dati non cambiano.
-- Rollback: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_archivio_chiuso.sql
revoke all on public.specie, public.generi from anon, authenticated, service_role;
grant select on public.specie, public.generi to service_role;
drop policy "specie: lettura pubblica" on public.specie;
drop policy "generi: lettura pubblica" on public.generi;
