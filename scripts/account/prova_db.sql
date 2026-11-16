-- Prove della migration dell'eliminazione dell'account: si cancella tutto il giardino di A e niente di B, e i client
-- non possono chiamare le funzioni. Ultima riga PROVA ACCOUNT OK.
\set A '''aaaaaaaa-0000-0000-0000-000000000001'''
\set B '''bbbbbbbb-0000-0000-0000-000000000002'''
insert into auth.users values (:A), (:B);

create function pg_temp.giardino(u uuid) returns void language plpgsql as $$
declare z uuid; s uuid; p uuid;
begin
  insert into public.zone (owner_id) values (u) returning id into z;
  insert into public.sottozone (owner_id, zona_id) values (u, z) returning id into s;
  insert into public.piante values (u::text || '-rosa', u, z, s), (u::text || '-salvia', u, z, null);
  insert into public.piante_vecchie_specie values (u::text || '-rosa');
  insert into public.progetti (owner_id) values (u) returning id into p;
  insert into public.tappe (owner_id, progetto_id) values (u, p), (u, p);
  insert into public.concimi (owner_id) values (u);
  insert into public.settings values (u);
  insert into public.programmi_irrigazione (owner_id, zona_id, pianta_id) values (u, z, u::text || '-rosa');
  insert into public.foto (owner_id, pianta_id) values (u, u::text || '-rosa'), (u, null);
  insert into public.zorba_fili (owner_id, progetto_id) values (u, p);
  insert into storage.objects (bucket_id, name) values
    ('galleria', u::text || '/' || u::text || '-rosa/1.webp'), ('galleria', u::text || '/generale/2.webp'),
    ('zorba-foto', u::text || '/filo/m.jpg'), ('altro', u::text || '/x.jpg');
end $$;
select pg_temp.giardino(:A), pg_temp.giardino(:B);

create function pg_temp.fallisce(sql text, cosa text) returns void language plpgsql as $$
begin
  execute sql;
  raise exception 'DOVEVA FALLIRE: %', cosa;
exception when insufficient_privilege then null;
end $$;

-- I client non vedono i file né cancellano dati altrui
set role authenticated;
select pg_temp.fallisce($$select public.account_file('aaaaaaaa-0000-0000-0000-000000000001')$$, 'account_file da authenticated');
select pg_temp.fallisce($$select public.account_elimina_dati('aaaaaaaa-0000-0000-0000-000000000001')$$, 'account_elimina_dati da authenticated');
set role anon;
select pg_temp.fallisce($$select public.account_elimina_dati('aaaaaaaa-0000-0000-0000-000000000001')$$, 'account_elimina_dati da anon');
reset role;

set role service_role;
do $$ begin
  if (select count(*) from public.account_file('aaaaaaaa-0000-0000-0000-000000000001')) <> 3 then raise exception 'file di A: attesi 3 (galleria e zorba-foto)'; end if;
  if exists (select 1 from public.account_file('aaaaaaaa-0000-0000-0000-000000000001') where percorso like 'bbbbbbbb%') then raise exception 'file di B tra quelli di A'; end if;
end $$;
select public.account_elimina_dati('aaaaaaaa-0000-0000-0000-000000000001');
do $$ begin
  if public.account_elimina_dati(null) is not null then raise exception 'proprietario nullo accettato'; end if;
exception when raise_exception then
  if sqlerrm <> 'account:proprietario_mancante' then raise; end if;
end $$;
reset role;

-- Dopo i dati, l'utente di Auth si cancella senza violare chiavi esterne (la cascata toglie fili e foto)
delete from auth.users where id = :A;
do $$
declare t text; n int;
begin
  foreach t in array array['zone','sottozone','piante','progetti','tappe','concimi','settings','programmi_irrigazione','foto','zorba_fili'] loop
    execute format('select count(*) from public.%I where owner_id = %L', t, 'aaaaaaaa-0000-0000-0000-000000000001') into n;
    if n <> 0 then raise exception 'restano righe di A in %', t; end if;
    execute format('select count(*) from public.%I where owner_id = %L', t, 'bbbbbbbb-0000-0000-0000-000000000002') into n;
    if n = 0 then raise exception 'cancellate righe di B in %', t; end if;
  end loop;
  if (select count(*) from public.piante_vecchie_specie) <> 1 then raise exception 'piante_vecchie_specie'; end if;
  if (select count(*) from public.tappe) <> 2 then raise exception 'tappe di B'; end if;
  if (select count(*) from public.account_eliminati) <> 1
     or not exists (select 1 from public.account_eliminati where id = 'aaaaaaaa-0000-0000-0000-000000000001') then raise exception 'registro degli eliminati'; end if;
end $$;

-- Il registro non si legge né si scrive dai client
set role authenticated;
select pg_temp.fallisce($$select * from public.account_eliminati$$, 'account_eliminati da authenticated');
reset role;
set role anon;
select pg_temp.fallisce($$insert into public.account_eliminati (id) values (gen_random_uuid())$$, 'account_eliminati da anon');
reset role;

-- Ripristino di un backup preso prima dell'eliminazione: A torna, con un giardino, e il registro è vecchio (vuoto).
-- riapplica_eliminazioni.sql, con il registro tenuto fuori dai backup, lo cancella di nuovo e non tocca B.
insert into auth.users (id) values (:A);
insert into public.zone (owner_id) values (:A);
truncate public.account_eliminati;
create temp table registro (id uuid primary key, eliminato_il timestamptz not null);
insert into registro values (:A, now() - interval '1 day');
\i scripts/backup/riapplica_eliminazioni.sql
\i scripts/backup/riapplica_eliminazioni.sql
do $$ begin
  if exists (select 1 from auth.users where id = 'aaaaaaaa-0000-0000-0000-000000000001') then raise exception 'A non rieliminato'; end if;
  if exists (select 1 from public.zone where owner_id = 'aaaaaaaa-0000-0000-0000-000000000001') then raise exception 'zona di A tornata'; end if;
  if not exists (select 1 from public.zone where owner_id = 'bbbbbbbb-0000-0000-0000-000000000002') then raise exception 'zone di B toccate'; end if;
  if (select count(*) from public.account_eliminati) <> 1 then raise exception 'registro non ricostruito'; end if;
end $$;
\echo PROVA ACCOUNT OK
