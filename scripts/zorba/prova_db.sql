-- Prove di permessi e limiti di Zorba, eseguite da postgres sul database usa e getta; ogni blocco cambia ruolo con
-- set local dentro una transazione. Ultima riga: PROVA ZORBA DB OK.
\set ON_ERROR_STOP 1
create function pg_temp.errore(sql text, atteso text) returns void language plpgsql as $$
begin
  execute sql;
  raise exception 'ATTESO ERRORE (%) MA RIUSCITO: %', atteso, sql;
exception when others then
  if sqlerrm like 'ATTESO ERRORE%' then raise; end if;
  if position(atteso in sqlstate || ' ' || sqlerrm) = 0 then
    raise exception 'ERRORE DIVERSO per %: % % (atteso %)', sql, sqlstate, sqlerrm, atteso;
  end if;
end $$;

insert into auth.users values ('aaaaaaaa-0000-0000-0000-000000000001'), ('bbbbbbbb-0000-0000-0000-000000000002'),
                              ('cccccccc-0000-0000-0000-000000000003');
\set A '''aaaaaaaa-0000-0000-0000-000000000001'''
\set B '''bbbbbbbb-0000-0000-0000-000000000002'''
\set C '''cccccccc-0000-0000-0000-000000000003'''
insert into public.abbonamenti (owner_id, attivo_fino) values (:A, current_date + 30);

-- A apre un filo (come la funzione, da service_role)
create temp table t (k text primary key, v jsonb);
insert into t select 'p1', public.zorba_prenota(:A, false, 6, 10, 5, null,
  '{"tipo":"consiglio_cura"}', 'come la curo?', gen_random_uuid(), false, false);
select public.zorba_concludi((select (v->>'messaggio_zorba')::uuid from t where k = 'p1'), 'completata', 'Così.', '[]', 'claude-sonnet-5-5', 10, 10, 0, 0, 0.05);
grant select on t to authenticated;

-- 1. lettura solo dei propri dati
begin; set local role authenticated; set local request.jwt.claim.sub = 'aaaaaaaa-0000-0000-0000-000000000001';
do $$ begin if (select count(*) from public.zorba_fili) <> 1 or (select count(*) from public.zorba_messaggi) <> 2 then raise exception 'A non vede i suoi dati'; end if; end $$;
commit;
begin; set local role authenticated; set local request.jwt.claim.sub = 'bbbbbbbb-0000-0000-0000-000000000002';
do $$ begin if (select count(*) from public.zorba_fili) + (select count(*) from public.zorba_messaggi) <> 0 then raise exception 'B vede i dati di A'; end if; end $$;
commit;

-- 2. dall'app niente inserimenti, niente campi riservati, niente funzioni di servizio, niente cancellazioni dirette
begin; set local role authenticated; set local request.jwt.claim.sub = 'aaaaaaaa-0000-0000-0000-000000000001';
select pg_temp.errore($q$insert into public.zorba_fili (owner_id, tipo) values (auth.uid(), 'altro')$q$, '42501');
select pg_temp.errore($q$insert into public.zorba_messaggi (filo_id, owner_id, ruolo, testo) select id, owner_id, 'utente', 'x' from public.zorba_fili$q$, '42501');
select pg_temp.errore($q$update public.zorba_messaggi set testo = 'iniettato'$q$, '42501');
select pg_temp.errore($q$update public.zorba_messaggi set costo_usd = 0$q$, '42501');
select pg_temp.errore($q$update public.zorba_messaggi set esito = 'errore'$q$, '42501');
select pg_temp.errore($q$update public.zorba_fili set modello = 'claude-fable-5-1'$q$, '42501');
select pg_temp.errore($q$update public.zorba_fili set segnalazione_stato = 'accolta'$q$, '42501');
select pg_temp.errore($q$update public.zorba_fili set in_elaborazione_dal = null$q$, '42501');
select pg_temp.errore($q$update public.zorba_fili set stato = 'aperto'$q$, '42501');
select pg_temp.errore($q$delete from public.zorba_fili$q$, '42501');
select pg_temp.errore($q$select * from public.abbonamenti$q$, '42501');
select pg_temp.errore($q$select * from public.zorba_consumi$q$, '42501');
select pg_temp.errore($q$select public.zorba_limiti(auth.uid(), true, 0, 1000, 0)$q$, '42501');
select pg_temp.errore($q$select public.zorba_prenota(auth.uid(), true, 0, 1000, 0, null, '{"tipo":"altro"}', 'x', gen_random_uuid(), false, false)$q$, '42501');
select pg_temp.errore($q$select public.zorba_concludi(gen_random_uuid(), 'completata', 'x', null, null, 0, 0, 0, 0, 0)$q$, '42501');
-- campi ammessi: lettura e voti, solo sui messaggi di Zorba e con valori ammessi
update public.zorba_fili set ultima_lettura = now();
update public.zorba_messaggi set voto = -1, voto_motivo = 'poco_chiara', voto_commento = 'non capisco' where ruolo = 'zorba';
do $$ begin if (select votato_il from public.zorba_messaggi where ruolo = 'zorba') is null then raise exception 'votato_il non impostato'; end if; end $$;
do $$ declare n int; begin update public.zorba_messaggi set voto = 1 where ruolo = 'utente'; get diagnostics n = row_count;
  if n <> 0 then raise exception 'voto scritto su un messaggio dell''utente'; end if; end $$;
