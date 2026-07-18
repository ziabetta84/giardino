import { defineStore } from 'pinia'
import { ref } from 'vue'

const BASE = import.meta.env.BASE_URL

async function caricaJSON(file) {
  const res = await fetch(`${BASE}data/${file}`)
  if (!res.ok) throw new Error(`Errore caricamento ${file}`)
  return res.json()
}

export const useDatiStore = defineStore('dati', () => {
  const piante    = ref(null)
  const specie    = ref(null)
  const zone      = ref(null)
  const sottozone = ref(null)
  const progetti  = ref(null)
  const settings  = ref(null)
  const loading   = ref(false)
  const errore    = ref(null)

  async function caricaTutto() {
    if (piante.value) return  // già caricati
    loading.value = true
    errore.value = null
    try {
      ;[piante.value, specie.value, zone.value, sottozone.value, progetti.value, settings.value] =
        await Promise.all([
          caricaJSON('piante.json'),
          caricaJSON('specie.json'),
          caricaJSON('zone.json'),
          caricaJSON('sottozone.json'),
          caricaJSON('progetti.json'),
          caricaJSON('settings.json'),
        ])
    } catch (e) {
      errore.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function aggiorna() {
    piante.value = null
    await caricaTutto()
  }

  return { piante, specie, zone, sottozone, progetti, settings, loading, errore, caricaTutto, aggiorna }
})
