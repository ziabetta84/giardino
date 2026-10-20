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
  return { titolo, autore: immagine.attribuzione ?? null, licenza, pagina: immagine.fonte_pagina ?? null, licenzaUrl: immagine.licenza_url ?? null }
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
