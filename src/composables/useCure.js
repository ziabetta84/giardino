// Logica valutazione cure (irrigazione, concimazione, potatura)

const STAGIONE_MESI = {
  primavera: [3,4,5],
  estate:    [6,7,8],
  autunno:   [9,10,11],
  inverno:   [12,1,2],
}

export function stagione(data = new Date()) {
  const mese = data.getMonth() + 1
  return Object.entries(STAGIONE_MESI).find(([,mesi]) => mesi.includes(mese))?.[0] ?? 'estate'
}

function parseGiorni(testo) {
  if (!testo) return null
  const match = testo.match(/(\d+)/)
  return match ? parseInt(match[1]) : null
}

// Pioggia cumulata (oggi + domani) considerata sufficiente da sostituire un'irrigazione manuale
const SOGLIA_PIOGGIA_MM = 5

function pioggiaInArrivo(meteoGiorni) {
  if (!Array.isArray(meteoGiorni) || !meteoGiorni.length) return false
  const cumulata = meteoGiorni.slice(0, 2).reduce((tot, g) => tot + (parseFloat(g.pioggia) || 0), 0)
  return cumulata >= SOGLIA_PIOGGIA_MM
}

export function valutaCura(pianta, specie, tipo, contesto = {}) {
  const stagCorrente = stagione()
  const manutenzione = specie?.manutenzione?.[tipo]?.[stagCorrente]
  if (!manutenzione || manutenzione === 'mai' || manutenzione === 'non necessario') {
    return { urgente: false, label: null, giorni: null }
  }

  const intervallo = parseGiorni(manutenzione)
  const ultimaStr  = pianta?.ultima_cura?.[tipo]
  if (!intervallo) return { urgente: false, label: manutenzione, giorni: null }

  if (tipo === 'irrigazione' && contesto.esterno && pioggiaInArrivo(contesto.meteo)) {
    return { urgente: false, label: 'irrigazione — pioggia prevista, salta', giorni: null }
  }

  if (!ultimaStr) {
    return { urgente: true, label: `${tipo} — mai registrata`, giorni: Infinity }
  }

  const ultima     = new Date(ultimaStr)
  const oggi       = new Date()
  const trascorsi  = Math.floor((oggi - ultima) / 86400000)
  const rimanenti  = intervallo - trascorsi
  const urgente    = rimanenti <= 0

  return {
    urgente,
    label: urgente
      ? `${tipo} — scaduta ${Math.abs(rimanenti)} gg fa`
      : `${tipo} — tra ${rimanenti} gg`,
    giorni: rimanenti,
    intervallo,
    trascorsi,
  }
}

export function cureUrgentiPianta(pianta, specie, contesto) {
  return ['irrigazione','concimazione','potatura','calcio']
    .map(tipo => ({ tipo, ...valutaCura(pianta, specie, tipo, contesto) }))
    .filter(c => c.urgente)
}
