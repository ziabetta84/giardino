// Alba e tramonto calcolati in locale (algoritmo NOAA semplificato, errore di
// un paio di minuti alle nostre latitudini), senza rete. Servono alla scena
// della Home e allo splash per scegliere giorno o notte dal primo fotogramma:
// le ore di Open-Meteo arrivano solo dopo il caricamento dello store, e fino
// ad allora la scena mostrava sempre «giorno», per poi passare alla notte
// davanti agli occhi (segnalato da Roberta il 06/11/2026).

const RAD = Math.PI / 180

// Istanti (Date) di alba e tramonto del giorno civile di `data` nel fuso del
// dispositivo, per la posizione data. null nelle notti o nei giorni polari.
export function albaTramonto(data, lat, lon) {
  // Giorno giuliano a mezzogiorno UTC della data locale
  const mezzogiorno = Date.UTC(data.getFullYear(), data.getMonth(), data.getDate(), 12)
  const n = mezzogiorno / 86400000 + 2440587.5 - 2451545.0
  const t = n / 36525
  const l0 = (280.46646 + t * (36000.76983 + t * 0.0003032)) % 360
  const m = 357.52911 + t * (35999.05029 - 0.0001537 * t)
  const e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
  const c = Math.sin(m * RAD) * (1.914602 - t * (0.004817 + 0.000014 * t))
    + Math.sin(2 * m * RAD) * (0.019993 - 0.000101 * t)
    + Math.sin(3 * m * RAD) * 0.000289
  const lambda = l0 + c - 0.00569 - 0.00478 * Math.sin((125.04 - 1934.136 * t) * RAD)
  const eps = 23.439291 - 0.0130042 * t + 0.00256 * Math.cos((125.04 - 1934.136 * t) * RAD)
  const decl = Math.asin(Math.sin(eps * RAD) * Math.sin(lambda * RAD))
  const y = Math.tan((eps / 2) * RAD) ** 2
  // Equazione del tempo, in minuti
  const eqt = 4 / RAD * (y * Math.sin(2 * l0 * RAD) - 2 * e * Math.sin(m * RAD)
    + 4 * e * y * Math.sin(m * RAD) * Math.cos(2 * l0 * RAD)
    - 0.5 * y * y * Math.sin(4 * l0 * RAD) - 1.25 * e * e * Math.sin(2 * m * RAD))
  const cosH = (Math.cos(90.833 * RAD) - Math.sin(lat * RAD) * Math.sin(decl))
    / (Math.cos(lat * RAD) * Math.cos(decl))
  if (cosH < -1 || cosH > 1) return null
  const h = Math.acos(cosH) / RAD
  // Mezzogiorno solare in minuti dalla mezzanotte UTC
  const noonUtc = 720 - 4 * lon - eqt
  const mezzanotteUtc = mezzogiorno - 12 * 3600000
  return {
    alba: new Date(mezzanotteUtc + (noonUtc - 4 * h) * 60000),
    tramonto: new Date(mezzanotteUtc + (noonUtc + 4 * h) * 60000),
  }
}

// Posizione di ripiego quando il giardino non ha ancora una posizione: Italia
// centrale per la latitudine, e la longitudine del fuso orario «solare» del
// dispositivo (lo scarto d'inverno, senza l'ora legale). Basta a dire se è
// giorno o notte, non a fare previsioni.
export function posizioneApprossimata(data = new Date()) {
  const gennaio = new Date(data.getFullYear(), 0, 1).getTimezoneOffset()
  const luglio = new Date(data.getFullYear(), 6, 1).getTimezoneOffset()
  return { lat: 43, lon: -Math.max(gennaio, luglio) / 4 }
}

// 'giorno' | 'notte' per l'istante `adesso`. Le ore di Open-Meteo, se ci
// sono, hanno la precedenza; altrimenti il calcolo locale.
export function luceDelMomento(adesso, { alba, tramonto } = {}, posizione = null) {
  let a = alba ? new Date(alba) : null
  let tr = tramonto ? new Date(tramonto) : null
  if (!a || !tr) {
    const pos = posizione ?? posizioneApprossimata(adesso)
    const sole = albaTramonto(adesso, pos.lat, pos.lon)
    if (!sole) {
      // Giorno o notte polare: decide la stagione
      const estiva = (pos.lat >= 0) === (adesso.getMonth() >= 3 && adesso.getMonth() <= 8)
      return estiva ? 'giorno' : 'notte'
    }
    a = sole.alba; tr = sole.tramonto
  }
  return adesso >= a && adesso < tr ? 'giorno' : 'notte'
}
