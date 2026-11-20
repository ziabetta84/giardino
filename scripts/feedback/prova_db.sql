-- Prove della migration del feedback della beta: permessi per utente, limite giornaliero di 20 invii, nessuna
-- modifica da parte dei client, cancellazione con l'account. Ultima riga PROVA FEEDBACK OK.
\set A '''aaaaaaaa-0000-0000-0000-000000000001'''
\set B '''bbbbbbbb-0000-0000-0000-000000000002'''
insert into auth.users values (:A), (:B);

-- Esegue sql e controlla che fallisca con un messaggio che contiene atteso
create function pg_temp.fallisce(sql text, cosa text, atteso text) returns void language plpgsql as $$
begin
  execute sql;
  raise exception 'DOVEVA FALLIRE: %', cosa;
exception when others then
  if sqlerrm not like '%' || atteso || '%' then
    raise exception 'ERRORE INATTESO in % : % (atteso %)', cosa, sqlerrm, atteso;
  end if;
end $$;

-- Validazione prima del limite (il trigger del limite gira prima dei vincoli di colonna)
set role authenticated;
set request.jwt.claim.sub = 'aaaaaaaa-0000-0000-0000-000000000001';
select pg_temp.fallisce($$insert into public.feedback (categoria, testo) values ('idea', '   ')$$,
  'testo vuoto', 'feedback_testo_check');
select pg_temp.fallisce($$insert into public.feedback (categoria, testo) values ('altro', 'x')$$,
  'categoria fuori elenco', 'feedback_categoria_check');
-- A invia 20 messaggi, il ventunesimo nello stesso giorno è respinto
insert into public.feedback (categoria, testo) select 'idea', 'messaggio ' || g from generate_series(1, 20) g;
select pg_temp.fallisce($$insert into public.feedback (categoria, testo) values ('idea', 'in più')$$,
  'ventunesimo invio', 'feedback:limite_giornaliero');
-- A non vede A? sì: vede le sue 20 righe; non può inserire a nome di B
select pg_temp.fallisce($$insert into public.feedback (owner_id, categoria, testo) values ('bbbbbbbb-0000-0000-0000-000000000002', 'idea', 'a nome di B')$$,
  'invio a nome di un altro', 'row-level security');
select pg_temp.fallisce($$update public.feedback set testo = 'modificato'$$, 'modifica da client', 'permission denied');
select pg_temp.fallisce($$delete from public.feedback$$, 'cancellazione da client', 'permission denied');
select pg_temp.fallisce($$select public.account_elimina_dati('aaaaaaaa-0000-0000-0000-000000000001')$$,
  'account_elimina_dati da authenticated', 'permission denied');
reset role;

-- B: un invio suo, il limite di A non lo tocca, e non vede le righe di A
set role authenticated;
set request.jwt.claim.sub = 'bbbbbbbb-0000-0000-0000-000000000002';
insert into public.feedback (categoria, testo) values ('problema', 'B scrive');
do $$ begin
  if (select count(*) from public.feedback) <> 1 then raise exception 'B vede righe che non sono sue'; end if;
end $$;
reset role;

-- anon non vede nulla
set role anon;
select pg_temp.fallisce($$select 1 from public.feedback$$, 'lettura da anon', 'permission denied');
reset role;

-- Il curatore (service_role) cambia stato e risposta; un client no (gia' provato sopra)
set role service_role;
update public.feedback set stato = 'risolto', risposta = 'Sistemato nella versione di prova' where categoria = 'problema';
do $$ begin
  if (select count(*) from public.feedback where stato = 'risolto') <> 1 then raise exception 'service_role non aggiorna'; end if;
end $$;
reset role;

-- Eliminazione dell'account di A: via 20 righe, restano quelle di B
select public.account_elimina_dati('aaaaaaaa-0000-0000-0000-000000000001') as esito \gset
do $$ begin
  if (select count(*) from public.feedback where owner_id = 'aaaaaaaa-0000-0000-0000-000000000001') <> 0 then raise exception 'restano righe di A'; end if;
  if (select count(*) from public.feedback where owner_id = 'bbbbbbbb-0000-0000-0000-000000000002') <> 1 then raise exception 'spariscono righe di B'; end if;
end $$;
select 'PROVA FEEDBACK OK';
