<template>
  <div class="agente-page">
    <!-- Storico conversazioni: drawer a scomparsa da sinistra -->
    <div class="hback" :class="{ open: sidebarAperta }" @click="sidebarAperta = false"></div>
    <aside id="hstore" class="hstore" :class="{ open: sidebarAperta }">
      <div class="hstore__hd">
        <b>Storico</b>
        <button type="button" class="hstore__new" @click="nuovaRichiesta">＋ Nuova</button>
      </div>

      <div class="hstore__list">
        <div v-for="r in richieste" :key="r.id" class="hitem-wrap">
          <a class="hitem" :class="{ on: r.id === richiestaSelezionataId }"
            role="button" tabindex="0"
            @click="selezionaRichiesta(r.id)" @keydown.enter="selezionaRichiesta(r.id)">
            <span class="hitem__ic">
              <Icon v-if="infoTipo(r.tipo).icon" :name="infoTipo(r.tipo).icon" />
            </span>
            <span class="hitem__m">
              <span class="hitem__t">{{ titoloRichiesta(r) }}</span>
              <span class="hitem__d">{{ formatData(r.creata) }}</span>
            </span>
            <span v-if="r.stato === 'in_attesa'" class="adot"></span>
          </a>
          <button type="button" class="hitem-kebab" aria-label="Altre azioni"
            @click.stop="toggleMenu(r.id, $event)">⋮</button>
        </div>
        <p v-if="!richieste.length" class="hstore__empty">Nessuna richiesta ancora</p>
      </div>
    </aside>

    <!-- Teleportato su body: la lista dello storico ha overflow-y auto, quindi
         un menu posizionato al suo interno verrebbe tagliato quando la riga è
         vicina al bordo scrollabile. -->
    <Teleport to="body">
      <div v-if="menuApertoId" class="agente-storico-menu" :style="{ top: menuPos.top + 'px', left: menuPos.left + 'px' }" @click.stop>
        <button type="button" class="agente-storico-menu-item" @click="apriEliminazione(menuApertoId)">
          <Icon name="cestino" style="width:14px;height:14px;" />Elimina
        </button>
      </div>
    </Teleport>

    <button type="button" class="htoggle" @click="sidebarAperta = true">
      <Icon name="lista" /> Storico
    </button>

    <h1 class="agente-h1">
      <ZorbaLogo style="width:30px;height:30px;flex-shrink:0;" />Zorba dice
    </h1>
    <p class="agente-sub">Elaborato da Claude Code · risposta entro pochi minuti</p>

    <!-- Token mancante -->
    <div v-if="!tokenPresente" class="agente-tokenbox">
      <p class="slabel">Token GitHub richiesto</p>
      <p class="prose">Serve un token con permesso <code>contents:write</code> per inviare richieste.</p>
      <RouterLink to="/account" class="btn btn-sage" style="display:inline-block;min-height:36px;padding:6px 14px;font-size:13px;">Vai su Account</RouterLink>
    </div>

    <!-- Nuova richiesta -->
    <div v-if="!richiestaSelezionata" class="agente-nuova">
      <p class="slabel">Nuova richiesta</p>

      <div class="reqchips">
        <button v-for="t in TIPI_RICHIESTA" :key="t.value" type="button" class="reqchip"
          :class="{ on: nuovoTipo === t.value }" @click="nuovoTipo = t.value">{{ t.label }}</button>
      </div>

      <!-- Revisione specie: indica quale specie, non serve una foto -->
      <div v-if="nuovoTipo === 'revisione_specie'" class="agente-extra">
        <SelettoreSpecie v-model="specieSelezionata" />
        <p class="agente-hint">Zorba controlla i campi mancanti o incompleti della scheda e li completa.</p>
      </div>

      <!-- Pianifica progetto: un progetto esistente da completare, oppure uno
           nuovo (basta il titolo, il resto lo ricava dalla descrizione) —
           anche qui non serve una foto. -->
      <div v-else-if="nuovoTipo === 'pianifica_progetto'" class="agente-extra">
        <select v-model="progettoSelezionato" class="form-input" style="margin-bottom:8px;">
          <option value="">➕ Nuovo progetto</option>
          <option v-for="p in progettiEsistenti" :key="p.id" :value="p.id">{{ p.titolo }}</option>
        </select>
        <input v-if="!progettoSelezionato" v-model="nuovoProgettoTitolo" placeholder="Titolo del nuovo progetto" class="form-input">
        <p class="agente-hint">Descrivi cosa vuoi fare: Zorba genera le tappe con le date attese.</p>
      </div>

      <div class="reqbox">
        <textarea v-model="nuovoMessaggio" :placeholder="placeholderMessaggio" rows="3"></textarea>

        <!-- Anteprima della foto selezionata -->
        <div v-if="fotoPreview && nuovoTipo !== 'revisione_specie' && nuovoTipo !== 'pianifica_progetto'" class="agente-foto-preview">
          <img :src="fotoPreview" alt="Anteprima della foto selezionata">
          <span class="agente-foto-nome">{{ nomeFile }}</span>
          <button type="button" @click="rimuoviFoto" aria-label="Rimuovi foto">×</button>
        </div>

        <div class="reqbar">
          <!-- Due input separati (libreria / fotocamera): su alcuni telefoni
               Android un input "accept=image/*" senza capture viene comunque
               risolto verso la fotocamera, saltando la scelta della libreria.
               Un input dedicato a ciascuna sorgente evita l'ambiguità. -->
          <span v-if="!fotoPreview && nuovoTipo !== 'revisione_specie' && nuovoTipo !== 'pianifica_progetto'" class="ph">
            <Icon name="fotocamera" />
            <label class="agente-foto-btn">Libreria
              <input type="file" accept="image/*" @change="selezionaFoto" hidden>
            </label>
            <label class="agente-foto-btn">Fotocamera
              <input type="file" accept="image/*" capture="environment" @change="selezionaFoto" hidden>
            </label>
          </span>
          <span v-else></span>

          <button type="button" class="reqsend" @click="aggiungiRichiesta"
            :disabled="!puoInviare || aggiungendo || !tokenPresente">
            <Spinner v-if="aggiungendo" />{{ aggiungendo ? 'Invio…' : 'Invia' }}
          </button>
        </div>
      </div>

      <p v-if="!fotoPreview && nuovoTipo !== 'revisione_specie' && nuovoTipo !== 'pianifica_progetto'" class="agente-hint">
        JPG, PNG — max 5 MB<span v-if="nuovoTipo === 'identifica_specie'"> · obbligatoria per identificare la specie</span>
      </p>

      <div v-if="errore" class="agente-errore">
        <Icon name="campanella" />{{ errore }}
      </div>
    </div>

    <!-- Dettaglio della richiesta selezionata nello storico -->
    <div v-else class="agente-dettaglio">
      <div class="agente-dettaglio-hd">
        <span class="hitem__ic">
          <Icon v-if="infoTipo(richiestaSelezionata.tipo).icon" :name="infoTipo(richiestaSelezionata.tipo).icon" />
        </span>
        <p class="agente-dettaglio-tipo">{{ infoTipo(richiestaSelezionata.tipo).label }}</p>
        <span class="badge" :style="stileBadge(richiestaSelezionata.stato)">{{ labelStato(richiestaSelezionata.stato) }}</span>
      </div>
      <p class="agente-dettaglio-data">{{ formatData(richiestaSelezionata.creata) }}</p>

      <!-- Specie coinvolta (solo revisione_specie) -->
      <p v-if="richiestaSelezionata.specie" class="agente-dettaglio-specie">
        {{ store.specie?.[richiestaSelezionata.specie]?.nome ?? richiestaSelezionata.specie }}
      </p>

      <!-- Messaggio utente -->
      <p v-if="richiestaSelezionata.messaggio" class="agente-dettaglio-msg">{{ richiestaSelezionata.messaggio }}</p>

      <!-- Foto allegata -->
      <div v-if="richiestaSelezionata.foto" class="agente-dettaglio-foto">
        <img :src="`data:image/jpeg;base64,${richiestaSelezionata.foto}`" alt="Foto allegata alla richiesta">
      </div>

      <!-- Risposta -->
      <div v-if="richiestaSelezionata.risposta?.messaggio" class="answer">
        <div class="answer__hd">
          <Icon name="lampadina" />
          Risposta · {{ infoTipo(richiestaSelezionata.tipo).label }} · {{ formatData(richiestaSelezionata.risposta?.completata ?? richiestaSelezionata.creata) }}
        </div>
        <div class="answer__body">
          <p class="answer__pre">{{ richiestaSelezionata.risposta.messaggio }}</p>
        </div>
      </div>

      <!-- In attesa -->
      <div v-else-if="richiestaSelezionata.stato === 'in_attesa'" class="agente-attesa">
        <span class="adot"></span>
        <p>In attesa di elaborazione da Claude Code…</p>
      </div>
    </div>

    <ModalConferma
      :aperto="daEliminare !== null"
      titolo="Eliminare questa richiesta?"
      messaggio="Questa azione non può essere annullata."
      :caricamento="eliminando"
      @conferma="confermaEliminazione"
      @annulla="daEliminare = null"
    />
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
import ModalConferma from '@/components/ModalConferma.vue'

