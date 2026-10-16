-- Rollback della fase 3: svuota mappa_specie e toglie da taxa i taxon locali e i taxon di COL aggiunti nella fase 3
-- (riconoscibili dalla nota). I taxon della fase 2 restano. Si rifiuta se le tabelle della fase 4 contengono dati o se
-- una pianta punta già a un taxon (fase 5). Non TRUNCATE: piante ha una chiave esterna verso taxa.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase3.sql
-- Poi, per restituire lo spazio: psql "$URL" -X -c 'vacuum full public.mappa_specie' -c 'vacuum full public.taxa'
set local statement_timeout = '10min';
do $$
begin
  if exists (select 1 from public.nomi_comuni) or exists (select 1 from public.cultivar) or exists (select 1 from public.schede)
     or exists (select 1 from public.piante where taxon_id is not null or cultivar_id is not null) then
    raise exception 'Rollback fase 3 rifiutato: le tabelle delle fasi 4-5 contengono già dati';
  end if;
end $$;
-- gli indici sulle chiavi esterne di taxa verso se stessa servono alla DELETE (vedi rollback_fase2.sql)
create index if not exists taxa_padre_id_idx on public.taxa (padre_id);
create index if not exists taxa_accettato_id_idx on public.taxa (accettato_id);
delete from public.mappa_specie;
delete from public.taxa where origine = 'locale' and nota = 'notogenere assente da COL (fase 3)';
delete from public.taxa where origine = 'col' and nota = 'importato nella fase 3 (abbinamento)';
