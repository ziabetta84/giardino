-- Zorba dice in app (spec docs/superpowers/specs/2026-10-21-zorba-dice-agente-design.md): fili, messaggi, consumi,
-- abbonamenti, bucket delle foto e le funzioni chiamate dalla Edge Function `zorba`.
-- Supabase concede di default tutto su ogni nuova tabella e funzione di public ad anon e authenticated: qui i permessi
-- si tolgono tutti e si ridanno solo quelli voluti (lettura dei propri dati, ultima_lettura, voti).

create table public.abbonamenti (
  owner_id uuid primary key references auth.users on delete cascade,
  attivo_fino date not null,
  note text,
  creato timestamptz not null default now(),
  aggiornato timestamptz not null default now()
);

create table public.zorba_fili (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users on delete cascade,
  tipo text not null check (tipo in ('identifica_specie', 'segnalazione_scheda', 'consiglio_cura', 'consiglio_concimazione',
                                     'diagnosi', 'pianifica_progetto', 'altro')),
  modello text,
  importato boolean not null default false,
  stato text not null default 'aperto' check (stato in ('aperto', 'chiuso')),
  voce text check (voce ~ '^[tc]:[0-9a-f-]{36}$'),
  nome_voce text,
  progetto_id uuid references public.progetti on delete set null,
  titolo_progetto text,
  segnalazione_stato text check (segnalazione_stato in ('in_attesa', 'accolta', 'non_accolta')),
  segnalazione_nota text,
  in_elaborazione_dal timestamptz,
  ultima_lettura timestamptz,
  creato timestamptz not null default clock_timestamp(),
  aggiornato timestamptz not null default clock_timestamp(),
  check ((tipo = 'segnalazione_scheda') = (segnalazione_stato is not null))
);
create index zorba_fili_owner on public.zorba_fili (owner_id, aggiornato desc);

create table public.zorba_messaggi (
  id uuid primary key default gen_random_uuid(),
  filo_id uuid not null references public.zorba_fili on delete cascade,
  owner_id uuid not null references auth.users on delete cascade,
  ruolo text not null check (ruolo in ('utente', 'zorba')),
  testo text,
  foto_path text,
  esito text check (esito in ('completata', 'in_corso', 'errore')),
  strumenti jsonb,
  modello_effettivo text,
  input_token int, output_token int, cache_lettura_token int, cache_scrittura_token int,
  costo_usd numeric(10, 5),
  voto smallint check (voto in (-1, 1)),
  voto_motivo text check (voto_motivo in ('sbagliata', 'poco_chiara', 'non_centra', 'troppo_generica')),
  voto_commento text check (length(voto_commento) <= 500),
  votato_il timestamptz,
  creato timestamptz not null default clock_timestamp(),
  check ((ruolo = 'zorba') = (esito is not null)),
  check (ruolo = 'zorba' or (voto is null and voto_motivo is null and voto_commento is null))
);
create index zorba_messaggi_filo on public.zorba_messaggi (filo_id, creato);

-- Una riga per risposta con un costo: conta mese, prova e tetto globale anche dopo l'eliminazione di un filo
create table public.zorba_consumi (
  id bigint generated always as identity primary key,
  owner_id uuid not null references auth.users on delete cascade,
  messaggio_id uuid,
  costo_usd numeric(10, 5) not null check (costo_usd > 0),
  creato timestamptz not null default now()
);
create index zorba_consumi_owner on public.zorba_consumi (owner_id, creato);
create index zorba_consumi_creato on public.zorba_consumi (creato);

alter table public.abbonamenti enable row level security;
alter table public.zorba_fili enable row level security;
alter table public.zorba_messaggi enable row level security;
alter table public.zorba_consumi enable row level security;

revoke all on public.abbonamenti, public.zorba_fili, public.zorba_messaggi, public.zorba_consumi from anon, authenticated;
grant select on public.zorba_fili, public.zorba_messaggi to authenticated;
grant update (ultima_lettura) on public.zorba_fili to authenticated;
grant update (voto, voto_motivo, voto_commento) on public.zorba_messaggi to authenticated;

