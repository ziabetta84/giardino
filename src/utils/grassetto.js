// Le risposte di Zorba sono testo semplice, ma alcune (le prime, e lo storico importato) hanno il grassetto in
// markdown (**così**). Il testo viene diviso in pezzi: quelli tra doppi asterischi diventano grassetto, il resto
// resta testo. Nessun HTML: il contenuto non viene mai interpretato come markup.
// Un ** senza chiusura (per esempio mentre Zorba sta ancora scrivendo) resta com'è.
export function pezziGrassetto(testo) {
  const pezzi = []
  const re = /\*\*(?=\S)([\s\S]*?\S)\*\*/g
  let ultimo = 0
  for (const m of String(testo ?? '').matchAll(re)) {
    if (m.index > ultimo) pezzi.push({ t: testo.slice(ultimo, m.index), b: false })
    pezzi.push({ t: m[1], b: true })
    ultimo = m.index + m[0].length
  }
  if (ultimo < String(testo ?? '').length) pezzi.push({ t: testo.slice(ultimo), b: false })
  return pezzi
}
