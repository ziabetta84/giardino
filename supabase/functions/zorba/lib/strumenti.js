import { valutaCura, tipiCuraPianta } from '../condivisi/cure.js'
import { concimeConsigliato, classificaConcimiPerFabbisogno, SOGLIA_DISTANZA } from '../condivisi/concimi.js'
import { stagioneRoma } from '../condivisi/date.js'

// Strumenti di Zorba. Elenco sempre uguale e nello stesso ordine per tutti i tipi: cambiarlo invaliderebbe la cache del
// prompt. salva_piano si rifiuta a runtime fuori dai fili pianifica_progetto. Le letture passano dal client con il JWT
// dell'utente: Zorba vede esattamente ciò che vede l'utente.
const oggetto = (properties, required = Object.keys(properties)) => ({ type: 'object', properties, required, additionalProperties: false })

export const DEFINIZIONI_STRUMENTI = [
  { name: 'piante_giardino', strict: true, description: 'Elenco compatto delle piante del giardino dell\'utente: id, nome, zona, sottozona, coltivazione (vaso/terra/acqua). Da usare per trovare la pianta di cui parla l\'utente.', input_schema: oggetto({}) },
  { name: 'pianta', strict: true, description: 'Scheda completa di una pianta dell\'utente: voce del catalogo (esigenze, manutenzione, avvisi), zona, note e stato di ogni cura (ultima volta, giorni trascorsi, se è in ritardo).', input_schema: oggetto({ id: { type: 'string', description: 'id della pianta da piante_giardino' } }) },
  { name: 'cerca_catalogo', strict: true, description: 'Cerca nel catalogo delle piante per nome comune o scientifico. Restituisce le voci più pertinenti con chiave, nome, nome scientifico e NPK per stagione.', input_schema: oggetto({ testo: { type: 'string' } }) },
  { name: 'consiglia_concime', strict: true, description: 'Confronta il fabbisogno NPK della pianta nella stagione corrente con i concimi in dispensa, con lo stesso criterio dell\'app. Usalo sempre per i consigli di concimazione invece di calcolare a mano.', input_schema: oggetto({ pianta_id: { type: 'string' } }) },
  { name: 'meteo', strict: true, description: 'Meteo attuale e previsioni a 7 giorni per la posizione del giardino.', input_schema: oggetto({}) },
  { name: 'progetti', strict: true, description: 'Progetti dell\'utente con le loro tappe.', input_schema: oggetto({}) },
  { name: 'conversazioni_precedenti', strict: true, description: 'Fili precedenti dell\'utente che contengono le parole cercate (al più 5): data, tipo, estratto della domanda e della risposta. Utile per riprendere un problema già visto.', input_schema: oggetto({ testo: { type: 'string', description: 'parole da cercare, per esempio il nome della pianta' } }) },
  { name: 'salva_piano', strict: true, description: 'Solo nei fili pianifica_progetto: salva nel progetto del filo (o crea quello nuovo) le tappe nuove e gli esiti aggiornati di tappe esistenti. Descrizione in HTML semplice (p, b, i). Una sola chiamata con tutto il piano.', input_schema: oggetto({
    descrizione: { type: ['string', 'null'], description: 'HTML con soli <p>, <b>, <i>; viene scritta solo se il progetto è nuovo o senza descrizione' },
    zona: { type: ['string', 'null'] },
    tappe: { type: 'array', items: oggetto({ data: { type: 'string', description: 'YYYY-MM-DD' }, descrizione: { type: 'string' }, esito: { type: 'string', enum: ['atteso', 'riuscito', 'fallito', 'saltato'] } }) },
    esiti: { type: 'array', items: oggetto({ id: { type: 'string' }, esito: { type: 'string', enum: ['atteso', 'riuscito', 'fallito', 'saltato'] } }) },
  }) },
]

export const ETICHETTE_STATO = {
  piante_giardino: 'do un\'occhiata al giardino…',
  pianta: 'controllo la scheda e le cure registrate…',
  cerca_catalogo: 'sfoglio il catalogo…',
  consiglia_concime: 'guardo cosa c\'è in dispensa…',
  meteo: 'sbircio il meteo…',
  progetti: 'ripasso i tuoi progetti…',
  conversazioni_precedenti: 'ripenso alle nostre chiacchierate…',
  salva_piano: 'scrivo le tappe nel progetto…',
}

const TAG_AMMESSI = new Set(['p', 'b', 'strong', 'i', 'em'])
// La descrizione dei progetti è mostrata come HTML: passa solo la formattazione minima, senza attributi. Contenuto di
// script e style tolto insieme ai tag.
export function pulisciHtml(html) {
  return String(html ?? '')
    .replace(/[\uE000\uE001]/g, '')
    .replace(/<(script|style)\b[^>]*>[\s\S]*?<\/\1>/gi, '')
    // tag ammessi: via gli attributi, minuscolo
    .replace(/<(\/?)(p|b|strong|i|em)\b[^<>]*>/gi, (_, c, n) => `\uE000${c}${n.toLowerCase()}\uE001`)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/(\/?)(p|b|strong|i|em)/g, '<$1$2>')
}

