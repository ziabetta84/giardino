// Logica valutazione cure (irrigazione, concimazione, calcio; potatura solo come etichetta)

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

// Riconosce l'unità dopo il numero (giorni/settimane/mesi): senza questo
// controllo un testo come "ogni 2 settimane" veniva letto come "ogni 2
// giorni", segnalando la cura scaduta quasi ogni giorno invece che ogni due
// settimane. In un range ("ogni 2-3 settimane") prende il primo numero,
// come già avviene per i range in giorni.
export function parseGiorni(testo) {
  if (!testo) return null
  const match = testo.match(/(\d+)(?:-\d+)?\s*(settiman\w*|mes[ei]\b|giorn\w*)?/i)
  if (!match) return null
  const numero = parseInt(match[1], 10)
  const unita = (match[2] || '').toLowerCase()
  if (unita.startsWith('settiman')) return numero * 7
  if (unita.startsWith('mes')) return numero * 30
  return numero
}

// Pioggia cumulata (oggi + domani) considerata sufficiente da sostituire un'irrigazione manuale.
// Esportate (non solo interne): MeteoView.vue le riusa per mostrare lo stesso
// segnale "irrigazione sospesa" con lo stesso criterio, invece di un avviso
// meteo scollegato con una soglia diversa.
export const SOGLIA_PIOGGIA_MM = 5

export function pioggiaCumulata2gg(meteoGiorni) {
  if (!Array.isArray(meteoGiorni) || !meteoGiorni.length) return 0
  return meteoGiorni.slice(0, 2).reduce((tot, g) => tot + (parseFloat(g.pioggia) || 0), 0)
}

export function pioggiaInArrivo(meteoGiorni) {
  return pioggiaCumulata2gg(meteoGiorni) >= SOGLIA_PIOGGIA_MM
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

  if (tipo === 'irrigazione' && pianta?.coltivato_in !== 'acqua' && contesto.esterno && pioggiaInArrivo(contesto.meteo)) {
    return { urgente: false, label: 'irrigazione — pioggia prevista, salta', giorni: null }
  }

  if (!ultimaStr) {
    // La potatura resta chiamabile (la scheda pianta mostra "ultima: N gg fa")
    // ma non è mai urgente: nessuna cadenza temporale da rispettare.
    return { urgente: tipo !== 'potatura', label: `${tipo} — mai registrata`, giorni: Infinity }
  }

  const ultima     = new Date(ultimaStr)
  const oggi       = new Date()
  const trascorsi  = Math.floor((oggi - ultima) / 86400000)
  const rimanenti  = intervallo - trascorsi
  const urgente    = tipo !== 'potatura' && rimanenti <= 0

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
  // La potatura non ha cadenza temporale: è un'etichetta testuale,
  // registrabile per pianta ma mai valutata per urgenza né mostrata nei
  // feed "attività". I tipi con cadenza sono irrigazione, concimazione e
  // (per le specie con beneficio documentato) calcio.
  const tipi = ['irrigazione', 'concimazione']
  if (specie?.manutenzione?.calcio) tipi.push('calcio')
  return tipi
    .map(tipo => ({ tipo, ...valutaCura(pianta, specie, tipo, contesto) }))
    .filter(c => c.urgente)
}
