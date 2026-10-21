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
    <p class="agente-sub">Chiedi a Zorba: risponde subito, e puoi continuare la conversazione.</p>

    <!-- Nuova richiesta: contenuto centrale finché non si apre una risposta dallo storico -->
    <div v-if="!filo" class="agente-nuova">
      <p class="slabel">Nuova richiesta</p>
      <div v-if="!online" class="agente-avviso">Sei offline: lo storico resta consultabile, per scrivere a Zorba serve la connessione.</div>
      <div v-else-if="inPausa" class="agente-avviso">Zorba è in pausa in questo momento: riprova più tardi.</div>
      <div v-else-if="esaurite && statoZorba.tipo_tetto === 'prova'" class="agente-avviso">
        <b>Hai usato le risposte di prova.</b> Zorba è riservato agli abbonati: chiedi l'abbonamento a chi gestisce l'app.
      </div>
      <div v-else-if="esaurite" class="agente-avviso">Hai usato tutte le risposte di questo mese: si riparte il {{ ripartenza }}.</div>

      <template v-if="!bloccato">

      <div class="reqgroups">
        <div v-for="g in GRUPPI_TIPO" :key="g.label" class="reqgroup">
          <span class="reqgroup__label">{{ g.label }}</span>
          <div class="reqchips">
            <button v-for="v in g.tipi" :key="v" type="button" class="reqchip"
              :class="{ on: nuovoTipo === v }" @click="selezionaTipo(v)">{{ infoTipo(v).label }}</button>
          </div>
        </div>
      </div>
      <p class="agente-hint">{{ infoTipo(nuovoTipo)?.hint }}</p>

      <!-- Segnalazione scheda: indica quale specie, non serve una foto -->
      <div v-if="nuovoTipo === 'segnalazione_scheda'" class="agente-extra">
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
        <div v-if="foto && !SENZA_FOTO.includes(nuovoTipo)" class="agente-foto-preview">
          <img :src="foto.anteprima" alt="Anteprima della foto selezionata">
          <button type="button" @click="foto = null" aria-label="Rimuovi foto">×</button>
        </div>

        <div class="reqbar">
          <!-- Due input separati (libreria / fotocamera): su alcuni telefoni
               Android un input "accept=image/*" senza capture viene comunque
               risolto verso la fotocamera, saltando la scelta della libreria.
               Un input dedicato a ciascuna sorgente evita l'ambiguità. -->
          <span v-if="!foto && !SENZA_FOTO.includes(nuovoTipo)" class="ph">
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
            :disabled="!puoInviare || aggiungendo || bloccato">
            <Spinner v-if="aggiungendo" />{{ aggiungendo ? 'Invio…' : 'Invia' }}
          </button>
        </div>
      </div>

      <p v-if="!foto && !SENZA_FOTO.includes(nuovoTipo)" class="agente-hint">
        JPG, PNG o HEIC: la foto viene ridotta prima dell'invio<span v-if="nuovoTipo === 'identifica_specie'"> · obbligatoria per identificare la specie</span>
      </p>

      <p v-if="rigaRimaste" class="agente-hint">{{ rigaRimaste }}</p>
      </template>

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
        <span class="areq__ic"><Icon v-if="infoTipo(filo.tipo).icon" :name="infoTipo(filo.tipo).icon" /></span>
        <p class="agente-dettaglio-tipo">{{ infoTipo(filo.tipo).label }}</p>
      </div>
      <p class="agente-dettaglio-data">{{ formatData(filo.creato) }}</p>
      <p v-if="filo.voce" class="agente-dettaglio-specie">{{ titoloFilo(filo, store) }}</p>
      <ZorbaFilo ref="filoRef" :filo="filo" :messaggi="messaggi" :in-corso="inCorso" :progetto="progettoDelFilo" :bloccato="bloccato"
        @rispondi="rispondi" @riprova="riprova" @vota="vota" @nuova="tornaANuova" />
      <div v-if="errore" class="agente-errore"><Icon name="campanella" />{{ errore }}</div>
    </div>

    <!-- Il Foglio: storico richieste, righe a filetti come nel resto dell'app -->
    <FoglioLaterale v-model="storicoAperto" titolo="Storico">
      <div class="foglio-form">
        <div v-if="fili.length" class="feedlist">
          <div v-for="f in fili" :key="f.id" class="feed feed--tap"
            role="button" tabindex="0"
            @click="apriFilo(f.id)" @keydown.enter="apriFilo(f.id)" @keydown.space.prevent="apriFilo(f.id)">
            <span class="areq__ic">
              <Icon v-if="infoTipo(f.tipo).icon" :name="infoTipo(f.tipo).icon" />
            </span>
            <div class="feed__m">
              <div class="feed__n">
                {{ titoloFilo(f, store) }}
                <span v-if="f.nuova_risposta" class="badge badge-gold">Nuovo</span><span v-else-if="f.segnalazione_stato === 'in_attesa'" class="badge badge-gold">In attesa</span>
              </div>
              <div class="feed__d">{{ formatData(f.aggiornato) }}</div>
            </div>
            <button type="button" class="feed__del" aria-label="Elimina conversazione" @click.stop="daEliminare = f.id">×</button>
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
      titolo="Eliminare questa conversazione?"
      messaggio="Le foto vengono cancellate. Le risposte già ricevute restano contate nel mese."
      :caricamento="eliminando"
      @conferma="confermaEliminazione"
      @annulla="daEliminare = null"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { useZorba } from '@/composables/useZorba'