select pg_temp.errore($q$update public.zorba_messaggi set voto = 5 where ruolo = 'zorba'$q$, '23514');
select pg_temp.errore($q$update public.zorba_messaggi set voto_motivo = 'boh' where ruolo = 'zorba'$q$, '23514');
-- pollice su: motivo e commento si azzerano
update public.zorba_messaggi set voto = 1 where ruolo = 'zorba';
do $$ begin if (select voto_motivo from public.zorba_messaggi where ruolo = 'zorba') is not null then raise exception 'motivo rimasto col pollice su'; end if; end $$;
commit;

-- 3. salva_piano: solo progetti propri, tappe solo del progetto indicato, HTML non filtrato qui (lo filtra la funzione)
insert into public.progetti (id, owner_id, titolo) values ('dddddddd-0000-0000-0000-00000000000b', :B, 'di B');
insert into public.tappe (id, owner_id, progetto_id, data, descrizione) values
  ('eeeeeeee-0000-0000-0000-00000000000b', :B, 'dddddddd-0000-0000-0000-00000000000b', current_date, 'tappa di B');
begin; set local role authenticated; set local request.jwt.claim.sub = 'aaaaaaaa-0000-0000-0000-000000000001';
select pg_temp.errore($q$select public.zorba_salva_piano('dddddddd-0000-0000-0000-00000000000b', null, null, null, '[]', '[]')$q$, 'zorba:progetto_inesistente');
create temp table pa as select public.zorba_salva_piano(null, 'Talee', '<p>Piano</p>', 'Orto',
  '[{"data":"2026-11-01","descrizione":"ripresa"},{"data":"2026-10-20","descrizione":"taglio","esito":"riuscito"}]',
  '[{"id":"eeeeeeee-0000-0000-0000-00000000000b","esito":"fallito"}]') id;
do $$ begin
  if (select count(*) from public.tappe where progetto_id = (select id from pa)) <> 2 then raise exception 'tappe non create'; end if;
  if (select descrizione from public.progetti where id = (select id from pa)) <> '<p>Piano</p>' then raise exception 'descrizione'; end if;
end $$;
-- seconda chiamata: descrizione già presente non sovrascritta
select public.zorba_salva_piano((select id from pa), null, '<p>Altro</p>', null, '[]', '[]');
do $$ begin if (select descrizione from public.progetti where id = (select id from pa)) <> '<p>Piano</p>' then raise exception 'descrizione sovrascritta'; end if; end $$;
commit;
do $$ begin if (select esito from public.tappe where id = 'eeeeeeee-0000-0000-0000-00000000000b') <> 'atteso' then raise exception 'tappa di B modificata'; end if; end $$;

