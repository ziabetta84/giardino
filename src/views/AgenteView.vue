<template>
  <div>
    <h1 class="title-display gradient-title" style="font-size:1.9rem;font-weight:800;margin-bottom:20px;">Assistente AI</h1>

    <!-- Token mancante -->
    <div v-if="!tokenSalvato" class="card" style="padding:16px;margin-bottom:16px;border-color:var(--gold-light);background:var(--gold-pale);">
      <p style="font-size:13px;font-weight:600;color:var(--gold-dark);margin-bottom:4px;">🔑 Token GitHub richiesto</p>
      <p style="font-size:12px;color:var(--ink-soft);margin-bottom:10px;">Per inviare richieste serve un token con permesso <code>contents:write</code>.</p>
      <div style="display:flex;gap:8px;">
        <input v-model="tokenInput" type="password" placeholder="ghp_…" class="form-input" style="flex:1;min-height:36px;font-size:13px;">
        <button @click="configuratToken" :disabled="!tokenInput.trim()" class="btn btn-sage" style="min-height:36px;padding:6px 14px;font-size:13px;">Salva</button>
      </div>
    </div>

    <!-- Nuova richiesta -->
    <div class="card" style="padding:16px;margin-bottom:20px;border-color:var(--sage-light);">
      <p class="section-label" style="margin-bottom:10px;">Nuova richiesta</p>
      <select v-model="nuovoTipo" class="form-input" style="margin-bottom:10px;">
        <option value="identifica_specie">Identifica specie da foto</option>
        <option value="consiglio_cura">Consiglio per cura</option>
        <option value="diagnosi">Diagnosi problema</option>
        <option value="altro">Altro</option>
      </select>

      <!-- Upload foto (solo per identifica_specie) -->
      <div v-if="nuovoTipo === 'identifica_specie'" style="margin-bottom:10px;">
        <label style="display:flex;align-items:center;gap:10px;padding:12px 14px;border:1.5px dashed var(--sage-light);border-radius:12px;cursor:pointer;background:var(--sage-pale);">
          <span style="font-size:22px;">📷</span>
          <div style="flex:1;">
            <div style="font-size:13px;font-weight:600;color:var(--sage-dark);">{{ fotoPreview ? nomeFile : 'Allega una foto' }}</div>
            <div style="font-size:11px;color:var(--ink-soft);margin-top:2px;">{{ fotoPreview ? 'Tocca per cambiare' : 'JPG, PNG — max 5 MB' }}</div>
          </div>
          <img v-if="fotoPreview" :src="fotoPreview" style="width:48px;height:48px;object-fit:cover;border-radius:8px;">
          <input type="file" accept="image/*" capture="environment" @change="selezionaFoto" style="display:none;">
        </label>
      </div>

      <textarea v-model="nuovoMessaggio" placeholder="Descrivi la richiesta…"
        rows="3" class="form-input" style="resize:vertical;font-family:inherit;"></textarea>
      <div v-if="errore" style="margin-top:8px;padding:8px 12px;background:var(--rose-pale);border-radius:10px;border:1px solid var(--rose-light);">
        <p style="font-size:12px;color:var(--rose-dark);">⚠ {{ errore }}</p>
      </div>
      <button @click="aggiungiRichiesta" :disabled="!nuovoMessaggio.trim() || aggiungendo" class="btn btn-sage"
        style="margin-top:10px;width:100%;">
        {{ aggiungendo ? '⏳ Invio…' : '+ Invia richiesta' }}
      </button>
    </div>

    <!-- Lista richieste -->
    <p v-if="richieste.length" class="section-label" style="margin-bottom:10px;">Storico</p>
    <div style="display:flex;flex-direction:column;gap:8px;">
      <div v-for="r in richieste" :key="r.id" class="card" style="padding:14px 16px;">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px;">
          <span class="badge" :style="badgeStato(r.stato)">{{ r.stato }}</span>
          <span style="font-size:11px;color:var(--ink-faint);">{{ formatData(r.creata) }}</span>
        </div>
        <p style="font-size:13px;font-weight:500;color:var(--ink-mid);margin-bottom:4px;text-transform:capitalize;">
          {{ r.tipo?.replace(/_/g, ' ') }}
        </p>
        <p style="font-size:12px;color:var(--ink-soft);line-height:1.5;white-space:pre-wrap;">{{ r.messaggio }}</p>
        <div v-if="r.risposta?.messaggio" style="margin-top:10px;padding:10px;background:var(--cream-dark);border-radius:10px;border-left:3px solid var(--sage);">
          <p style="font-size:12px;color:var(--ink-mid);line-height:1.6;white-space:pre-wrap;">{{ r.risposta.messaggio }}</p>
        </div>
      </div>

      <div v-if="!richieste.length" style="text-align:center;padding:40px 20px;color:var(--ink-faint);">
        <div style="font-size:40px;margin-bottom:12px;">🤖</div>
        <p style="font-size:13px;">Nessuna richiesta ancora</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useApi } from '@/composables/useApi'
