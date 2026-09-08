<template>
  <div style="max-width:420px;margin:0 auto;">
    <h1 class="page-title" style="margin-bottom:24px">Impostazioni</h1>

    <div class="form-card" style="margin-bottom:12px">
      <p id="posizione-label" class="slabel">Posizione</p>

      <button type="button" @click="usaPosizioneDispositivo" :disabled="localizzando" class="btn btn-ghost" style="width:100%;margin-bottom:10px;">
        <Spinner v-if="localizzando" /><Icon v-else name="pin" style="width:16px;height:16px;flex-shrink:0;" />{{ localizzando ? 'Localizzazione…' : 'Usa la mia posizione' }}
      </button>

      <div style="position:relative;margin-bottom:10px;">
        <input v-model="queryIndirizzo" @keyup.enter="cercaIndirizzoUtente" type="text" placeholder="Cerca indirizzo…" class="form-input" style="width:100%;">
        <ul v-if="risultatiIndirizzo.length" class="risultati-indirizzo" role="listbox" aria-label="Risultati indirizzo" style="list-style:none;margin:4px 0 0;padding:0;background:var(--white);border:1px solid var(--cream-dark);border-radius:14px;box-shadow:0 2px 12px rgba(42,34,24,0.06);overflow:hidden;">
          <li v-for="(r, i) in risultatiIndirizzo" :key="i" role="option" tabindex="0" @click="scegliIndirizzo(r)" @keydown.enter.prevent="scegliIndirizzo(r)" @keydown.space.prevent="scegliIndirizzo(r)" style="padding:8px 10px;cursor:pointer;font-size:13px;">
            {{ r.display_name }}
          </li>
        </ul>
        <p v-if="risultatiIndirizzo.length" style="font-size:11px;color:var(--ink-soft);margin:4px 0 0;">dati © OpenStreetMap</p>
      </div>

      <div style="display:flex;gap:8px;margin-bottom:10px;">
        <div style="flex:1;">
          <label class="field-label" for="settings-lat">Latitudine</label>
          <input id="settings-lat" v-model.number="form.lat" type="number" placeholder="Latitudine" class="form-input">
        </div>
        <div style="flex:1;">
          <label class="field-label" for="settings-lon">Longitudine</label>
          <input id="settings-lon" v-model.number="form.lon" type="number" placeholder="Longitudine" class="form-input">
        </div>
      </div>
      <label class="field-label" for="settings-altitude">Altitudine</label>
      <input id="settings-altitude" v-model.number="form.altitude" type="number" placeholder="Altitudine (m)" class="form-input">
      <p v-if="erroreGeo" role="alert" style="font-size:12px;color:var(--rose-dark);margin:8px 0 0;">{{ erroreGeo }}</p>
    </div>

    <div class="form-card" style="margin-bottom:12px">
      <p id="zona-climatica-label" class="slabel">Zona climatica</p>
      <select v-model="form.zona_climatica_id" aria-labelledby="zona-climatica-label" class="form-input">
        <option :value="null">Non impostata</option>
        <option v-for="z in zoneClimatiche" :key="z.id" :value="z.id">{{ z.nome }}</option>
      </select>
    </div>

    <div class="form-card" style="margin-bottom:12px">
      <p id="aspetto-label" class="slabel">Aspetto</p>
      <select :value="tema" @change="impostaTema($event.target.value)" aria-labelledby="aspetto-label" class="form-input">
        <option value="light">Chiaro</option>
        <option value="dark">Scuro</option>
      </select>
    </div>

    <RouterLink to="/impostazioni/irrigazione" class="form-card" style="display:flex;align-items:center;justify-content:space-between;margin-bottom:12px;text-decoration:none;color:inherit;">
      <span style="font-size:13px;font-weight:600;"><Icon name="goccia" style="width:14px;height:14px;vertical-align:-2px;margin-right:6px;color:var(--acqua);" />Irrigazione automatica</span>
      <Icon name="back" style="width:14px;height:14px;flex-shrink:0;color:var(--ink-faint);transform:rotate(180deg);" />
    </RouterLink>

    <p v-if="errore" role="alert" style="font-size:12px;color:var(--rose-dark);margin-bottom:10px;">{{ errore }}</p>

    <button @click="salva" :disabled="salvando" class="btn btn-sage" style="width:100%;min-height:44px;">
      <Spinner v-if="salvando" />{{ salvando ? 'Salvataggio…' : 'Salva' }}
    </button>
    <Transition name="fade">
      <p v-if="salvato" class="badge badge-ok" style="display:block;width:fit-content;margin:10px auto 0;">Salvato</p>
    </Transition>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useSettingsApi } from '@/composables/useSettingsApi'
