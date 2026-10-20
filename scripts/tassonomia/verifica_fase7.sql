-- Verifica della fase 7 sul database reale (dopo la migration 20261021120000_tassonomia_fase7_piante_specie), senza
-- scritture: piante.specie non c'è più, ogni pianta che l'aveva ha il suo slug in piante_vecchie_specie, che i client
-- non leggono, e le funzioni del catalogo funzionano. Da lanciare insieme a verifica_fase6.sql. Le piante create dopo
-- la fase 7 non hanno uno slug salvato: sono solo contate.
-- Comando: psql "$URL" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/verifica_fase7.sql      Ultima riga VERIFICA FASE 7 OK.
begin read only;
do $$
declare n bigint;
begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'piante' and column_name = 'specie') then
    raise exception 'piante.specie c''è ancora';
  end if;
  select count(*) into n from public.piante p left join public.piante_vecchie_specie v on v.pianta_id = p.id where v.pianta_id is null;
  if n > 0 then raise notice 'piante senza slug salvato (create dopo la fase 7): %', n; end if;
  if (select count(*) from public.piante_vecchie_specie v left join public.specie s on s.slug = v.specie where s.slug is null) > 0 then
    raise exception 'slug salvati che non sono nell''archivio specie';
  end if;
  execute 'set local role anon';
  begin
    perform 1 from public.piante_vecchie_specie limit 1;
    raise exception 'piante_vecchie_specie leggibile con il ruolo pubblico';
  exception when insufficient_privilege then null;
  end;
  execute 'reset role';
  execute 'set local role authenticated';
  begin
    perform 1 from public.piante_vecchie_specie limit 1;
    raise exception 'piante_vecchie_specie leggibile con il ruolo authenticated';
  exception when insufficient_privilege then null;
  end;
  execute 'reset role';
  if not (select relrowsecurity from pg_class where oid = 'public.piante_vecchie_specie'::regclass) then raise exception 'RLS non attiva su piante_vecchie_specie'; end if;
  raise notice 'VERIFICA FASE 7 OK';
end $$;
rollback;