create policy "zorba_fili: lettura del proprietario" on public.zorba_fili for select to authenticated using (owner_id = auth.uid());
create policy "zorba_fili: lettura segnata dal proprietario" on public.zorba_fili for update to authenticated
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "zorba_messaggi: lettura del proprietario" on public.zorba_messaggi for select to authenticated using (owner_id = auth.uid());
create policy "zorba_messaggi: voto del proprietario" on public.zorba_messaggi for update to authenticated
  using (owner_id = auth.uid() and ruolo = 'zorba') with check (owner_id = auth.uid() and ruolo = 'zorba');

-- votato_il lo imposta il database; motivo e commento hanno senso solo col pollice giù
create function public.zorba_voto() returns trigger language plpgsql set search_path = '' as $$
begin
  if new.voto is distinct from -1 then new.voto_motivo := null; new.voto_commento := null; end if;
  if (new.voto, new.voto_motivo, new.voto_commento) is distinct from (old.voto, old.voto_motivo, old.voto_commento) then
    new.votato_il := now();
  end if;
  return new;
end $$;
create trigger zorba_messaggi_voto before update on public.zorba_messaggi for each row execute function public.zorba_voto();

-- Foto: bucket privato, lettura solo nella propria cartella; i caricamenti li fa solo la funzione (service_role)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('zorba-foto', 'zorba-foto', false, 1572864, array['image/jpeg']) on conflict (id) do nothing;
create policy "zorba-foto: lettura del proprietario" on storage.objects for select to authenticated
  using (bucket_id = 'zorba-foto' and (storage.foldername(name))[1] = auth.uid()::text);

-- Limiti: le risposte in corso (bloccate da meno di 3 minuti) contano come già usate, così due invii in parallelo
-- non superano il tetto.
create function public.zorba_limiti(p_owner uuid, p_curatore boolean, p_costo_max numeric, p_margine numeric, p_riserva numeric)
returns jsonb language plpgsql stable set search_path = '' as $$
declare
  oggi date := (now() at time zone 'Europe/Rome')::date;
  inizio timestamptz := date_trunc('month', now() at time zone 'Europe/Rome') at time zone 'Europe/Rome';
  fino date; in_corso int; mese int; totale int; spesa numeric; abbonati int; tetto numeric;
  tipo text; rimaste int; blocco text;
begin
  select attivo_fino into fino from public.abbonamenti where owner_id = p_owner and attivo_fino >= oggi;
  select count(*) into in_corso from public.zorba_messaggi m join public.zorba_fili f on f.id = m.filo_id
   where m.owner_id = p_owner and m.esito = 'in_corso' and f.in_elaborazione_dal > now() - interval '3 minutes';
  select count(*) filter (where creato >= inizio), count(*) into mese, totale from public.zorba_consumi where owner_id = p_owner;
  select coalesce(sum(costo_usd), 0) into spesa from public.zorba_consumi where creato >= inizio;
  select count(*) into abbonati from public.abbonamenti where attivo_fino >= oggi;
  tetto := abbonati * p_costo_max + p_margine + case when p_curatore then p_riserva else 0 end;
  if not p_curatore then
    if fino is not null then tipo := 'mese'; rimaste := greatest(30 - mese - in_corso, 0);
    else tipo := 'prova'; rimaste := greatest(3 - totale - in_corso, 0);
    end if;
    if rimaste = 0 then blocco := case when tipo = 'mese' then 'tetto_mese' else 'abbonamento_richiesto' end; end if;
  end if;
  if blocco is null and spesa >= tetto then blocco := 'in_pausa_mese'; end if;
  return jsonb_build_object('curatore', p_curatore, 'abbonato', fino is not null, 'attivo_fino', fino,
                            'tipo_tetto', tipo, 'rimaste', rimaste, 'blocco', blocco);
end $$;

create function public.zorba_prenota(p_owner uuid, p_curatore boolean, p_costo_max numeric, p_margine numeric, p_riserva numeric,
  p_filo uuid, p_nuovo jsonb, p_testo text, p_messaggio_utente uuid, p_con_foto boolean, p_riprova boolean)
returns jsonb language plpgsql set search_path = '' as $$
declare
  f public.zorba_fili; lim jsonb; n_utente int; ultima public.zorba_messaggi; m_zorba uuid; percorso text; tipo_n text;
