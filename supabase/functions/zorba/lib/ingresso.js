// Validazione del corpo di POST /zorba prima di qualsiasi costo (spec, "Passi", punto 2). I controlli che richiedono
// il database (filo dell'utente, progetto suo, voce esistente) li fanno la funzione e zorba_prenota.
export const TIPI = ['identifica_specie', 'segnalazione_scheda', 'consiglio_cura', 'consiglio_concimazione', 'diagnosi', 'pianifica_progetto', 'altro']
export const MAX_TESTO = 4000
export const MAX_FOTO_BYTES = 1_572_864
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
const VOCE = /^[tc]:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

const no = (codice) => ({ ok: false, codice })

function byteBase64(b64) {
  const pad = b64.endsWith('==') ? 2 : b64.endsWith('=') ? 1 : 0
  return Math.floor(b64.length * 3 / 4) - pad
}

function eJpeg(b64) {
  try {
    const testa = atob(b64.slice(0, 8))
    return testa.charCodeAt(0) === 0xff && testa.charCodeAt(1) === 0xd8 && testa.charCodeAt(2) === 0xff
  } catch {
    return false
  }
}

export function validaRichiesta(corpo) {
  if (!corpo || typeof corpo !== 'object') return no('richiesta_non_valida')
  const testo = typeof corpo.testo === 'string' ? corpo.testo.trim() : ''
  const foto = typeof corpo.foto === 'string' && corpo.foto ? corpo.foto : null
  const riprova = corpo.riprova === true
  if (testo.length > MAX_TESTO) return no('testo_troppo_lungo')
  if (foto) {
    if (!/^[A-Za-z0-9+/]+={0,2}$/.test(foto)) return no('foto_non_valida')
    if (foto.length % 4 !== 0) return no('foto_non_valida')
    if (byteBase64(foto) > MAX_FOTO_BYTES) return no('foto_troppo_grande')
    if (!eJpeg(foto)) return no('foto_non_valida')
  }
  if (corpo.filo_id != null) {
    if (typeof corpo.filo_id !== 'string' || !UUID.test(corpo.filo_id) || corpo.nuovo !== undefined) return no('richiesta_non_valida')
    if (riprova) return { ok: true, valore: { filoId: corpo.filo_id, nuovo: null, testo: '', foto: null, riprova: true } }
    if (!testo && !foto) return no('testo_mancante')
    return { ok: true, valore: { filoId: corpo.filo_id, nuovo: null, testo, foto, riprova: false } }
  }
  const n = corpo.nuovo
  if (riprova || !n || !TIPI.includes(n.tipo)) return no('richiesta_non_valida')
  const nuovo = { tipo: n.tipo, voce: null, nome_voce: null, progetto_id: null, titolo_progetto: null }
  if (n.tipo === 'segnalazione_scheda') {
    if (typeof n.voce !== 'string' || !VOCE.test(n.voce)) return no('richiesta_non_valida')
    nuovo.voce = n.voce
    nuovo.nome_voce = typeof n.nome_voce === 'string' ? n.nome_voce.slice(0, 200) : null
    if (!testo) return no('testo_mancante')
  } else if (n.tipo === 'pianifica_progetto') {
    if (n.progetto_id) {
      if (typeof n.progetto_id !== 'string' || !UUID.test(n.progetto_id)) return no('richiesta_non_valida')
      nuovo.progetto_id = n.progetto_id
    } else if (typeof n.titolo_progetto === 'string' && n.titolo_progetto.trim()) {
      nuovo.titolo_progetto = n.titolo_progetto.trim().slice(0, 200)
    } else return no('richiesta_non_valida')
    if (!testo) return no('testo_mancante')
  } else if (n.tipo === 'identifica_specie') {
    if (!foto) return no('foto_mancante')
  } else if (n.tipo === 'diagnosi') {
    if (!foto && !testo) return no('testo_mancante')
  } else if (!testo) return no('testo_mancante')
  return { ok: true, valore: { filoId: null, nuovo, testo, foto, riprova: false } }
}