const store = useDatiStore()
const { saveJSON, tokenPresente } = useApi()
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
const sidebarAperta = ref(false)
const richiestaSelezionataId = ref(null)
const menuApertoId = ref(null)
const menuPos = ref({ top: 0, left: 0 })
const daEliminare = ref(null)
const eliminando = ref(false)

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
  // Con una foto allegata, la descrizione testuale è facoltativa: identifica_specie
  // richiede comunque sempre la foto, diagnosi accetta foto oppure testo.
  if (nuovoTipo.value === 'identifica_specie') return !!fotoBase64.value
  if (nuovoTipo.value === 'diagnosi') return !!fotoBase64.value || !!nuovoMessaggio.value.trim()
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
  identifica_specie: 'Note aggiuntive (opzionale)…',
  diagnosi: 'Descrivi il problema (opzionale se alleghi una foto)…',
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

function toggleMenu(id, event) {
  if (menuApertoId.value === id) {
    menuApertoId.value = null
    return
  }
  const rect = event.currentTarget.getBoundingClientRect()
  const LARGHEZZA_MENU = 130
  menuPos.value = { top: rect.bottom + 4, left: Math.max(8, rect.right - LARGHEZZA_MENU) }
  menuApertoId.value = id
}

function chiudiMenu() {
  menuApertoId.value = null
}

