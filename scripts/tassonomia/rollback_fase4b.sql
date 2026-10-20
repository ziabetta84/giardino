-- Rollback della fase 4b: toglie tutte le schede. Si rifiuta se una scheda è stata modificata dopo il caricamento
-- (aggiornata_il oltre creata_il, per esempio una revisione fatta dall'app o da /zorbadice): quel lavoro andrebbe perso.
-- Non TRUNCATE, per coerenza con gli altri rollback.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase4b.sql
-- Poi, per restituire lo spazio: psql "$URL" -X -c 'vacuum full public.schede'
set local statement_timeout = '10min';
do $$
begin
  if exists (select 1 from public.schede where aggiornata_il > creata_il + interval '1 second') then
    raise exception 'Rollback fase 4b rifiutato: alcune schede sono state modificate dopo il caricamento';
  end if;
end $$;
delete from public.schede;