begin
  -- un utente alla volta: i controlli dei limiti e l'apertura della risposta non si sovrappongono
  perform pg_advisory_xact_lock(hashtext(p_owner::text));
  if p_filo is null then
    tipo_n := p_nuovo ->> 'tipo';
    if p_riprova or p_nuovo is null
       or tipo_n is null or tipo_n not in ('identifica_specie', 'segnalazione_scheda', 'consiglio_cura', 'consiglio_concimazione',
                                           'diagnosi', 'pianifica_progetto', 'altro')
       or (tipo_n = 'segnalazione_scheda' and coalesce(p_nuovo ->> 'voce', '') = '')
       or (tipo_n = 'pianifica_progetto' and coalesce(p_nuovo ->> 'progetto_id', '') = '' and coalesce(btrim(p_nuovo ->> 'titolo_progetto'), '') = '') then
      raise exception 'zorba:richiesta_non_valida';
    end if;
  else
    select * into f from public.zorba_fili where id = p_filo and owner_id = p_owner for update;
    if not found then raise exception 'zorba:filo_inesistente'; end if;
    if f.importato or f.stato = 'chiuso' then raise exception 'zorba:filo_chiuso'; end if;
    if f.in_elaborazione_dal is not null then
      if f.in_elaborazione_dal > now() - interval '3 minutes' then raise exception 'zorba:in_elaborazione'; end if;
      update public.zorba_messaggi set esito = 'errore' where filo_id = f.id and esito = 'in_corso';
      update public.zorba_fili set in_elaborazione_dal = null where id = f.id;
    end if;
  end if;

  lim := public.zorba_limiti(p_owner, p_curatore, p_costo_max, p_margine, p_riserva);
  if lim ->> 'blocco' is not null then raise exception 'zorba:%', lim ->> 'blocco'; end if;

  if p_filo is null then
    insert into public.zorba_fili (owner_id, tipo, modello, voce, nome_voce, progetto_id, titolo_progetto, segnalazione_stato)
    values (p_owner, tipo_n,
            case when tipo_n in ('identifica_specie', 'diagnosi') then 'claude-opus-5-5' else 'claude-sonnet-5-5' end,
            nullif(p_nuovo ->> 'voce', ''), nullif(p_nuovo ->> 'nome_voce', ''), nullif(p_nuovo ->> 'progetto_id', '')::uuid,
            nullif(btrim(p_nuovo ->> 'titolo_progetto'), ''), case when tipo_n = 'segnalazione_scheda' then 'in_attesa' end)
    returning * into f;
  end if;

  select * into ultima from public.zorba_messaggi where filo_id = f.id and ruolo = 'zorba' order by creato desc limit 1;
  if p_riprova then
    if ultima.id is null or ultima.esito <> 'errore' then raise exception 'zorba:niente_da_ritentare'; end if;
    update public.zorba_messaggi set esito = 'in_corso', testo = null, strumenti = null, modello_effettivo = null,
           input_token = null, output_token = null, cache_lettura_token = null, cache_scrittura_token = null, costo_usd = null
     where id = ultima.id;
    m_zorba := ultima.id;
  else
    if ultima.esito = 'errore' then raise exception 'zorba:riprova_prima'; end if;
    select count(*) into n_utente from public.zorba_messaggi where filo_id = f.id and ruolo = 'utente';
    if n_utente >= 4 then raise exception 'zorba:filo_chiuso'; end if;
    if p_con_foto then percorso := p_owner || '/' || f.id || '/' || p_messaggio_utente || '.jpg'; end if;
    insert into public.zorba_messaggi (id, filo_id, owner_id, ruolo, testo, foto_path)
    values (p_messaggio_utente, f.id, p_owner, 'utente', nullif(btrim(p_testo), ''), percorso);
    insert into public.zorba_messaggi (filo_id, owner_id, ruolo, esito) values (f.id, p_owner, 'zorba', 'in_corso')
    returning id into m_zorba;
  end if;
  update public.zorba_fili set in_elaborazione_dal = now(), aggiornato = clock_timestamp() where id = f.id;
  return jsonb_build_object('filo', jsonb_build_object('id', f.id, 'tipo', f.tipo, 'modello', f.modello, 'voce', f.voce,
           'nome_voce', f.nome_voce, 'progetto_id', f.progetto_id, 'titolo_progetto', f.titolo_progetto),
         'messaggio_zorba', m_zorba, 'foto_path', percorso);
