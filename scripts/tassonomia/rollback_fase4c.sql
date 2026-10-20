-- Rollback della fase 4c: toglie tutti i nomi comuni. Si rifiuta se un nome è stato aggiunto dopo il caricamento (un
-- creato_il diverso da quello delle righe caricate, che entrano tutte nella stessa transazione: fasi successive, app o
-- /zorbadice), perché quel lavoro andrebbe perso. Con più lotti, i creato_il distinti sono al più uno per lotto.
-- Non TRUNCATE, per coerenza con gli altri rollback.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -v lotti=N -f scripts/tassonomia/rollback_fase4c.sql   (N = righe del manifesto)
-- Poi, per restituire lo spazio: psql "$URL" -X -c 'vacuum full public.nomi_comuni'
select set_config('fase4c.lotti', :'lotti', false) \g /dev/null
set local statement_timeout = '10min';
do $$
begin
  if (select count(distinct creato_il) from public.nomi_comuni) > current_setting('fase4c.lotti')::int then
    raise exception 'Rollback fase 4c rifiutato: alcuni nomi sono stati aggiunti dopo il caricamento';
  end if;
end $$;
delete from public.nomi_comuni;
