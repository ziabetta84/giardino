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
