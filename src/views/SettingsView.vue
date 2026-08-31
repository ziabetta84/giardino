<template>
  <div style="max-width:420px;margin:0 auto;">
    <h1 class="title-display gradient-title title-settle" style="font-size:1.9rem;font-weight:800;margin-bottom:16px;">Impostazioni</h1>

    <div class="card" style="padding:18px;margin-bottom:12px;">
      <p class="section-label" style="margin-bottom:10px;">Posizione</p>
      <div style="display:flex;gap:8px;margin-bottom:10px;">
        <input v-model.number="form.lat" type="number" placeholder="Latitudine" class="form-input">
        <input v-model.number="form.lon" type="number" placeholder="Longitudine" class="form-input">
      </div>
      <input v-model.number="form.altitude" type="number" placeholder="Altitudine (m)" class="form-input">
    </div>

    <div class="card" style="padding:18px;margin-bottom:12px;">
      <p class="section-label" style="margin-bottom:10px;">Zona climatica</p>
      <select v-model="form.zona_climatica_id" class="form-input">
        <option :value="null">Non impostata</option>
        <option v-for="z in zoneClimatiche" :key="z.id" :value="z.id">{{ z.nome }}</option>
      </select>
    </div>

    <p v-if="errore" style="font-size:12px;color:var(--rose-dark);margin-bottom:10px;">{{ errore }}</p>

    <button @click="salva" :disabled="salvando" class="btn btn-sage" style="width:100%;min-height:44px;">
      <Spinner v-if="salvando" />{{ salvando ? 'Salvataggio…' : 'Salva' }}
    </button>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useSettingsApi } from '@/composables/useSettingsApi'
import { useSupabase } from '@/composables/useSupabase'
import Spinner from '@/components/Spinner.vue'

const store = useDatiStore()
const settingsApi = useSettingsApi()
const supabase = useSupabase()

const salvando = ref(false)
const errore = ref(null)
const zoneClimatiche = ref([])
const form = ref({ lat: null, lon: null, altitude: null, zona_climatica_id: null })

onMounted(async () => {
  await store.caricaTutto()
  const s = store.settings
  form.value = {
    lat: s?.location?.lat ?? null,
    lon: s?.location?.lon ?? null,
    altitude: s?.location?.altitude ?? null,
    zona_climatica_id: s?.zona_climatica_id ?? null,
  }
  const { data } = await supabase.from('zone_climatiche').select('id, nome').order('nome')
  zoneClimatiche.value = data ?? []
})

async function salva() {
  if (salvando.value) return
  salvando.value = true
  errore.value = null
  try {
    await settingsApi.salvaSettings({
      location: { lat: form.value.lat, lon: form.value.lon, altitude: form.value.altitude },
      units: store.settings?.units ?? { temperature: 'celsius', wind: 'kmh', precipitation: 'mm' },
      meteo: store.settings?.meteo ?? { provider: 'open-meteo', days: 3 },
      ui: store.settings?.ui ?? { theme: 'auto' },
      zona_climatica_id: form.value.zona_climatica_id,
    })
  } catch (e) {
    errore.value = e.message || 'Errore durante il salvataggio.'
  } finally {
    salvando.value = false
  }
}
</script>
