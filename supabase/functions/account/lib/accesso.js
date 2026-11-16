// Controlli della Edge Function `account`, senza dipendenze da Deno (provati con node --test).

// Quanto può essere vecchia la password riscritta per confermare l'eliminazione.
export const FINESTRA_SECONDI = 600

// Payload del JWT, già verificato da auth.getUser: qui serve solo leggere `amr`.
export function payload(jwt) {
  const parte = String(jwt ?? '').split('.')[1]
  if (!parte) return null
  try {
    const b64 = parte.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(parte.length / 4) * 4, '=')
    const byte = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0))
    return JSON.parse(new TextDecoder().decode(byte))
  } catch { return null }
}

// true se la sessione viene da un accesso con password negli ultimi FINESTRA_SECONDI: chi trova il telefono sbloccato
// con l'app aperta non può eliminare l'account senza conoscere la password. Supabase scrive in `amr` un elemento per
// metodo, con il momento dell'accesso in secondi; un rinnovo del token non lo cambia.
export function accessoRecente(dati, adessoMs = Date.now()) {
  const amr = Array.isArray(dati?.amr) ? dati.amr : []
  const limite = adessoMs / 1000 - FINESTRA_SECONDI
  return amr.some((m) => m?.method === 'password' && Number(m.timestamp) >= limite && Number(m.timestamp) <= adessoMs / 1000 + 60)
}

// File da cancellare raggruppati per bucket, a blocchi (l'API di Storage accetta al più 1000 percorsi per chiamata).
export function blocchiFile(righe, dimensione = 500) {
  const perBucket = new Map()
  for (const r of righe ?? []) {
    if (!perBucket.has(r.bucket)) perBucket.set(r.bucket, [])
    perBucket.get(r.bucket).push(r.percorso)
  }
  const blocchi = []
  for (const [bucket, percorsi] of perBucket) {
    for (let i = 0; i < percorsi.length; i += dimensione) blocchi.push({ bucket, percorsi: percorsi.slice(i, i + dimensione) })
  }
  return blocchi
}

export const MESSAGGI = {
  non_autenticato: 'La sessione è scaduta: esci, rientra e riprova.',
  accesso_vecchio: 'Per sicurezza riscrivi la password e riprova.',
  curatore: "L'account del curatore non si elimina dall'app.",
  interno: 'Qualcosa non ha funzionato e non ho eliminato l\'account: riprova tra poco.',
}
