-- Sposta due cultivar sulla specie a cui le attribuisce RHS (decisione di Roberta del 23/11/2026, insieme al lotto 3):
--   Ficus 'Alii': da Ficus binnendijkii a Ficus maclellandii;
--   Dracaena 'Tricolor': da Dracaena marginata (sinonimo ambiguo) a Dracaena cincta.
-- Da applicare dopo 20261123140000_rhs_schede_nuove_lotto3.sql. Rollback: scripts/rhs-import/rollback_rhs_cultivar_alii_tricolor.sql
do $$ declare n int; begin
  update public.cultivar set taxon_id = 'cb492351-bb49-471b-a2e5-b41242737033'
   where id = '89f37725-bdd6-4994-b268-1d6153304c99' and epiteto = 'Alii' and taxon_id = '85dc4d3b-8000-4bfd-a8f7-a668bca2095d';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'Ficus ''Alii'' non trovata sul taxon atteso'; end if;
  update public.cultivar set taxon_id = 'cf1ad0da-4e56-4558-b519-655907885fab'
   where id = 'a28a632c-28f3-4d3e-a39d-37c0f52acd3c' and epiteto = 'Tricolor' and taxon_id = '45a55020-f3fb-4d20-9e3c-b496779d05ca';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'Dracaena ''Tricolor'' non trovata sul taxon atteso'; end if;
end $$;
