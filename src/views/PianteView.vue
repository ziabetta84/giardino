<template>
  <div>
    <div class="page-title__row">
      <h1 class="page-title">Piante</h1>
      <div class="pv-azioni">
        <button v-if="!giardinoVuoto" type="button" class="pill" :class="{ active: selezionando }" :aria-pressed="selezionando" @click="alternaSelezione">
          {{ selezionando ? 'Fine' : 'Seleziona' }}
        </button>
        <RouterLink v-if="!selezionando" to="/piante/nuova" class="pill" style="text-decoration:none;">＋ Aggiungi</RouterLink>
      </div>
    </div>

    <!-- Search -->
    <div style="position:relative;margin-bottom:12px;">
      <Icon name="cerca" style="position:absolute;left:14px;top:50%;transform:translateY(-50%);width:15px;height:15px;color:var(--ink-faint);pointer-events:none;" />
      <input class="search-input" v-model="cerca" type="search" placeholder="Cerca per nome o specie…" style="padding-right:40px;">
      <button v-if="cerca" type="button" class="search-clear" @click="cerca = ''" aria-label="Cancella ricerca">×</button>
    </div>

    <!-- Filtri zona -->
    <div style="display:flex;gap:8px;overflow-x:auto;padding-bottom:12px;margin-bottom:8px;" class="no-scroll">
      <button v-for="z in filtriZona" :key="z.key"
        class="pill pill--acqua" :class="{ active: filtroZona === z.key }"
        @click="selezionaZona(z.key)"
        :style="z.key !== 'tutte' ? 'display:inline-flex;align-items:center;gap:5px;' : ''">
        <Icon v-if="z.key !== 'tutte'" :name="store.iconaZona(z.key)" style="width:13px;height:13px;flex-shrink:0;" />{{ z.label }}
      </button>
    </div>

    <!-- Filtri sottozona (solo se la zona selezionata ne ha) -->
    <div v-if="filtriSottozona.length" style="display:flex;gap:8px;overflow-x:auto;padding-bottom:12px;margin-bottom:16px;" class="no-scroll">
      <button v-for="s in filtriSottozona" :key="s"
        class="pill pill--acqua" :class="{ active: filtroSottozona === s }"
        @click="filtroSottozona = s"
        :style="s !== 'tutte' ? 'font-size:12px;display:inline-flex;align-items:center;gap:5px;' : 'font-size:12px;'">
        <Icon v-if="s !== 'tutte'" :name="store.iconaSottozona(filtroZona, s)" style="width:12px;height:12px;flex-shrink:0;" />{{ s === 'tutte' ? 'Tutte' : s }}
      </button>
    </div>

    <!-- Selezione: tutte le piante che filtri e ricerca mostrano, in un tocco -->
    <div v-if="selezionando && pianteFiltrate.length" class="pv-sel">
      <span>Tocca le piante da spostare.</span>
      <button type="button" class="pv-sel__tutte" @click="alternaVisibili">
        {{ tutteVisibiliScelte ? 'Deseleziona le visibili' : `Seleziona le visibili (${pianteFiltrate.length})` }}
      </button>
    </div>

    <!-- Skeleton -->
    <div v-if="store.loading" style="display:flex;flex-direction:column;">
      <div v-for="i in 5" :key="i" class="pr-skeleton">
        <div class="skeleton" style="width:48px;height:48px;border-radius:14px;flex-shrink:0;"></div>
        <div style="flex:1;display:flex;flex-direction:column;gap:6px;">
          <div class="skeleton" style="height:14px;width:40%;"></div>
          <div class="skeleton" style="height:11px;width:60%;"></div>
          <div class="skeleton" style="height:11px;width:30%;"></div>
        </div>
      </div>
    </div>

    <template v-else>
      <!-- Urgenti in sezione separata (solo se nessun filtro attivo) -->
      <template v-if="!selezionando && !cerca && filtroZona === 'tutte' && pianteUrgenti.length">
        <p class="section-label" style="display:flex;align-items:center;gap:6px;">
          <Icon name="campanella" style="width:12px;height:12px;flex-shrink:0;" />Da curare
        </p>
        <TransitionGroup name="stagger" tag="div" style="display:flex;flex-direction:column;margin-bottom:20px;position:relative;">
          <PiantaRiga v-for="(p, i) in pianteUrgenti" :key="'u'+p.id" :pianta="p" urgente :thumb-url="thumbnail[p.id]"
            :style="`--stagger-delay:${Math.min(i,8) * 0.06}s;`"
            @elimina="avviaElimina(p)" />
        </TransitionGroup>
        <p class="section-label">Tutte le piante</p>
      </template>

      <!-- Lista principale: un cambio di filtro sostituisce quasi per intero
           l'insieme delle chiavi, non lo modifica — il Transition esterno,
           agganciato al filtro, fa uscire del tutto la lista vecchia prima
           di far entrare quella nuova. Durante una ricerca invece
           (chiaveLista non cambia, si resta sulla stessa istanza) l'elenco
           si restringe/allarga a ogni tasto: ogni riga anima la propria
           altezza (grid-template-rows 1fr↔0fr, vedi .riga-cella) invece di
           uscire dal flusso e farsi scavalcare da un transform di
           riposizionamento delle righe restanti — quel movimento condiviso
           è la causa dell'effetto "risultati sovrapposti" segnalato: righe
           in uscita ferme nella vecchia posizione mentre altre vi scorrono
           sopra. Con il collasso in altezza il riflusso delle righe
           rimanenti è una conseguenza naturale del layout, non
           un'animazione a parte da tenere sincronizzata. -->
      <Transition v-if="pianteFiltrate.length" name="fade" mode="out-in">
        <TransitionGroup :key="chiaveLista" name="righe" tag="div" style="display:flex;flex-direction:column;position:relative;">
          <div v-for="(p, i) in pianteFiltrate" :key="p.id" class="riga-cella"
            :style="`--stagger-delay:${Math.min(i,8) * 0.06}s;`">
            <div class="riga-cella__inner">
              <PiantaRiga :pianta="p" :thumb-url="thumbnail[p.id]" @elimina="avviaElimina(p)"
                :selezionabile="selezionando" :selezionata="scelte.has(p.id)" @alterna="alterna(p.id)" />
            </div>
          </div>
        </TransitionGroup>
      </Transition>

      <!-- Stato vuoto: un giardino senza ancora nessuna pianta (frequente ora
           che l'app è multiutente, ogni account riparte da zero) è un caso
           diverso da un filtro/ricerca che non trova corrispondenze — lo
           stesso messaggio per entrambi indicherebbe di "cambiare il filtro"
           a chi non ne ha impostato nessuno. -->
      <div v-else-if="giardinoVuoto" class="empty">
        <Icon name="foglia" />
        <p><b>Nessuna pianta, per ora</b>Presentami la prima: la cerco nel catalogo e da lì calcolo quando bagnarla e quando concimarla.</p>
        <RouterLink to="/piante/nuova" class="pill" style="text-decoration:none;display:inline-flex;margin-top:14px;">＋ Aggiungi una pianta</RouterLink>
      </div>
      <div v-else class="empty">
        <Icon name="foglia" />
        <p><b>Qui non trovo nessuna pianta</b>Prova un altro nome o togli il filtro della zona.</p>
      </div>
    </template>

    <!-- Barra della selezione, fissa in fondo alla pagina -->
    <div v-if="selezionando" class="pv-barra" role="region" aria-label="Piante selezionate">
      <span class="pv-barra__n">{{ scelte.size === 0 ? 'Nessuna pianta selezionata' : scelte.size === 1 ? '1 pianta selezionata' : `${scelte.size} piante selezionate` }}</span>
      <button type="button" class="btn btn-sage pv-barra__sposta" :disabled="!scelte.size" @click="foglioSposta = true">Sposta…</button>
    </div>

    <FoglioLaterale v-model="foglioSposta" titolo="Sposta in un'altra zona">
      <FoglioSposta v-if="foglioSposta" :ids="[...scelte]" @spostate="onSpostate" />
    </FoglioLaterale>

    <ToastCura ref="toastCura" @errore="e => erroreToast = e.messaggio" />
    <p v-if="erroreToast" class="pv-err" role="alert">{{ erroreToast }}</p>

    <ModalConferma
      :aperto="!!daEliminare"
      titolo="Eliminare questa pianta?"
      messaggio="Questa azione non può essere annullata. Verranno eliminate anche eventuali foto associate."
      :caricamento="eliminando"
      :errore="erroreEliminazione"
      @conferma="eliminaPianta"
      @annulla="daEliminare = null; erroreEliminazione = null"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { usePianteApi } from '@/composables/usePianteApi'
import { useGalleria } from '@/composables/useGalleria'
import { cureUrgentiPianta } from '@/composables/useCure'
import { programmaIrrigazioneEffettivo } from '@/composables/useIrrigazioneAuto'
import { normalizzaApici } from '@/utils/normalizzaTesto'
import ModalConferma from '@/components/ModalConferma.vue'
import FoglioLaterale from '@/components/FoglioLaterale.vue'
import FoglioSposta from '@/components/FoglioSposta.vue'
import ToastCura from '@/components/ToastCura.vue'
import PiantaRiga from '@/components/PiantaRiga.vue'
import Icon from '@/components/Icon.vue'

const store      = useDatiStore()
const route      = useRoute()
const pianteApi  = usePianteApi()
const galleria   = useGalleria()

// Una sola chiamata per tutte le piante (vedi useGalleria.mappaThumbnail):
// se fallisce (rete assente, repo privata senza token, ecc.) l'elenco resta
// comunque utilizzabile, semplicemente senza le miniature.
const thumbnail = ref({})
onMounted(async () => {
  try {
    thumbnail.value = await galleria.mappaThumbnail()
  } catch {
    thumbnail.value = {}
  }
})

const cerca      = ref('')
const filtroZona = ref(route.query.zona ?? 'tutte')
const filtroSottozona = ref('tutte')
const daEliminare = ref(null)
const eliminando  = ref(false)
const erroreEliminazione = ref(null)

const filtriZona = computed(() => {
  const zone = store.zone ? Object.entries(store.zone).map(([key, z]) => ({ key, label: z.nome ?? key })) : []
  return [{ key: 'tutte', label: 'Tutte' }, ...zone]
})

// Sottozone effettivamente presenti tra le piante della zona selezionata
// (non tutte quelle configurate in store.sottozone: solo quelle in uso, per
// non mostrare filtri vuoti). Vuoto se la zona è "tutte" o non ha sottozone.
const filtriSottozona = computed(() => {
  if (filtroZona.value === 'tutte' || !store.piante) return []
  const nomi = new Set()
  for (const p of Object.values(store.piante)) {
    if (p.zona === filtroZona.value && p.sottozona) nomi.add(p.sottozona)
  }
  if (!nomi.size) return []
  return ['tutte', ...[...nomi].sort((a, b) => a.localeCompare(b))]
})

// Selezione di più piante per spostarle insieme (24/11/2026). In selezione la
// lista mostra anche le urgenti (niente sezione «Da curare» a parte, che le
// avrebbe tolte dall'elenco principale) e le righe spuntano invece di aprire.
const selezionando = ref(false)
const scelte = ref(new Set())
const foglioSposta = ref(false)
const toastCura = ref(null)
const erroreToast = ref(null)

function alternaSelezione() {
  selezionando.value = !selezionando.value
  scelte.value = new Set()
}

function alterna(id) {
  const nuove = new Set(scelte.value)
  if (nuove.has(id)) nuove.delete(id)
  else nuove.add(id)
  scelte.value = nuove
}

const tutteVisibiliScelte = computed(() =>
  pianteFiltrate.value.length > 0 && pianteFiltrate.value.every(p => scelte.value.has(p.id)))

function alternaVisibili() {
  const nuove = new Set(scelte.value)
  if (tutteVisibiliScelte.value) pianteFiltrate.value.forEach(p => nuove.delete(p.id))
  else pianteFiltrate.value.forEach(p => nuove.add(p.id))
  scelte.value = nuove
}

function onSpostate(precedenti) {
  foglioSposta.value = false
  selezionando.value = false
  scelte.value = new Set()
  erroreToast.value = null
  toastCura.value?.apriSpostamento(precedenti, `spostamento-${Date.now()}`)
}

function selezionaZona(key) {
  filtroZona.value = key
  filtroSottozona.value = 'tutte'
}

const piante = computed(() => {
  if (!store.piante) return []
  return Object.entries(store.piante).map(([id, p]) => {
    const sp = store.vocePianta(p)
    const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, p.sottozona, store.programmiIrrigazione)?.ogniGiorni ?? null
    const urgenti = cureUrgentiPianta(p, sp, { programmaAutomatico })
    return { id, ...p, urgente: urgenti.length > 0 }
  })
})

