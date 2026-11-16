// Edge Function `account`: DELETE elimina l'account di chi chiama, con tutto il suo giardino. Qui solo il collegamento
// (HTTP, autenticazione, Supabase); i controlli sono in lib/accesso.js, provati con node --test.
// Ordine: file dei bucket (se uno non si cancella ci si ferma prima di toccare i dati, e un nuovo tentativo riparte),
// tabelle del giardino in una transazione (account_elimina_dati), infine l'utente di Supabase Auth, la cui cascata
// toglie Zorba, consumi, abbonamento e righe della galleria. Se l'ultimo passo fallisce resta un account vuoto, che
// un nuovo tentativo elimina.
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'npm:@supabase/supabase-js@2'
import { payload, accessoRecente, blocchiFile, MESSAGGI } from './lib/accesso.js'

const env = (k: string) => Deno.env.get(k) ?? ''
const CURATORE = env('CURATORE_ID')

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'DELETE, OPTIONS',
}
const errore = (codice: keyof typeof MESSAGGI, status: number) =>
  new Response(JSON.stringify({ codice, messaggio: MESSAGGI[codice] }), { status, headers: { ...CORS, 'Content-Type': 'application/json' } })

const servizio = createClient(env('SUPABASE_URL'), env('SUPABASE_SERVICE_ROLE_KEY'), { auth: { persistSession: false } })

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })
  if (req.method !== 'DELETE') return errore('interno', 405)
  const jwt = req.headers.get('Authorization')?.replace(/^Bearer /, '') ?? ''
  try {
    const { data: { user } } = await servizio.auth.getUser(jwt)
    if (!user) return errore('non_autenticato', 401)
    if (CURATORE && user.id === CURATORE) return errore('curatore', 403)
    if (!accessoRecente(payload(jwt))) return errore('accesso_vecchio', 401)

    const { data: file, error: eFile } = await servizio.rpc('account_file', { p_owner: user.id })
    if (eFile) throw new Error(`file: ${eFile.message}`)
    for (const { bucket, percorsi } of blocchiFile(file)) {
      const { error } = await servizio.storage.from(bucket).remove(percorsi)
      if (error) throw new Error(`remove ${bucket}: ${error.message}`)
    }

    const { data: righe, error: eDati } = await servizio.rpc('account_elimina_dati', { p_owner: user.id })
    if (eDati) throw new Error(`dati: ${eDati.message}`)

    const { error: eUtente } = await servizio.auth.admin.deleteUser(user.id)
    if (eUtente) throw new Error(`utente: ${eUtente.message}`)

    console.log('account', 'eliminato', JSON.stringify({ file: file?.length ?? 0, righe }))
    return new Response(null, { status: 204, headers: CORS })
  } catch (e) {
    console.error('account', String((e as Error)?.message ?? e))
    return errore('interno', 500)
  }
})
