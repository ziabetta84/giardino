// Logica valutazione cure (irrigazione, concimazione, calcio; potatura solo come etichetta)

// Stagioni meteorologiche per mese intero, tarate sull'emisfero nord/calendario
// italiano — coerente con la stessa scelta di scope già dichiarata in
// useZonaClimatica.js (euristica calibrata sulla sola penisola italiana). Non
// un'assunzione dimenticata: finché l'app resta pensata per giardini italiani,
// generalizzare solo qui per un ipotetico utente nell'emisfero sud servirebbe
// a poco, dato che il resto dell'app (zona climatica) non lo supporterebbe comunque.
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

// Pioggia già caduta (23/11/2026): dopo giorni di pioggia le piante all'aperto
// risultavano ancora «da irrigare» da settimane, perché contava solo la pioggia
// prevista per oggi e domani. Ora un giorno passato con almeno
// SOGLIA_PIOGGIA_MM di pioggia vale come un'irrigazione per le piante
// all'aperto: la cadenza riparte da quel giorno. Non si scrive nulla in
// ultima_cura (la decisione del 09/09/2026 resta: niente registrazioni
// permanenti dal meteo), si calcola a ogni apertura dai giorni passati di
// Open-Meteo (past_days). giorniPassati: [{ data: 'YYYY-MM-DD', pioggia }],
// solo giorni conclusi (oggi è coperto dalla previsione).
// spostataIl (piante.spostata_il, 24/11/2026): giorno dell'ultimo passaggio fra
// chiuso e aperto. Conta solo la pioggia dei giorni successivi: una pianta
// riportata fuori a primavera non riceve il merito della pioggia caduta quando
// era ancora in casa. Il giorno stesso dello spostamento non conta (non si sa
// se la pianta era già fuori quando pioveva).
export function ultimaPioggiaUtile(giorniPassati, spostataIl = null) {
  if (!Array.isArray(giorniPassati)) return null
  const dopo = spostataIl ? String(spostataIl).slice(0, 10) : null
  let ultima = null
  for (const g of giorniPassati) {
    if (!g?.data || (dopo && g.data <= dopo)) continue
    if ((parseFloat(g.pioggia) || 0) >= SOGLIA_PIOGGIA_MM && (!ultima || g.data > ultima)) ultima = g.data
  }
  return ultima
}

// '2026-11-21' → '21/11'
function giornoMese(data) {
  const [, m, g] = data.split('-')
  return `${g}/${m}`
}

// Cadenza generica per il ricambio dell'acqua finché la specie non ha un dato
// dedicato in specie.manutenzione.cambio_acqua (catalogo di ~15.700 specie:
// la stragrande maggioranza non lo avrà popolato da subito) — deciso in chat
// il 29/09/2026 (issue #173): meglio un'indicazione generica utile che uno
// stato "non configurata" che non aiuta chi ha una pianta in acqua.
const INTERVALLO_CAMBIO_ACQUA_DEFAULT = 14

export function valutaCura(pianta, specie, tipo, contesto = {}) {
  // Un programma di irrigazione automatica attivo (giardino/zona/sottozona/
  // pianta, vedi useIrrigazioneAuto.js) sostituisce del tutto la valutazione da
  // specie+stagione per questa pianta: l'utente non deve più vedere un
  // promemoria manuale per un'irrigazione che ha già pianificato altrove.
  // La sospensione per pioggia resta valida — stessa soglia e messaggio
  // già usati per l'irrigazione manuale, per non contraddirsi in due punti
  // diversi dell'app. (Il guard coltivato_in === 'acqua' qui e più sotto è
  // difensivo: da issue #173 una pianta in acqua non riceve più tipo
  // 'irrigazione' — vedi tipiCuraPianta — ma se mai richiamata così va
  // comunque trattata come le altre piante esterne.)
  if (tipo === 'irrigazione' && contesto.programmaAutomatico != null) {
    if (pianta?.coltivato_in !== 'acqua' && contesto.esterno && !contesto.alRiparo && pioggiaInArrivo(contesto.meteo)) {
      return { urgente: false, label: 'irrigazione — pioggia prevista, salta', giorni: null }
    }
    return {
      urgente: false,
      label: `irrigazione — automatica (ogni ${contesto.programmaAutomatico} gg)`,
      giorni: null,
      automatico: true,
    }
  }

  const stagCorrente = stagione()
  const manutenzione = specie?.manutenzione?.[tipo]?.[stagCorrente]
  let intervallo = parseGiorni(manutenzione)

  if (manutenzione === 'mai' || manutenzione === 'non necessario') {
    return { urgente: false, label: null, giorni: null }
  }
  if (!manutenzione) {
    if (tipo !== 'cambio_acqua') return { urgente: false, label: null, giorni: null }
    intervallo = INTERVALLO_CAMBIO_ACQUA_DEFAULT
  }

  let ultimaStr = pianta?.ultima_cura?.[tipo]
  if (!intervallo) return { urgente: false, label: manutenzione, giorni: null }

  // Al riparo dalla pioggia (zona o sottozona con tettoia, veranda…, 24/11/2026):
  // all'aperto, ma la pioggia non le arriva.
  const allAperto = tipo === 'irrigazione' && pianta?.coltivato_in !== 'acqua' && contesto.esterno && !contesto.alRiparo
  if (allAperto && pioggiaInArrivo(contesto.meteo)) {
    return { urgente: false, label: 'irrigazione — pioggia prevista, salta', giorni: null }
  }

  // La pioggia caduta conta come irrigazione se è più recente dell'ultima
  // registrata (confronto sul giorno: ultima_cura è 'YYYY-MM-DD').
  let pioggia = null
  const ultimaPioggia = allAperto ? ultimaPioggiaUtile(contesto.pioggiaCaduta, pianta?.spostata_il) : null
  if (ultimaPioggia && (!ultimaStr || ultimaPioggia > String(ultimaStr).slice(0, 10))) {
    ultimaStr = ultimaPioggia
    pioggia = ultimaPioggia
  }

  // "cambio_acqua" nel testo della label si legge "ricambio acqua" (stesso
  // nome scelto per l'utente, vedi LABEL_CURA in useCureVisual.js) invece
  // del nome della chiave interna.
  const nomeTipo = tipo === 'cambio_acqua' ? 'ricambio acqua' : tipo

  if (!ultimaStr) {
    // La potatura resta chiamabile (la scheda pianta mostra "ultima: N gg fa")
    // ma non è mai urgente: nessuna cadenza temporale da rispettare.
    return { urgente: tipo !== 'potatura', label: `${nomeTipo} — mai registrata`, giorni: Infinity }
  }

  const ultima     = new Date(ultimaStr)
  const oggi       = new Date()
  const trascorsi  = Math.floor((oggi - ultima) / 86400000)
  const rimanenti  = intervallo - trascorsi
  const urgente    = tipo !== 'potatura' && rimanenti <= 0
  const daPioggia  = pioggia ? ` (ha piovuto il ${giornoMese(pioggia)})` : ''

  return {
    urgente,
    label: (urgente
      ? `${nomeTipo} — scaduta ${Math.abs(rimanenti)} gg fa`
      : `${nomeTipo} — tra ${rimanenti} gg`) + daPioggia,
    giorni: rimanenti,
    intervallo,
    trascorsi,
    pioggia,
  }
}

