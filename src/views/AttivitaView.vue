<template>
  <div>
    <h1 class="page-title">Attività</h1>
    <p class="attivita-data">{{ dataOggi }}</p>

    <!-- Skeleton -->
    <div v-if="store.loading" style="display:flex;flex-direction:column;gap:8px;">
      <div v-for="i in 4" :key="i" class="card" style="padding:14px 16px;display:flex;align-items:center;gap:12px;">
        <div class="skeleton" style="width:40px;height:40px;border-radius:12px;flex-shrink:0;"></div>
        <div style="flex:1;display:flex;flex-direction:column;gap:5px;">
          <div class="skeleton" style="height:13px;width:50%;"></div>
          <div class="skeleton" style="height:11px;width:70%;"></div>
        </div>
        <div class="skeleton" style="width:70px;height:28px;border-radius:999px;"></div>
      </div>
    </div>

    <template v-else>
      <!-- Tab: con 128 piante su 6 zone l'elenco unico diventava lunghissimo,
           diviso per tipo di cura invece che tutto insieme. La potatura non
           ha una tab propria: i suoi valori sono testo libero per stagione
           (es. "taglio leggero"), non un intervallo in giorni, quindi non
           genera mai una scadenza qui (vedi useCure.js/parseGiorni). -->
      <div style="display:flex;gap:6px;margin-bottom:20px;flex-wrap:wrap;" role="tablist" aria-label="Tipo di attività">
        <button type="button" id="tab-irrigazione" role="tab" :aria-selected="tabAttiva === 'irrigazione'" aria-controls="pannello-attivita" class="pill tab-icona" :class="{ active: tabAttiva === 'irrigazione' }" @click="tabAttiva = 'irrigazione'">
          <Icon name="goccia" />Irrigazione
          <span v-if="conteggioTab.irrigazione" class="badge badge-warn" style="margin-left:4px;">{{ conteggioTab.irrigazione }}</span>
        </button>
        <button type="button" id="tab-concimi" role="tab" :aria-selected="tabAttiva === 'concimi'" aria-controls="pannello-attivita" class="pill tab-icona" :class="{ active: tabAttiva === 'concimi' }" @click="tabAttiva = 'concimi'">
          <Icon name="concimazione" />Concimi &amp; calcio
          <span v-if="conteggioTab.concimi" class="badge badge-warn" style="margin-left:4px;">{{ conteggioTab.concimi }}</span>
        </button>
        <button type="button" id="tab-progetti" role="tab" :aria-selected="tabAttiva === 'progetti'" aria-controls="pannello-attivita" class="pill tab-icona" :class="{ active: tabAttiva === 'progetti' }" @click="tabAttiva = 'progetti'">
          <Icon name="lampadina" />Progetti
          <span v-if="conteggioTab.progetti" class="badge badge-warn" style="margin-left:4px;">{{ conteggioTab.progetti }}</span>
        </button>
      </div>

      <Transition name="fade" mode="out-in">
      <div :key="tabAttiva" id="pannello-attivita" role="tabpanel" :aria-labelledby="`tab-${tabAttiva}`">
      <!-- Per urgenza (le cure che l'app ritiene dovute) o per zona (una cura
           registrata su tutta un'aiuola, con le piante scelte nel foglio). -->
      <div v-if="tabAttiva !== 'progetti'" class="modo" role="radiogroup" aria-label="Come mostrare le cure">
        <button type="button" role="radio" :aria-checked="modo === 'urgenza'" class="modo__b" :class="{ 'modo__b--attivo': modo === 'urgenza' }" @click="scegliModo('urgenza')">Per urgenza</button>
        <span class="modo__sep" aria-hidden="true"></span>
        <button type="button" role="radio" :aria-checked="modo === 'zona'" class="modo__b" :class="{ 'modo__b--attivo': modo === 'zona' }" @click="scegliModo('zona')">Per zona</button>
      </div>

      <AttivitaPerZona v-if="tabAttiva !== 'progetti' && modo === 'zona'"
        :tipo="tabAttiva === 'irrigazione' ? 'irrigazione' : 'concimazione'"
        @apri="apriCuraZona" />

      <template v-else-if="tabAttiva !== 'progetti'">
        <!-- Da fare -->
        <template v-if="daFareTab.length">
          <div class="slabel"><Icon name="campanella" style="width:12px;height:12px;flex-shrink:0;" />Da fare</div>
          <div style="margin-bottom:24px;">
            <AttivitaGruppoZona
              v-for="gruppo in gruppiDaFareTab"
              :key="gruppo.chiave"
              :gruppo="gruppo"
              variante="urgente"
              :salvando="salvando"
              :salvando-gruppo="salvandoGruppo"
              :errore-azione="erroreAzione"
              @registra="registra"
              @registra-gruppo="registraGruppo"
              @apri-dossier="apriDossier"
            />
          </div>
        </template>

        <!-- In scadenza -->
        <template v-if="inScadenzaTab.length">
          <div class="slabel"><Icon name="orologio" style="width:13px;height:13px;flex-shrink:0;" />In scadenza (entro 3 giorni)</div>
          <div style="margin-bottom:24px;">
            <AttivitaGruppoZona
              v-for="gruppo in gruppiInScadenzaTab"
              :key="gruppo.chiave"
              :gruppo="gruppo"
              variante="scadenza"
              :salvando="salvando"
              :salvando-gruppo="salvandoGruppo"
              :errore-azione="erroreAzione"
              @registra="registra"
              @registra-gruppo="registraGruppo"
              @apri-dossier="apriDossier"
            />
          </div>
        </template>
      </template>

      <!-- Tappe progetto -->
      <template v-else-if="tappeProgetto.length">
        <TransitionGroup name="stagger" tag="div" class="tappa-lista">
          <div v-for="(t, i) in tappeProgetto" :key="`${t.progettoId}-${t.indice}`"
            class="tappa-riga" :class="{ 'tappa-riga--urgente': t.urgente }"
            :style="`--stagger-delay:${Math.min(i, 6) * 0.06}s;`">
            <span class="tappa-riga__ic" :class="{ 'tappa-riga__ic--urgente': t.urgente }"><Icon name="lampadina" /></span>
            <div class="tappa-riga__m">
              <RouterLink :to="`/progetti/${t.progettoId}`" class="tappa-riga__t">{{ t.progettoTitolo }}</RouterLink>
              <div class="tappa-riga__d" :class="{ 'tappa-riga__d--urgente': t.urgente }">
                {{ t.tappa.descrizione }} — {{ t.urgente ? `scaduta ${Math.abs(t.giorni)} gg fa` : `tra ${t.giorni} gg` }}
              </div>
              <div v-if="erroreAzione?.chiave === `${t.progettoId}-${t.indice}`" class="tappa-riga__d tappa-riga__err" role="alert">{{ erroreAzione.messaggio }}</div>
            </div>
            <button @click="registraTappa(t)" :disabled="salvandoTappa === `${t.progettoId}-${t.indice}`"
              :class="['care-act', { 'care-act--rose': t.urgente }]">
              <Spinner v-if="salvandoTappa === `${t.progettoId}-${t.indice}`" /><span v-else>Fatto</span>
            </button>
          </div>
        </TransitionGroup>
      </template>

      <!-- Tutto ok (per la tab attiva): l'unico vero traguardo di questa
           vista — azzerare l'arretrato — merita un ingresso autoriale
           invece di comparire di scatto. Non riusa i token --motion-quick/
           --motion-sheet apposta: è un momento raro, non un feedback di
           routine (vedi Motion in DESIGN.md). -->
      <Transition name="tab-pulita">
        <div v-if="vuotaTab && !(modo === 'zona' && tabAttiva !== 'progetti')" class="empty">
          <Icon name="foglia" />
          <p><b>Tutto in ordine!</b>Nessuna cura urgente qui</p>
        </div>
      </Transition>
      </div>
      </Transition>
    </template>

    <FoglioLaterale
      :model-value="!!dossierItem"
      @update:model-value="v => { if (!v) dossierItem = null }"
      :titolo="dossierItem?.nomeSpecie ?? ''"
    >
      <DossierPianta v-if="dossierItem" :pianta-id="dossierItem.piantaId" />
    </FoglioLaterale>

    <FoglioLaterale
      :model-value="!!curaZona"
      @update:model-value="v => { if (!v) chiudiCuraZona() }"
    >
      <!-- Intestazione: quale cura e dove, prima di tutto il resto. -->
      <template #intestazione>
        <div v-if="curaZona" class="fz-hd">
          <span class="care__ic" :class="`care__ic--${tipoZona}`"><Icon :name="iconaCura(tipoZona)" /></span>
          <h3>{{ LABEL_CURA[tipoZona] }} <span class="fz-hd__dove">· {{ curaZona.sottozona ? `${curaZona.zona} – ${curaZona.sottozona}` : curaZona.zona }}</span></h3>
        </div>
      </template>
      <FoglioCuraZona v-if="curaZona" :key="`${curaZona.zona}|${curaZona.sottozona}|${tabAttiva}`"
        :zona="curaZona.zona" :sottozona="curaZona.sottozona" :tab="tabAttiva"
        :salvando="salvandoZona" :errore="erroreZona"
        @registra="registraZona" @tipo="t => tipoZona = t" />
    </FoglioLaterale>

    <ToastCura ref="toastCura" @errore="onErroreToast" />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { usePianteApi } from '@/composables/usePianteApi'
import { useProgettiApi } from '@/composables/useProgettiApi'
import { valutaCura, stagione, tipiCuraPianta } from '@/composables/useCure'
import { programmaIrrigazioneEffettivo } from '@/composables/useIrrigazioneAuto'
import { concimeConsigliato } from '@/composables/useConcimi'
import { tappeAttese } from '@/composables/useProgetti'
import AttivitaGruppoZona from '@/components/AttivitaGruppoZona.vue'
import AttivitaPerZona from '@/components/AttivitaPerZona.vue'
import FoglioCuraZona from '@/components/FoglioCuraZona.vue'
import { LABEL_CURA, iconaCura } from '@/composables/useCureVisual'
import FoglioLaterale from '@/components/FoglioLaterale.vue'
import DossierPianta from '@/components/DossierPianta.vue'
import ToastCura from '@/components/ToastCura.vue'
import { raggruppaPerZona } from '@/utils/raggruppaAttivita'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const store    = useDatiStore()
const pianteApi = usePianteApi()
const progettiApi = useProgettiApi()
const salvando = ref(null)
const salvandoGruppo = ref(null)
const salvandoTappa = ref(null)
const dossierItem = ref(null)

function apriDossier(item) { dossierItem.value = item }

const dataOggi = new Date().toLocaleDateString('it-IT', { weekday:'long', day:'numeric', month:'long' })

const attivita = computed(() => {
  if (!store.piante) return []
  const stagioneCorrente = stagione()
  const items = []
  for (const [id, p] of Object.entries(store.piante)) {
    const sp = store.vocePianta(p)
    const nomeSpecie = store.nomePianta(p)
    const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, p.sottozona, store.programmiIrrigazione)?.ogniGiorni ?? null
    const contesto = { ...store.contestoMeteoPianta(p), programmaAutomatico }
    // La potatura non ha cadenza temporale: è un'etichetta testuale,
    // registrabile per pianta ma mai valutata per urgenza né mostrata nei
    // feed "attività" (vedi tipiCuraPianta).
    for (const tipo of tipiCuraPianta(p, sp)) {
      const c = valutaCura(p, sp, tipo, contesto)
      if (c.giorni !== null) {
        const suggerimento = tipo === 'concimazione'
          ? concimeConsigliato(sp?.manutenzione?.npk?.[stagioneCorrente], store.concimi)
          : null
        items.push({ key: `${id}-${tipo}`, piantaId: id, tipo, nomeSpecie, label: c.label, giorni: c.giorni, urgente: c.urgente, suggerimento })
      }
    }
  }
  return items
})

