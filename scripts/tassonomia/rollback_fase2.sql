-- Rollback della fase 2: toglie da taxa le righe di COL. Si rifiuta se taxa è già usata (fasi 3-6) o se contiene
-- taxon locali. Non TRUNCATE: piante ha una chiave esterna verso taxa e TRUNCATE ... CASCADE svuoterebbe piante.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase2.sql
-- Poi, per restituire lo spazio: psql "$URL" -X -c 'vacuum full public.taxa'
set local statement_timeout = '10min';
do $$
begin
  if exists (select 1 from public.nomi_comuni) or exists (select 1 from public.cultivar)
     or exists (select 1 from public.schede) or exists (select 1 from public.mappa_specie where taxon_id is not null)
     or exists (select 1 from public.piante where taxon_id is not null)
     or exists (select 1 from public.taxa where origine = 'locale') then
    raise exception 'Rollback fase 2 rifiutato: taxa è già usata da altre tabelle o contiene taxon locali';
  end if;
end $$;
delete from public.taxa where origine = 'col';