// Vero solo se il giardino non ha ancora nessuna pianta, indipendentemente
// da filtro/ricerca — distingue "non c'è ancora niente da mostrare" da
// "il filtro attuale non trova corrispondenze" (vedi stato vuoto nel template).
const giardinoVuoto = computed(() => !store.piante || !Object.keys(store.piante).length)

// Cambiare zona/sottozona sostituisce quasi per intero l'insieme delle
// piante mostrate: la lista principale si rimonta su questa chiave (vedi
// il <Transition mode="out-in"> nel template) per far uscire del tutto la
// vecchia prima di far entrare la nuova. La ricerca invece resta fuori: a
// ogni carattere digitato l'elenco si restringe sullo stesso sottoinsieme
// (le piante che restano non cambiano posizione/chiave), quindi lo
// TransitionGroup da solo già anima bene la rimozione senza bisogno di un
// remount completo ad ogni tasto premuto.
const chiaveLista = computed(() => `${filtroZona.value}|${filtroSottozona.value}`)

const pianteFiltrate = computed(() => {
  let lista = piante.value
  if (filtroZona.value !== 'tutte')
    lista = lista.filter(p => p.zona === filtroZona.value)
  if (filtroZona.value !== 'tutte' && filtroSottozona.value !== 'tutte')
    lista = lista.filter(p => p.sottozona === filtroSottozona.value)
  if (cerca.value.trim()) {
    const q = normalizzaApici(cerca.value.toLowerCase())
    // Anche su varietà, nome e nome scientifico della voce del catalogo: sono i
    // dati che la riga mostra in evidenza, quelli con cui un utente con più
    // piante della stessa specie le distingue.
    lista = lista.filter(p => {
      const nomeComune = store.vocePianta(p)?.nome ?? ''
      const scientifico = store.vocePianta(p)?.specie ?? ''
      return p.id.includes(q) ||
        normalizzaApici(scientifico.toLowerCase()).includes(q) ||
        normalizzaApici((p.varieta ?? '').toLowerCase()).includes(q) ||
        normalizzaApici(nomeComune.toLowerCase()).includes(q)
    })
    lista = [...lista].sort((a, b) => (a.urgente ? -1 : 1) - (b.urgente ? -1 : 1))
  } else if (filtroZona.value !== 'tutte') {
    lista = [...lista].sort((a, b) => (a.urgente ? -1 : 1) - (b.urgente ? -1 : 1))
  } else if (!selezionando.value) {
    lista = lista.filter(p => !p.urgente)
  }
  return lista
})