import { ridimensionaFoto } from '@/utils/foto'
import SelettoreSpecie from '@/components/SelettoreSpecie.vue'
import Icon from '@/components/Icon.vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import Spinner from '@/components/Spinner.vue'
import ModalConferma from '@/components/ModalConferma.vue'
import FoglioLaterale from '@/components/FoglioLaterale.vue'
import ZorbaFilo from '@/components/ZorbaFilo.vue'
import { infoTipo, titoloFilo, formatData } from '@/composables/useRichiesteAgente'

const store = useDatiStore()
const route = useRoute()
const router = useRouter()
const zorba = useZorba()

const fili = ref([])
const filoId = ref(null)
const messaggi = ref([])
const statoZorba = ref(null)
const inCorso = ref(null)          // { id, stati: [], testo: '' } mentre Zorba scrive
const progettoCreato = ref(null)
const online = ref(navigator.onLine)
const aggiornaRete = () => { online.value = navigator.onLine }
window.addEventListener('online', aggiornaRete)
window.addEventListener('offline', aggiornaRete)
onUnmounted(() => {
  window.removeEventListener('online', aggiornaRete)
  window.removeEventListener('offline', aggiornaRete)
})

const nuovoTipo = ref('identifica_specie')
const nuovoMessaggio = ref('')
const specieSelezionata = ref('')
const progettoSelezionato = ref('')
const nuovoProgettoTitolo = ref('')
const foto = ref(null)             // { base64, anteprima }
const aggiungendo = ref(false)
const errore = ref(null)
const storicoAperto = ref(false)
const filoRef = ref(null)
const daEliminare = ref(null)
const eliminando = ref(false)

// Raggruppati per restare sotto la soglia di ~4 scelte visibili per decisione (critica del 07/09/2026)
const GRUPPI_TIPO = [
  { label: 'Specie', tipi: ['identifica_specie', 'segnalazione_scheda'] },
  { label: 'Cura', tipi: ['consiglio_cura', 'consiglio_concimazione', 'diagnosi'] },
  { label: 'Varie', tipi: ['pianifica_progetto', 'altro'] },
]
const SENZA_FOTO = ['segnalazione_scheda', 'pianifica_progetto']

const filo = computed(() => fili.value.find(f => f.id === filoId.value) ?? null)
const nonVisti = computed(() => fili.value.filter(f => f.nuova_risposta).length)
const progettiEsistenti = computed(() => Object.entries(store.progetti ?? {})
  .map(([id, p]) => ({ id, titolo: p.titolo })).sort((a, b) => a.titolo.localeCompare(b.titolo)))
const progettoDelFilo = computed(() => {
  if (progettoCreato.value) return progettoCreato.value
  const id = filo.value?.progetto_id
  return id && store.progetti?.[id] ? { id, titolo: store.progetti[id].titolo } : null
})

// Riga sotto il form: assente per il curatore; per gli altri dice quante risposte restano
const rigaRimaste = computed(() => {
  const s = statoZorba.value
  if (!s || s.curatore || s.rimaste == null) return null
  if (s.tipo_tetto === 'prova') return `Prova Zorba: ti restano ${s.rimaste} ${s.rimaste === 1 ? 'risposta gratuita' : 'risposte gratuite'}`
  return s.rimaste === 1 ? 'Questo mese ti resta 1 risposta di Zorba' : `Questo mese ti restano ${s.rimaste} risposte di Zorba`
})
const esaurite = computed(() => statoZorba.value && !statoZorba.value.curatore && statoZorba.value.rimaste === 0)
const inPausa = computed(() => statoZorba.value && !statoZorba.value.attivo)
const ripartenza = computed(() => {
  const d = new Date(); d.setMonth(d.getMonth() + 1, 1)
  return d.toLocaleDateString('it-IT', { day: 'numeric', month: 'long' })
})
const bloccato = computed(() => !online.value || inPausa.value || esaurite.value)

