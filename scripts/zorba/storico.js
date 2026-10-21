// Mappatura di public/data/richieste-agente.json nei fili di Zorba (spec, sezione "Storico"). Un filo chiuso e
// importato per richiesta; nessun consumo (lo storico non conta nei limiti); ultima_lettura = ora di importazione.
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

export function testoVecchioFormato(risposta) {
  const righe = (risposta?.candidati ?? []).map(c => `- ${c.nome} (${c.specieBotanica}), confidenza ${c.confidenza}: ${c.note}`)
  return ['Candidati più probabili:', ...righe].join('\n')
}

export function mappaRichiesta(id, r, progettiEsistenti) {
  const segnalazione = r.tipo === 'revisione_specie'
  const progetto = r.progetto && UUID.test(r.progetto) && progettiEsistenti.has(r.progetto) ? r.progetto : null
  const testoZorba = r.risposta?.messaggio ?? (r.risposta?.candidati ? testoVecchioFormato(r.risposta) : null)
  const quando = r.risposta?.elaborata ?? r.elaborata ?? r.creata
  const messaggi = [{ ruolo: 'utente', testo: r.messaggio?.trim() || null, esito: null, creato: r.creata }]
  if (testoZorba || r.stato === 'errore') {
    messaggi.push({ ruolo: 'zorba', testo: testoZorba, esito: r.stato === 'errore' ? 'errore' : 'completata', creato: quando })
  }
  return {
    id,
    filo: {
      tipo: segnalazione ? 'segnalazione_scheda' : r.tipo,
      stato: 'chiuso', importato: true,
      voce: r.voce ?? null, nome_voce: r.nome_voce ?? null,
      progetto_id: progetto,
      titolo_progetto: progetto ? null : (r.titolo_progetto ?? r.progetto ?? null),
      segnalazione_stato: segnalazione ? 'accolta' : null,
      creato: r.creata, aggiornato: quando,
    },
    messaggi,
  }
}

const q = v => v == null ? 'null' : `'${String(v).replace(/'/g, "''")}'`

export function sqlStorico(voci, owner, progettiEsistenti) {
  const usati = [...new Set(voci.map(([id, r]) => mappaRichiesta(id, r, progettiEsistenti).filo.progetto_id).filter(Boolean))]
  const righe = ['-- Generato da scripts/zorba/genera_storico.mjs: i fili storici di richieste-agente.json (spec, "Storico").',
    '-- Rollback: delete from public.zorba_fili where importato;', `-- progetti: ${usati.join(',')}`, 'begin;']
  for (const [id, r] of voci) {
    const { filo, messaggi } = mappaRichiesta(id, r, progettiEsistenti)
    righe.push(`-- ${id}`)
    righe.push(`with f as (insert into public.zorba_fili (owner_id, tipo, stato, importato, voce, nome_voce, progetto_id, titolo_progetto, segnalazione_stato, creato, aggiornato, ultima_lettura)
  values (${q(owner)}, ${q(filo.tipo)}, 'chiuso', true, ${q(filo.voce)}, ${q(filo.nome_voce)}, ${q(filo.progetto_id)}, ${q(filo.titolo_progetto)}, ${q(filo.segnalazione_stato)}, ${q(filo.creato)}, ${q(filo.aggiornato)}, now()) returning id)
insert into public.zorba_messaggi (filo_id, owner_id, ruolo, testo, esito, creato)
select f.id, ${q(owner)}, m.ruolo, m.testo, m.esito, m.creato::timestamptz from f, (values ${messaggi.map((m, i) =>
      `(${q(m.ruolo)}, ${q(m.testo)}, ${q(m.esito)}, ${q(new Date(new Date(m.creato).getTime() + i).toISOString())})`).join(', ')}) as m (ruolo, testo, esito, creato);`)
  }
  righe.push('commit;')
  return righe.join('\n') + '\n'
}
