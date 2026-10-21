// Riscontro automatico sulla foto, chiamato prima di Claude (il riscontro oggettivo arriva prima del giudizio, non
// dopo come timbro). Restituisce una riga di testo per il messaggio di sistema, o null: un fallimento non blocca mai.
const SOGLIA = 0.2
const pct = (s) => `${Math.round(s * 100)}%`

export async function riscontroPlantNet({ tipo, fotoBytes, chiave, fetch }) {
  if (!chiave || !fotoBytes || !['identifica_specie', 'diagnosi'].includes(tipo)) return null
  try {
    const form = new FormData()
    const foto = new Blob([fotoBytes], { type: 'image/jpeg' })
    let url
    if (tipo === 'identifica_specie') {
      url = `https://my-api.plantnet.org/v2/identify/all?api-key=${encodeURIComponent(chiave)}&lang=it&nb-results=5&type=kt`
      form.append('images', foto, 'foto.jpg')
    } else {
      url = `https://my-api.plantnet.org/v2/diseases/identify?api-key=${encodeURIComponent(chiave)}&lang=it`
      form.append('image', foto, 'foto.jpg')
    }
    form.append('organs', 'auto')
    const r = await fetch(url, { method: 'POST', body: form, signal: AbortSignal.timeout(15000) })
    if (!r.ok) return null
    const risultati = ((await r.json()).results ?? []).filter(x => x.score >= SOGLIA).slice(0, 5)
    if (!risultati.length) return null
    if (tipo === 'identifica_specie') return `candidati: ${risultati.map(x => `${x.species.scientificNameWithoutAuthor} (${pct(x.score)})`).join(', ')}`
    return `possibili problemi: ${risultati.map(x => `${x.description ?? x.name} (${pct(x.score)})`).join(', ')}`
  } catch {
    return null
  }
}
