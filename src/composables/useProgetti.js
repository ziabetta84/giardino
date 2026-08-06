// Logica di scadenza delle tappe progetto: a differenza delle cure (che
// dipendono da specie/stagione), qui è solo un confronto tra la data della
// tappa e oggi — ma centralizzato comunque, così Attività e ProgettoView
// restano coerenti su cosa vuol dire "scaduta"/"in arrivo".

// La scadenza non è un campo a parte da tenere allineato a mano: è
// semplicemente la data dell'ultima tappa, l'unica fonte di verità sulla
// timeline del progetto. Nessuna tappa -> nessuna scadenza da mostrare.
export function scadenzaCalcolata(progetto) {
  const date = (progetto?.tappe || []).map(t => t.data).filter(Boolean).sort()
  return date.length ? date[date.length - 1] : null
}

export function statoTappa(tappa) {
  if (!tappa?.data || tappa.esito !== 'atteso') {
    return { urgente: false, giorni: null }
  }
  const oggi = new Date()
  oggi.setHours(0, 0, 0, 0)
  const data = new Date(tappa.data)
  const giorni = Math.round((data - oggi) / 86400000)
  return { urgente: giorni <= 0, giorni }
}

// Tutte le tappe "atteso" di tutti i progetti (non cancellati/completati/
// falliti), con l'id del progetto e il proprio indice nell'array tappe (per
// poterle aggiornare), pronte per essere filtrate/ordinate in Attività.
export function tappeAttese(progetti) {
  if (!progetti) return []
  const risultato = []
  for (const [progettoId, p] of Object.entries(progetti)) {
    if (p.stato === 'completato' || p.stato === 'cancellato' || p.stato === 'fallito') continue
    ;(p.tappe || []).forEach((tappa, indice) => {
      const { urgente, giorni } = statoTappa(tappa)
      if (giorni === null) return
      risultato.push({ progettoId, progettoTitolo: p.titolo, indice, tappa, urgente, giorni })
    })
  }
  return risultato
}