import { useSupabase } from '@/composables/useSupabase'
import { useTema } from '@/composables/useTema'
import { useGeolocalizzazione } from '@/composables/useGeolocalizzazione'
import Spinner from '@/components/Spinner.vue'
import Icon from '@/components/Icon.vue'

const store = useDatiStore()
const settingsApi = useSettingsApi()
const supabase = useSupabase()
const { tema, impostaTema } = useTema()
const { richiediPosizioneDispositivo, cercaIndirizzo, ottieniAltitudine } = useGeolocalizzazione()

const salvando = ref(false)
const salvato = ref(false)
let salvatoTimeout = null
const errore = ref(null)
const zoneClimatiche = ref([])
const form = ref({ lat: null, lon: null, altitude: null, zona_climatica_id: null })

const localizzando = ref(false)
const erroreGeo = ref(null)
const queryIndirizzo = ref('')
const risultatiIndirizzo = ref([])

async function usaPosizioneDispositivo() {
  localizzando.value = true
  erroreGeo.value = null
  try {
    const { lat, lon } = await richiediPosizioneDispositivo()
    await impostaPosizione(lat, lon)
  } catch (e) {
    erroreGeo.value = e.message
  } finally {
    localizzando.value = false
  }
}

async function cercaIndirizzoUtente() {
  if (!queryIndirizzo.value.trim()) return
  erroreGeo.value = null
  try {
    risultatiIndirizzo.value = await cercaIndirizzo(queryIndirizzo.value.trim())
    if (!risultatiIndirizzo.value.length) erroreGeo.value = 'Nessun indirizzo trovato.'
  } catch (e) {
    erroreGeo.value = e.message
  }
}

async function scegliIndirizzo(r) {
  risultatiIndirizzo.value = []
  queryIndirizzo.value = r.display_name
  await impostaPosizione(r.lat, r.lon)
}

async function impostaPosizione(lat, lon) {
  form.value.lat = lat
  form.value.lon = lon
  try {
    const altitudine = await ottieniAltitudine(lat, lon)
    if (altitudine != null) form.value.altitude = altitudine
  } catch {
    // altitudine resta modificabile a mano, nessun blocco del flusso
  }
}

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
  salvato.value = false
  try {
    await settingsApi.salvaSettings({
      location: { lat: form.value.lat, lon: form.value.lon, altitude: form.value.altitude },
      units: store.settings?.units ?? { temperature: 'celsius', wind: 'kmh', precipitation: 'mm' },
      meteo: store.settings?.meteo ?? { provider: 'open-meteo', days: 3 },
      ui: store.settings?.ui ?? { theme: 'light' },
      zona_climatica_id: form.value.zona_climatica_id,
    })
    salvato.value = true
    clearTimeout(salvatoTimeout)
    salvatoTimeout = setTimeout(() => { salvato.value = false }, 2400)
  } catch (e) {
    errore.value = e.message || 'Errore durante il salvataggio.'
  } finally {
    salvando.value = false
  }
}

onUnmounted(() => clearTimeout(salvatoTimeout))
</script>

<style scoped>
.form-card > .slabel:first-child { margin-top: 0; }
.risultati-indirizzo li:hover { background: var(--cream); }
.risultati-indirizzo li:focus-visible { outline: none; background: var(--cream); box-shadow: inset 0 0 0 2px var(--gold); }
</style>