function selezionaTipo(v) {
  if (nuovoTipo.value === v) return
  nuovoTipo.value = v
  nuovoMessaggio.value = ''
  specieSelezionata.value = ''
  progettoSelezionato.value = ''
  nuovoProgettoTitolo.value = ''
  foto.value = null
}

const puoInviare = computed(() => {
  const t = nuovoMessaggio.value.trim()
  if (nuovoTipo.value === 'segnalazione_scheda') return !!specieSelezionata.value && !!t
  if (nuovoTipo.value === 'pianifica_progetto') return !!t && (!!progettoSelezionato.value || !!nuovoProgettoTitolo.value.trim())
  if (nuovoTipo.value === 'identifica_specie') return !!foto.value
  if (nuovoTipo.value === 'diagnosi') return !!foto.value || !!t
  return !!t
})

const PLACEHOLDER_MESSAGGIO = {
  segnalazione_scheda: 'Cosa non ti torna in questa scheda?',
  pianifica_progetto: 'Descrivi il progetto: cosa vuoi fare, dove, entro quando…',
  identifica_specie: 'Note aggiuntive (opzionale)…',
  diagnosi: 'Descrivi il problema (opzionale se alleghi una foto)…',
}
const placeholderMessaggio = computed(() => PLACEHOLDER_MESSAGGIO[nuovoTipo.value] ?? 'Descrivi la richiesta…')

async function caricaFili() {
  fili.value = await zorba.caricaFili()
}

async function apriFilo(id) {
  filoId.value = id
  storicoAperto.value = false
  progettoCreato.value = null
  errore.value = null
  messaggi.value = []
  try {
    messaggi.value = await zorba.caricaMessaggi(id)
    const f = fili.value.find(x => x.id === id)
    if (f?.nuova_risposta) {
      await zorba.segnaLetto(id)
      f.nuova_risposta = false
    }
  } catch (e) {
    errore.value = e.message || 'Non riesco a caricare la conversazione: riprova tra poco.'
  }
}

function tornaANuova(tipo) {
  filoId.value = null
  errore.value = null
  if (typeof tipo === 'string') selezionaTipo(tipo)
}

async function aggiornaStato() {
  try { statoZorba.value = await zorba.stato() } catch { statoZorba.value = null }
}

// Un invio (richiesta nuova, replica o riprova): segue lo streaming e alla fine ricarica il filo dal database,
// che resta la fonte di verità (testo salvato, esito, chiusura del filo).
// Ritorna true se l'invio è partito (il filo esiste o la replica è stata accettata), false se è fallito prima.
async function esegui(corpo) {
  let inviato = false
  errore.value = null
  let idFilo = corpo.filo_id ?? null
  const mio = { id: 'mio', ruolo: 'utente', testo: corpo.testo, foto_url: corpo.foto ? `data:image/jpeg;base64,${corpo.foto}` : null }
  const attesa = { id: 'in-corso', ruolo: 'zorba', esito: 'in_corso' }
  const segnaposto = { id: 'in-corso', stati: [], testo: '' }
  inCorso.value = { ...segnaposto }
  if (idFilo) {
    // Riprova: la risposta in errore (l'ultima) lascia il posto a quella in corso; replica: il messaggio dell'utente in coda
    const base = corpo.riprova ? messaggi.value.slice(0, -1) : [...messaggi.value, mio]
    messaggi.value = [...base, attesa]
  }
  try {
    await zorba.invia(corpo, (nome, dati) => {
      inviato = true
      if (nome === 'filo' && !idFilo) {
        idFilo = dati.id
        // Filo provvisorio finché caricaFili() non lo rilegge dal database
        fili.value = [{ id: dati.id, tipo: corpo.nuovo.tipo, stato: 'aperto', importato: false, creato: new Date().toISOString(),
          aggiornato: new Date().toISOString(), voce: corpo.nuovo.voce, nome_voce: corpo.nuovo.nome_voce,
          progetto_id: corpo.nuovo.progetto_id, titolo_progetto: corpo.nuovo.titolo_progetto,
          segnalazione_stato: corpo.nuovo.tipo === 'segnalazione_scheda' ? 'in_attesa' : null, primo_testo: corpo.testo }, ...fili.value]
        filoId.value = dati.id
        messaggi.value = [mio, attesa]
      } else if (nome === 'stato') segnaposto.stati = [...segnaposto.stati, dati.t]
      else if (nome === 'testo') segnaposto.testo += dati.t
      else if (nome === 'annulla_testo') segnaposto.testo = ''
      else if (nome === 'progetto') progettoCreato.value = dati
      else if (nome === 'errore') errore.value = dati.messaggio
      inCorso.value = { ...segnaposto }
    })
  } catch (e) {
    errore.value = e.message
  } finally {
    inCorso.value = null
    try {
      await Promise.all([caricaFili(), aggiornaStato()])
      if (idFilo) {
        filoId.value = idFilo
        messaggi.value = await zorba.caricaMessaggi(idFilo)
        await zorba.segnaLetto(idFilo)
      }
    } catch (e) {
      // Ricarica fallita (es. connessione persa): la risposta provvisoria diventa un errore con Riprova
      if (idFilo) messaggi.value = messaggi.value.map(m => m.id === 'in-corso' ? { id: 'in-corso', ruolo: 'zorba', esito: 'errore' } : m)
      if (!errore.value) errore.value = 'Connessione interrotta: non riesco ad aggiornare la conversazione.'
    }
    if (progettoCreato.value) Promise.resolve(store.aggiorna()).catch(() => {})
  }
  return inviato
}

