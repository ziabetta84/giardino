import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useMeteo } from '@/composables/useMeteo'
import { useApi } from '@/composables/useApi'
import { useSupabase } from '@/composables/useSupabase'

const BASE = import.meta.env.BASE_URL

async function caricaStatico(file) {
  const res = await fetch(`${BASE}data/${file}`)
  if (!res.ok) throw new Error(`Errore caricamento ${file}`)
  return res.json()
}

// Legge sempre prima da GitHub (stessa fonte usata dai salvataggi, senza
// cache): così le modifiche sono visibili subito, senza aspettare che build
// e deploy pubblichino una nuova copia statica su GitHub Pages. Se GitHub
// non è raggiungibile (offline, in giardino senza campo) ripiega sull'ultima
// copia statica pubblicata, che il service worker può servire da cache.
async function caricaJSON(file) {
  const { loadJSON } = useApi()
  try {
    return await loadJSON(file)
  } catch {
    return caricaStatico(file)
  }
}

// Pilota Fase 2: le specie vengono da Supabase (sola lettura), non più dal
// JSON statico — ma la forma dell'oggetto resta identica a prima (stessa
// chiave slug, stessi nomi di campo "specie" e "coltivazione") perché tutto
// il resto dell'app si aspetta ancora quella forma. Le scritture (creare o
// modificare una specie da SelettoreSpecie) restano su GitHub per ora: la
// migrazione delle scritture è compito di una fase successiva, non di questa.
// Se Supabase non risponde, ripiega sul JSON statico come le altre risorse.
async function caricaSpecie() {
  try {
    const supabase = useSupabase()
    const { data, error } = await supabase
      .from('specie')
      .select('slug, nome, nome_scientifico, descrizione, esigenze, alert, manutenzione, ciclo_colturale, ciclo_vitale, stato_verifica')
    if (error) throw error
    return Object.fromEntries(data.map(riga => [riga.slug, {
      nome: riga.nome,
      specie: riga.nome_scientifico,
      descrizione: riga.descrizione,
      esigenze: riga.esigenze,
      alert: riga.alert,
      manutenzione: riga.manutenzione,
      coltivazione: riga.ciclo_colturale,
      ciclo_vitale: riga.ciclo_vitale,
      stato_verifica: riga.stato_verifica,
    }]))
  } catch {
    return caricaStatico('specie.json')
  }
}

export const useDatiStore = defineStore('dati', () => {
  const piante    = ref(null)
  const specie    = ref(null)
  const zone      = ref(null)
  const sottozone = ref(null)
  const progetti  = ref(null)
  const settings  = ref(null)
  const concimi   = ref(null)
  const meteo     = ref(null)
  const loading   = ref(false)
  const errore    = ref(null)

  async function caricaTutto() {
    if (piante.value) return  // già caricati
    loading.value = true
    errore.value = null
    try {
      ;[piante.value, specie.value, zone.value, sottozone.value, progetti.value, settings.value, concimi.value] =
        await Promise.all([
          caricaJSON('piante.json'),
          caricaSpecie(),
          caricaJSON('zone.json'),
          caricaJSON('sottozone.json'),
          caricaJSON('progetti.json'),
          caricaJSON('settings.json'),
          caricaJSON('concimi.json'),
        ])
    } catch (e) {
      errore.value = e.message
    } finally {
      loading.value = false
    }

    // Previsioni meteo (solo oggi/domani): usate da useCure per sospendere
    // l'irrigazione delle piante esterne quando è prevista pioggia sufficiente.
    // Un eventuale errore di rete resta silenzioso: senza dati meteo affidabili
    // le cure vengono valutate come se non piovesse (nessuna soppressione).
    const lat = settings.value?.location?.lat
    const lon = settings.value?.location?.lon
    if (lat && lon) {
      const { giorni, carica } = useMeteo()
      await carica(lat, lon, 2)
      meteo.value = giorni.value
    }
  }

  async function aggiorna() {
    piante.value = null
    await caricaTutto()
  }

  return { piante, specie, zone, sottozone, progetti, settings, concimi, meteo, loading, errore, caricaTutto, aggiorna }
})