end $$;

create function public.zorba_concludi(p_messaggio uuid, p_esito text, p_testo text, p_strumenti jsonb, p_modello text,
  p_input int, p_output int, p_cache_lettura int, p_cache_scrittura int, p_costo numeric)
returns jsonb language plpgsql set search_path = '' as $$
declare v_filo uuid; v_owner uuid; v_stato text;
begin
  if p_esito not in ('completata', 'errore') then raise exception 'zorba:esito_non_valido'; end if;
  update public.zorba_messaggi set esito = p_esito, testo = p_testo, strumenti = p_strumenti, modello_effettivo = p_modello,
         input_token = p_input, output_token = p_output, cache_lettura_token = p_cache_lettura,
         cache_scrittura_token = p_cache_scrittura, costo_usd = p_costo
   where id = p_messaggio and ruolo = 'zorba' returning filo_id, owner_id into v_filo, v_owner;
  if v_filo is null then raise exception 'zorba:messaggio_inesistente'; end if;
  if coalesce(p_costo, 0) > 0 then
    insert into public.zorba_consumi (owner_id, messaggio_id, costo_usd) values (v_owner, p_messaggio, p_costo);
  end if;
  update public.zorba_fili set in_elaborazione_dal = null, aggiornato = clock_timestamp(),
         stato = case when p_esito = 'completata'
                       and (select count(*) from public.zorba_messaggi where filo_id = v_filo and ruolo = 'utente') >= 4
                      then 'chiuso' else stato end
   where id = v_filo returning stato into v_stato;
  return jsonb_build_object('stato_filo', v_stato);
end $$;

-- Piano di un progetto: chiamata con il JWT dell'utente (RLS di progetti e tappe), una transazione. Il progetto è quello
-- del filo (lo passa la funzione, non il modello); le tappe aggiornate devono appartenere a quel progetto.
create function public.zorba_salva_piano(p_progetto uuid, p_titolo text, p_descrizione text, p_zona text, p_tappe jsonb, p_esiti jsonb)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare pid uuid := p_progetto;
begin
  if pid is null then
    if coalesce(btrim(p_titolo), '') = '' then raise exception 'zorba:titolo_mancante'; end if;
    insert into public.progetti (titolo, descrizione, zona, stato, creato)
    values (btrim(p_titolo), p_descrizione, nullif(btrim(p_zona), ''), 'aperto', (now() at time zone 'Europe/Rome')::date)
    returning id into pid;
  else
    update public.progetti set descrizione = case when coalesce(btrim(descrizione), '') = '' then p_descrizione else descrizione end,
                               zona = coalesce(nullif(btrim(p_zona), ''), zona)
     where id = pid;
    if not found then raise exception 'zorba:progetto_inesistente'; end if;
  end if;
  insert into public.tappe (progetto_id, data, descrizione, esito)
  select pid, (x ->> 'data')::date, x ->> 'descrizione', coalesce(x ->> 'esito', 'atteso')
    from jsonb_array_elements(coalesce(p_tappe, '[]')) x;
  update public.tappe t set esito = x ->> 'esito'
    from jsonb_array_elements(coalesce(p_esiti, '[]')) x
   where t.id = (x ->> 'id')::uuid and t.progetto_id = pid;
  return pid;
end $$;

revoke all on function public.zorba_voto(), public.zorba_limiti(uuid, boolean, numeric, numeric, numeric),
  public.zorba_prenota(uuid, boolean, numeric, numeric, numeric, uuid, jsonb, text, uuid, boolean, boolean),
  public.zorba_concludi(uuid, text, text, jsonb, text, int, int, int, int, numeric),
  public.zorba_salva_piano(uuid, text, text, text, jsonb, jsonb) from public, anon, authenticated;
grant execute on function public.zorba_limiti(uuid, boolean, numeric, numeric, numeric),
  public.zorba_prenota(uuid, boolean, numeric, numeric, numeric, uuid, jsonb, text, uuid, boolean, boolean),
  public.zorba_concludi(uuid, text, text, jsonb, text, int, int, int, int, numeric) to service_role;
grant execute on function public.zorba_salva_piano(uuid, text, text, text, jsonb, jsonb) to authenticated;
