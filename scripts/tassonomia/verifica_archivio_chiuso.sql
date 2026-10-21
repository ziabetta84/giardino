-- Verifica dell'archivio chiuso (migration 20261021140000_tassonomia_archivio_chiuso), in una transazione annullata:
-- anon e authenticated non leggono né scrivono specie e generi, nessuna policy, service_role ha solo SELECT, il
-- catalogo nuovo risponde ancora con il ruolo pubblico. Vale sul reale e sulla copia locale.
-- Comando: psql "$URL" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/verifica_archivio_chiuso.sql
-- Ultima riga VERIFICA ARCHIVIO CHIUSO OK = riuscita.
begin;
do $$
declare
  ruolo text; tab text; n bigint; v jsonb;
begin
  select count(*) into n from pg_policies where schemaname = 'public' and tablename in ('specie', 'generi');
  if n > 0 then raise exception 'policy ancora presenti su specie/generi: %', n; end if;
  for tab in select unnest(array['specie', 'generi']) loop
    if exists (select 1 from information_schema.role_table_grants where table_schema = 'public' and table_name = tab
                and grantee in ('anon', 'authenticated')) then
      raise exception '% ha ancora permessi per anon o authenticated', tab;
    end if;
    if (select string_agg(privilege_type, ',' order by privilege_type) from information_schema.role_table_grants
         where table_schema = 'public' and table_name = tab and grantee = 'service_role') is distinct from 'SELECT' then
      raise exception '%: service_role non ha solo SELECT', tab;
    end if;
    for ruolo in select unnest(array['anon', 'authenticated']) loop
      execute format('set local role %I', ruolo);
      begin
        execute format('select count(*) from public.%I', tab);
        raise exception '%: % legge ancora la tabella', ruolo, tab;
      exception when insufficient_privilege then null;
      end;
      begin
        execute format('update public.%I set nome = nome where false', tab);
        raise exception '%: % può ancora modificare la tabella', ruolo, tab;
      exception when insufficient_privilege then null;
      end;
      execute 'reset role';
    end loop;
  end loop;
  -- il catalogo nuovo non dipende dall'archivio
  execute 'set local role anon';
  v := public.cerca_catalogo('rosmarino');
  if not exists (select 1 from jsonb_array_elements(v) e where e ->> 'specie' = 'Salvia rosmarinus') then
    raise exception 'ricerca pubblica: Salvia rosmarinus non trovata';
  end if;
  execute 'reset role';
  select count(*) into n from public.specie;
  if n = 0 then raise exception 'archivio vuoto per postgres'; end if;
  raise notice 'VERIFICA ARCHIVIO CHIUSO OK';
end $$;
rollback;