// Stessa precedenza di useIrrigazioneAuto.js: pianta, poi sottozona, poi zona, poi giardino.
export function programmaPerPianta(righe, pianta) {
  const r = righe.find(x => x.pianta_id && x.pianta_id === pianta.id)
    ?? righe.find(x => !x.pianta_id && x.sottozona_id && x.sottozona_id === pianta.sottozona_id)
    ?? righe.find(x => !x.pianta_id && !x.sottozona_id && x.zona_id && x.zona_id === pianta.zona_id)
    ?? righe.find(x => !x.pianta_id && !x.sottozona_id && !x.zona_id)
  return r?.ogni_giorni ?? null
}

const chiave = (p) => p.cultivar_id ? `c:${p.cultivar_id}` : (p.taxon_id ? `t:${p.taxon_id}` : null)
const ok = (dati) => ({ contenuto: JSON.stringify(dati), errore: false })
const ko = (msg) => ({ contenuto: msg, errore: true })
function controlla({ data, error }) { if (error) throw new Error(error.message); return data }

async function voci(db, chiavi) {
  const valide = chiavi.filter(Boolean)
  if (!valide.length) return {}
  return controlla(await db.rpc('catalogo_voci', { chiavi: valide })) ?? {}
}

const ESEGUI = {
  async piante_giardino(_, { db }) {
    const piante = controlla(await db.from('piante').select('id, taxon_id, cultivar_id, coltivato_in, zone(nome), sottozone(nome)'))
    const v = await voci(db, piante.map(chiave))
    return piante.map(p => ({ id: p.id, nome: v[chiave(p)]?.nome ?? null, zona: p.zone?.nome ?? null, sottozona: p.sottozone?.nome ?? null, coltivato_in: p.coltivato_in }))
  },
  async pianta({ id }, { db }) {
    const p = controlla(await db.from('piante').select('*, zone(nome), sottozone(nome)').eq('id', id).maybeSingle())
    if (!p) throw new Error('pianta non trovata')
    const voce = (await voci(db, [chiave(p)]))[chiave(p)] ?? {}
    const programmi = controlla(await db.from('programmi_irrigazione').select('pianta_id, zona_id, sottozona_id, ogni_giorni'))
    const programma = programmaPerPianta(programmi, p)
    const cure = [...tipiCuraPianta(p, voce), 'potatura'].map(tipo => {
      const v = valutaCura(p, voce, tipo, { programmaAutomatico: tipo === 'irrigazione' ? programma : null })
      return { tipo, ultima: p.ultima_cura?.[tipo] ?? null, giorni_trascorsi: Number.isFinite(v.trascorsi) ? v.trascorsi : null, in_ritardo: v.urgente, stato: v.label }
    })
    return { id: p.id, nome: voce.nome ?? null, nome_scientifico: voce.specie ?? null, zona: p.zone?.nome ?? null, sottozona: p.sottozone?.nome ?? null,
      coltivato_in: p.coltivato_in, varieta: p.varieta, impianto: p.impianto ?? p.impianto_circa, note: p.note,
      voce: { descrizione: voce.descrizione, esigenze: voce.esigenze, manutenzione: voce.manutenzione, coltivazione: voce.coltivazione,
        vaso: voce.vaso, alert: voce.alert, livelli: voce.livelli }, cure }
  },
  async cerca_catalogo({ testo }, { db }) {
    const risultati = controlla(await db.rpc('cerca_catalogo', { q: testo })) ?? []
    return risultati.slice(0, 8).map(v => ({ chiave: v.chiave, nome: v.nome, nome_scientifico: v.specie, npk: v.manutenzione?.npk ?? null }))
  },
  async consiglia_concime({ pianta_id }, { db, adesso }) {
    const p = controlla(await db.from('piante').select('id, taxon_id, cultivar_id').eq('id', pianta_id).maybeSingle())
    if (!p) throw new Error('pianta non trovata')
    const voce = (await voci(db, [chiave(p)]))[chiave(p)] ?? {}
    const stagione = stagioneRoma(adesso)
    const fabbisogno = voce.manutenzione?.npk?.[stagione] ?? null
    const righe = controlla(await db.from('concimi').select('id, nome, npk, disponibile').eq('disponibile', true))
    const dispensa = Object.fromEntries(righe.map(c => [c.id, { nome: c.nome, npk: c.npk }]))
    const migliore = concimeConsigliato(fabbisogno, dispensa)
    return { pianta: voce.nome ?? null, stagione, fabbisogno, soglia: SOGLIA_DISTANZA,
      consigliato: migliore ? { nome: migliore.nome, npk: migliore.npk, distanza: Number(migliore.distanza.toFixed(3)) } : null,
      classifica: classificaConcimiPerFabbisogno(fabbisogno, dispensa).slice(0, 3).map(c => ({ nome: c.nome, npk: c.npk, distanza: Number(c.distanza.toFixed(3)) })),
      dispensa_vuota: righe.length === 0 }
  },
  async meteo(_, { db, fetch }) {
    const s = controlla(await db.from('settings').select('location').maybeSingle())
    // Senza posizione nessun meteo di un altro posto (prima ripiegava su Fano): Zorba lo dice e chiede dove si trova il giardino.
    if (s?.location?.lat == null || s?.location?.lon == null) return { posizione_mancante: true, nota: "L'utente non ha ancora impostato la posizione del giardino (Impostazioni giardino): nessun meteo disponibile." }
    const lat = s.location.lat, lon = s.location.lon
    const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max,et0_fao_evapotranspiration&forecast_days=7&timezone=Europe%2FRome`
    const r = await fetch(url)
    if (!r.ok) throw new Error(`meteo ${r.status}`)
    const j = await r.json()
    return { adesso: j.current, giorni: j.daily.time.map((t, i) => ({ data: t, max: j.daily.temperature_2m_max[i], min: j.daily.temperature_2m_min[i],
      pioggia_mm: j.daily.precipitation_sum[i], vento_max: j.daily.wind_speed_10m_max[i], et0: j.daily.et0_fao_evapotranspiration[i] })) }
  },
  async progetti(_, { db }) {
    return controlla(await db.from('progetti').select('id, titolo, descrizione, zona, stato, creato, tappe(id, data, descrizione, esito)').order('creato', { ascending: false }))
  },
  async conversazioni_precedenti({ testo }, { db, filo }) {
    const parole = String(testo).replace(/[%_\\]/g, ' ').trim().slice(0, 100)
    if (parole.length < 3) return []
    let q = db.from('zorba_messaggi').select('filo_id, creato').ilike('testo', `%${parole}%`)
    if (filo.id) q = q.neq('filo_id', filo.id)
    const righe = controlla(await q.order('creato', { ascending: false }).limit(20))
    const ids = []
    for (const r of righe) {
      if (r.filo_id === filo.id || ids.includes(r.filo_id)) continue
      ids.push(r.filo_id)
      if (ids.length === 5) break
    }
    if (!ids.length) return []
    const fili = controlla(await db.from('zorba_fili').select('id, tipo, creato, zorba_messaggi(ruolo, testo, esito, creato)').in('id', ids))
    const perId = new Map(fili.map(f => [f.id, f]))
    return ids.filter(id => perId.has(id)).map(id => {
      const f = perId.get(id)
      const msg = [...(f.zorba_messaggi ?? [])].sort((x, y) => String(x.creato).localeCompare(String(y.creato)))
      const domanda = msg.find(m => m.ruolo === 'utente' && m.testo)
      const risposta = msg.find(m => m.ruolo === 'zorba' && m.esito === 'completata')
      return { filo_id: id, data: String(f.creato ?? '').slice(0, 10), tipo: f.tipo, domanda: domanda?.testo?.slice(0, 300) ?? null, risposta: risposta?.testo?.slice(0, 300) ?? null }
    })
  },
  async salva_piano({ descrizione, zona, tappe, esiti }, ctx) {
    if (ctx.filo.tipo !== 'pianifica_progetto') throw new Error('salva_piano si usa solo nei fili pianifica_progetto')
    const pid = controlla(await ctx.db.rpc('zorba_salva_piano', {
      p_progetto: ctx.filo.progetto_id, p_titolo: ctx.filo.titolo_progetto,
      p_descrizione: descrizione ? pulisciHtml(descrizione) : null, p_zona: zona, p_tappe: tappe, p_esiti: esiti }))
    if (!ctx.filo.progetto_id) { await ctx.collegaProgetto(pid); ctx.filo.progetto_id = pid }
    const p = controlla(await ctx.db.from('progetti').select('id, titolo').eq('id', pid).maybeSingle())
    ctx.emetti('progetto', { id: pid, titolo: p?.titolo ?? ctx.filo.titolo_progetto })
    return { progetto_id: pid, tappe_aggiunte: tappe.length, esiti_aggiornati: esiti.length }
  },
}

export async function eseguiStrumento(nome, input, ctx) {
  const f = ESEGUI[nome]
  if (!f) return ko(`strumento sconosciuto: ${nome}`)
  try { return ok(await f(input ?? {}, ctx)) } catch (e) { return ko(String(e?.message ?? e)) }
}
