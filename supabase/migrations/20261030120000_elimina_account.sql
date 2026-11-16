-- Eliminazione dell'account dall'app (pagina Account → «Elimina l'account»). La chiama solo la Edge Function `account`
-- con la chiave di servizio, dopo aver controllato che l'utente abbia appena riscritto la password; poi la funzione
-- cancella i file e l'utente di Supabase Auth, la cui cascata toglie fili e messaggi di Zorba, consumi, abbonamento e
-- righe della galleria. Le tabelle del giardino hanno la chiave verso auth.users senza cascata (e piante → zone è
-- RESTRICT), quindi le svuota qui, in ordine, in una sola transazione.
-- Prove: bash scripts/account/prova_db.sh (database usa e getta). Rollback: drop delle due funzioni (nessun dato toccato).

-- I file dell'utente nei due bucket privati, per cancellarli con l'API di Storage (dal 2025 Supabase non permette più
-- di cancellare righe di storage.objects in SQL: i file resterebbero nel bucket).
create function public.account_file(p_owner uuid) returns table (bucket text, percorso text)
language sql stable set search_path = '' as $$
  select o.bucket_id, o.name from storage.objects o
   where o.bucket_id in ('galleria', 'zorba-foto') and (storage.foldername(o.name))[1] = p_owner::text
$$;

-- Restituisce quante righe ha tolto per tabella (per il registro della funzione, non per l'utente).
create function public.account_elimina_dati(p_owner uuid) returns jsonb
language plpgsql set search_path = '' as $$
declare
  esito jsonb := '{}';
  n int;
begin
  if p_owner is null then raise exception 'account:proprietario_mancante'; end if;
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

revoke all on function public.account_file(uuid), public.account_elimina_dati(uuid) from public, anon, authenticated;
grant execute on function public.account_file(uuid), public.account_elimina_dati(uuid) to service_role;
