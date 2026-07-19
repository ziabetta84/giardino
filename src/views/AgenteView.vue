<template>
  <div>
    <h1 class="title-display gradient-title" style="font-size:1.9rem;font-weight:800;margin-bottom:4px;">Assistente</h1>
    <p style="font-size:13px;color:var(--ink-soft);margin-bottom:20px;">Elaborato da Claude Code · risposte entro pochi minuti</p>

    <!-- Token mancante -->
    <div v-if="!tokenSalvato" class="card" style="padding:16px;margin-bottom:16px;border-color:var(--gold-light);background:var(--gold-pale);">
      <p style="font-size:13px;font-weight:600;color:var(--gold-dark);margin-bottom:4px;">🔑 Token GitHub richiesto</p>
      <p style="font-size:12px;color:var(--ink-soft);margin-bottom:10px;">Serve un token con permesso <code>contents:write</code> per inviare richieste.</p>
      <div style="display:flex;gap:8px;">
        <input v-model="tokenInput" type="password" placeholder="ghp_…" class="form-input"
          style="flex:1;min-height:36px;font-size:13px;" @keyup.enter="configuratToken">
        <button @click="configuratToken" :disabled="!tokenInput.trim()" class="btn btn-sage"
          style="min-height:36px;padding:6px 14px;font-size:13px;">Salva</button>
      </div>
    </div>

    <!-- Nuova richiesta -->
    <div class="card" style="padding:16px;margin-bottom:20px;border-color:var(--sage-light);">
      <p class="section-label" style="margin-bottom:10px;">Nuova richiesta</p>

      <select v-model="nuovoTipo" class="form-input" style="margin-bottom:10px;">
        <option value="identifica_specie">🌿 Identifica specie da foto</option>
        <option value="consiglio_cura">💧 Consiglio per cura</option>
        <option value="diagnosi">🔍 Diagnosi problema</option>
        <option value="altro">💬 Altro</option>
      </select>

      <!-- Upload foto -->
      <label style="display:flex;align-items:center;gap:10px;padding:12px 14px;border:1.5px dashed var(--sage-light);border-radius:12px;cursor:pointer;background:var(--sage-pale);margin-bottom:10px;">
        <span style="font-size:22px;">📷</span>
        <div style="flex:1;">
          <div style="font-size:13px;font-weight:600;color:var(--sage-dark);">{{ fotoPreview ? nomeFile : 'Allega una foto (opzionale)' }}</div>
          <div style="font-size:11px;color:var(--ink-soft);margin-top:2px;">{{ fotoPreview ? 'Tocca per cambiare' : 'JPG, PNG — max 5 MB' }}</div>
        </div>
        <img v-if="fotoPreview" :src="fotoPreview" style="width:48px;height:48px;object-fit:cover;border-radius:8px;flex-shrink:0;">
        <input type="file" accept="image/*" @change="selezionaFoto" style="display:none;">
      </label>

      <textarea v-model="nuovoMessaggio" placeholder="Descrivi la richiesta…"
        rows="3" class="form-input" style="resize:vertical;font-family:inherit;margin-bottom:10px;"></textarea>

      <div v-if="errore" style="margin-bottom:10px;padding:8px 12px;background:var(--rose-pale);border-radius:10px;border:1px solid var(--rose-light);">
        <p style="font-size:12px;color:var(--rose-dark);">⚠ {{ errore }}</p>
      </div>

      <button @click="aggiungiRichiesta" :disabled="!nuovoMessaggio.trim() || aggiungendo || !tokenSalvato"
        class="btn btn-sage" style="width:100%;">
        {{ aggiungendo ? '⏳ Invio…' : '→ Invia richiesta' }}
      </button>
    </div>

    <!-- Richieste -->
    <template v-if="richieste.length">
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:10px;">
        <p class="section-label" style="margin-bottom:0;">Storico richieste</p>
        <span v-if="inAttesa > 0" style="font-size:11px;color:var(--gold-dark);display:flex;align-items:center;gap:4px;">
          <span class="pulse-dot"></span> {{ inAttesa }} in attesa…
        </span>
      </div>

      <div style="display:flex;flex-direction:column;gap:8px;">
        <div v-for="r in richieste" :key="r.id" class="card" style="padding:14px 16px;">
          <!-- Header -->
          <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;">
            <span class="badge" :style="stileBadge(r.stato)">{{ labelStato(r.stato) }}</span>
            <span style="font-size:11px;color:var(--ink-faint);">{{ formatData(r.creata) }}</span>
          </div>

          <!-- Tipo -->
          <p style="font-size:12px;font-weight:600;color:var(--ink-soft);margin-bottom:4px;text-transform:capitalize;">
            {{ r.tipo?.replace(/_/g,' ') }}
          </p>

          <!-- Messaggio utente -->
          <p style="font-size:13px;color:var(--ink-mid);line-height:1.5;white-space:pre-wrap;">{{ r.messaggio }}</p>

          <!-- Foto allegata -->
          <div v-if="r.foto" style="margin-top:8px;">
            <img :src="`data:image/jpeg;base64,${r.foto}`" style="max-width:120px;border-radius:10px;border:1px solid var(--cream-dark);">
          </div>

          <!-- Risposta -->
          <div v-if="r.risposta?.messaggio" style="margin-top:10px;padding:12px;background:var(--sage-pale);border-radius:10px;border-left:3px solid var(--sage);">
            <p style="font-size:11px;font-weight:600;color:var(--sage-dark);margin-bottom:4px;">Risposta</p>
            <p style="font-size:13px;color:var(--ink-mid);line-height:1.6;white-space:pre-wrap;">{{ r.risposta.messaggio }}</p>
          </div>

          <!-- In attesa -->
          <div v-else-if="r.stato === 'in_attesa'" style="margin-top:10px;padding:10px 12px;background:var(--gold-pale);border-radius:10px;border-left:3px solid var(--gold);">
            <p style="font-size:12px;color:var(--gold-dark);">⏳ In attesa di elaborazione da Claude Code…</p>
          </div>
        </div>
      </div>
    </template>

    <div v-else style="text-align:center;padding:40px 20px;color:var(--ink-faint);">
      <div style="font-size:40px;margin-bottom:12px;">🌿</div>
      <p style="font-size:13px;">Nessuna richiesta ancora</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useApi } from '@/composables/useApi'
