-- Modello predefinito di Zorba: Qwen 3.5 397B su OVHcloud AI Endpoints per tutti i tipi di richiesta (scelta di Roberta del
-- 26/11/2026, dopo le prove alla cieca del 23-24/11). Prima: claude-opus-5-5 per identifica_specie e diagnosi,
-- claude-sonnet-5-5 per gli altri. Il modello resta fissato per filo: i fili già aperti continuano con il loro.
-- La curatrice può ancora scegliere Claude su un filo nuovo con «Modello in prova». Rollback:
-- scripts/zorba/rollback_predefinito_qwen.sql. I permessi della funzione restano quelli di 20261022100000_zorba_agente.sql.

create or replace function public.zorba_prenota(p_owner uuid, p_curatore boolean, p_costo_max numeric, p_margine numeric, p_riserva numeric,
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
            'ovh:Qwen3.5-397B-A17B',
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
