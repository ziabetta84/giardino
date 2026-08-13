<template>
  <div>
    <h1 class="title-display gradient-title" style="display:flex;align-items:center;gap:9px;font-size:1.9rem;font-weight:800;margin-bottom:4px;">
      <Icon name="gatto" style="width:26px;height:26px;flex-shrink:0;" />Zorba dice
    </h1>
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
        <option value="revisione_specie">📋 Revisiona/completa specie</option>
        <option value="consiglio_cura">💧 Consiglio per cura</option>
        <option value="consiglio_concimazione">🌱 Consiglio concimazione</option>
        <option value="diagnosi">🔍 Diagnosi problema</option>
        <option value="pianifica_progetto">🗂️ Pianifica progetto</option>
        <option value="altro">💬 Altro</option>
      </select>

      <!-- Revisione specie: indica quale specie, non serve una foto -->
      <div v-if="nuovoTipo === 'revisione_specie'" style="margin-bottom:10px;">
        <SelettoreSpecie v-model="specieSelezionata" />
        <p style="font-size:11px;color:var(--ink-soft);margin-top:6px;">Zorba controlla i campi mancanti o incompleti della scheda e li completa.</p>
      </div>

      <!-- Pianifica progetto: un progetto esistente da completare, oppure uno
           nuovo (basta il titolo, il resto lo ricava dalla descrizione) —
           anche qui non serve una foto. -->
      <div v-else-if="nuovoTipo === 'pianifica_progetto'" style="margin-bottom:10px;">
        <select v-model="progettoSelezionato" class="form-input" style="margin-bottom:8px;">
          <option value="">➕ Nuovo progetto</option>
          <option v-for="p in progettiEsistenti" :key="p.id" :value="p.id">{{ p.titolo }}</option>
        </select>
        <input v-if="!progettoSelezionato" v-model="nuovoProgettoTitolo" placeholder="Titolo del nuovo progetto" class="form-input">
        <p style="font-size:11px;color:var(--ink-soft);margin-top:6px;">Descrivi cosa vuoi fare: Zorba genera le tappe con le date attese.</p>
      </div>

      <!-- Upload foto -->
      <div v-else style="margin-bottom:10px;">
        <div v-if="fotoPreview" style="display:flex;align-items:center;gap:10px;padding:10px 14px;border:1.5px solid var(--sage-light);border-radius:12px;background:var(--sage-pale);margin-bottom:8px;">
          <img :src="fotoPreview" alt="Anteprima della foto selezionata" style="width:44px;height:44px;object-fit:cover;border-radius:8px;flex-shrink:0;">
          <div style="flex:1;font-size:13px;font-weight:600;color:var(--sage-dark);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">{{ nomeFile }}</div>
          <button type="button" @click="rimuoviFoto" aria-label="Rimuovi foto" style="background:none;border:none;color:var(--ink-faint);font-size:20px;line-height:1;cursor:pointer;flex-shrink:0;">×</button>
        </div>

        <!-- Due bottoni separati invece di un unico input generico: su alcuni
             browser/telefoni Android un input "accept=image/*" senza capture
             viene comunque risolto dal sistema verso la fotocamera, saltando
             la scelta della libreria. Un bottone dedicato alla libreria (senza
             alcun attributo capture) e uno dedicato alla fotocamera evitano
             del tutto questa ambiguità. Nascosti quando una foto è già
             selezionata (rimuovila con la "×" per sceglierne un'altra), per
             non occupare spazio prezioso su schermo mobile. -->
        <div v-else style="display:flex;gap:8px;">
          <label style="flex:1;display:flex;align-items:center;justify-content:center;gap:6px;padding:12px;border:1.5px dashed var(--sage-light);border-radius:12px;cursor:pointer;background:var(--sage-pale);font-size:13px;font-weight:600;color:var(--sage-dark);">
            <Icon name="cornice" style="width:16px;height:16px;flex-shrink:0;" />Libreria
            <input type="file" accept="image/*" @change="selezionaFoto" style="display:none;">
          </label>
          <label style="flex:1;display:flex;align-items:center;justify-content:center;gap:6px;padding:12px;border:1.5px dashed var(--sage-light);border-radius:12px;cursor:pointer;background:var(--sage-pale);font-size:13px;font-weight:600;color:var(--sage-dark);">
            <Icon name="fotocamera" style="width:16px;height:16px;flex-shrink:0;" />Fotocamera
            <input type="file" accept="image/*" capture="environment" @change="selezionaFoto" style="display:none;">
          </label>
        </div>
        <p v-if="!fotoPreview" style="font-size:11px;color:var(--ink-soft);margin-top:6px;text-align:center;">JPG, PNG — max 5 MB</p>
      </div>

      <textarea v-model="nuovoMessaggio" :placeholder="placeholderMessaggio"
        rows="3" class="form-input" style="resize:vertical;font-family:inherit;margin-bottom:10px;"></textarea>

      <div v-if="errore" style="margin-bottom:10px;padding:8px 12px;background:var(--rose-pale);border-radius:10px;border:1px solid var(--rose-light);">
        <p style="display:flex;align-items:center;gap:6px;font-size:12px;color:var(--rose-dark);">
          <Icon name="campanella" style="width:13px;height:13px;flex-shrink:0;" />{{ errore }}
        </p>
      </div>

      <button @click="aggiungiRichiesta" :disabled="!puoInviare || aggiungendo || !tokenSalvato"
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

          <!-- Specie coinvolta (solo revisione_specie) -->
          <p v-if="r.specie" style="font-size:13px;font-weight:600;color:var(--sage-dark);margin-bottom:4px;">
            🌿 {{ store.specie?.[r.specie]?.nome ?? r.specie }}
          </p>

          <!-- Messaggio utente -->
          <p v-if="r.messaggio" style="font-size:13px;color:var(--ink-mid);line-height:1.5;white-space:pre-wrap;">{{ r.messaggio }}</p>

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
      <div style="width:56px;height:56px;border-radius:50%;background:var(--gold-tile);display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
        <Icon name="gatto" style="width:24px;height:24px;" />
      </div>
      <p style="font-size:13px;">Nessuna richiesta ancora</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useApi } from '@/composables/useApi'
