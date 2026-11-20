-- Feedback della beta (docs/brief-feedback-beta.md): i beta tester scrivono a chi costruisce l'app, vedono lo stato
-- del messaggio e l'eventuale risposta. I client possono solo inserire e leggere le proprie righe: stato e risposta
-- li scrive il curatore con service_role. Il limite giornaliero (20 invii per utente, giorno di Roma) sta nel database,
-- non solo nell'interfaccia. La tabella entra anche in account_elimina_dati (eliminazione dell'account).
-- Prove: bash scripts/feedback/prova_db.sh (database usa e getta). Rollback: rieseguire la create della funzione
-- account_elimina_dati dalla migration 20261030130000_account_eliminati.sql, poi drop table public.feedback cascade.

create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users on delete cascade,
  categoria text not null check (categoria in ('problema', 'non_riesco', 'idea')),
  testo text not null check (char_length(btrim(testo)) between 1 and 1000),
  pagina text check (char_length(pagina) <= 200),
  versione text check (char_length(versione) <= 40),
  dispositivo text check (char_length(dispositivo) <= 200),
  stato text not null default 'nuovo' check (stato in ('nuovo', 'letto', 'risolto', 'non_previsto')),
  risposta text check (char_length(risposta) <= 1000),
  creato timestamptz not null default clock_timestamp(),
  aggiornato timestamptz not null default clock_timestamp()
);
create index feedback_owner on public.feedback (owner_id, creato desc);

-- Il limite conta le righe del giorno di Roma. Il lucchetto di transazione per utente evita che due invii
-- simultanei superino il limite insieme.
create function public.feedback_limite() returns trigger
language plpgsql set search_path = '' as $$
declare
  oggi date := (now() at time zone 'Europe/Rome')::date;
  gia_inviati int;
begin
  perform pg_advisory_xact_lock(hashtextextended(new.owner_id::text, 0));
  select count(*) into gia_inviati from public.feedback
   where owner_id = new.owner_id and (creato at time zone 'Europe/Rome')::date = oggi;
  if gia_inviati >= 20 then raise exception 'feedback:limite_giornaliero'; end if;
  return new;
end $$;
create trigger feedback_limite before insert on public.feedback
  for each row execute function public.feedback_limite();

alter table public.feedback enable row level security;
create policy "feedback: lettura propria" on public.feedback for select to authenticated using (owner_id = auth.uid());
create policy "feedback: invio proprio" on public.feedback for insert to authenticated with check (owner_id = auth.uid());

-- Permessi: i client leggono e inseriscono; nessun aggiornamento né cancellazione. Il curatore usa service_role.
revoke all on table public.feedback from public, anon, authenticated;
grant select, insert on table public.feedback to authenticated;
grant select, update on table public.feedback to service_role;
revoke all on function public.feedback_limite() from public, anon, authenticated;

-- account_elimina_dati: come nella 20261030130000, più i feedback dell'utente.
create or replace function public.account_elimina_dati(p_owner uuid) returns jsonb
language plpgsql set search_path = '' as $$
declare
  esito jsonb := '{}';
  n int;
begin
  if p_owner is null then raise exception 'account:proprietario_mancante'; end if;
  insert into public.account_eliminati (id) values (p_owner) on conflict (id) do nothing;
  delete from public.programmi_irrigazione where owner_id = p_owner; get diagnostics n = row_count; esito := esito || jsonb_build_object('programmi_irrigazione', n);
  delete from public.foto where owner_id = p_owner;                  get diagnostics n = row_count; esito := esito || jsonb_build_object('foto', n);
  delete from public.piante where owner_id = p_owner;                get diagnostics n = row_count; esito := esito || jsonb_build_object('piante', n);
  delete from public.sottozone where owner_id = p_owner;             get diagnostics n = row_count; esito := esito || jsonb_build_object('sottozone', n);
  delete from public.zone where owner_id = p_owner;                  get diagnostics n = row_count; esito := esito || jsonb_build_object('zone', n);
  delete from public.tappe where owner_id = p_owner;                 get diagnostics n = row_count; esito := esito || jsonb_build_object('tappe', n);
  delete from public.progetti where owner_id = p_owner;              get diagnostics n = row_count; esito := esito || jsonb_build_object('progetti', n);
  delete from public.concimi where owner_id = p_owner;               get diagnostics n = row_count; esito := esito || jsonb_build_object('concimi', n);
  delete from public.settings where owner_id = p_owner;              get diagnostics n = row_count; esito := esito || jsonb_build_object('settings', n);
  delete from public.feedback where owner_id = p_owner;              get diagnostics n = row_count; esito := esito || jsonb_build_object('feedback', n);
  return esito;
end $$;
