-- Registro degli account eliminati: solo l'id e la data, nessun altro dato. Serve a rifare le eliminazioni dopo il
-- ripristino di un backup preso prima (scripts/backup/riapplica_eliminazioni.sh), che altrimenti riporterebbe in vita
-- account e giardini che l'utente aveva cancellato. scripts/backup-db.sh ne tiene una copia fuori dai backup, in
-- backups/account_eliminati.tsv, perché il registro dentro un backup vecchio è vecchio anche lui.
-- account_elimina_dati (20261030120000_elimina_account.sql) ora scrive qui per prima cosa.
-- Prove: bash scripts/account/prova_db.sh. Rollback: rieseguire la create della funzione dalla migration precedente,
-- poi drop table public.account_eliminati.

create table public.account_eliminati (
  id uuid primary key,
  eliminato_il timestamptz not null default now()
);
alter table public.account_eliminati enable row level security;  -- nessuna policy: solo per uso interno
revoke all on table public.account_eliminati from public, anon, authenticated;
grant select, insert on table public.account_eliminati to service_role;

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
  return esito;
end $$;
