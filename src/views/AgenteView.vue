<template>
  <div class="agente-layout">
    <!-- Sidebar: storico conversazioni -->
    <aside class="agente-sidebar" :class="{ aperta: sidebarAperta }">
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:12px;">
        <p class="section-label" style="margin:0;">Storico</p>
        <button type="button" class="icon-btn agente-sidebar-close" aria-label="Chiudi storico" @click="sidebarAperta = false">
          <Icon name="back" style="width:16px;height:16px;" />
        </button>
      </div>

      <button type="button" class="btn btn-sage" style="width:100%;margin-bottom:14px;" @click="nuovaRichiesta">
        ＋ Nuova richiesta
      </button>

      <div class="agente-sidebar-list">
        <button v-for="r in richieste" :key="r.id" type="button" class="agente-storico-riga"
          :class="{ active: r.id === richiestaSelezionataId }" @click="selezionaRichiesta(r.id)">
          <span class="agente-storico-icona">
            <Icon v-if="infoTipo(r.tipo).icon" :name="infoTipo(r.tipo).icon" />
          </span>
          <span class="agente-storico-testo">
            <span class="agente-storico-titolo">{{ titoloRichiesta(r) }}</span>
            <span class="agente-storico-data">{{ formatData(r.creata) }}</span>
          </span>
          <span v-if="r.stato === 'in_attesa'" class="pulse-dot" style="flex-shrink:0;"></span>
        </button>
        <p v-if="!richieste.length" class="text-light" style="font-size:12px;color:var(--ink-faint);text-align:center;padding:20px 8px;">
          Nessuna richiesta ancora
        </p>
      </div>
    </aside>
    <div v-if="sidebarAperta" class="agente-backdrop" @click="sidebarAperta = false"></div>

    <!-- Contenuto principale -->
    <div class="agente-main">
    <div style="display:flex;align-items:center;gap:8px;margin-bottom:4px;">
      <button type="button" class="icon-btn agente-storico-toggle" aria-label="Apri storico" @click="sidebarAperta = true">
        <Icon name="lista" style="width:18px;height:18px;" />
      </button>
      <h1 class="title-display gradient-title title-settle" style="display:flex;align-items:center;gap:9px;font-size:1.9rem;font-weight:800;margin:0;min-width:0;">
        <ZorbaLogo style="width:38px;height:38px;flex-shrink:0;" />Zorba dice
      </h1>
    </div>
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
    <div v-if="!richiestaSelezionata" class="card" style="padding:16px;margin-bottom:20px;border-color:var(--sage-light);">
      <p class="section-label" style="margin-bottom:10px;">Nuova richiesta</p>

      <div style="display:flex;gap:6px;flex-wrap:wrap;margin-bottom:10px;">
        <button v-for="t in TIPI_RICHIESTA" :key="t.value" type="button" class="pill tab-icona"
          :class="{ active: nuovoTipo === t.value }" @click="nuovoTipo = t.value">
          <Icon v-if="t.icon" :name="t.icon" />{{ t.label }}
        </button>
      </div>

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
        <Spinner v-if="aggiungendo" />{{ aggiungendo ? 'Invio…' : '→ Invia richiesta' }}
      </button>
    </div>

    <!-- Dettaglio della richiesta selezionata nello storico -->
    <div v-else class="card" style="padding:20px;">
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:14px;">
        <span class="badge" :style="stileBadge(richiestaSelezionata.stato)">{{ labelStato(richiestaSelezionata.stato) }}</span>
        <span style="font-size:11px;color:var(--ink-faint);">{{ formatData(richiestaSelezionata.creata) }}</span>
      </div>

      <div style="display:flex;align-items:center;gap:10px;margin-bottom:12px;">
        <span style="width:34px;height:34px;border-radius:50%;background:var(--sage-tile);display:flex;align-items:center;justify-content:center;flex-shrink:0;">
          <Icon v-if="infoTipo(richiestaSelezionata.tipo).icon" :name="infoTipo(richiestaSelezionata.tipo).icon" style="width:16px;height:16px;" />
        </span>
        <p style="font-size:14px;font-weight:600;color:var(--ink-soft);">{{ infoTipo(richiestaSelezionata.tipo).label }}</p>
      </div>

      <!-- Specie coinvolta (solo revisione_specie) -->
      <p v-if="richiestaSelezionata.specie" style="font-size:13px;font-weight:600;color:var(--sage-dark);margin-bottom:8px;">
        {{ store.specie?.[richiestaSelezionata.specie]?.nome ?? richiestaSelezionata.specie }}
      </p>

      <!-- Messaggio utente -->
      <p v-if="richiestaSelezionata.messaggio" style="font-size:13px;color:var(--ink-mid);line-height:1.6;white-space:pre-wrap;margin-bottom:8px;">{{ richiestaSelezionata.messaggio }}</p>

      <!-- Foto allegata -->
      <div v-if="richiestaSelezionata.foto" style="margin-bottom:8px;">
        <img :src="`data:image/jpeg;base64,${richiestaSelezionata.foto}`" style="max-width:200px;border-radius:12px;border:1px solid var(--cream-dark);">
      </div>

      <!-- Risposta -->
      <div v-if="richiestaSelezionata.risposta?.messaggio" style="margin-top:12px;padding:14px;background:var(--sage-pale);border-radius:12px;border-left:3px solid var(--sage);">
        <p style="font-size:11px;font-weight:600;color:var(--sage-dark);margin-bottom:4px;">Risposta</p>
        <p style="font-size:13px;color:var(--ink-mid);line-height:1.6;white-space:pre-wrap;">{{ richiestaSelezionata.risposta.messaggio }}</p>
      </div>

      <!-- In attesa -->
      <div v-else-if="richiestaSelezionata.stato === 'in_attesa'" style="margin-top:12px;padding:12px 14px;background:var(--gold-pale);border-radius:12px;border-left:3px solid var(--gold);display:flex;align-items:center;gap:8px;">
        <span class="pulse-dot"></span>
        <p style="font-size:12px;color:var(--gold-dark);">In attesa di elaborazione da Claude Code…</p>
      </div>
    </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useApi } from '@/composables/useApi'
