-- Rollback della fase 5: scollega le piante (taxon_id e cultivar_id a null) e rimette l'epiteto 'Piccante Calabresé'.
-- Si rifiuta se una pianta è collegata diversamente da dati/fase5_piante.tsv (lavoro fatto dopo, per esempio dall'app
-- nella fase 6) o se ci sono piante nuove collegate: quel lavoro andrebbe perso.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase5.sql
set local statement_timeout = '1min';
create temp table fase5 (pianta text primary key, vecchio_slug text not null, taxon_id uuid, cultivar_id uuid,
                         destinazione text not null, motivo text not null);
\copy fase5 from 'scripts/tassonomia/dati/fase5_piante.tsv' with (format text, header true)
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'piante' and column_name = 'specie') then
    raise exception 'Rollback fase 5 rifiutato: piante.specie non c''è (fase 7 applicata), prima rollback_fase7.sql (poi rollback_fase6.sql)';
  end if;
  if exists (select 1 from public.piante p left join fase5 f on f.pianta = p.id
              where (p.taxon_id is not null or p.cultivar_id is not null)
                and (f.pianta is null or p.taxon_id is distinct from f.taxon_id or p.cultivar_id is distinct from f.cultivar_id)) then
    raise exception 'Rollback fase 5 rifiutato: alcune piante sono collegate diversamente dal file della fase 5';
  end if;
end $$;
update public.piante p set taxon_id = null, cultivar_id = null from fase5 f where f.pianta = p.id;
update public.cultivar set epiteto = 'Piccante Calabresé'
 where slug = 'capsicum-annuum-piccante-calabrese' and epiteto = 'Piccante Calabrese';