const pianteUrgenti = computed(() =>
  piante.value.filter(p => p.urgente && (filtroZona.value === 'tutte' || p.zona === filtroZona.value))
)

function avviaElimina(pianta) {
  daEliminare.value = pianta
}

async function eliminaPianta() {
  if (!daEliminare.value) return
  eliminando.value = true
  erroreEliminazione.value = null
  const id = daEliminare.value.id
  try {
    await galleria.eliminaCartella(id)
    await pianteApi.eliminaPianta(id)
    daEliminare.value = null
  } catch {
    erroreEliminazione.value = 'Non sono riuscito a eliminare la pianta. Riprova.'
  } finally {
    eliminando.value = false
  }
}
</script>

<style scoped>
.pv-azioni { display: flex; align-items: center; gap: 8px; }

.pv-sel { display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap;
  margin: -4px 0 8px; font: 400 12.5px/1.4 var(--font-sans); color: var(--ink-mid); }
.pv-sel__tutte { min-height: 44px; padding: 0 2px; background: none; border: none; cursor: pointer;
  font: 600 13px/1 var(--font-sans); color: var(--sage-ink); text-decoration: underline; text-underline-offset: 3px; text-decoration-thickness: 1px; }
.pv-sel__tutte:focus-visible { outline: none; box-shadow: 0 0 0 3px var(--gold); border-radius: 8px; }