import { useDatiStore } from '@/stores/dati'
import SelettoreSpecie from '@/components/SelettoreSpecie.vue'
import Icon from '@/components/Icon.vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import Spinner from '@/components/Spinner.vue'

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
const sidebarAperta = ref(false)
const richiestaSelezionataId = ref(null)

const TIPI_RICHIESTA = [
  { value: 'identifica_specie',      label: 'Identifica specie da foto',  icon: 'foglia' },
  { value: 'revisione_specie',       label: 'Revisiona/completa specie',  icon: 'matita' },
  { value: 'consiglio_cura',         label: 'Consiglio per cura',         icon: 'goccia' },
  { value: 'consiglio_concimazione', label: 'Consiglio concimazione',     icon: 'concimazione' },
  { value: 'diagnosi',               label: 'Diagnosi problema',          icon: 'cerca' },
  { value: 'pianifica_progetto',     label: 'Pianifica progetto',         icon: 'lampadina' },
  { value: 'altro',                  label: 'Altro',                      icon: null },
]
const TIPI_MAP = Object.fromEntries(TIPI_RICHIESTA.map(t => [t.value, t]))
function infoTipo(tipo) {
  return TIPI_MAP[tipo] ?? { label: tipo?.replace(/_/g, ' ') ?? '', icon: null }
}

function titoloRichiesta(r) {
  if (r.tipo === 'revisione_specie' && r.specie) return store.specie?.[r.specie]?.nome ?? r.specie
  if (r.tipo === 'pianifica_progetto') {
    if (r.progetto) return store.progetti?.[r.progetto]?.titolo ?? infoTipo(r.tipo).label
    if (r.titolo_progetto) return r.titolo_progetto
  }
  return r.messaggio || infoTipo(r.tipo).label
}

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

const richiestaSelezionata = computed(() =>
  richieste.value.find(r => r.id === richiestaSelezionataId.value) ?? null
)

function selezionaRichiesta(id) {
  richiestaSelezionataId.value = id
  sidebarAperta.value = false
}

function nuovaRichiesta() {
  richiestaSelezionataId.value = null
  sidebarAperta.value = false
}

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
  return '○ In attesa'
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
    richiestaSelezionataId.value = id
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
.tab-icona { display: inline-flex; align-items: center; gap: 5px; }
.tab-icona :deep(svg) { width: 14px; height: 14px; flex-shrink: 0; }

/* Layout a due colonne, come le altre app di AI: storico a sinistra,
   conversazione/composer a destra. Sotto i 640px (soglia mobile già
   usata nel resto dell'app) lo storico diventa un cassetto a
   scomparsa, aperto dal bottone "lista" accanto al titolo. */
.agente-layout {
  display: flex;
  gap: 20px;
  align-items: flex-start;
}
.agente-sidebar {
  width: 260px;
  flex-shrink: 0;
}
.agente-main {
  flex: 1;
  min-width: 0;
}
.agente-sidebar-close,
.agente-storico-toggle {
  display: none;
}
.agente-sidebar-list {
  display: flex;
  flex-direction: column;
  gap: 2px;
  max-height: 60vh;
  overflow-y: auto;
}
.agente-storico-riga {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  text-align: left;
  padding: 8px;
  border-radius: 12px;
  border: none;
  background: none;
  cursor: pointer;
  font-family: var(--font-sans);
  transition: background 0.15s;
}
.agente-storico-riga:hover { background: var(--cream); }
.agente-storico-riga.active { background: var(--sage-pale); }
.agente-storico-icona {
  width: 30px; height: 30px; border-radius: 50%;
  background: var(--sage-tile);
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.agente-storico-icona :deep(svg) { width: 15px; height: 15px; }
.agente-storico-testo {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.agente-storico-titolo {
  font-size: 12.5px;
  font-weight: 600;
  color: var(--ink-mid);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.agente-storico-data {
  font-size: 10.5px;
  color: var(--ink-faint);
}
.icon-btn {
  background: none; border: none; cursor: pointer; color: var(--ink-mid);
  padding: 8px; border-radius: 10px;
  display: inline-flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.icon-btn:hover { background: var(--cream); }
.agente-backdrop { display: none; }

@media (max-width: 640px) {
  .agente-sidebar {
    position: fixed; top: 0; bottom: 0; left: 0;
    width: 82vw; max-width: 320px;
    background: var(--cream);
    padding: 20px 16px;
    box-shadow: 8px 0 24px rgba(42,34,24,0.15);
    transform: translateX(-100%);
    transition: transform 0.25s ease;
    overflow-y: auto;
    z-index: 150;
  }
  .agente-sidebar.aperta { transform: translateX(0); }
  .agente-sidebar-list { max-height: none; }
  .agente-sidebar-close,
  .agente-storico-toggle { display: inline-flex; }
  .agente-backdrop {
    display: block;
    position: fixed; inset: 0;
    background: rgba(42,34,24,0.4);
    z-index: 140;
  }
}
</style>
