// Edge Function `zorba` (spec docs/superpowers/specs/2026-10-21-zorba-dice-agente-design.md). Qui solo il
// collegamento: HTTP, autenticazione, SDK Anthropic e Supabase. La logica è nei moduli di lib/, provati con node --test.
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import Anthropic from 'npm:@anthropic-ai/sdk@1.0.0'
import { createClient } from 'npm:@supabase/supabase-js@2'
import { encodeBase64, decodeBase64 } from 'jsr:@std/encoding@1/base64'
import { validaRichiesta, TIPI } from './lib/ingresso.js'
import { costoRisposte } from './lib/costi.js'
import { messaggiDalFilo, contestoSistema, MESSAGGI_ERRORE } from './lib/filo.js'
import { creaEmettitore } from './lib/sse.js'
import { DEFINIZIONI_STRUMENTI, eseguiStrumento } from './lib/strumenti.js'
import { eseguiCiclo } from './lib/ciclo.js'
import { riscontroPlantNet } from './lib/plantnet.js'
import { componiSistema } from './lib/regole.js'
import { TESTI } from './regole/testi.js'

const env = (k: string) => Deno.env.get(k) ?? ''
const CURATORE = env('CURATORE_ID')
const NUM = (k: string, d: number) => Number(env(k) || d)
const LIMITI = () => ({ p_costo_max: NUM('ZORBA_COSTO_MAX_ABBONATO', 6), p_margine: NUM('ZORBA_MARGINE_USD', 10), p_riserva: NUM('ZORBA_RISERVA_CURATORE_USD', 5) })
const attivo = () => env('ZORBA_ATTIVO') === 'true'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
}
const json = (corpo: unknown, status = 200) => new Response(JSON.stringify(corpo), { status, headers: { ...CORS, 'Content-Type': 'application/json' } })
const errore = (codice: string, status = 400) => json({ codice, messaggio: MESSAGGI_ERRORE[codice] ?? MESSAGGI_ERRORE.interno }, status)
const codiceDa = (e: unknown) => /zorba:([a-z_]+)/.exec(String((e as Error)?.message ?? e))?.[1] ?? 'interno'

const servizio = createClient(env('SUPABASE_URL'), env('SUPABASE_SERVICE_ROLE_KEY'), { auth: { persistSession: false } })
const anthropic = new Anthropic({ apiKey: env('ANTHROPIC_API_KEY') })

// I .md non arrivano a runtime con il deploy: i testi sono in un modulo generato (scripts/zorba/genera_regole.mjs)
const SISTEMA = componiSistema({ tono: TESTI['tono.md'], ambito: TESTI['ambito.md'],
  procedure: Object.fromEntries(TIPI.map(t => [t, TESTI[`${t}.md`]])) })