/* Barra della selezione: resta in fondo mentre si scorre la lista. */
.pv-barra { position: sticky; bottom: 12px; z-index: 5; margin-top: 16px;
  display: flex; align-items: center; justify-content: space-between; gap: 12px;
  padding: 10px 10px 10px 18px; border-radius: 20px; background: var(--ink); color: var(--cream);
  box-shadow: 0 10px 30px rgba(42,34,24,0.28); }
.pv-barra__n { font: 500 13px/1.2 var(--font-sans); }
.pv-barra__sposta { min-height: 44px; padding: 0 18px; }
.pv-barra__sposta:disabled { opacity: .55; cursor: default; box-shadow: none; }
.pv-err { margin: 12px 0 0; color: var(--rose-ink); font: 400 12.5px/1.4 var(--font-sans); }

/* Ricalca esattamente la forma di .pr (PiantaRiga.vue) durante il
   caricamento — stesso filetto hairline tra le righe, non una card. */
.pr-skeleton { display: flex; align-items: center; gap: 14px; padding: 12px 2px; }
.pr-skeleton + .pr-skeleton { border-top: 1px solid var(--cream-dark); }

/* Svuota la ricerca in un tocco invece di cancellare carattere per
   carattere — utile su mobile con una mano sola. */
.search-clear {
  position: absolute; right: 0; top: 0; width: 44px; height: 44px;
  display: flex; align-items: center; justify-content: center;
  border: none; background: transparent; color: var(--ink-faint);
  font-size: 18px; line-height: 1; cursor: pointer;
}

