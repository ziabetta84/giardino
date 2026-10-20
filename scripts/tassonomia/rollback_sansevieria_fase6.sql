-- Rollback di sansevieria_fase6.sql: la pianta torna sul genere Sansevieria e la scheda di Dracaena trifasciata riprende
-- manutenzione e vaso vuoti come nel caricamento della fase 4b (gli scheletri di PFAF), il suo solo avviso e la sua
-- sola fonte. Rifiutato se la scheda non è più come l'ha lasciata lo script.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_sansevieria_fase6.sql
do $$
declare
  a public.schede%rowtype;
begin
  select * into strict a from public.schede where id = '22df7855-bd6d-426b-b677-747348deac0b';
  if a.nota is distinct from 'manutenzione, vaso e avvisi dalla scheda 6a3e2ad5-8685-49e4-ba98-307ba7000920 (Sansevieria), scelta dell''utente del 20/10/2026'
     or a.manutenzione is distinct from (select manutenzione from public.schede where id = '6a3e2ad5-8685-49e4-ba98-307ba7000920') then
    raise exception 'Rollback Sansevieria rifiutato: la scheda di Dracaena trifasciata è cambiata dopo lo script';
  end if;
  update public.schede set
    manutenzione = '{"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}',
    vaso = '{"adatta": null, "rinvaso_ogni_mesi": null, "irrigazione_fattore": null, "dimensione_minima_litri": null}',
    alert = alert[1:1], fonti = fonti[1:1], nota = null, aggiornata_il = now()
   where id = a.id;
  update public.piante set taxon_id = (select id from public.taxa where nome_scientifico = 'Sansevieria' and rango = 'genus')
   where id = 'sansevieria-1777363126334'
     and taxon_id = (select id from public.taxa where nome_scientifico = 'Sansevieria trifasciata' and rango = 'species');
end $$;
