import { testoFinale } from './filo.js'
import { ETICHETTE_STATO } from './strumenti.js'

// Ciclo di una risposta di Zorba. Dentro il ciclo la risposta dell'assistente si rimanda intera (anche i blocchi di
// ragionamento); i risultati di più strumenti vanno in un solo messaggio utente. Al passaggio maxPassaggi si chiede
// la risposta senza strumenti (tool_choice none è ammesso; any/tool no).
export async function eseguiCiclo({ chiama, richiesta, eseguiStrumento, emetti, maxPassaggi = 8 }) {
  const messages = [...richiesta.messages]
  const risposte = []
  const strumenti = []
  for (let passo = 0; ; passo++) {
    const params = { ...richiesta, messages: [...messages] }
    if (passo >= maxPassaggi) params.tool_choice = { type: 'none' }
    let testoMostrato = false
    const msg = await chiama(params, {
      onTesto: (delta) => { testoMostrato = true; emetti('testo', { t: delta }) },
      onRipiego: () => emetti('annulla_testo', {}),
    })
    risposte.push(msg)
    if (msg.stop_reason === 'tool_use' && passo < maxPassaggi) {
      const toolBlocks = msg.content.filter(b => b.type === 'tool_use')
      if (toolBlocks.length === 0) return { esito: 'errore', codice: 'interno', testo: null, risposte, strumenti }
      if (testoMostrato) emetti('annulla_testo', {})
      messages.push({ role: 'assistant', content: msg.content })
      const risultati = []
      for (const b of toolBlocks) {
        emetti('stato', { t: ETICHETTE_STATO[b.name] ?? 'ci penso…' })
        const r = await eseguiStrumento(b.name, b.input, b)
        strumenti.push({ nome: b.name, errore: r.errore })
        risultati.push({ type: 'tool_result', tool_use_id: b.id, content: r.contenuto, ...(r.errore ? { is_error: true } : {}) })
      }
      messages.push({ role: 'user', content: risultati })
      continue
    }
    if (msg.stop_reason === 'pause_turn') {
      if (!msg.content || msg.content.length === 0) return { esito: 'errore', codice: 'interno', testo: null, risposte, strumenti }
      if (passo >= maxPassaggi) return { esito: 'errore', codice: 'interno', testo: null, risposte, strumenti }
      messages.push({ role: 'assistant', content: msg.content })
      continue
    }
    if (msg.stop_reason === 'refusal') return { esito: 'errore', codice: 'rifiuto', testo: null, risposte, strumenti }
    if (msg.stop_reason === 'max_tokens') return { esito: 'errore', codice: 'troppo_lunga', testo: null, risposte, strumenti }
    const testo = testoFinale(msg.content)
    if (!testo) return { esito: 'errore', codice: 'interno', testo: null, risposte, strumenti }
    return { esito: 'completata', testo, risposte, strumenti }
  }
}
