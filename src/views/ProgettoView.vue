<template>
  <div>
    <RouterLink to="/progetti" class="back-link"><Icon name="back" /> Progetti</RouterLink>

    <template v-if="store.loading">
      <div class="skeleton" style="height:28px;width:60%;margin-bottom:8px;"></div>
      <div class="skeleton" style="height:14px;width:40%;margin-bottom:24px;"></div>
      <div class="skeleton" style="height:160px;border-radius:16px;margin-bottom:12px;"></div>
      <div class="skeleton" style="height:120px;border-radius:16px;"></div>
    </template>

    <template v-else-if="!form">
      <div style="text-align:center;padding:60px 0;color:var(--ink-faint);">
        <div style="width:56px;height:56px;border-radius:50%;background:var(--gold-tile);display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
          <Icon name="lampadina" style="width:24px;height:24px;" />
        </div>
        <p>Progetto non trovato</p>
      </div>
    </template>

    <template v-else>
      <!-- Intestazione: modifica inline, senza card -->
      <div style="display:flex;flex-direction:column;gap:10px;margin-bottom:22px;">
        <input v-model="form.titolo" placeholder="Titolo" class="form-input"
          style="font:600 20px/1.2 var(--font-display);">

        <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
          <select v-model="form.stato" class="form-input" style="width:auto;">
            <option v-for="(label, chiave) in LABEL_STATO" :key="chiave" :value="chiave">{{ label }}</option>
          </select>
          <span class="st" :class="classeStato(form.stato)">{{ labelStato(form.stato) }}</span>
        </div>

        <input v-model="form.zona" placeholder="Zona (opzionale)" class="form-input">

        <MiniEditor v-model="form.descrizione" placeholder="Descrizione, contesto, note…" />

        <div style="display:flex;flex-direction:column;gap:2px;font-size:11px;color:var(--ink-soft);margin-top:2px;">
          <span>creato il {{ formatData(form.creato) }}</span>
          <span v-if="scadenza" style="display:flex;align-items:center;gap:5px;">
            <Icon name="bandiera" style="width:11px;height:11px;flex-shrink:0;" />Scadenza (dall'ultima tappa): {{ formatData(scadenza) }}
          </span>
        </div>
      </div>

      <!-- Tappe: la traccia si disegna sullo scroll -->
      <div class="slabel">Tappe</div>
      <div class="path" ref="pathEl">
        <svg class="path__svg" viewBox="0 0 20 600" preserveAspectRatio="none" aria-hidden="true">
          <defs>
            <linearGradient id="trailGrad" x1="0" y1="0" x2="0" y2="1">
              <stop v-for="(s, si) in gradientStops" :key="si" :offset="s.offset" :stop-color="s.color" />
            </linearGradient>
          </defs>
          <path class="path__base" d="M 10 4 L 10 596" />
          <path class="path__trail" pathLength="100" d="M 10 4 L 10 596" />
        </svg>

        <!-- inserimento prima della prima tappa -->
        <div v-if="inserimentoIndex === 0" class="tappa-insert">
          <input type="date" v-model="nuovaTappaInserimento.data" class="form-input" style="flex:1;min-width:120px;">
          <input v-model="nuovaTappaInserimento.descrizione" placeholder="Cosa aspettarti / cosa fare" class="form-input"
            style="flex:2;min-width:140px;" @keyup.enter="confermaInserimento">
          <button type="button" class="btn btn-sage" style="flex-shrink:0;padding:8px 14px;font-size:13px;" @click="confermaInserimento">Aggiungi</button>
          <button type="button" @click="inserimentoIndex = null" aria-label="Annulla"
            style="background:none;border:none;color:var(--ink-faint);font-size:20px;line-height:1;cursor:pointer;padding:0 4px;flex-shrink:0;">×</button>
        </div>
        <div v-else class="path__add">
          <button type="button" @click="apriInserimento(0)">＋ Aggiungi tappa</button>
        </div>

        <template v-for="(t, i) in form.tappe" :key="i">
          <div class="step">
            <span class="step__dot" :class="classeEsitoDot(t.esito)"></span>
            <div class="step__head">
              <span class="step__date">{{ formatData(t.data) }}</span>
              <span class="step__esito" :class="classeEsito(t.esito)">{{ labelEsito(t.esito) }}</span>
            </div>

            <template v-if="tappaApertaIndex === i">
              <div style="display:flex;gap:6px;align-items:center;flex-wrap:wrap;margin:6px 0;">
                <input type="date" v-model="t.data" class="form-input" style="flex:1;min-width:120px;">
                <select v-model="t.esito" class="form-input" style="flex:1;min-width:100px;">
                  <option value="atteso">Atteso</option>
                  <option value="riuscito">Riuscito</option>
                  <option value="fallito">Fallito</option>
                  <option value="saltato">Saltato</option>
                </select>
              </div>
              <textarea v-model="t.descrizione" placeholder="Cosa aspettarti / cosa fare" rows="2"
                class="form-input" style="resize:vertical;font-family:inherit;margin-bottom:8px;"></textarea>
              <div style="display:flex;gap:10px;align-items:center;">
                <button type="button" @click="tappaApertaIndex = null" class="btn btn-sage" style="flex:1;font-size:13px;padding:7px;">Fatto</button>
                <button type="button" @click="rimuoviTappa(i)" style="background:none;border:none;color:var(--rose-dark);font-size:12px;cursor:pointer;">Elimina</button>
              </div>
            </template>
            <p v-else class="step__desc" style="cursor:pointer;" @click="tappaApertaIndex = i">{{ t.descrizione }}</p>
          </div>

          <!-- "+" solo TRA le tappe: l'append in fondo è coperto dal pulsante in cima
               (le tappe si riordinano comunque per data) -->
          <template v-if="i !== form.tappe.length - 1">
            <div v-if="inserimentoIndex === i + 1" class="tappa-insert">
              <input type="date" v-model="nuovaTappaInserimento.data" class="form-input" style="flex:1;min-width:120px;">
              <input v-model="nuovaTappaInserimento.descrizione" placeholder="Cosa aspettarti / cosa fare" class="form-input"
                style="flex:2;min-width:140px;" @keyup.enter="confermaInserimento">
              <button type="button" class="btn btn-sage" style="flex-shrink:0;padding:8px 14px;font-size:13px;" @click="confermaInserimento">Aggiungi</button>
              <button type="button" @click="inserimentoIndex = null" aria-label="Annulla"
                style="background:none;border:none;color:var(--ink-faint);font-size:20px;line-height:1;cursor:pointer;padding:0 4px;flex-shrink:0;">×</button>
            </div>
            <div v-else class="path__add">
              <button type="button" @click="apriInserimento(i + 1)">＋</button>
            </div>
          </template>
        </template>

        <div class="pgoal">
          <span class="pnode"></span>
          <Icon name="bandiera" /> Scadenza<template v-if="scadenza"> · {{ formatData(scadenza) }}</template>
        </div>
      </div>

      <p v-if="errore" style="display:flex;align-items:center;gap:6px;font-size:12px;color:var(--rose-dark);margin:14px 0 10px;">
        <Icon name="campanella" style="width:13px;height:13px;flex-shrink:0;" />{{ errore }}
      </p>

      <div style="display:flex;gap:10px;margin-top:18px;">
        <button @click="daEliminare = true" class="btn" style="font-size:13px;color:var(--rose-dark);background:transparent;border-color:var(--rose-light);">
          Elimina progetto
        </button>
        <button @click="salva" :disabled="!form.titolo.trim() || salvando" class="btn btn-sage" style="flex:1;">
          <Spinner v-if="salvando" />{{ salvando ? 'Salvataggio…' : 'Salva modifiche' }}
        </button>
      </div>
    </template>

    <ModalConferma
      :aperto="daEliminare"
      titolo="Eliminare questo progetto?"
      messaggio="Questa azione non può essere annullata."
      :caricamento="eliminando"
      @conferma="eliminaProgetto"
      @annulla="daEliminare = false"
    />
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { useProgettiApi } from '@/composables/useProgettiApi'
import { scadenzaCalcolata } from '@/composables/useProgetti'
import ModalConferma from '@/components/ModalConferma.vue'
import MiniEditor from '@/components/MiniEditor.vue'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const route  = useRoute()
const router = useRouter()
const store  = useDatiStore()
const progettiApi = useProgettiApi()

const form = ref(null)
const tappaApertaIndex = ref(null)
const inserimentoIndex = ref(null)
const tappeOriginali = ref([])
const nuovaTappaInserimento = ref({ data: '', descrizione: '' })
const salvando = ref(false)
const errore = ref(null)
const daEliminare = ref(false)
const eliminando = ref(false)

const LABEL_STATO = {
  aperto: 'Aperto', in_corso: 'In corso', completato: 'Completato',
  fallito: 'Fallito', cancellato: 'Cancellato',
}
// Stessa mappa di ProgettiView.vue: lo stato usa le pill globali .st--*.
const CLASSE_STATO = {
  aperto: 'st--n', in_corso: 'st--g', completato: 'st--s',
  fallito: 'st--r', cancellato: 'st--n',
}
function labelStato(stato) { return LABEL_STATO[stato] ?? 'Aperto' }
function classeStato(stato) { return CLASSE_STATO[stato] ?? 'st--n' }

// Duplicata da ProgettiView.vue di proposito (ruling R1): giorno + mese per
// esteso, anno solo se diverso da quello corrente.
function formatData(d) {
  if (!d) return ''
  const dt = new Date(d), ora = new Date()
  const s = dt.toLocaleDateString('it-IT', { day: 'numeric', month: 'long' })
  return dt.getFullYear() !== ora.getFullYear() ? s + ' ' + dt.getFullYear() : s
}

// Non un campo a parte da tenere allineato a mano: è la data dell'ultima
// tappa, ricalcolata mentre si modificano le tappe nel form (non serve
// salvare per vederla aggiornata).
const scadenza = computed(() => form.value ? scadenzaCalcolata(form.value) : null)

// Copia locale modificabile: il salvataggio è esplicito (bottone "Salva
// modifiche") invece che automatico a ogni campo, per non moltiplicare le
// scritture su GitHub mentre si sistemano più tappe in una volta.
function caricaForm() {
  const p = store.progetti?.[route.params.id]
  form.value = p ? { ...p, tappe: (p.tappe || []).map(t => ({ ...t })) } : null
  tappeOriginali.value = p ? (p.tappe || []).map(t => ({ ...t })) : []
  tappaApertaIndex.value = null
  inserimentoIndex.value = null
  // Ridisegna la traccia dopo un cambio progetto (rotta /progetti/a → /progetti/b
  // sullo stesso componente riusato) o quando lo store risolve al primo load.
  nextTick(updateTrail)
}
watch(() => [store.progetti, route.params.id], caricaForm, { immediate: true })

const LABEL_ESITO = { atteso: 'Atteso', riuscito: 'Riuscito', fallito: 'Fallito', saltato: 'Saltato' }
// Suffissi -g/-s/-r/-f delle classi globali .step__dot--* / .step__esito--*.
const CLASSE_ESITO_DOT = {
  atteso: 'step__dot--g', riuscito: 'step__dot--s',
  fallito: 'step__dot--r', saltato: 'step__dot--f',
}
const CLASSE_ESITO = {
  atteso: 'step__esito--g', riuscito: 'step__esito--s',
  fallito: 'step__esito--r', saltato: 'step__esito--f',
}
function labelEsito(esito) { return LABEL_ESITO[esito] ?? LABEL_ESITO.atteso }
function classeEsitoDot(esito) { return CLASSE_ESITO_DOT[esito] ?? CLASSE_ESITO_DOT.atteso }
function classeEsito(esito) { return CLASSE_ESITO[esito] ?? CLASSE_ESITO.atteso }

// Gradiente della traccia: una banda piena per tappa, colore dell'esito.
// Due <stop> per banda (stesso colore agli offset i/n e (i+1)/n) → transizioni
// nette invece di sfumature. Nessuna tappa → un solo stop neutro.
const COLORE_ESITO_STOP = {
  atteso: 'var(--gold)', riuscito: 'var(--sage)',
  fallito: 'var(--rose)', saltato: 'var(--ink-soft)',
}
const gradientStops = computed(() => {
  const tappe = form.value?.tappe ?? []
  const n = tappe.length
  if (!n) return [{ offset: '0%', color: 'var(--cream-dark)' }]
  const stops = []
  tappe.forEach((t, i) => {
    const color = COLORE_ESITO_STOP[t.esito] ?? COLORE_ESITO_STOP.atteso
    stops.push({ offset: (i / n * 100).toFixed(4) + '%', color })
    stops.push({ offset: ((i + 1) / n * 100).toFixed(4) + '%', color })
  })
  return stops
})

// L'indice serve solo per sapere quale "+" ha aperto il mini-form: la
// posizione finale della tappa è sempre determinata dalla data (le tappe
// restano ordinate cronologicamente), non dalla posizione cliccata — così
// funziona identicamente per un inserimento in fondo o in mezzo alla lista.
function apriInserimento(indice) {
  inserimentoIndex.value = indice
  nuovaTappaInserimento.value = { data: '', descrizione: '' }
}
function confermaInserimento() {
  if (!nuovaTappaInserimento.value.data || !nuovaTappaInserimento.value.descrizione.trim()) return
  form.value.tappe.push({
    data: nuovaTappaInserimento.value.data,
    descrizione: nuovaTappaInserimento.value.descrizione.trim(),
    esito: 'atteso',
  })
  form.value.tappe.sort((a, b) => (a.data || '').localeCompare(b.data || ''))
  inserimentoIndex.value = null
  nextTick(updateTrail)
}
function rimuoviTappa(i) {
  form.value.tappe.splice(i, 1)
  tappaApertaIndex.value = null
  nextTick(updateTrail)
}

// --- scrub della traccia legato allo scroll di window ---
const pathEl = ref(null)
let scrollHandler = null
let pending = false
function updateTrail() {
  const el = pathEl.value; if (!el) return
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
    el.style.setProperty('--draw', 1)
    el.querySelectorAll('.step__dot, .pgoal .pnode').forEach(d => d.classList.add('in'))
    return
  }
  const pr = el.getBoundingClientRect()
  const vh = window.innerHeight
  let frac = (vh * 0.9 - pr.top) / (pr.height || 1)
  frac = Math.max(0, Math.min(1, frac))
  el.style.setProperty('--draw', frac.toFixed(4))
  // Due passate: prima si leggono tutti i rect, poi si applicano tutti i toggle
  // — un frame in cui i dot cambiano stato non forza un reflow per ogni dot.
  const dots = el.querySelectorAll('.step__dot, .pgoal .pnode')
  const attivi = []
  dots.forEach(d => {
    const dr = d.getBoundingClientRect()
    const df = ((dr.top + dr.height / 2) - pr.top) / (pr.height || 1)
    attivi.push(frac >= df - 0.02)
  })
  dots.forEach((d, i) => d.classList.toggle('in', attivi[i]))
}
// Rieseguito quando l'elemento .path compare davvero nel DOM: su un cold load
// (refresh, deep link, avvio PWA) store.loading è ancora true al primo
// onMounted, quindi pathEl.value è null e updateTrail esce subito senza che
// nulla la richiami quando lo store risolve e .path monta.
watch(pathEl, (el) => { if (el) nextTick(updateTrail) })
onMounted(async () => {
  await nextTick()
  // Flag di frame in sospeso: una raffica di resize/scroll non accoda un rAF
  // per evento.
  scrollHandler = () => {
    if (pending) return
    pending = true
    requestAnimationFrame(() => { pending = false; updateTrail() })
  }
  window.addEventListener('scroll', scrollHandler, { passive: true })
  window.addEventListener('resize', scrollHandler)
  updateTrail()
})
onBeforeUnmount(() => {
  if (scrollHandler) { window.removeEventListener('scroll', scrollHandler); window.removeEventListener('resize', scrollHandler) }
})

async function salva() {
  if (!form.value.titolo.trim() || salvando.value) return
  salvando.value = true
  errore.value = null
  const id = route.params.id
  try {
    await progettiApi.salvaProgetto(id, {
      titolo: form.value.titolo.trim(),
      descrizione: form.value.descrizione.trim() || null,
      zona: form.value.zona.trim() || null,
      stato: form.value.stato,
      creato: form.value.creato,
      tappe: form.value.tappe.filter(t => t.data && t.descrizione.trim()),
      tappeOriginali: tappeOriginali.value,
    }, false)
  } catch (e) {
    errore.value = e.message
  } finally {
    salvando.value = false
  }
}

async function eliminaProgetto() {
  eliminando.value = true
  const id = route.params.id
  try {
    await progettiApi.eliminaProgetto(id)
    router.push('/progetti')
  } finally {
    eliminando.value = false
  }
}
</script>

<style scoped>
.tappa-insert {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  width: 100%;
  padding: 6px 0;
}
</style>