// Tipi di cura con cadenza/urgenza da valutare per questa pianta — irrigazione
// (o, per le piante coltivate in acqua, il suo equivalente "cambio_acqua":
// mostrare "Irrigazione" per una pianta già immersa in acqua non ha senso,
// issue #173), concimazione e — per le specie con beneficio documentato —
// calcio. Centralizza una lista prima duplicata in 4 punti (DossierPianta,
// PiantaView, AttivitaView, HomeView), che altrimenti avrebbero dovuto
// aggiungere la stessa condizione coltivato_in ciascuno per conto proprio.
export function tipiCuraPianta(pianta, specie) {
  const tipi = [pianta?.coltivato_in === 'acqua' ? 'cambio_acqua' : 'irrigazione', 'concimazione']
  if (specie?.manutenzione?.calcio) tipi.push('calcio')
  return tipi
}

export function cureUrgentiPianta(pianta, specie, contesto) {
  // La potatura non ha cadenza temporale: è un'etichetta testuale,
  // registrabile per pianta ma mai valutata per urgenza né mostrata nei
  // feed "attività".
  return tipiCuraPianta(pianta, specie)
    .map(tipo => ({ tipo, ...valutaCura(pianta, specie, tipo, contesto) }))
    .filter(c => c.urgente)
}

// Se il programma di irrigazione automatica di questa pianta (giardino,
// zona, sottozona o pianta — vedi useIrrigazioneAuto.js) la rende sospesa
// ma sarebbe comunque dovuta oggi, l'app la registra da sola al posto del
// promemoria manuale: si fida che l'irrigazione avvenga per conto suo
// (un impianto o un programma indipendente) invece di continuare a
// chiederla all'utente. Puramente di lettura, come valutaCura() — che
// resta l'unica fonte di verità per cosa mostrare in interfaccia: questa
// funzione non la chiama e non ne altera il risultato, serve solo a
// decidere se stores/dati.js deve scrivere ultima_cura.
//
// Deliberatamente NON copre la sospensione per pioggia prevista: una
// previsione a 48 ore non è un fatto avvenuto, e oggi la sospensione da
// pioggia si autocorregge da sola (se la previsione cambia, il promemoria
// torna) — scrivere una registrazione permanente sulla sola base di una
// previsione toglierebbe quella capacità di autocorrezione. Un'eventuale
// estensione alla pioggia richiede prima di poter verificare la pioggia
// caduta per davvero, non solo quella prevista — fuori dal perimetro di
// questa funzione per ora, deciso esplicitamente in chat il 9 settembre 2026.
export function irrigazioneDaRegistrareOggi(pianta, contesto = {}) {
  if (pianta?.coltivato_in === 'acqua') return false
  if (contesto.programmaAutomatico == null) return false

  const ultimaStr = pianta?.ultima_cura?.irrigazione
  if (!ultimaStr) return true
  const trascorsi = Math.floor((new Date() - new Date(ultimaStr)) / 86400000)
  return trascorsi >= contesto.programmaAutomatico
}
