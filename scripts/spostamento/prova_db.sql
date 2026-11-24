-- Prove della data di spostamento (vedi prova_db.sh). Ultima riga: PROVA SPOSTAMENTO OK.
\set ON_ERROR_STOP 1
insert into auth.users values ('00000000-0000-0000-0000-00000000000a');
insert into public.zone (id, owner_id, nome, tipo) values
  ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'Giardino', 'esterno'),
  ('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000a', 'Orto', 'esterno'),
  ('20000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-00000000000a', 'Casa', 'interno');
insert into public.sottozone (id, owner_id, zona_id, nome, tipo) values
  ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', '20000000-0000-0000-0000-000000000003', 'Terrazzo', 'esterno'),
  ('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000a', '20000000-0000-0000-0000-000000000003', 'Soggiorno', null);
insert into public.piante (id, owner_id, zona_id) values
  ('aloe', '00000000-0000-0000-0000-00000000000a', '20000000-0000-0000-0000-000000000001');

set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000a', false);
create temp table oggi as select (now() at time zone 'Europe/Rome')::date as d;

-- 1. fra due zone all'aperto: nessuna data
update public.piante set zona_id = '20000000-0000-0000-0000-000000000002' where id = 'aloe';
do $$ begin
  if (select spostata_il from public.piante where id = 'aloe') is not null then raise exception 'prova 1: data scritta fra due zone all''aperto'; end if;
end $$;

-- 2. dall'aperto al chiuso (sottozona senza tipo: conta la zona Casa): data di oggi
update public.piante set zona_id = '20000000-0000-0000-0000-000000000003', sottozona_id = '30000000-0000-0000-0000-000000000002' where id = 'aloe';
do $$ begin
  if (select spostata_il from public.piante where id = 'aloe') is distinct from (select d from oggi) then raise exception 'prova 2: data mancante entrando in casa'; end if;
end $$;

-- 3. l'«Annulla» rimette la data di prima insieme alla zona
update public.piante set zona_id = '20000000-0000-0000-0000-000000000002', sottozona_id = null, spostata_il = null where id = 'aloe';
do $$ begin
  if (select spostata_il from public.piante where id = 'aloe') is not null then raise exception 'prova 3: annullamento non rispettato'; end if;
end $$;

-- 4. la sottozona all'aperto dentro una zona al chiuso conta come aperto: Orto → Terrazzo non scrive nulla
update public.piante set zona_id = '20000000-0000-0000-0000-000000000003', sottozona_id = '30000000-0000-0000-0000-000000000001' where id = 'aloe';
do $$ begin
  if (select spostata_il from public.piante where id = 'aloe') is not null then raise exception 'prova 4: data scritta passando al terrazzo'; end if;
end $$;

-- 5. Terrazzo → Soggiorno (stessa zona, sottozona al chiuso): data di oggi
update public.piante set sottozona_id = '30000000-0000-0000-0000-000000000002' where id = 'aloe';
do $$ begin
  if (select spostata_il from public.piante where id = 'aloe') is distinct from (select d from oggi) then raise exception 'prova 5: data mancante passando al soggiorno'; end if;
end $$;

-- 6. un aggiornamento che non tocca zona e sottozona lascia la data com'è
update public.piante set spostata_il = '2026-01-01' where id = 'aloe';
update public.piante set coltivato_in = 'vaso' where id = 'aloe';
do $$ begin
  if (select spostata_il from public.piante where id = 'aloe') is distinct from date '2026-01-01' then raise exception 'prova 6: data cambiata senza spostamento'; end if;
end $$;

-- 7. la funzione del trigger non è chiamabile dai client
do $$ begin
  if has_function_privilege('authenticated', 'public.piante_data_spostamento()', 'execute') then raise exception 'prova 7: funzione eseguibile da authenticated'; end if;
end $$;

reset role;
select 'PROVA SPOSTAMENTO OK';
