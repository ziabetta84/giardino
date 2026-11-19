-- Prove dei controlli sul proprietario (vedi prova_db.sh). Ultima riga: PROVA PROPRIETARIO OK.
\set ON_ERROR_STOP 1
insert into auth.users values ('00000000-0000-0000-0000-00000000000a'), ('00000000-0000-0000-0000-00000000000b');
insert into public.zone (id, owner_id, nome) values
  ('20000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a', 'zona di A'),
  ('20000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-00000000000b', 'zona di B');
insert into public.sottozone (id, owner_id, zona_id, nome) values
  ('30000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a', '20000000-0000-0000-0000-00000000000a', 'sz di A'),
  ('30000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-00000000000b', '20000000-0000-0000-0000-00000000000b', 'sz di B');
insert into public.progetti (id, owner_id, nome) values
  ('40000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a', 'progetto di A'),
  ('40000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-00000000000b', 'progetto di B');

set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000a', false);

-- 1. tutto ciò che è proprio si collega come prima
insert into public.piante (id, zona_id, sottozona_id) values ('pianta-a', '20000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-00000000000a');
insert into public.piante (id, zona_id) values ('pianta-a2', '20000000-0000-0000-0000-00000000000a');
insert into public.sottozone (owner_id, zona_id, nome) values ('00000000-0000-0000-0000-00000000000a', '20000000-0000-0000-0000-00000000000a', 'sz2 di A');
insert into public.tappe (progetto_id, nome) values ('40000000-0000-0000-0000-00000000000a', 'tappa di A');
update public.piante set note = 'nota' where id = 'pianta-a';
update public.piante set sottozona_id = null where id = 'pianta-a2';

-- 2. ogni riferimento a righe altrui è rifiutato
do $$
declare r text;
begin
  foreach r in array array[
    $q$insert into public.piante (id, zona_id) values ('x1', '20000000-0000-0000-0000-00000000000b')$q$,
    $q$insert into public.piante (id, zona_id, sottozona_id) values ('x2', '20000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-00000000000b')$q$,
    $q$update public.piante set zona_id = '20000000-0000-0000-0000-00000000000b' where id = 'pianta-a'$q$,
    $q$update public.piante set sottozona_id = '30000000-0000-0000-0000-00000000000b' where id = 'pianta-a'$q$,
    $q$insert into public.sottozone (zona_id, nome) values ('20000000-0000-0000-0000-00000000000b', 'x')$q$,
    $q$update public.sottozone set zona_id = '20000000-0000-0000-0000-00000000000b' where id = '30000000-0000-0000-0000-00000000000a'$q$,
    $q$insert into public.tappe (progetto_id, nome) values ('40000000-0000-0000-0000-00000000000b', 'x')$q$
  ] loop
    begin
      execute r;
      raise exception 'prova 2: accettato: %', r;
    exception when foreign_key_violation then null;
    end;
  end loop;
end $$;

-- 3. i trigger non sono chiamabili dai client
do $$ begin
  if has_function_privilege('authenticated', 'public.piante_controlla_zona()', 'execute')
     or has_function_privilege('authenticated', 'public.sottozone_controlla_zona()', 'execute')
     or has_function_privilege('authenticated', 'public.tappe_controlla_progetto()', 'execute') then
    raise exception 'prova 3: funzione eseguibile da authenticated';
  end if;
end $$;
reset role;

-- 4. cambiare il proprietario di una pianta a mano (come dall'editor della dashboard) è rifiutato
do $$ begin
  begin
    update public.piante set owner_id = '00000000-0000-0000-0000-00000000000b' where id = 'pianta-a';
    raise exception 'prova 4: cambio di proprietario accettato';
  exception when foreign_key_violation then null;
  end;
end $$;

-- 5. eliminare zone e progetti funziona come prima (cascate e set null non toccano i trigger)
delete from public.piante where owner_id = '00000000-0000-0000-0000-00000000000a';
delete from public.zone where id = '20000000-0000-0000-0000-00000000000a';
delete from public.progetti where id = '40000000-0000-0000-0000-00000000000a';

-- 6. il rollback si applica
\i scripts/proprietario/rollback_riferimenti.sql
do $$ begin
  if exists (select 1 from pg_trigger where tgname in ('piante_controlla_zona','sottozone_controlla_zona','tappe_controlla_progetto')) then
    raise exception 'prova 6: trigger ancora presenti';
  end if;
end $$;
\echo PROVA PROPRIETARIO OK