import { useDatiStore } from '@/stores/dati'

const store = useDatiStore()
const { saveJSON, isAutenticato, salvaToken } = useApi()

const raw            = ref({})
const nuovoTipo      = ref('identifica_specie')
const nuovoMessaggio = ref('')
const aggiungendo    = ref(false)
const fotoBase64     = ref(null)
const fotoPreview    = ref(null)
const nomeFile       = ref('')
const errore         = ref(null)
const tokenInput     = ref('')
const tokenSalvato   = ref(isAutenticato())

const BASE = import.meta.env.BASE_URL

onMounted(async () => {
  await store.caricaTutto()
  try {
    const res = await fetch(`${BASE}data/richieste-agente.json`)
    raw.value = res.ok ? await res.json() : {}
  } catch { raw.value = {} }
})

const richieste = computed(() =>
  Object.entries(raw.value)
    .map(([id, r]) => ({ id, ...r }))
    .sort((a, b) => new Date(b.creata) - new Date(a.creata))
)

function badgeStato(stato) {
  if (stato === 'completata') return 'background:var(--sage-pale);color:var(--sage-dark);'
  if (stato === 'errore')     return 'background:var(--rose-pale);color:var(--rose-dark);'
  return 'background:var(--gold-pale);color:var(--gold-dark);'
}

function formatData(iso) {
  if (!iso) return ''
  return new Date(iso).toLocaleDateString('it-IT', { day:'numeric', month:'short', hour:'2-digit', minute:'2-digit' })
}

function selezionaFoto(e) {
  const file = e.target.files?.[0]
  if (!file) return
  nomeFile.value = file.name
  const reader = new FileReader()
  reader.onload = () => {
    fotoPreview.value = reader.result
    fotoBase64.value  = reader.result.split(',')[1]
  }
  reader.readAsDataURL(file)
}

function configuratToken() {
  if (!tokenInput.value.trim()) return
  salvaToken(tokenInput.value.trim())
  tokenSalvato.value = true
  tokenInput.value   = ''
  window.location.reload()
}

async function aggiungiRichiesta() {
  if (!nuovoMessaggio.value.trim() || aggiungendo.value) return
  aggiungendo.value = true
  errore.value = null
  try {
    const id = `richiesta-${Date.now()}-${Math.random().toString(36).slice(2,7)}`
    const specieEsistenti = store.specie ? Object.values(store.specie).map(s => s.nome) : []
    const nuove = {
      ...raw.value,
      [id]: {
        tipo: nuovoTipo.value,
        messaggio: nuovoMessaggio.value.trim(),
        contesto: { specieEsistenti },
        speciesName: null,
        foto: fotoBase64.value ?? null,
        stato: 'in_attesa',
        creata: new Date().toISOString(),
        elaborata: null,
        risposta: null,
      }
    }
    await saveJSON('richieste-agente.json', nuove)
    raw.value = nuove
    nuovoMessaggio.value = ''
    fotoBase64.value  = null
    fotoPreview.value = null
    nomeFile.value    = ''
  } catch (e) {
    errore.value = e.message || 'Errore durante l\'invio della richiesta'
  } finally {
    aggiungendo.value = false
  }
}
</script>
