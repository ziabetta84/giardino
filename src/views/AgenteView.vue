<template>
  <div class="agente-page">
    <div class="agente-hd">
      <h1 class="agente-h1">
        <ZorbaLogo style="width:30px;height:30px;flex-shrink:0;" />Zorba dice
      </h1>
      <button type="button" class="pill agente-storico-btn" @click="storicoAperto = true">
        <Icon name="lista" /> Storico
        <span v-if="nonVisti" class="badge badge-gold">{{ nonVisti }}</span>
      </button>
    </div>
    <p class="agente-sub">Zorba controlla la coda quando può</p>

    <!-- Token mancante -->
    <div v-if="!tokenPresente" class="agente-tokenbox">
      <p class="slabel">Token GitHub richiesto</p>
      <p class="prose">Serve un token con permesso <code>contents:write</code> per inviare richieste.</p>
      <RouterLink to="/account" class="btn btn-sage" style="display:inline-block;min-height:36px;padding:6px 14px;font-size:13px;">Vai su Account</RouterLink>
    </div>

    <!-- Nuova richiesta: contenuto centrale finché non si apre una risposta dallo storico -->
    <div v-if="!richiestaSelezionata" class="agente-nuova">
      <p class="slabel">Nuova richiesta</p>

      <div class="reqgroups">
        <div v-for="g in GRUPPI_TIPO" :key="g.label" class="reqgroup">
          <span class="reqgroup__label">{{ g.label }}</span>
          <div class="reqchips">
            <button v-for="v in g.tipi" :key="v" type="button" class="reqchip"
              :class="{ on: nuovoTipo === v }" @click="selezionaTipo(v)">{{ TIPI_MAP[v].label }}</button>
          </div>
        </div>
      </div>
      <p class="agente-hint">{{ TIPI_MAP[nuovoTipo]?.hint }}</p>

      <!-- Revisione specie: indica quale specie, non serve una foto -->
      <div v-if="nuovoTipo === 'revisione_specie'" class="agente-extra">
        <SelettoreSpecie v-model="specieSelezionata" />
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

    <!-- Dettaglio e risposta della richiesta selezionata: sostituisce il
         compose form nel contenuto centrale, con un modo esplicito per
         tornare a scrivere una nuova richiesta. -->
    <div v-else class="agente-dettaglio">
      <button type="button" class="back-link agente-torna" @click="tornaANuova">
        <Icon name="back" />Nuova richiesta
      </button>
      <div class="agente-dettaglio-hd">
        <span class="areq__ic">
          <Icon v-if="infoTipo(richiestaSelezionata.tipo).icon" :name="infoTipo(richiestaSelezionata.tipo).icon" />
        </span>
        <p class="agente-dettaglio-tipo">{{ infoTipo(richiestaSelezionata.tipo).label }}</p>
        <span class="badge" :class="classeBadge(richiestaSelezionata.stato)">{{ labelStato(richiestaSelezionata.stato) }}</span>
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
        <p>In attesa che Zorba risponda…</p>
      </div>
    </div>

    <!-- Il Foglio: storico richieste, righe a filetti come nel resto dell'app -->
    <FoglioLaterale v-model="storicoAperto" titolo="Storico">
      <div class="foglio-form">
        <div v-if="richieste.length" class="feedlist">
          <div v-for="r in richieste" :key="r.id" class="feed feed--tap"
            role="button" tabindex="0"
            @click="selezionaRichiesta(r.id)" @keydown.enter="selezionaRichiesta(r.id)" @keydown.space.prevent="selezionaRichiesta(r.id)">
            <span class="areq__ic">
              <Icon v-if="infoTipo(r.tipo).icon" :name="infoTipo(r.tipo).icon" />
            </span>
            <div class="feed__m">
              <div class="feed__n">
                {{ titoloRichiesta(r) }}
                <span v-if="statoRiga(r)" class="badge" :class="statoRiga(r).classe">{{ statoRiga(r).testo }}</span>
              </div>
              <div class="feed__d">{{ formatData(r.creata) }}</div>
            </div>
            <button type="button" class="feed__del" aria-label="Elimina richiesta" @click.stop="apriEliminazione(r.id)">×</button>
          </div>
        </div>
        <div v-else class="empty">
          <Icon name="lampadina" />
          <p><b>Nessuna richiesta ancora</b>Scrivi a Zorba per identificare una specie, un consiglio di cura o un progetto da pianificare</p>
        </div>
      </div>
    </FoglioLaterale>

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
import FoglioLaterale from '@/components/FoglioLaterale.vue'

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
const storicoAperto = ref(false)
const richiestaSelezionataId = ref(null)
const daEliminare = ref(null)
const eliminando = ref(false)

