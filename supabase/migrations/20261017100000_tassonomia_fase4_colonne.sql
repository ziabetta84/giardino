-- Modello tassonomico, fase 4: due colonne nuove sulle tabelle della fase 1, ancora vuote
-- (specifica docs/superpowers/specs/2026-10-13-modello-tassonomico-design.md, "Decisioni per la fase 4", punti 5 e 13).
-- - cultivar.grex_id: il grex di una cultivar di orchidea (ICNCP art. 6.5: l'epiteto va associato al grex), leggibile
--   dai client come le altre colonne pubbliche di cultivar;
-- - schede.nota: note di lavorazione interne, non leggibile dai client (come le note di taxa, nomi_comuni e mappa_specie).
-- La chiave esterna è differita come quelle di taxa: dentro un lotto l'ordine delle righe non conta.
-- Rollback: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase4_colonne.sql
alter table public.cultivar add column grex_id uuid,
  add constraint cultivar_grex_fk foreign key (grex_id) references public.cultivar (id) on delete restrict deferrable initially deferred,
  add constraint cultivar_grex_non_se_stesso check (grex_id <> id);
create index cultivar_grex_id_idx on public.cultivar (grex_id) where grex_id is not null;
grant select (grex_id) on public.cultivar to anon, authenticated;

alter table public.schede add column nota text;
