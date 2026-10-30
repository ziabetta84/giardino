// Logica pura del catalogo (fase 6 del modello tassonomico): chiavi delle voci, credito delle foto, livelli
// dell'eredità. Una voce è un taxon (chiave "t:<uuid>") o una cultivar ("c:<uuid>"), calcolata nel database
// (funzioni catalogo_* della migration 20261021100000).

export function chiavePianta(riga) {
  if (riga?.cultivar_id) return `c:${riga.cultivar_id}`
  if (riga?.taxon_id) return `t:${riga.taxon_id}`
  return null
}

export function colonneDaChiave(chiave) {
  const [tipo, id] = String(chiave ?? '').split(':')
  if (!id) return null
  if (tipo === 't') return { taxon_id: id, cultivar_id: null }
  if (tipo === 'c') return { taxon_id: null, cultivar_id: id }
  return null
}

// Prima parte dell'id delle piante nuove ("slug-timestamp", come sempre: la galleria usa l'id come cartella)
export function slugDaNome(testo) {
  const slug = String(testo ?? '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()
    .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '')
  return slug || 'pianta'
}

// Attribuzione richiesta dalle licenze Creative Commons (TASL): autore, pagina del file, licenza; il titolo del file
// solo per le licenze fino alla 3.0, che lo chiedono. La fonte (il sito) non si nomina.
export function creditoFoto(immagine) {
  if (!immagine?.url) return null
  const licenza = immagine.licenza ?? null
  const versione = Number(/(\d+(?:\.\d+)?)\s*$/.exec(licenza ?? '')?.[1])
  let titolo = null
  if (versione && versione <= 3 && immagine.fonte_pagina) {
    const file = decodeURIComponent(immagine.fonte_pagina.split('/').pop() ?? '').replace(/^File:/, '')
    titolo = file.replace(/\.[a-z0-9]+$/i, '').replace(/_/g, ' ') || null
  }
  return { titolo, autore: autoreFoto(immagine.attribuzione), licenza, pagina: immagine.fonte_pagina ?? null, licenzaUrl: immagine.licenza_url ?? null }
}

// Alcune attribuzioni importate sono il nome del sito, un paragrafo di istruzioni o HTML: l'autore si mostra solo se
// è un nome leggibile, mai una fonte (la pagina del file resta comunque collegata al credito).
const ENTITA = { '&amp;': '&', '&quot;': '"', '&#39;': "'", '&apos;': "'", '&lt;': '<', '&gt;': '>', '&nbsp;': ' ' }
function autoreFoto(testo) {
  if (!testo) return null
  const pulito = String(testo).replace(/<[^>]*>/g, '').replace(/&(amp|quot|#39|apos|lt|gt|nbsp);/g, m => ENTITA[m])
    .replace(/\s+/g, ' ').trim()
  if (!pulito || pulito.length > 80 || /wiki|commons|flickr/i.test(pulito)) return null
  return pulito
}

const PREPOSIZIONI = {
  genus: 'del genere', subgenus: 'del sottogenere', 'section botany': 'della sezione', species: 'della specie',
  'species aggregate': 'dell\'aggregato', subspecies: 'della sottospecie', variety: 'della varietà',
  subvariety: 'della sottovarietà', form: 'della forma', subform: 'della sottoforma', grex: 'del grex',
  cultivar: 'della cultivar', gruppo: 'del gruppo',
}

export function etichettaLivello(livello) {
  if (!livello?.nome) return ''
  return `${PREPOSIZIONI[livello.rango] ?? 'di'} ${livello.nome}`
}

// Una pianta collegata a una cultivar ha già la varietà nel nome: non si ripete quella scritta a mano
export function varietaNelTitolo(voce, varieta) {
  return voce?.tipo === 'cultivar' ? '' : (varieta || '')
}

// I risultati di cerca_catalogo portano «via» (il nome o il sinonimo con cui la voce è stata trovata): vale solo per
// quella ricerca, quindi nello store le voci entrano senza, e «via» resta accanto, per chiave.
export function separaVia(risultati) {
  const voci = {}, via = {}
  for (const { via: v, via_botanico, ...voce } of risultati ?? []) {
    voci[voce.chiave] = voce
    if (v) via[voce.chiave] = { via: v, via_botanico: !!via_botanico }
  }
  return { voci, via }
}

// La foto da mostrare per una voce. Una foto ereditata da un genere o da un livello più alto ritrae un'altra specie:
// se la voce ha una forma, si mostra il disegno di quella forma (utils/forme.js), che dice solo ciò che è vero per la
// pianta. La foto della specie per sottospecie, varietà e cultivar resta. Senza forma si tiene la foto, anche ereditata.
const SOPRA_LA_SPECIE = new Set(['species aggregate', 'section botany', 'subgenus', 'genus', 'subtribe', 'tribe', 'subfamily',
  'family', 'superorder', 'order', 'subclass', 'class', 'subphylum', 'phylum', 'subkingdom', 'kingdom', 'domain'])
export function fotoVoce(voce) {
  const immagine = voce?.immagine
  if (!immagine?.url) return null
  return voce.forma && SOPRA_LA_SPECIE.has(voce.livelli?.immagine?.rango) ? null : immagine
}

// Stato da mostrare nel badge: una voce senza nessun campo di scheda (nemmeno ereditato) non è una bozza, è «senza
// scheda»; lo stesso criterio ordina i risultati della ricerca nel database (cerca_catalogo).
const CAMPI_SCHEDA = ['descrizione', 'esigenze', 'manutenzione', 'coltivazione', 'ciclo_vitale', 'vaso', 'alert', 'immagine']
export function statoVoce(voce) {
  if (!voce || !CAMPI_SCHEDA.some(c => c in voce)) return 'senza scheda'
  return voce.stato_verifica === 'verificato' ? 'verificata' : 'bozza'
}