const daFare = computed(() => attivita.value.filter(i => i.urgente).sort((a, b) => a.giorni - b.giorni))
const inScadenza = computed(() => attivita.value.filter(i => !i.urgente && i.giorni !== null && i.giorni <= 3).sort((a, b) => a.giorni - b.giorni))

// Solo le tappe scadute o in arrivo entro 14 giorni: un progetto come una
// germinazione da seme può avere tappe previste anche a distanza di anni,
// che qui affollerebbero la lista senza essere ancora attuabili.
const tappeProgetto = computed(() =>
  tappeAttese(store.progetti).filter(t => t.giorni <= 14).sort((a, b) => a.giorni - b.giorni)
)

// Tab: divide l'elenco per tipo di cura invece di mostrarlo tutto insieme
// (con molte piante diventa uno scroll lunghissimo). Niente tab per la
// potatura: essendo testo libero non genera mai voci in daFare/inScadenza.
const tabAttiva = ref('irrigazione')
// La tab "Irrigazione" raggruppa anche "cambio_acqua" (piante coltivate in
// acqua, issue #173): stessa icona "goccia", stesso ambito "cure legate
// all'acqua", esattamente come "Concimi & calcio" raggruppa già due tipi.
const TIPI_TAB = { irrigazione: ['irrigazione', 'cambio_acqua'], concimi: ['concimazione', 'calcio'] }