const TIPI_RICHIESTA = [
  { value: 'identifica_specie',      label: 'Identifica da foto',        icon: 'foglia',       hint: 'Carica una foto: Zorba prova a riconoscere la specie.' },
  { value: 'revisione_specie',       label: 'Revisiona/completa specie', icon: 'matita',        hint: 'Zorba controlla i campi mancanti o incompleti della scheda e li completa.' },
  { value: 'consiglio_cura',         label: 'Consiglio per cura',        icon: 'goccia',        hint: 'Descrivi la pianta o il problema: Zorba consiglia come curarla.' },
  { value: 'consiglio_concimazione', label: 'Consiglio concimazione',    icon: 'concimazione',  hint: 'Zorba suggerisce quale concime della dispensa usare e con che dose.' },
  { value: 'diagnosi',               label: 'Diagnosi problema',         icon: 'cerca',         hint: 'Foto o descrizione di un problema: Zorba prova a capire cosa non va.' },
  { value: 'pianifica_progetto',     label: 'Pianifica progetto',        icon: 'lampadina',     hint: 'Descrivi cosa vuoi fare: Zorba genera le tappe con le date attese.' },
  { value: 'altro',                  label: 'Altro',                     icon: null,            hint: 'Qualcosa che non rientra nelle altre categorie.' },
]
const TIPI_MAP = Object.fromEntries(TIPI_RICHIESTA.map(t => [t.value, t]))
function infoTipo(tipo) {
  return TIPI_MAP[tipo] ?? { label: tipo?.replace(/_/g, ' ') ?? '', icon: null }
}

// Raggruppati per restare sotto la soglia di ~4 scelte visibili per decisione
// (7 tipi piatti la superavano — vedi critica del 07/09/2026).
const GRUPPI_TIPO = [
  { label: 'Specie',      tipi: ['identifica_specie', 'revisione_specie'] },
  { label: 'Cura',        tipi: ['consiglio_cura', 'consiglio_concimazione', 'diagnosi'] },
  { label: 'Varie',       tipi: ['pianifica_progetto', 'altro'] },
]

// Ogni tipo mostra campi diversi (foto, testo, specie, progetto): passare da
// uno all'altro azzera i campi del form precedente, altrimenti un valore
// nascosto dal tipo corrente (es. una foto allegata sotto "diagnosi") può
// finire silenziosamente in un invio di tipo diverso che non la mostra più.
function selezionaTipo(v) {
  if (nuovoTipo.value === v) return
  nuovoTipo.value = v
  nuovoMessaggio.value = ''
  specieSelezionata.value = ''
  progettoSelezionato.value = ''
  nuovoProgettoTitolo.value = ''
  fotoBase64.value = null
  fotoPreview.value = null
  nomeFile.value = ''
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

// --- "Nuovo": una risposta arrivata che l'utente non ha ancora aperto.
// Salvato solo in localStorage (come il token GitHub): richieste-agente.json
// resta senza scoping per utente, quindi il "letto" è per-browser, non condiviso.
const CHIAVE_VISTE = 'agente_risposte_viste'
function caricaViste() {
  try { return new Set(JSON.parse(localStorage.getItem(CHIAVE_VISTE) ?? '[]')) } catch { return new Set() }
}
const viste = ref(caricaViste())
function segnaVisto(id) {
  if (viste.value.has(id)) return
  viste.value = new Set(viste.value).add(id)
  try { localStorage.setItem(CHIAVE_VISTE, JSON.stringify([...viste.value])) } catch { /* localStorage non disponibile */ }
}
// Prima apertura in assoluto (chiave mai scritta): le richieste già risposte
// non contano come "nuove" solo perché questa funzionalità non esisteva prima.
function inizializzaViste() {
  if (localStorage.getItem(CHIAVE_VISTE) !== null) return
  const risposte = richieste.value.filter(r => r.stato !== 'in_attesa').map(r => r.id)
  viste.value = new Set(risposte)
  try { localStorage.setItem(CHIAVE_VISTE, JSON.stringify(risposte)) } catch { /* localStorage non disponibile */ }
}
const nonVisti = computed(() => richieste.value.filter(r => r.stato !== 'in_attesa' && !viste.value.has(r.id)).length)

function statoRiga(r) {
  if (r.stato === 'in_attesa') return { classe: 'badge-gold', testo: 'In attesa' }
  if (!viste.value.has(r.id)) return { classe: 'badge-gold', testo: 'Nuovo' }
  if (r.stato === 'errore') return { classe: 'badge-warn', testo: 'Errore' }
  return null
}

function selezionaRichiesta(id) {
  richiestaSelezionataId.value = id
  storicoAperto.value = false
  const r = richieste.value.find(x => x.id === id)
  if (r && r.stato !== 'in_attesa') segnaVisto(id)
}

function tornaANuova() {
  richiestaSelezionataId.value = null
}

function apriEliminazione(id) {
  daEliminare.value = id
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
  inizializzaViste()
  avviaPolling()
})

