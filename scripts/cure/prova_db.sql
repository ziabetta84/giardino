-- Prove della colonna piante.ultimo_concime_id (vedi prova_db.sh). Ultima riga: PROVA CONCIME OK.
\set ON_ERROR_STOP 1
insert into auth.users values ('00000000-0000-0000-0000-00000000000a'), ('00000000-0000-0000-0000-00000000000b');
insert into public.concimi (id, owner_id, nome) values
  ('10000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a', 'di A'),
  ('10000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-00000000000b', 'di B');
insert into public.piante (id, owner_id) values ('pianta-a', '00000000-0000-0000-0000-00000000000a');

set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000a', false);

-- 1. il proprio concime si registra insieme alla data
update public.piante set ultima_cura = '{"concimazione":"2026-11-17"}', ultimo_concime_id = '10000000-0000-0000-0000-00000000000a' where id = 'pianta-a';
do $$ begin
  if (select ultimo_concime_id from public.piante where id = 'pianta-a') is distinct from '10000000-0000-0000-0000-00000000000a' then
    raise exception 'prova 1: concime non salvato';
  end if;
end $$;

-- 2. il concime di un altro utente è rifiutato
do $$ begin
  begin
    update public.piante set ultimo_concime_id = '10000000-0000-0000-0000-00000000000b' where id = 'pianta-a';
    raise exception 'prova 2: concime altrui accettato';
  exception when foreign_key_violation then null;
  end;
end $$;

-- 3. il trigger non è chiamabile dai client
do $$ begin
  if has_function_privilege('authenticated', 'public.piante_controlla_concime()', 'execute') then
    raise exception 'prova 3: funzione eseguibile da authenticated';
  end if;
end $$;

-- 4. togliere il concime dalla dispensa lascia la pianta, senza concime
delete from public.concimi where id = '10000000-0000-0000-0000-00000000000a';
do $$ begin
  if (select ultimo_concime_id from public.piante where id = 'pianta-a') is not null then
    raise exception 'prova 4: concime non azzerato';
  end if;
  if (select ultima_cura->>'concimazione' from public.piante where id = 'pianta-a') <> '2026-11-17' then
    raise exception 'prova 4: data persa';
  end if;
end $$;
reset role;

-- 5. il rollback si applica
\i scripts/cure/rollback_ultimo_concime.sql
do $$ begin
  if exists (select 1 from information_schema.columns where table_name = 'piante' and column_name = 'ultimo_concime_id') then
    raise exception 'prova 5: colonna ancora presente';
  end if;
end $$;
\echo PROVA CONCIME OK