const daFareTab = computed(() =>
  tabAttiva.value === 'progetti' ? [] : daFare.value.filter(i => TIPI_TAB[tabAttiva.value].includes(i.tipo))
)
const inScadenzaTab = computed(() =>
  tabAttiva.value === 'progetti' ? [] : inScadenza.value.filter(i => TIPI_TAB[tabAttiva.value].includes(i.tipo))
)
const gruppiDaFareTab = computed(() => raggruppaPerZona(daFareTab.value, store.piante))
const gruppiInScadenzaTab = computed(() => raggruppaPerZona(inScadenzaTab.value, store.piante))

const conteggioTab = computed(() => ({
  irrigazione: daFare.value.filter(i => TIPI_TAB.irrigazione.includes(i.tipo)).length,
  concimi: daFare.value.filter(i => i.tipo === 'concimazione' || i.tipo === 'calcio').length,
  progetti: tappeProgetto.value.filter(t => t.urgente).length,
}))

const vuotaTab = computed(() =>
  tabAttiva.value === 'progetti' ? !tappeProgetto.value.length : !daFareTab.value.length && !inScadenzaTab.value.length
)

const toastCura = ref(null)
// Un solo stato d'errore per riga/gruppo/tappa (in scrittura o in annullamento
// da ToastCura): la vista non aveva alcuna gestione errore prima di questa
// correzione — un fallimento silenzioso su una PWA usata sul campo con
// connessione instabile è indistinguibile da un successo. Tenuto per chiave
// (item.key / gruppo.chiave / `${progettoId}-${indice}`) così ogni riga
// mostra solo il proprio errore, stesso pattern di erroreRegistrazione in
// HomeView.vue.
const erroreAzione = ref(null)

