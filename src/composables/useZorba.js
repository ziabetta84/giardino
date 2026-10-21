import { useSupabase } from '@/composables/useSupabase'
import { creaLettoreSSE } from '@/utils/sse'

// Dati di Zorba dice: fili e messaggi si leggono direttamente da Supabase (RLS del proprietario); invio, stato e
// eliminazione passano dalla Edge Function `zorba`, l'unica che può scrivere fili e messaggi.
const URL_FUNZIONE = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/zorba`

export function useZorba() {
  const supabase = useSupabase()

  async function intestazioni() {
    const { data } = await supabase.auth.getSession()
    return { Authorization: `Bearer ${data.session?.access_token}`, apikey: import.meta.env.VITE_SUPABASE_ANON_KEY }
  }

  async function chiamata(metodo, percorso, corpo) {
    const r = await fetch(`${URL_FUNZIONE}${percorso}`, { method: metodo, headers: { ...(await intestazioni()), 'Content-Type': 'application/json' },
      body: corpo ? JSON.stringify(corpo) : undefined })
    if (!r.ok) {
      const j = await r.json().catch(() => ({}))
      const e = new Error(j.messaggio ?? 'Zorba non risponde: riprova tra poco.')
      e.codice = j.codice ?? 'interno'
      throw e
    }
    return r
  }

  async function caricaFili() {
    const { data, error } = await supabase.from('zorba_fili')
      .select('id, tipo, stato, voce, nome_voce, progetto_id, titolo_progetto, segnalazione_stato, segnalazione_nota, importato, creato, aggiornato, ultima_lettura, zorba_messaggi(ruolo, testo, esito, creato)')
      .order('aggiornato', { ascending: false })
    if (error) throw error
    return data.map(({ zorba_messaggi: m, ...f }) => {
      const ordinati = [...m].sort((a, b) => new Date(a.creato) - new Date(b.creato))
      const ultimaZorba = ordinati.filter(x => x.ruolo === 'zorba' && x.esito === 'completata').at(-1)
      return { ...f, primo_testo: ordinati.find(x => x.ruolo === 'utente')?.testo ?? null,
        nuova_risposta: !!ultimaZorba && (!f.ultima_lettura || new Date(ultimaZorba.creato) > new Date(f.ultima_lettura)) }
    })
  }

  async function caricaMessaggi(filoId) {
    const { data, error } = await supabase.from('zorba_messaggi')
      .select('id, ruolo, testo, esito, foto_path, voto, voto_motivo, voto_commento, creato').eq('filo_id', filoId).order('creato')
    if (error) throw error
    const percorsi = data.map(m => m.foto_path).filter(Boolean)
    const firmati = percorsi.length ? (await supabase.storage.from('zorba-foto').createSignedUrls(percorsi, 3600)).data ?? [] : []
    const url = Object.fromEntries(firmati.map(f => [f.path, f.signedUrl]))
    return data.map(({ foto_path, ...m }) => ({ ...m, foto_url: foto_path ? url[foto_path] ?? null : null }))
  }

  async function stato() {
    return (await chiamata('GET', '/stato')).json()
  }

  async function invia(corpo, onEvento) {
    const r = await chiamata('POST', '', corpo)
    const lettore = r.body.getReader()
    const decodifica = new TextDecoder()
    let concluso = false
    const leggi = creaLettoreSSE((nome, dati) => {
      if (nome === 'fine' || nome === 'errore') concluso = true
      onEvento(nome, dati)
    })
    let finito = false
    try {
      for (;;) {
        const { value, done } = await lettore.read()
        if (done) break
        leggi(decodifica.decode(value, { stream: true }))
      }
      finito = true
    } catch (err) {
      if (err?.codice) throw err
      const e = new Error('La risposta si è interrotta: riprova.')
      e.codice = 'interrotto'
      throw e
    } finally {
      if (!finito) lettore.cancel().catch(() => {})
    }
    if (!concluso) {
      const e = new Error('La risposta si è interrotta: riprova.')
      e.codice = 'interrotto'
      throw e
    }
  }

  async function segnaLetto(filoId) {
    await supabase.from('zorba_fili').update({ ultima_lettura: new Date().toISOString() }).eq('id', filoId)
  }

  async function vota(messaggioId, voto, motivo = null, commento = null) {
    const { error } = await supabase.from('zorba_messaggi').update({ voto, voto_motivo: motivo, voto_commento: commento?.trim() || null }).eq('id', messaggioId)
    if (error) throw error
  }

  async function elimina(filoId) {
    await chiamata('DELETE', `/filo/${filoId}`)
  }

  return { caricaFili, caricaMessaggi, stato, invia, segnaLetto, vota, elimina }
}