async function rpc<T>(nome: string, args: Record<string, unknown>): Promise<T> {
  const { data, error } = await servizio.rpc(nome, args)
  if (error) throw new Error(error.message)
  return data as T
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })
  const jwt = req.headers.get('Authorization')?.replace(/^Bearer /, '') ?? ''
  try {
  const { data: { user } } = await servizio.auth.getUser(jwt)
  if (!user) return errore('richiesta_non_valida', 401)
  const curatore = user.id === CURATORE
  const db = createClient(env('SUPABASE_URL'), env('SUPABASE_ANON_KEY'), {
    global: { headers: { Authorization: `Bearer ${jwt}` } }, auth: { persistSession: false } })
  const percorso = new URL(req.url).pathname.replace(/^.*\/zorba/, '')

    if (req.method === 'GET' && percorso === '/stato') {
      const l = await rpc<Record<string, unknown>>('zorba_limiti', { p_owner: user.id, p_curatore: curatore, ...LIMITI() })
      return json({ attivo: attivo() || curatore, curatore, abbonato: l.abbonato, attivo_fino: l.attivo_fino, tipo_tetto: l.tipo_tetto, rimaste: l.rimaste })
    }
    const del = /^\/filo\/([0-9a-f-]{36})$/.exec(percorso)
    if (req.method === 'DELETE' && del) {
      const { data: f } = await servizio.from('zorba_fili').select('id, in_elaborazione_dal').eq('id', del[1]).eq('owner_id', user.id).maybeSingle()
      if (!f) return errore('filo_inesistente', 404)
      // Con una risposta in corso la cancellazione farebbe perdere il consumo (zorba_concludi non troverebbe il messaggio)
      if (f.in_elaborazione_dal && Date.now() - new Date(f.in_elaborazione_dal).getTime() < 180_000) return errore('in_elaborazione', 409)
      const cartella = `${user.id}/${f.id}`
      const { data: file, error: eList } = await servizio.storage.from('zorba-foto').list(cartella)
      if (eList) { console.error('zorba', 'list', eList.message); return errore('interno', 500) }
      if (file?.length) {
        const { error: eRem } = await servizio.storage.from('zorba-foto').remove(file.map((x) => `${cartella}/${x.name}`))
        if (eRem) { console.error('zorba', 'remove', eRem.message); return errore('interno', 500) }
      }
      const { error: eDel } = await servizio.from('zorba_fili').delete().eq('id', f.id)
      if (eDel) { console.error('zorba', 'delete', eDel.message); return errore('interno', 500) }
      return new Response(null, { status: 204, headers: CORS })
    }
    if (req.method !== 'POST' || percorso !== '') return errore('richiesta_non_valida', 404)
    if (!attivo() && !curatore) return errore('in_pausa', 503)
    const v = validaRichiesta(await req.json().catch(() => null))
    if (!v.ok) return errore(v.codice)
    const { filoId, nuovo, testo, foto, riprova } = v.valore

    // Controlli che richiedono il database, con il JWT dell'utente: il progetto deve essere suo, la voce deve esistere
    if (nuovo?.progetto_id) {
      const { data } = await db.from('progetti').select('id').eq('id', nuovo.progetto_id).maybeSingle()
      if (!data) return errore('progetto_non_trovato')
    }
    if (nuovo?.voce) {
      const { data } = await db.rpc('catalogo_voci', { chiavi: [nuovo.voce] })
      if (!data?.[nuovo.voce]) return errore('voce_non_trovata')
      nuovo.nome_voce = data[nuovo.voce].nome
    }

    const idMessaggio = crypto.randomUUID()
    let prenotazione: { filo: Record<string, string | null>, messaggio_zorba: string, foto_path: string | null }
    try {
      prenotazione = await rpc('zorba_prenota', { p_owner: user.id, p_curatore: curatore, ...LIMITI(), p_filo: filoId, p_nuovo: nuovo,
        p_testo: testo, p_messaggio_utente: riprova ? null : idMessaggio, p_con_foto: !!foto, p_riprova: riprova })
    } catch (e) {
      const c = codiceDa(e)
      const stato = c === 'richiesta_non_valida' ? 400 : c === 'filo_inesistente' ? 404
        : ['tetto_mese', 'abbonamento_richiesto', 'in_pausa_mese'].includes(c) ? 402 : 409
      return errore(c, stato)
    }
    const filo = prenotazione.filo
    const messaggioZorba = prenotazione.messaggio_zorba

    const corpo = new ReadableStream({
      start(controller) {
        const e = creaEmettitore(controller)
        e.emetti('filo', { id: filo.id })
        EdgeRuntime.waitUntil(lavora(e).finally(() => e.chiudi()))
      },
    })

    async function lavora(e: ReturnType<typeof creaEmettitore>) {
      const risposte: Anthropic.Messages.Message[] = []
      const scadenza = AbortSignal.timeout(120_000) // 120 s in tutto, dall'inizio del lavoro
      let concluso = false
      try {
        if (foto && prenotazione.foto_path) {
          const { error } = await servizio.storage.from('zorba-foto').upload(prenotazione.foto_path, decodeBase64(foto), { contentType: 'image/jpeg' })
          if (error) throw new Error(`foto: ${error.message}`)
        }
        // Il filo come lo vede Claude: messaggi in ordine, con le foto riscaricate dallo Storage
        const { data: righe } = await servizio.from('zorba_messaggi').select('id, ruolo, testo, esito, foto_path').eq('filo_id', filo.id).order('creato')
        const storia = []
        for (const m of righe ?? []) {
          if (m.id === messaggioZorba) continue
          let fotoBase64 = null
          if (m.foto_path) {
            const { data } = await servizio.storage.from('zorba-foto').download(m.foto_path)
            if (data) fotoBase64 = encodeBase64(new Uint8Array(await data.arrayBuffer()))
          }
          storia.push({ ruolo: m.ruolo, testo: m.testo, esito: m.esito, fotoBase64 })
        }
        const ultimaFoto = [...storia].reverse().find((m) => m.ruolo === 'utente')?.fotoBase64
        if (ultimaFoto && ['identifica_specie', 'diagnosi'].includes(filo.tipo!)) e.emetti('stato', { t: 'guardo la foto…' })
        const plantnet = ultimaFoto
          ? await riscontroPlantNet({ tipo: filo.tipo, fotoBytes: decodeBase64(ultimaFoto), chiave: env('PLANTNET_API_KEY'), fetch })
          : null
        let progetto = null
        if (filo.progetto_id) {
          const { data } = await db.from('progetti').select('id, titolo').eq('id', filo.progetto_id).maybeSingle()
          progetto = data
        }
        const messages = [...messaggiDalFilo(storia), { role: 'system', content: contestoSistema({ tipo: filo.tipo, nomeVoce: filo.nome_voce,
          voce: filo.voce, progetto, titoloProgetto: filo.titolo_progetto, plantnet }) }]

        const richiesta = {
          model: filo.modello, max_tokens: 8000, betas: ['server-side-fallback-2026-07-01'], fallbacks: 'default',
          thinking: { type: 'adaptive' }, output_config: { effort: 'medium' }, cache_control: { type: 'ephemeral' },
          system: [{ type: 'text', text: SISTEMA, cache_control: { type: 'ephemeral' } }],
          tools: DEFINIZIONI_STRUMENTI, messages,
        }
        const ctx = { db, filo: { ...filo }, adesso: new Date(), fetch,
          collegaProgetto: async (id: string) => { await servizio.from('zorba_fili').update({ progetto_id: id }).eq('id', filo.id) },
          emetti: (n: string, d: unknown) => e.emetti(n, d) }
        const esito = await eseguiCiclo({
          richiesta, emetti: (n: string, d: unknown) => e.emetti(n, d),
          eseguiStrumento: (nome: string, input: unknown) => eseguiStrumento(nome, input, ctx),
          chiama: async (params: Record<string, unknown>, hooks: { onTesto: (t: string) => void, onRipiego: () => void }) => {
            // deno-lint-ignore no-explicit-any
            const stream = anthropic.beta.messages.stream(params as any, { signal: scadenza })
            stream.on('text', (t: string) => hooks.onTesto(t))
            // deno-lint-ignore no-explicit-any
            stream.on('streamEvent', (ev: any) => { if (ev.type === 'content_block_start' && ev.content_block?.type === 'fallback') hooks.onRipiego() })
            let msg
            try {
              msg = await stream.finalMessage()
            } catch (err) {
              // Passaggio interrotto a metà: si conta l'uso parziale visto finora (BetaMessageStream.currentMessage)
              const parziale = stream.currentMessage
              if (parziale?.usage) risposte.push(parziale as unknown as Anthropic.Messages.Message)
              throw err
            }
            risposte.push(msg as Anthropic.Messages.Message)
            return msg
          },
        })
        const c = costoRisposte(risposte)
        if (esito.esito !== 'completata') e.emetti('annulla_testo', {})
        const fine = await rpc<{ stato_filo: string }>('zorba_concludi', { p_messaggio: messaggioZorba, p_esito: esito.esito,
          p_testo: esito.testo, p_strumenti: esito.strumenti, p_modello: c.modello, p_input: c.input, p_output: c.output,
          p_cache_lettura: c.cacheLettura, p_cache_scrittura: c.cacheScrittura, p_costo: c.costo })
        concluso = true
        if (esito.esito !== 'completata') {
          e.emetti('errore', { codice: esito.codice, messaggio: MESSAGGI_ERRORE[esito.codice] })
          return
        }
        let rimaste: unknown = null
        try {
          rimaste = (await rpc<Record<string, unknown>>('zorba_limiti', { p_owner: user.id, p_curatore: curatore, ...LIMITI() })).rimaste
        } catch (errL) { console.error('zorba', filo.id, 'limiti', String(errL)) }
        e.emetti('fine', { messaggio_id: messaggioZorba, rimaste, stato_filo: fine.stato_filo })
      } catch (err) {
        const testoErr = String((err as Error)?.message ?? err)
        console.error('zorba', filo.id, testoErr)
        if (concluso) return // risposta già salvata e conteggiata: niente secondo consumo né errore
        let codice = 'claude_non_disponibile'
        if ((err as Error)?.name === 'AbortError' || /aborted|timeout/i.test(testoErr)) codice = 'tempo_scaduto'
        else if (/credit|spend|billing|usage limit/i.test(testoErr)) codice = 'in_pausa_mese'
        else if (testoErr.startsWith('foto:')) codice = 'interno'
        const c = costoRisposte(risposte)
        await rpc('zorba_concludi', { p_messaggio: messaggioZorba, p_esito: 'errore', p_testo: null, p_strumenti: null, p_modello: c.modello,
          p_input: c.input, p_output: c.output, p_cache_lettura: c.cacheLettura, p_cache_scrittura: c.cacheScrittura, p_costo: c.costo }).catch(() => {})
        e.emetti('annulla_testo', {})
        e.emetti('errore', { codice, messaggio: MESSAGGI_ERRORE[codice] })
      }
    }

    return new Response(corpo, { headers: { ...CORS, 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache' } })
  } catch (e) {
    console.error('zorba', String(e))
    return errore(codiceDa(e), 500)
  }
})
