// Euristica dichiaratamente approssimativa (coerente con stato_verifica
// bozza/verificato già presente sulle righe di zone_climatiche stessa):
// fasce di latitudine per nord/centro/sud continentali, bounding box
// grezzo per Sicilia/Sardegna, soglia di altitudine per le varianti
// "-montana". Non è geolocalizzazione precisa, è un punto di partenza
// sempre modificabile a mano (vedi SettingsView.vue).
const SOGLIA_MONTANA_M = 600

const SARDEGNA = { latMin: 38.8, latMax: 41.3, lonMin: 8.0, lonMax: 9.8 }
const SICILIA  = { latMin: 36.6, latMax: 38.3, lonMin: 12.4, lonMax: 15.7 }

function inBox(lat, lon, box) {
  return lat >= box.latMin && lat <= box.latMax && lon >= box.lonMin && lon <= box.lonMax
}

export function calcolaCodiceZonaClimatica({ lat, lon, altitude = 0 } = {}) {
  if (lat == null || lon == null) return null
  const montana = (altitude ?? 0) >= SOGLIA_MONTANA_M

  if (inBox(lat, lon, SARDEGNA) || inBox(lat, lon, SICILIA)) {
    return montana ? 'insulare-montana' : 'insulare'
  }
  if (lat >= 44.5) return montana ? 'nord-montana' : 'nord'
  if (lat >= 41.5) return montana ? 'centro-montana' : 'centro'
  return montana ? 'sud-montana' : 'sud'
}

export function useZonaClimatica() {
  return { calcolaCodiceZonaClimatica }
}
