-- Prove della migration della galleria: ogni utente vede, carica ed elimina solo le proprie foto. Ultima riga PROVA GALLERIA OK.
\set A '''aaaaaaaa-0000-0000-0000-000000000001'''
\set B '''bbbbbbbb-0000-0000-0000-000000000002'''
insert into auth.users values (:A), (:B);
insert into public.piante values ('rosa-1', :A), ('rosa-2', :B);

create function pg_temp.come(utente uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', coalesce(utente::text, ''), false);
  if utente is null then set role anon; else set role authenticated; end if;
end $$;
create function pg_temp.fallisce(sql text, cosa text) returns void language plpgsql as $$
begin
  execute sql;
  raise exception 'DOVEVA FALLIRE: %', cosa;
exception when insufficient_privilege or check_violation or foreign_key_violation then null;
end $$;

-- A carica una foto sulla sua pianta e una generica
select pg_temp.come(:A);
insert into public.foto (pianta_id, scattata_il, percorso, percorso_media, percorso_miniatura)
values ('rosa-1', now(), 'aaaaaaaa-0000-0000-0000-000000000001/rosa-1/1_x.webp', 'aaaaaaaa-0000-0000-0000-000000000001/rosa-1/1_x_medium.webp', null),
       (null, now(), 'aaaaaaaa-0000-0000-0000-000000000001/generale/2_y.jpg', null, null);
insert into storage.objects (bucket_id, name) values ('galleria', 'aaaaaaaa-0000-0000-0000-000000000001/rosa-1/1_x.webp');
-- ... ma non sulla pianta di B, né nella cartella di B, né a nome di B
select pg_temp.fallisce($$insert into public.foto (pianta_id, scattata_il, percorso) values ('rosa-2', now(), 'aaaaaaaa-0000-0000-0000-000000000001/rosa-2/3.jpg')$$, 'foto sulla pianta di un altro');
select pg_temp.fallisce($$insert into public.foto (scattata_il, percorso) values (now(), 'bbbbbbbb-0000-0000-0000-000000000002/generale/4.jpg')$$, 'percorso nella cartella di un altro');
select pg_temp.fallisce($$insert into public.foto (scattata_il, percorso, percorso_media) values (now(), 'aaaaaaaa-0000-0000-0000-000000000001/generale/5.jpg', 'bbbbbbbb-0000-0000-0000-000000000002/generale/5_medium.jpg')$$, 'derivata nella cartella di un altro');
select pg_temp.fallisce($$insert into public.foto (owner_id, scattata_il, percorso) values ('bbbbbbbb-0000-0000-0000-000000000002', now(), 'bbbbbbbb-0000-0000-0000-000000000002/generale/6.jpg')$$, 'foto a nome di un altro');
select pg_temp.fallisce($$insert into storage.objects (bucket_id, name) values ('galleria', 'bbbbbbbb-0000-0000-0000-000000000002/generale/7.jpg')$$, 'file nella cartella di un altro');
select pg_temp.fallisce($$update public.foto set pianta_id = null$$, 'aggiornamento');
reset role;

-- B non vede né cancella le foto di A
select pg_temp.come(:B);
do $$ begin
  if (select count(*) from public.foto) <> 0 then raise exception 'B vede le foto di A'; end if;
  if (select count(*) from storage.objects where bucket_id = 'galleria') <> 0 then raise exception 'B vede i file di A'; end if;
  delete from public.foto;
  delete from storage.objects;
end $$;
reset role;
do $$ begin
  if (select count(*) from public.foto) <> 2 then raise exception 'B ha cancellato le foto di A'; end if;
  if (select count(*) from storage.objects) <> 1 then raise exception 'B ha cancellato i file di A'; end if;
end $$;

-- Senza accesso niente
select pg_temp.come(null);
select pg_temp.fallisce($$select * from public.foto$$, 'lettura anonima');
reset role;

-- A elimina la sua foto; cancellando la pianta se ne va anche la riga rimasta
select pg_temp.come(:A);
delete from public.foto where pianta_id is null;
delete from storage.objects where bucket_id = 'galleria';
delete from public.piante where id = 'rosa-1';
reset role;
do $$ begin
  if (select count(*) from public.foto) <> 0 then raise exception 'foto rimaste dopo la cancellazione'; end if;
  if (select count(*) from storage.objects) <> 0 then raise exception 'file rimasti'; end if;
end $$;
\echo PROVA GALLERIA OK