import { useDatiStore } from '@/stores/dati'
import SelettoreSpecie from '@/components/SelettoreSpecie.vue'
import Icon from '@/components/Icon.vue'

const store = useDatiStore()
const { saveJSON, isAutenticato, salvaToken } = useApi()
const BASE = import.meta.env.BASE_URL

const raw          = ref({})
const nuovoTipo    = ref('identifica_specie')
const nuovoMessaggio = ref('')
const specieSelezionata = ref('')
const progettoSelezionato = ref('')
const nuovoProgettoTitolo = ref('')
const aggiungendo  = ref(false)
const fotoBase64   = ref(null)
const fotoPreview  = ref(null)
const nomeFile     = ref('')
const errore       = ref(null)
const tokenInput   = ref('')
const tokenSalvato = ref(isAutenticato())

const puoInviare = computed(() => {
  if (nuovoTipo.value === 'revisione_specie') return !!specieSelezionata.value
  if (nuovoTipo.value === 'pianifica_progetto') {
    return !!nuovoMessaggio.value.trim() && (!!progettoSelezionato.value || !!nuovoProgettoTitolo.value.trim())
  }
  return !!nuovoMessaggio.value.trim()
})

const progettiEsistenti = computed(() => {
  if (!store.progetti) return []
  return Object.entries(store.progetti)
    .map(([id, p]) => ({ id, titolo: p.titolo }))
    .sort((a, b) => a.titolo.localeCompare(b.titolo))
})

const PLACEHOLDER_MESSAGGIO = {
  revisione_specie: 'Note aggiuntive (opzionale)…',
  pianifica_progetto: 'Descrivi il progetto: cosa vuoi fare, dove, entro quando…',
}
const placeholderMessaggio = computed(() => PLACEHOLDER_MESSAGGIO[nuovoTipo.value] ?? 'Descrivi la richiesta…')

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

const MAX_FOTO_BYTES = 5 * 1024 * 1024

function selezionaFoto(e) {
  const file = e.target.files?.[0]
  if (!file) return
  if (file.size > MAX_FOTO_BYTES) {
    errore.value = 'La foto è troppo grande (limite 5 MB).'
    e.target.value = ''
    return
  }
  errore.value = null
  nomeFile.value = file.name
  const reader = new FileReader()
  reader.onload = () => {
    fotoPreview.value = reader.result
    fotoBase64.value  = reader.result.split(',')[1]
  }
  reader.readAsDataURL(file)
  e.target.value = ''
}

function rimuoviFoto() {
  fotoBase64.value  = null
  fotoPreview.value = null
  nomeFile.value    = ''
}

function configuratToken() {
  if (!tokenInput.value.trim()) return
  salvaToken(tokenInput.value.trim())
  tokenSalvato.value = true
  tokenInput.value = ''
  window.location.reload()
}

async function aggiungiRichiesta() {
  if (!puoInviare.value || aggiungendo.value) return
  aggiungendo.value = true
  errore.value = null
  try {
    const id = `r-${Date.now()}-${Math.random().toString(36).slice(2,6)}`
    const nuove = await saveJSON('richieste-agente.json', (correnti) => ({
      ...(correnti ?? raw.value),
      [id]: {
        tipo: nuovoTipo.value,
        messaggio: nuovoMessaggio.value.trim(),
        specie: nuovoTipo.value === 'revisione_specie' ? specieSelezionata.value : null,
        progetto: nuovoTipo.value === 'pianifica_progetto' ? (progettoSelezionato.value || null) : null,
        titolo_progetto: nuovoTipo.value === 'pianifica_progetto' && !progettoSelezionato.value ? nuovoProgettoTitolo.value.trim() : null,
        foto: fotoBase64.value ?? null,
        stato: 'in_attesa',
        creata: new Date().toISOString(),
        risposta: null,
      }
    }))
    raw.value = nuove
    nuovoMessaggio.value = ''
    specieSelezionata.value = ''
    progettoSelezionato.value = ''
    nuovoProgettoTitolo.value = ''
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
