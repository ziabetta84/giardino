-- Fase 6, scelta dell'utente del 20/10/2026: la sua sansevieria è una Sansevieria trifasciata (sinonimo di Dracaena
-- trifasciata in COL), non un generico genere Sansevieria. La pianta passa dal genere Sansevieria al taxon Sansevieria
-- trifasciata (l'app mostra Dracaena trifasciata, «Già nota come Sansevieria trifasciata»), e la scheda mostrata di
-- Dracaena trifasciata riceve dalla vecchia scheda Sansevieria (non mostrata, sul genere Dracaena, con le fonti di
-- Sansevieria trifasciata) i campi che oggi sono vuoti, manutenzione e vaso, più gli avvisi che non ha (in coda, senza
-- doppioni). Le esigenze già presenti restano. Dopo questo script rollback_fase5.sql si rifiuta per questa pianta
-- (collegata diversamente dal file della fase 5): prima va eseguito rollback_sansevieria_fase6.sql.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/sansevieria_fase6.sql
set local statement_timeout = '1min';
do $$
declare
  pianta constant text := 'sansevieria-1777363126334';
  genere uuid := (select id from public.taxa where nome_scientifico = 'Sansevieria' and rango = 'genus');
  trifasciata uuid := (select id from public.taxa where nome_scientifico = 'Sansevieria trifasciata' and rango = 'species');
  dest uuid := (select id from public.taxa where nome_scientifico = 'Dracaena trifasciata' and stato = 'accepted');
  da public.schede%rowtype; a public.schede%rowtype;
begin
  if genere is null or trifasciata is null or dest is null then raise exception 'Sansevieria rifiutato: taxon non trovati'; end if;
  if (select taxon_id from public.piante where id = pianta) is distinct from genere then
    if (select taxon_id from public.piante where id = pianta) = trifasciata then raise notice 'pianta già collegata'; return; end if;
    raise exception 'Sansevieria rifiutato: la pianta non è collegata al genere Sansevieria';
  end if;
  select * into strict da from public.schede where id = '6a3e2ad5-8685-49e4-ba98-307ba7000920' and not mostrata;
  select * into strict a from public.schede where id = '22df7855-bd6d-426b-b677-747348deac0b' and mostrata and taxon_id = dest;
  if not (catalogo.vuoto(a.manutenzione) and catalogo.vuoto(a.vaso)) or cardinality(a.alert) <> 1 or a.nota is not null then
    raise exception 'Sansevieria rifiutato: la scheda di Dracaena trifasciata è cambiata dopo la revisione';
  end if;
  update public.piante set taxon_id = trifasciata where id = pianta;
  update public.schede s set manutenzione = da.manutenzione, vaso = da.vaso,
         alert = a.alert || array(select x from unnest(da.alert) with ordinality u(x, o) where not x = any(a.alert)
                                   group by x order by min(o)),
         fonti = a.fonti || da.fonti,
         nota = 'manutenzione, vaso e avvisi dalla scheda ' || da.id || ' (Sansevieria), scelta dell''utente del 20/10/2026',
         aggiornata_il = now()
   where s.id = a.id;
  raise notice 'SANSEVIERIA COLLEGATA';
end $$;