async function registra(item) {
  if (salvando.value || salvandoGruppo.value) return
  salvando.value = item.key
  erroreAzione.value = null
  const valorePrecedente = store.piante?.[item.piantaId]?.ultima_cura?.[item.tipo] ?? null
  const concimePrecedente = store.piante?.[item.piantaId]?.ultimo_concime_id ?? null
  try {
    await pianteApi.registraCura(item.piantaId, item.tipo)
    toastCura.value?.apri(item.piantaId, item.tipo, valorePrecedente, concimePrecedente)
  } catch {
    erroreAzione.value = { chiave: item.key, messaggio: 'Non sono riuscito a registrare la cura. Riprova.' }
  } finally {
    salvando.value = null
  }
}

async function registraGruppo(gruppo) {
  if (salvandoGruppo.value || salvando.value) return
  salvandoGruppo.value = gruppo.chiave
  erroreAzione.value = null
  // Voci per l'annullamento in blocco: il valore precedente di ogni pianta va
  // letto ORA, prima della scrittura — dopo, store.piante riflette già il
  // nuovo valore e l'annulla del toast non avrebbe più nulla da ripristinare.
  const voci = gruppo.items.map(item => ({
    id: item.piantaId,
    tipo: item.tipo,
    valorePrecedente: store.piante?.[item.piantaId]?.ultima_cura?.[item.tipo] ?? null,
    concimePrecedente: store.piante?.[item.piantaId]?.ultimo_concime_id ?? null,
  }))
  try {
    await pianteApi.registraCuraMultipla(gruppo.items)
    toastCura.value?.apriLotto(voci, gruppo.chiave)
  } catch {
    erroreAzione.value = { chiave: gruppo.chiave, messaggio: 'Non sono riuscito a registrare le cure del gruppo. Riprova.' }
  } finally {
    salvandoGruppo.value = null
  }
}

