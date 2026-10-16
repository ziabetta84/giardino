-- Rollback della migration 20261017100000_tassonomia_fase4_colonne.sql: toglie cultivar.grex_id e schede.nota.
-- Si rifiuta se una delle due colonne contiene dati (prima rollback_fase4a.sql e, per le schede, quello della fase 4b).
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase4_colonne.sql
do $$
begin
  if exists (select 1 from public.cultivar where grex_id is not null) or exists (select 1 from public.schede where nota is not null) then
    raise exception 'Rollback colonne fase 4 rifiutato: cultivar.grex_id o schede.nota contengono dati';
  end if;
end $$;
alter table public.cultivar drop column grex_id;
alter table public.schede drop column nota;