async function aggiungiRichiesta() {
  if (!puoInviare.value || aggiungendo.value || bloccato.value) return
  aggiungendo.value = true
  const tipo = nuovoTipo.value
  const corpo = {
    nuovo: {
      tipo,
      voce: tipo === 'segnalazione_scheda' ? specieSelezionata.value : null,
      nome_voce: tipo === 'segnalazione_scheda' ? (store.catalogo?.[specieSelezionata.value]?.nome ?? null) : null,
      progetto_id: tipo === 'pianifica_progetto' ? (progettoSelezionato.value || null) : null,
      titolo_progetto: tipo === 'pianifica_progetto' && !progettoSelezionato.value ? nuovoProgettoTitolo.value.trim() : null,
    },
    testo: nuovoMessaggio.value.trim(),
    foto: SENZA_FOTO.includes(tipo) ? null : (foto.value?.base64 ?? null),
  }
  // Copia del form: se l'invio fallisce prima che il filo esista, l'utente ritrova tutto com'era
  const salvato = { m: nuovoMessaggio.value, s: specieSelezionata.value, p: progettoSelezionato.value, t: nuovoProgettoTitolo.value, f: foto.value }
  nuovoMessaggio.value = ''; specieSelezionata.value = ''; progettoSelezionato.value = ''; nuovoProgettoTitolo.value = ''; foto.value = null
  try {
    const inviato = await esegui(corpo)
    if (!inviato && nuovoTipo.value === tipo) {
      nuovoMessaggio.value = salvato.m; specieSelezionata.value = salvato.s; progettoSelezionato.value = salvato.p
      nuovoProgettoTitolo.value = salvato.t; foto.value = salvato.f
    }
  } catch (e) {
    errore.value = e.message
  } finally { aggiungendo.value = false }
}

const rispondi = async ({ testo, foto: f }) => {
  try {
    if (await esegui({ filo_id: filoId.value, testo, foto: f })) filoRef.value?.svuota()
  } catch (e) { errore.value = e.message }
}
const riprova = async () => {
  try { await esegui({ filo_id: filoId.value, riprova: true }) } catch (e) { errore.value = e.message }
}

async function vota(id, voto, motivo, commento) {
  try {
    await zorba.vota(id, voto, motivo, commento)
    messaggi.value = messaggi.value.map(m => m.id === id ? { ...m, voto, voto_motivo: voto === -1 ? motivo : null, voto_commento: voto === -1 ? commento : null } : m)
  } catch (e) { errore.value = e.message }
}

async function selezionaFoto(e) {
  const file = e.target.files?.[0]
  e.target.value = ''
  if (!file) return
  errore.value = null
  try { foto.value = await ridimensionaFoto(file) } catch { errore.value = 'Questa foto non si riesce a leggere: prova con un\'altra.' }
}

async function confermaEliminazione() {
  if (!daEliminare.value) return
  eliminando.value = true
  try {
    await zorba.elimina(daEliminare.value)
    if (filoId.value === daEliminare.value) filoId.value = null
    daEliminare.value = null
    await caricaFili()
  } catch (e) {
    errore.value = e.message
  } finally {
    eliminando.value = false
  }
}

onMounted(async () => {
  await Promise.all([store.caricaTutto(), caricaFili(), aggiornaStato()])
  // Arrivo dalla colonna laterale (ZorbaDiceSidebar.vue, ?filo=<id>): apre quel filo. replace per non lasciare
  // l'id in cronologia. I vecchi link ?id=richiesta-… non trovano nulla e lasciano la pagina com'è.
  const id = route.query.filo
  if (id && fili.value.some(f => f.id === id)) await apriFilo(id)
  if (route.query.filo || route.query.id) router.replace({ path: route.path })
})
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

.agente-avviso {
  border: 1px solid var(--gold-light); background: var(--gold-pale); border-radius: 12px;
  padding: 12px 14px; margin-bottom: 14px; font: 400 12.5px/1.5 var(--font-sans); color: var(--gold-dark);
}

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

</style>