async function registraTappa(t) {
  const chiave = `${t.progettoId}-${t.indice}`
  if (salvandoTappa.value) return
  salvandoTappa.value = chiave
  erroreAzione.value = null
  const espitoPrecedente = t.tappa.esito ?? 'atteso'
  try {
    await progettiApi.registraTappa(t.tappa.id, 'riuscito')
    toastCura.value?.apriTappa(t.tappa.id, espitoPrecedente, chiave)
  } catch {
    erroreAzione.value = { chiave, messaggio: 'Non sono riuscito a registrare la tappa. Riprova.' }
  } finally {
    salvandoTappa.value = null
  }
}

// Modo «Per zona»: ricordato su questo dispositivo, come una preferenza di
// vista (se la memoria del browser non è disponibile si riparte da «Per urgenza»).
const CHIAVE_MODO = 'attivita.modo'
function leggiModo() {
  try { return localStorage.getItem(CHIAVE_MODO) === 'zona' ? 'zona' : 'urgenza' } catch { return 'urgenza' }
}
const modo = ref(leggiModo())
function scegliModo(m) {
  modo.value = m
  try { localStorage.setItem(CHIAVE_MODO, m) } catch { /* solo una preferenza */ }
}

const curaZona = ref(null)
const tipoZona = ref('irrigazione')
const salvandoZona = ref(false)
const erroreZona = ref(null)
function apriCuraZona(z) { erroreZona.value = null; curaZona.value = z }
function chiudiCuraZona() { if (!salvandoZona.value) curaZona.value = null }

async function registraZona({ voci, concimeId }) {
  if (salvandoZona.value) return
  salvandoZona.value = true
  erroreZona.value = null
  const chiave = `zona-${curaZona.value.zona}|${curaZona.value.sottozona ?? ''}`
  // Valori precedenti letti prima della scrittura, per «Annulla tutte».
  const precedenti = voci.map(v => ({
    id: v.piantaId,
    tipo: v.tipo,
    valorePrecedente: store.piante?.[v.piantaId]?.ultima_cura?.[v.tipo] ?? null,
    concimePrecedente: store.piante?.[v.piantaId]?.ultimo_concime_id ?? null,
  }))
  try {
    await pianteApi.registraCuraMultipla(voci, undefined, { concimeId })
    toastCura.value?.apriLotto(precedenti, chiave)
    salvandoZona.value = false
    curaZona.value = null
  } catch {
    erroreZona.value = 'Non sono riuscito a registrare le cure. Riprova.'
    salvandoZona.value = false
  }
}

function onErroreToast(e) {
  erroreAzione.value = { chiave: e.chiave, messaggio: e.messaggio }
}
</script>

