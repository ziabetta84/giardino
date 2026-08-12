// Suggerimento del concime più adatto in base al rapporto N:P:K

function parseNPK(testo) {
  if (!testo) return null
  const m = testo.match(/^(\d+(?:\.\d+)?)-(\d+(?:\.\d+)?)-(\d+(?:\.\d+)?)$/)
  if (!m) return null
  return { n: parseFloat(m[1]), p: parseFloat(m[2]), k: parseFloat(m[3]) }
}

function normalizza({ n, p, k }) {
  const somma = n + p + k
  if (somma === 0) return { n: 0, p: 0, k: 0 }
  return { n: n / somma, p: p / somma, k: k / somma }
}

function distanza(a, b) {
  const na = normalizza(a), nb = normalizza(b)
  return Math.sqrt((na.n - nb.n) ** 2 + (na.p - nb.p) ** 2 + (na.k - nb.k) ** 2)
}

const SOGLIA_DISTANZA = 0.15

export function concimeConsigliato(npkRichiestoTesto, concimi) {
  const richiesto = parseNPK(npkRichiestoTesto)
  if (!richiesto || !concimi || !Object.keys(concimi).length) return null

  let migliore = null
  for (const [id, c] of Object.entries(concimi)) {
    if (!c.npk) continue
    const d = distanza(richiesto, c.npk)
    if (!migliore || d < migliore.distanza) migliore = { id, ...c, distanza: d }
  }
  if (!migliore || migliore.distanza > SOGLIA_DISTANZA) return null
  return migliore
}

// Classifica i concimi in dispensa per copertura reale: per ogni pianta con
// un fabbisogno NPK nella stagione data, trova il concime che lo copre
// meglio (stessa logica di concimeConsigliato, usata anche in Attività) e
// conta quante piante ciascun concime "vince". Non è un punteggio astratto
// sul concime in sé: riflette solo cosa serve davvero alle piante che hai.
export function classificaConcimi(piante, specie, concimi, stagioneCorrente) {
  if (!piante || !concimi || !Object.keys(concimi).length) return []

  const copertura = {}
  for (const id of Object.keys(concimi)) copertura[id] = 0

  for (const p of Object.values(piante)) {
    const npkRichiesto = specie?.[p.specie]?.manutenzione?.npk?.[stagioneCorrente]
    const migliore = concimeConsigliato(npkRichiesto, concimi)
    if (migliore) copertura[migliore.id] = (copertura[migliore.id] ?? 0) + 1
  }

  return Object.entries(concimi)
    .map(([id, c]) => ({ id, ...c, copertura: copertura[id] ?? 0 }))
    .sort((a, b) => b.copertura - a.copertura)
}
