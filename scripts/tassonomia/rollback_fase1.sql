-- Rollback della fase 1 del modello tassonomico: rimuove le tabelle nuove e le colonne aggiunte a piante.
-- Si rifiuta se le tabelle nuove contengono dati: dalla fase 2 in poi va prima eseguito il rollback della fase corrispondente.
-- Controllo e cancellazione sono un'unica istruzione: se il controllo o una cancellazione falliscono non cambia nulla,
-- anche se il file viene lanciato senza -1 o senza ON_ERROR_STOP.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase1.sql
do $$
begin
  lock table public.piante, public.mappa_specie, public.schede, public.cultivar, public.nomi_comuni, public.taxa in access exclusive mode;
  if exists (select 1 from public.taxa) or exists (select 1 from public.nomi_comuni) or exists (select 1 from public.cultivar)
     or exists (select 1 from public.schede) or exists (select 1 from public.mappa_specie)
     or exists (select 1 from public.piante where taxon_id is not null or cultivar_id is not null) then
    raise exception 'Rollback fase 1 rifiutato: le tabelle nuove contengono dati';
  end if;

  alter table public.piante
    drop constraint piante_taxon_o_cultivar,
    drop column cultivar_id,
    drop column taxon_id;
  drop table public.mappa_specie, public.schede, public.cultivar, public.nomi_comuni, public.taxa;
end $$;