<style scoped>
.attivita-data { font-family: var(--font-sans); font-size: 12px; color: var(--ink-soft); margin: 4px 2px 20px; }
.tab-icona { display: inline-flex; align-items: center; gap: 5px; }

/* Commutatore «Per urgenza · Per zona»: due voci di testo, più discrete
   delle tab sopra perché cambiano il modo di guardare, non il contenuto.
   La voce attiva è in salvia e sottolineata, come la scelta in corso nel
   resto dell'app. */
.modo { display:flex; align-items:center; gap:4px; margin:-14px 0 8px; }
.modo__b { min-height:44px; padding:0 6px; border:none; background:none; cursor:pointer;
  font:500 13px/1 var(--font-sans); color:var(--ink-mid);
  text-decoration:underline 2px transparent; text-underline-offset:7px;
  transition: color var(--motion-quick) var(--ease-standard), text-decoration-color var(--motion-quick) var(--ease-standard); }
.modo__b:first-child { padding-left:2px; }
.modo__b:hover { color:var(--ink); }
.modo__b--attivo { font-weight:600; color:var(--sage-ink); text-decoration-color:var(--sage); }
.modo__b:focus-visible { outline:none; box-shadow:0 0 0 3px var(--gold); border-radius:8px; }
.modo__sep { width:3px; height:3px; border-radius:999px; background:var(--ink-faint); }

/* Intestazione del foglio «cura per zona». */
.fz-hd { display:flex; align-items:center; gap:10px; min-width:0; }
.fz-hd .care__ic { flex:none; }
.fz-hd h3 { margin:0; font:600 16px/1.2 var(--font-display); color:var(--ink); min-width:0; }
.fz-hd__dove { color:var(--ink-mid); font-weight:500; }
.tab-icona :deep(svg) { width: 14px; height: 14px; flex-shrink: 0; }

.tappa-lista { display:flex; flex-direction:column; margin-bottom:24px; position:relative; }
.tappa-riga { display:flex; align-items:center; gap:12px; padding:12px 2px; }
.tappa-riga + .tappa-riga { border-top:1px solid var(--cream-dark); }
.tappa-riga--urgente { padding:12px; background:var(--rose-pale); border-radius:12px; }
.tappa-riga__ic { flex:none; width:40px; height:40px; border-radius:12px; display:flex; align-items:center; justify-content:center;
  background:var(--gold-bg); color:var(--gold-ink); }
.tappa-riga__ic--urgente { background:var(--rose-bg); color:var(--rose-ink); }
.tappa-riga__ic svg { width:18px; height:18px; }
.tappa-riga__m { flex:1; min-width:0; }
.tappa-riga__t { display:block; font:600 13px/1.25 var(--font-display); color:var(--ink); text-decoration:none;
  white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.tappa-riga__d { font:400 11px/1.4 var(--font-sans); color:var(--ink-soft); margin-top:2px; }
.tappa-riga__d--urgente { color:var(--rose-dark); }
.tappa-riga__err { color:var(--rose-ink); }

/* "Tutto in ordine!": l'unico vero traguardo della vista Attività — arrivare
   a zero cure urgenti nella tab attiva. Ingresso deliberatamente più lento
   e composto di una transizione di routine (600ms, non le 180-260ms di
   --motion-quick/--motion-sheet): un momento raro che merita di essere
   notato, non un cambio di stato qualsiasi. Nessun rimbalzo — la stessa
   decelerazione morbida di tutto il resto, solo più a lungo. */
.tab-pulita-enter-active { transition: opacity .6s var(--ease-standard), transform .6s var(--ease-standard); }
.tab-pulita-enter-from { opacity: 0; transform: translateY(14px) scale(.96); }
@media (prefers-reduced-motion: reduce) {
  .tab-pulita-enter-active { transition: opacity .3s var(--ease-standard); }
  .tab-pulita-enter-from { transform: none; }
}
</style>