-- 4. limiti
-- non abbonato (C): prova di 3, poi abbonamento_richiesto
insert into public.zorba_consumi (owner_id, costo_usd) select :C, 0.1 from generate_series(1, 3);
select pg_temp.errore(format($q$select public.zorba_prenota(%L, false, 6, 10, 5, null, '{"tipo":"altro"}', 'x', gen_random_uuid(), false, false)$q$, :C), 'zorba:abbonamento_richiesto');
do $$ begin if (public.zorba_limiti('cccccccc-0000-0000-0000-000000000003', false, 6, 10, 5) ->> 'tipo_tetto') <> 'prova' then raise exception 'tipo_tetto prova'; end if; end $$;
-- curatore: nessun tetto per utente
select public.zorba_prenota(:C, true, 6, 10, 5, null, '{"tipo":"altro"}', 'x', gen_random_uuid(), false, false);
-- abbonato al 29º: il primo invio passa, il secondo in parallelo no (il primo è ancora in corso)
insert into public.zorba_consumi (owner_id, costo_usd) select :A, 0.01 from generate_series(1, 28);
select public.zorba_prenota(:A, false, 6, 10, 5, null, '{"tipo":"altro"}', 'uno', gen_random_uuid(), false, false);
select pg_temp.errore(format($q$select public.zorba_prenota(%L, false, 6, 10, 5, null, '{"tipo":"altro"}', 'due', gen_random_uuid(), false, false)$q$, :A), 'zorba:tetto_mese');
-- tetto globale: 1 abbonato × 6 + 10 = 16 $; oltre, in pausa per tutti tranne il curatore (riserva 5)
insert into public.zorba_consumi (owner_id, costo_usd) values (:B, 16);
insert into public.abbonamenti (owner_id, attivo_fino) values (:B, current_date + 30);
-- con 2 abbonati il tetto è 22: B passa
do $$ begin if public.zorba_limiti('bbbbbbbb-0000-0000-0000-000000000002', false, 6, 10, 5) ->> 'blocco' is not null then raise exception 'B bloccato sotto il tetto'; end if; end $$;
insert into public.zorba_consumi (owner_id, costo_usd) values (:B, 10);
select pg_temp.errore(format($q$select public.zorba_prenota(%L, false, 6, 10, 5, null, '{"tipo":"altro"}', 'x', gen_random_uuid(), false, false)$q$, :B), 'zorba:in_pausa_mese');
delete from public.zorba_consumi where owner_id = :B;

-- 5. filo: replica dopo un errore, riprova, chiusura dopo 4 messaggi, blocco scaduto
insert into t select 'p2', public.zorba_prenota(:B, false, 6, 10, 5, null, '{"tipo":"consiglio_cura"}', 'uno', gen_random_uuid(), false, false);
select public.zorba_concludi((select (v->>'messaggio_zorba')::uuid from t where k = 'p2'), 'errore', null, null, 'claude-sonnet-5-5', 5, 0, 0, 0, 0.001);
select pg_temp.errore(format($q$select public.zorba_prenota(%L, false, 6, 10, 5, %L, null, 'due', gen_random_uuid(), false, false)$q$,
  :B, (select v->'filo'->>'id' from t where k = 'p2')), 'zorba:riprova_prima');
insert into t select 'p2r', public.zorba_prenota(:B, false, 6, 10, 5, (select (v->'filo'->>'id')::uuid from t where k = 'p2'), null, null, null, false, true);
do $$ begin if (select v->>'messaggio_zorba' from t where k = 'p2r') <> (select v->>'messaggio_zorba' from t where k = 'p2') then raise exception 'riprova non riusa il messaggio'; end if; end $$;
-- in elaborazione: un secondo invio è rifiutato; dopo 3 minuti il blocco scade e la risposta rimasta diventa errore
select pg_temp.errore(format($q$select public.zorba_prenota(%L, false, 6, 10, 5, %L, null, 'tre', gen_random_uuid(), false, false)$q$,
  :B, (select v->'filo'->>'id' from t where k = 'p2')), 'zorba:in_elaborazione');