/* Riga della lista principale come "smaterializzazione": .riga-cella è
   l'unica traccia di una grid (animare grid-template-rows tra 1fr e 0fr
   ne collassa/espande l'altezza), ma la dissolvenza+sfocatura del
   contenuto vive separata su .riga-cella__inner e la precede — invece di
   un contenuto che si "ritaglia" mentre il box si stringe (l'effetto
   ghigliottina della versione a fisarmonica), il contenuto è già
   scomparso quando lo spazio inizia davvero a richiudersi. Niente
   position:absolute né transform di riposizionamento: a differenza di
   .stagger (main.css, usato altrove per liste più statiche), qui non c'è
   nessun .righe-move da tenere sincronizzato con entrata/uscita — il
   riflusso delle righe vicine è solo l'effetto normale del layout che
   cambia altezza, non un'animazione a parte. */
.riga-cella { display: grid; grid-template-rows: 1fr; min-height: 0; }
.riga-cella__inner {
  overflow: hidden; min-height: 0;
  opacity: 1; filter: blur(0); transform: scale(1);
  transition: opacity 0.22s ease-out, filter 0.22s ease-out, transform 0.22s ease-out;
}
.righe-leave-to .riga-cella__inner,
.righe-enter-from .riga-cella__inner {
  opacity: 0; filter: blur(3px); transform: scale(0.96);
}

/* In uscita il collasso dell'altezza parte con un piccolo ritardo fisso
   (0.12s) rispetto alla dissolvenza del contenuto, sempre lo stesso per
   tutte le righe — non un ritardo a cascata per indice: le righe che
   escono si dissolvono tutte insieme, senza aspettare il proprio turno
   (è proprio l'attesa in uscita ad aver causato l'effetto sovrapposto
   della prima versione). In entrata invece l'altezza cresce subito, e
   solo il contenuto aspetta un istante (0.08s, più l'eventuale ritardo a
   cascata --stagger-delay) prima di "materializzarsi". */
.righe-leave-active { transition: grid-template-rows 0.36s cubic-bezier(0.22,1,0.36,1) 0.12s; }
.righe-enter-active { transition: grid-template-rows 0.36s cubic-bezier(0.22,1,0.36,1); transition-delay: var(--stagger-delay, 0s); }
.righe-enter-active .riga-cella__inner { transition-delay: calc(var(--stagger-delay, 0s) + 0.08s); }
.righe-enter-from, .righe-leave-to { grid-template-rows: 0fr; }

@media (prefers-reduced-motion: reduce) {
  .righe-enter-active, .righe-leave-active, .riga-cella__inner { transition: none !important; }
}
</style>