import { useDatiStore } from '@/stores/dati'

const store = useDatiStore()
const { saveJSON, isAutenticato, salvaToken } = useApi()
const BASE = import.meta.env.BASE_URL

const raw          = ref({})
const nuovoTipo    = ref('identifica_specie')
const nuovoMessaggio = ref('')
const aggiungendo  = ref(false)
const fotoBase64   = ref(null)
const fotoPreview  = ref(null)
const nomeFile     = ref('')
const errore       = ref(null)
const tokenInput   = ref('')
const tokenSalvato = ref(isAutenticato())

let pollTimer = null

const richieste = computed(() =>
  Object.entries(raw.value)
    .map(([id, r]) => ({ id, ...r }))
    .sort((a, b) => new Date(b.creata) - new Date(a.creata))
)

const inAttesa = computed(() => richieste.value.filter(r => r.stato === 'in_attesa').length)

async function caricaRichieste() {
  try {
    const res = await fetch(`${BASE}data/richieste-agente.json?t=${Date.now()}`)
    raw.value = res.ok ? await res.json() : {}
  } catch { raw.value = {} }
}

function avviaPolling() {
  if (pollTimer) return
  pollTimer = setInterval(async () => {
    if (inAttesa.value > 0) await caricaRichieste()
  }, 30000)
}

onMounted(async () => {
  await store.caricaTutto()
  await caricaRichieste()
  avviaPolling()
})

onUnmounted(() => {
  if (pollTimer) clearInterval(pollTimer)
})

function labelStato(stato) {
  if (stato === 'completata') return '✓ Completata'
  if (stato === 'errore') return '✗ Errore'
  return '⏳ In attesa'
}

function stileBadge(stato) {
  if (stato === 'completata') return 'background:var(--sage-pale);color:var(--sage-dark);'
  if (stato === 'errore') return 'background:var(--rose-pale);color:var(--rose-dark);'
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
  e.target.value = ''
}

function configuratToken() {
  if (!tokenInput.value.trim()) return
  salvaToken(tokenInput.value.trim())
  tokenSalvato.value = true
  tokenInput.value = ''
  window.location.reload()
}

async function aggiungiRichiesta() {
  if (!nuovoMessaggio.value.trim() || aggiungendo.value) return
  aggiungendo.value = true
  errore.value = null
  try {
    const id = `r-${Date.now()}-${Math.random().toString(36).slice(2,6)}`
    const nuove = {
      ...raw.value,
      [id]: {
        tipo: nuovoTipo.value,
        messaggio: nuovoMessaggio.value.trim(),
        foto: fotoBase64.value ?? null,
        stato: 'in_attesa',
        creata: new Date().toISOString(),
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
    errore.value = e.message || 'Errore durante l\'invio'
  } finally {
    aggiungendo.value = false
  }
}
</script>

<style scoped>
.pulse-dot {
  width: 7px; height: 7px; border-radius: 50%;
  background: var(--gold);
  display: inline-block;
  animation: pulse-dot 1.4s ease-in-out infinite;
}
@keyframes pulse-dot {
  0%, 100% { opacity: .4; transform: scale(.8); }
  50%       { opacity: 1;  transform: scale(1.2); }
}
</style>
