import { ref, computed } from 'vue'

const WMO = {
  0:'☀️', 1:'🌤️', 2:'⛅', 3:'☁️',
  45:'🌫️', 48:'🌫️',
  51:'🌦️', 53:'🌦️', 55:'🌦️',
  61:'🌧️', 63:'🌧️', 65:'🌧️',
  71:'🌨️', 73:'🌨️', 75:'🌨️',
  77:'🌨️', 80:'🌦️', 81:'🌧️', 82:'⛈️',
  85:'🌨️', 86:'🌨️',
  95:'⛈️', 96:'⛈️', 99:'⛈️',
}

const WMO_LABEL = {
  0:'Soleggiato', 1:'Poco nuvoloso', 2:'Parzialmente nuvoloso', 3:'Nuvoloso',
  45:'Nebbia', 48:'Nebbia',
  51:'Pioggia leggera', 53:'Pioggia moderata', 55:'Pioggia intensa',
  61:'Pioggia leggera', 63:'Pioggia moderata', 65:'Pioggia intensa',
  71:'Neve leggera', 73:'Neve moderata', 75:'Neve intensa',
  80:'Rovesci leggeri', 81:'Rovesci moderati', 82:'Rovesci intensi',
  95:'Temporale', 96:'Temporale con grandine', 99:'Temporale forte',
}

const CODICI_TEMPORALE = [95, 96, 99]

function valutaAvvisi(g) {
  const avvisi = []
  if (g.tMin <= 3) avvisi.push({ icona:'❄️', testo:`Rischio gelo (min ${g.tMin}°)` })
  if (g.tMax >= 35) avvisi.push({ icona:'🥵', testo:`Caldo estremo (max ${g.tMax}°)` })
  if (g.vento >= 40) avvisi.push({ icona:'💨', testo:`Vento forte (${g.vento} km/h)` })
  if (CODICI_TEMPORALE.includes(g.codice)) avvisi.push({ icona:'⛈️', testo:'Temporale previsto' })
  else if (parseFloat(g.pioggia) >= 20) avvisi.push({ icona:'🌧️', testo:`Pioggia intensa (${g.pioggia} mm)` })
  return avvisi
}

export function useMeteo() {
  const giorni      = ref([])
  const oggi        = ref(null)
  const orarieOggi  = ref([])
  const loading     = ref(false)
  const errore      = ref(null)

  async function carica(lat, lon, days = 7) {
    loading.value = true
    errore.value  = null
    try {
      const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max&hourly=temperature_2m,precipitation_probability,weathercode,windspeed_10m&forecast_days=${days}&timezone=auto`
      const res  = await fetch(url)
      if (!res.ok) throw new Error('Errore API meteo')
      const raw  = await res.json()
      const d    = raw.daily
      const h    = raw.hourly

      giorni.value = d.time.map((data, i) => ({
        data,
        label: new Date(data).toLocaleDateString('it-IT', { weekday:'short', day:'numeric', month:'short' }),
        codice: d.weathercode[i],
        icona: WMO[d.weathercode[i]] ?? '🌡️',
        descrizione: WMO_LABEL[d.weathercode[i]] ?? '',
        tMax: Math.round(d.temperature_2m_max[i]),
        tMin: Math.round(d.temperature_2m_min[i]),
        pioggia: d.precipitation_sum[i]?.toFixed(1) ?? '0',
        vento: Math.round(d.windspeed_10m_max[i]),
      }))
      oggi.value = giorni.value[0] ?? null

      orarieOggi.value = h?.time ? h.time.slice(0, 24).map((ora, i) => ({
        ora,
        label: ora.slice(11, 16),
        icona: WMO[h.weathercode[i]] ?? '🌡️',
        descrizione: WMO_LABEL[h.weathercode[i]] ?? '',
        temp: Math.round(h.temperature_2m[i]),
        pioggiaProb: h.precipitation_probability?.[i] ?? null,
        vento: Math.round(h.windspeed_10m[i]),
      })) : []
    } catch (e) {
      errore.value = e.message
    } finally {
      loading.value = false
    }
  }

  const avvisi = computed(() => giorni.value.flatMap((g, i) =>
    valutaAvvisi(g).map(a => ({ ...a, giorno: i === 0 ? 'Oggi' : g.label, key: `${g.data}-${a.testo}` }))
  ))

  return { giorni, oggi, orarieOggi, avvisi, loading, errore, carica }
}