function apriEliminazione(id) {
  daEliminare.value = id
  menuApertoId.value = null
}

async function confermaEliminazione() {
  if (!daEliminare.value) return
  eliminando.value = true
  try {
    const id = daEliminare.value
    const nuove = await saveJSON('richieste-agente.json', (correnti) => {
      const copia = { ...(correnti ?? raw.value) }
      delete copia[id]
      return copia
    })
    raw.value = nuove
    if (richiestaSelezionataId.value === id) richiestaSelezionataId.value = null
    daEliminare.value = null
  } catch (e) {
    errore.value = e.message || 'Errore durante l\'eliminazione'
  } finally {
    eliminando.value = false
  }
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
  window.addEventListener('click', chiudiMenu)
})

onUnmounted(() => {
  if (pollTimer) clearInterval(pollTimer)
  window.removeEventListener('click', chiudiMenu)
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
.agente-page { position: relative; }

/* --- intestazione locale --- */
.htoggle { margin-bottom: 14px; }
.agente-h1 {
  display: flex; align-items: center; gap: 9px;
  font: 600 23px/1.1 var(--font-display);
  letter-spacing: -0.01em;
  color: var(--ink);
  margin: 0 0 4px;
}
.agente-sub {
  font: 400 13px/1.5 var(--font-sans);
  color: var(--ink-soft);
  margin: 0 0 20px;
}

/* --- banner token mancante: card leggera, niente decorazione pesante --- */
.agente-tokenbox {
  border: 1px solid var(--gold-light);
  background: var(--gold-pale);
  border-radius: 12px;
  padding: 14px;
  margin-bottom: 18px;
}
.agente-tokenbox .slabel { margin-bottom: 8px; }
.agente-tokenbox .prose { margin: 0 0 10px; }

/* --- blocco nuova richiesta --- */
.agente-nuova { margin-bottom: 22px; }
.agente-nuova .slabel { margin-bottom: 12px; }
.agente-extra { margin-bottom: 12px; }
.agente-hint {
  font: 400 11.5px/1.5 var(--font-sans);
  color: var(--ink-soft);
  margin: 6px 0 0;
}
.reqchip { appearance: none; font-family: var(--font-sans); }
.reqbox textarea { font-family: var(--font-sans); }

.agente-foto-preview {
  display: flex; align-items: center; gap: 10px;
  margin-top: 10px;
}
.agente-foto-preview img {
  width: 40px; height: 40px; object-fit: cover;
  border-radius: 8px; flex-shrink: 0;
}
.agente-foto-nome {
  flex: 1; min-width: 0;
  font: 600 12px/1.3 var(--font-sans);
  color: var(--ink-mid);
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.agente-foto-preview button {
  background: none; border: none; cursor: pointer;
  color: var(--ink-soft); font-size: 20px; line-height: 1;
  flex-shrink: 0;
}
.reqbar .ph { flex-wrap: wrap; }
.agente-foto-btn {
  cursor: pointer;
  font: 600 11px/1 var(--font-sans);
  color: var(--sage-ink);
  text-decoration: underline;
  text-underline-offset: 2px;
}
.reqsend { display: inline-flex; align-items: center; gap: 6px; }
.reqsend:disabled { opacity: .5; cursor: not-allowed; }

.agente-errore {
  display: flex; align-items: center; gap: 6px;
  margin-top: 10px;
  padding: 8px 12px;
  background: var(--rose-pale);
  border: 1px solid var(--rose-light);
  border-radius: 10px;
  font: 400 12px/1.4 var(--font-sans);
  color: var(--rose-dark);
}
.agente-errore svg { width: 13px; height: 13px; flex-shrink: 0; }

/* --- storico: righe + kebab (drawer .hstore/.hitem sono globali, Fase 2) --- */
.hitem-wrap {
  position: relative;
  display: flex;
  align-items: center;
}
.hitem-wrap + .hitem-wrap { border-top: 1px solid var(--cream-dark); }
.hitem-wrap .hitem { flex: 1; min-width: 0; cursor: pointer; }
.hitem-kebab {
  flex-shrink: 0;
  background: none; border: none; cursor: pointer;
  color: var(--ink-soft);
  font-size: 16px;
  padding: 6px 10px;
}
.hstore__empty {
  font: 400 12px/1.5 var(--font-sans);
  color: var(--ink-soft);
  text-align: center;
  padding: 20px 8px;
}

/* --- menu kebab, teleportato su body --- */
.agente-storico-menu {
  position: fixed;
  z-index: 300;
  background: var(--white);
  border-radius: 10px;
  box-shadow: 0 8px 24px rgba(42,34,24,0.18);
  padding: 4px;
  min-width: 130px;
}
.agente-storico-menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 10px;
  border: none;
  background: none;
  border-radius: 8px;
  font-family: var(--font-sans);
  font-size: 12.5px;
  font-weight: 600;
  color: var(--rose-dark);
  cursor: pointer;
  text-align: left;
}
.agente-storico-menu-item:hover { background: var(--rose-pale); }

/* --- dettaglio richiesta selezionata --- */
.agente-dettaglio { margin-top: 4px; }
.agente-dettaglio-hd {
  display: flex; align-items: center; gap: 10px;
}
.agente-dettaglio-hd .hitem__ic { width: 22px; height: 22px; flex: none; }
.agente-dettaglio-hd .hitem__ic svg { width: 100%; height: 100%; }
.agente-dettaglio-tipo {
  flex: 1; min-width: 0;
  font: 600 14px/1.3 var(--font-display);
  color: var(--ink);
}
.agente-dettaglio-data {
  font: 400 11px/1.3 var(--font-sans);
  color: var(--ink-soft);
  margin: 6px 0 0;
}
.agente-dettaglio-specie {
  font: 600 13px/1.4 var(--font-sans);
  color: var(--sage-dark);
  margin: 12px 0 0;
}
.agente-dettaglio-msg {
  font: 400 13px/1.6 var(--font-sans);
  color: var(--ink-mid);
  white-space: pre-wrap;
  margin: 12px 0 0;
}
.agente-dettaglio-foto { margin-top: 12px; }
.agente-dettaglio-foto img {
  max-width: 200px;
  border-radius: 12px;
  border: 1px solid var(--cream-dark);
}
.answer__body .answer__pre { white-space: pre-wrap; }

.agente-attesa {
  display: flex; align-items: center; gap: 8px;
  margin-top: 16px;
  padding: 12px 14px;
  background: var(--gold-pale);
  border-radius: 12px;
  border-left: 3px solid var(--gold);
}
.agente-attesa p {
  font: 400 12px/1.4 var(--font-sans);
  color: var(--gold-dark);
}
</style>
