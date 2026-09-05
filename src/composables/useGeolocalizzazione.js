// Tre API gratuite, nessuna chiave richiesta:
// - Geolocation API del browser per la posizione del dispositivo
// - Nominatim (OpenStreetMap) per la ricerca indirizzo → lat/lon
// - Elevation API di Open-Meteo (stesso provider già usato per il meteo,
//   vedi useMeteo.js) per l'altitudine da lat/lon

function richiediPosizioneDispositivo() {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('Geolocalizzazione non disponibile su questo dispositivo.'))
      return
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => resolve({ lat: pos.coords.latitude, lon: pos.coords.longitude }),
      (err) => {
        if (err.code === err.PERMISSION_DENIED) {
          reject(new Error('Permesso di geolocalizzazione negato.'))
        } else if (err.code === err.TIMEOUT) {
          reject(new Error('Richiesta posizione scaduta, riprova.'))
        } else {
          reject(new Error('Posizione non disponibile.'))
        }
      },
      { enableHighAccuracy: true, timeout: 10000 }
    )
  })
}

async function cercaIndirizzo(query) {
  const url = `https://nominatim.openstreetmap.org/search?format=json&limit=5&q=${encodeURIComponent(query)}`
  const res = await fetch(url)
  if (!res.ok) throw new Error('Errore nella ricerca indirizzo.')
  const dati = await res.json()
  return dati.map(r => ({ display_name: r.display_name, lat: parseFloat(r.lat), lon: parseFloat(r.lon) }))
}

async function ottieniAltitudine(lat, lon) {
  const url = `https://api.open-meteo.com/v1/elevation?latitude=${lat}&longitude=${lon}`
  const res = await fetch(url)
  if (!res.ok) throw new Error('Errore elevation API')
  const dati = await res.json()
  const valore = dati.elevation?.[0]
  return typeof valore === 'number' ? Math.round(valore) : null
}

export function useGeolocalizzazione() {
  return { richiediPosizioneDispositivo, cercaIndirizzo, ottieniAltitudine }
}
