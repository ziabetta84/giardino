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

// Un nutriente non specificato (null, es. concime fatto in casa mai testato)
// resta "N/D": va distinto da uno zero reale ("0-10-10" è un dato valido),
// che altrimenti si leggerebbe come "non contiene nutrienti" (vedi critica
// del 07/09/2026).
export function formattaNPK(npk) {
  if (!npk || (npk.n == null && npk.p == null && npk.k == null)) return 'N/D'
  const parte = v => (v == null ? '–' : v)
  return `${parte(npk.n)}-${parte(npk.p)}-${parte(npk.k)}`
}

// Esportata perché ConcimiView.vue la riusa per costruire "Adatto per" dalla
// classifica completa invece che dal solo vincitore (vedi critica del
// 07/09/2026): un'unica soglia condivisa, non due copie dello stesso 0.15.
export const SOGLIA_DISTANZA = 0.15

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

// Classifica tutti i concimi in dispensa dal più al meno adatto per UN
// fabbisogno NPK specifico (una pianta, una stagione) — a differenza di
// concimeConsigliato(), che restituisce solo il migliore (o niente, se
// nessuno è abbastanza vicino), qui vogliamo l'intero ordinamento per
// mostrarlo nella scheda della pianta.
export function classificaConcimiPerFabbisogno(npkRichiestoTesto, concimi) {
  const richiesto = parseNPK(npkRichiestoTesto)
  if (!richiesto || !concimi) return []
  return Object.entries(concimi)
    .filter(([, c]) => c.npk)
    .map(([id, c]) => ({ id, ...c, distanza: distanza(richiesto, c.npk) }))
    .sort((a, b) => a.distanza - b.distanza)
}
