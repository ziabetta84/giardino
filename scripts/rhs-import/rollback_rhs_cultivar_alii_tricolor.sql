-- Rollback di 20261123140100_rhs_cultivar_alii_tricolor.sql: rimette le due cultivar sul taxon di prima.
do $$ declare n int; begin
  update public.cultivar set taxon_id = '85dc4d3b-8000-4bfd-a8f7-a668bca2095d'
   where id = '89f37725-bdd6-4994-b268-1d6153304c99' and taxon_id = 'cb492351-bb49-471b-a2e5-b41242737033';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'Ficus ''Alii'' non è su Ficus maclellandii: rollback rifiutato'; end if;
  update public.cultivar set taxon_id = '45a55020-f3fb-4d20-9e3c-b496779d05ca'
   where id = 'a28a632c-28f3-4d3e-a39d-37c0f52acd3c' and taxon_id = 'cf1ad0da-4e56-4558-b519-655907885fab';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'Dracaena ''Tricolor'' non è su Dracaena cincta: rollback rifiutato'; end if;
end $$;