onUnmounted(() => {
  if (pollTimer) clearInterval(pollTimer)
})

function labelStato(stato) {
  if (stato === 'completata') return 'Completata'
  if (stato === 'errore') return 'Errore'
  return 'In attesa'
}

function classeBadge(stato) {
  if (stato === 'completata') return 'badge-ok'
  if (stato === 'errore') return 'badge-warn'
  return 'badge-gold'
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
.agente-hd { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 4px; }
/* Stessa tipografia di .page-title (26px/600/1.05), qui in flex per
   affiancare Zorba al titolo — .page-title da sola non lo consentirebbe. */
.agente-h1 {
  display: flex; align-items: center; gap: 9px;
  font: 600 26px/1.05 var(--font-display);
  letter-spacing: -0.01em;
  color: var(--ink);
  margin: 0;
}
.agente-sub {
  font: 400 13px/1.5 var(--font-sans);
  color: var(--ink-soft);
  margin: 0 0 20px;
}
.agente-storico-btn { display: inline-flex; align-items: center; gap: 6px; flex: none; }
.agente-storico-btn svg { width: 14px; height: 14px; }
.agente-storico-btn .badge { margin-left: 2px; }

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
.agente-nuova { margin-bottom: 26px; }
.agente-nuova .slabel { margin-bottom: 12px; }
.agente-extra { margin-bottom: 12px; }
.agente-hint {
  font: 400 11.5px/1.5 var(--font-sans);
  color: var(--ink-soft);
  margin: 6px 0 12px;
}
.reqchip { appearance: none; font-family: var(--font-sans); }
.reqbox textarea { font-family: var(--font-sans); }

.agente-foto-preview {
  display: flex; align-items: center; gap: 10px;
  margin-top: 10px;
}
.agente-foto-preview img {
  width: 40px; height: 40px; object-fit: cover;
  border-radius: 11px; flex-shrink: 0;
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
  border-radius: 12px;
  font: 400 12px/1.4 var(--font-sans);
  color: var(--rose-dark);
}
.agente-errore svg { width: 13px; height: 13px; flex-shrink: 0; }

/* --- storico, nel Foglio: righe a filetti (.feedlist/.feed sono globali) --- */
.areq__ic { width: 22px; height: 22px; flex: none; }
.areq__ic svg { width: 100%; height: 100%; }
.feedlist .feed--tap { cursor: pointer; }
.feedlist .feed__n { display: flex; align-items: center; gap: 8px; }
.feedlist .feed__del {
  flex: none;
  background: none;
  border: none;
  color: var(--ink-faint);
  font-size: 20px;
  line-height: 1;
  cursor: pointer;
  padding: 4px;
}
.feedlist .feed__del:hover { color: var(--rose-dark); }

/* --- dettaglio richiesta: contenuto centrale al posto del compose form --- */
.agente-torna {
  appearance: none; background: none; border: none; padding: 0; cursor: pointer;
}
.agente-dettaglio-hd {
  display: flex; align-items: center; gap: 10px;
}
/* Etichetta di categoria (es. "Diagnosi problema"), non un nome: DM Sans,
   non Fraunces — la specie sotto (.agente-dettaglio-specie) è il nome vero. */
.agente-dettaglio-tipo {
  flex: 1; min-width: 0;
  font: 600 14px/1.3 var(--font-sans);
  color: var(--ink);
}
.agente-dettaglio-data {
  font: 400 11px/1.3 var(--font-sans);
  color: var(--ink-soft);
  margin: 6px 0 0;
}
.agente-dettaglio-specie {
  font: 600 13px/1.4 var(--font-display);
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
  border: 1px solid var(--gold-light);
  border-radius: 12px;
}
.agente-attesa p {
  font: 400 12px/1.4 var(--font-sans);
  color: var(--gold-dark);
}
</style>