update public.zorba_fili set in_elaborazione_dal = now() - interval '4 minutes' where id = (select (v->'filo'->>'id')::uuid from t where k = 'p2');
insert into t select 'p2s', public.zorba_prenota(:B, false, 6, 10, 5, (select (v->'filo'->>'id')::uuid from t where k = 'p2'), null, null, null, false, true);
do $$ begin if (select count(*) from public.zorba_messaggi where esito = 'in_corso' and filo_id = (select (v->'filo'->>'id')::uuid from t where k = 'p2')) <> 1 then raise exception 'risposta rimasta'; end if; end $$;
select public.zorba_concludi((select (v->>'messaggio_zorba')::uuid from t where k = 'p2s'), 'completata', 'ok', '[]', 'claude-sonnet-5-5', 1, 1, 0, 0, 0.01);
-- tre repliche, poi chiuso
do $$ declare f uuid := (select (v->'filo'->>'id')::uuid from t where k = 'p2'); m jsonb; i int; begin
  for i in 1..3 loop
    m := public.zorba_prenota('bbbbbbbb-0000-0000-0000-000000000002', false, 6, 10, 5, f, null, 'replica', gen_random_uuid(), false, false);
    perform public.zorba_concludi((m->>'messaggio_zorba')::uuid, 'completata', 'ok', '[]', 'claude-sonnet-5-5', 1, 1, 0, 0, 0.01);
  end loop;
  if (select stato from public.zorba_fili where id = f) <> 'chiuso' then raise exception 'filo non chiuso dopo 4 messaggi'; end if;
end $$;
select pg_temp.errore(format($q$select public.zorba_prenota(%L, false, 6, 10, 5, %L, null, 'cinque', gen_random_uuid(), false, false)$q$,
  :B, (select v->'filo'->>'id' from t where k = 'p2')), 'zorba:filo_chiuso');
-- consumi: una riga per costo > 0, nessuna per costo 0, e restano dopo l'eliminazione del filo
do $$ declare n int := (select count(*) from public.zorba_consumi where owner_id = 'bbbbbbbb-0000-0000-0000-000000000002'); begin
  delete from public.zorba_fili where owner_id = 'bbbbbbbb-0000-0000-0000-000000000002';
  if (select count(*) from public.zorba_consumi where owner_id = 'bbbbbbbb-0000-0000-0000-000000000002') <> n or n <> 5 then raise exception 'consumi: % righe', n; end if;
end $$;

-- 6. foto: percorso con l'owner esplicito, policy di lettura sulla cartella del proprietario
do $$ declare m jsonb := public.zorba_prenota('aaaaaaaa-0000-0000-0000-000000000001', true, 6, 10, 5, null, '{"tipo":"diagnosi"}', null, 'ffffffff-0000-0000-0000-000000000001', true, false); begin
  if m->>'foto_path' not like 'aaaaaaaa-0000-0000-0000-000000000001/%/ffffffff-0000-0000-0000-000000000001.jpg' then raise exception 'foto_path %', m->>'foto_path'; end if;
  if (m->'filo'->>'modello') <> 'claude-opus-5-5' then raise exception 'modello diagnosi'; end if;
end $$;
insert into storage.objects (bucket_id, name) values ('zorba-foto', 'aaaaaaaa-0000-0000-0000-000000000001/f/x.jpg');
begin; set local role authenticated; set local request.jwt.claim.sub = 'bbbbbbbb-0000-0000-0000-000000000002';
do $$ begin if (select count(*) from storage.objects) <> 0 then raise exception 'B vede le foto di A'; end if; end $$;
commit;

-- 7. validazioni in prenota
select pg_temp.errore(format($q$select public.zorba_prenota(%L, true, 6, 10, 5, null, '{"tipo":"segnalazione_scheda"}', 'x', gen_random_uuid(), false, false)$q$, :A), 'zorba:richiesta_non_valida');
select pg_temp.errore(format($q$select public.zorba_prenota(%L, true, 6, 10, 5, null, '{"tipo":"pianifica_progetto"}', 'x', gen_random_uuid(), false, false)$q$, :A), 'zorba:richiesta_non_valida');
select pg_temp.errore(format($q$select public.zorba_prenota(%L, true, 6, 10, 5, null, '{"tipo":"boh"}', 'x', gen_random_uuid(), false, false)$q$, :A), 'zorba:richiesta_non_valida');

\echo PROVA ZORBA DB OK
