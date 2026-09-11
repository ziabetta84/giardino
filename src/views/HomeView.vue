<template>
  <div>
    <!-- Hero: aiuola a china, animata, con Zorba -->
    <div class="hero">
      <div class="hero__scene">
        <HeroAiuola :stagione="stagioneEffettiva" :luce="luceEffettiva" @cambio-scena="zorbaLogo?.reagisci?.()" />
      </div>

      <div class="hero__grid">
        <div class="hero__txt">
          <div class="date">{{ oggi }}</div>
          <h1 class="greet">{{ saluto }}</h1>
          <div class="stat">
            <template v-if="store.loading">
              <span class="skeleton" style="width:64px;height:22px;border-radius:999px;"></span>
              <span class="skeleton" style="width:52px;height:22px;border-radius:999px;"></span>
              <span class="skeleton" style="width:76px;height:22px;border-radius:999px;"></span>
            </template>
            <template v-else-if="store.errore">
              <span>Dati non disponibili</span>
            </template>
            <template v-else-if="numPiante === 0">
              <span>{{ numZone === 0 ? 'Pronto per iniziare' : 'Aggiungi una pianta' }}</span>
            </template>
            <template v-else>
              <span>{{ numPiante }} piante</span>
              <span>{{ numZone }} zone</span>
              <span><b :class="{ urg: numUrgenti }">{{ numUrgenti }} piante da curare</b></span>
            </template>
          </div>
        </div>
      </div>

      <ZorbaLogo ref="zorbaLogo" class="hero__z"
        :class="luceEffettiva === 'notte' ? 'hero__z--notte' : 'hero__z--giorno'" />
    </div>

    <!-- Pannello di QA visiva: forza stagione/luce per vedere a comando il
         ridisegno cinematico e le altre scene, senza aspettare un vero
         cambio di stagione/tramonto (l'unico modo pratico di rivedere tutte
         le combinazioni in fase di sviluppo/verifica). Fuori da .hero
         apposta: .hero ha overflow:hidden e un'altezza pensata solo per la
         scena, qualunque cosa aggiunta lì dentro viene ritagliata via e
         resta invisibile. Escluso dalla build di produzione via
         `import.meta.env.DEV` (dead-code eliminato da Vite): resta
         infrastruttura di sviluppo permanente, non uno scarto da rimuovere. -->
    <div v-if="modalitaSviluppo" class="hero-debug">
      <span class="hero-debug__label">Test scena (solo sviluppo)</span>
      <div class="hero-debug__row">
        <button v-for="s in ['primavera','estate','autunno','inverno']" :key="s" type="button"
          class="pill" :class="{ active: stagioneEffettiva === s }" @click="stagioneForzata = s">{{ s }}</button>
      </div>
      <div class="hero-debug__row">
        <button type="button" class="pill" :class="{ active: luceEffettiva === 'giorno' }" @click="luceForzata = 'giorno'">giorno</button>
        <button type="button" class="pill" :class="{ active: luceEffettiva === 'notte' }" @click="luceForzata = 'notte'">notte</button>
        <button type="button" class="pill" @click="stagioneForzata = null; luceForzata = null">reale</button>
      </div>
    </div>

    <!-- Meteo -->
    <RouterLink class="wxrow" to="/meteo">
      <Icon :name="meteoOggi?.icona ?? 'meteo'" class="wxrow__ic" />
      <span class="wxrow__m">
        <span v-if="meteoOggi" class="wxrow__t">{{ meteoOggi.tMax }}° / {{ meteoOggi.tMin }}° · {{ meteoOggi.descrizione }}</span>
        <span v-else-if="store.loading" class="wxrow__t">Caricamento meteo…</span>
        <span v-else class="wxrow__t">Meteo non disponibile</span>
        <span v-if="meteoOggi" class="wxrow__s">{{ meteoOggi.pioggia }} mm di pioggia · vento {{ meteoOggi.vento }} km/h</span>
      </span>
      <Icon name="back" class="wxrow__chev" style="transform:rotate(180deg)" />
    </RouterLink>

    <!-- Zorba dice -->
    <RouterLink class="zdice" to="/agente">
      <span class="zdice__ic is-zorba"><Icon name="gatto" /></span>
      <span class="zdice__m">
        <span class="zdice__t">Zorba dice</span>
        <span class="zdice__s">{{ zorbaDiceSottotitolo }}</span>
      </span>
      <Icon name="back" class="zdice__chev" style="transform:rotate(180deg)" />
    </RouterLink>

    <!-- Da fare oggi -->
    <div class="slabel">Da fare oggi</div>

    <p v-if="store.loading" class="prose">Sto raccogliendo le cure di oggi…</p>

    <div v-else-if="store.errore" class="alertbox alertbox--rose">
      <span class="alertbox__ic"><Icon name="allerta" /></span>
      <div class="alertbox__main">
        <div class="alertbox__title">Non riesco a controllare le cure di oggi</div>
        <div class="alertbox__rows">
          <button class="care-act care-act--rose" type="button" @click="store.caricaTutto()">Riprova</button>
        </div>
      </div>
    </div>

    <template v-else-if="daFareOggi.length">
      <div class="tasklist">
        <div v-for="a in daFareOggi.slice(0, 5)" :key="a.key" class="task">
          <template v-if="a.tipo === 'tappa'">
            <span class="care__ic care__ic--tappa"><Icon name="lampadina" /></span>
            <div class="task__m">
              <div class="task__n">{{ a.progettoTitolo }}</div>
              <div class="task__d">{{ a.label }}</div>
              <div v-if="a.extra" class="task__d">+{{ a.extra }} altr{{ a.extra === 1 ? 'a tappa' : 'e tappe' }} in ritardo</div>
            </div>
            <RouterLink class="care-act" :to="`/progetti/${a.progettoId}`">Vedi</RouterLink>
          </template>
          <template v-else>
            <span class="care__ic" :class="`care__ic--${a.tipo}`"><Icon :name="iconaCura(a.tipo)" /></span>
            <div class="task__m">
              <div class="task__n">{{ a.nomeSpecie }}</div>
              <div class="task__d">{{ a.label }}</div>
              <div v-if="a.tipo === 'concimazione' && a.suggerimento" class="attivita-riga__sugg">
                <Icon name="concimazione" /> Consigliato: {{ a.suggerimento.nome }} ({{ a.suggerimento.npk.n }}-{{ a.suggerimento.npk.p }}-{{ a.suggerimento.npk.k }})
                <Icon v-if="a.suggerimento.disponibile === false" name="allerta" class="attivita-riga__sugg-warn" aria-label="Terminato" />
              </div>
              <div v-if="erroreRegistrazione?.key === a.key" class="task__d task__d--err" role="alert">{{ erroreRegistrazione.messaggio }}</div>
            </div>
            <button class="care-act" type="button" @click="registra(a)" :disabled="salvando === a.key">
              <Spinner v-if="salvando === a.key" /><span v-else>Fatto</span>
            </button>
          </template>
        </div>
      </div>
      <RouterLink v-if="daFareOggi.length > 5" class="seeall" to="/attivita">
        Vedi tutte le {{ daFareOggi.length }} attività →
      </RouterLink>
    </template>

    <!-- Primo avvio: zero piante non è un traguardo, è l'inizio — non riusa
         la ricompensa "Tutto in ordine!" (vedi critica del 06/09/2026: un
         giardino vuoto e un arretrato azzerato non sono la stessa cosa).
         Due varianti, non una sola: zero zone e zero piante-ma-zone-già-
         create sono situazioni diverse con un'azione successiva diversa —
         mandare chi ha già una zona a "creane una" è un'affermazione falsa,
         non solo un tono sbagliato (vedi critica del 07/09/2026). In più,
         "!daFareOggi.length": zero piante non vuol dire zero da fare — una
         tappa di progetto scaduta è comunque reale anche senza piante, e
         deve vedersi nella lista sopra invece che sotto un invito a
         iniziare che la nasconderebbe (vedi critica del 07/09/2026). -->
    <div v-if="!store.loading && !store.errore && numPiante === 0 && numZone === 0 && !daFareOggi.length" class="empty">
      <Icon name="pin" />
      <p><b>Il tuo giardino ti aspetta</b>Aggiungi la prima zona per iniziare a tracciare piante e cure</p>
      <RouterLink class="btn btn-sage empty__cta" to="/zone">Crea la tua prima zona</RouterLink>
    </div>

    <div v-else-if="!store.loading && !store.errore && numPiante === 0 && !daFareOggi.length" class="empty">
      <Icon name="foglia" />
      <p><b>La tua prima pianta ti aspetta</b>Aggiungi una pianta a una delle tue zone per iniziare a monitorarne le cure</p>
      <RouterLink class="btn btn-sage empty__cta" to="/piante/nuova">Aggiungi la tua prima pianta</RouterLink>
    </div>

    <!-- "Tutto in ordine!": lo stesso traguardo di AttivitaView.vue (azzerare
         l'arretrato), qui è anche il momento di ricompensa quotidiana di
         questa vista — merita lo stesso ingresso da 600ms, non un cambio di
         stato qualsiasi (vedi Motion in DESIGN.md e .tab-pulita in
         AttivitaView.vue, stessa impostazione). `appear` condizionato ad
         animaTraguardo (vero solo la prima volta in sessione), non sempre
         vero: senza `appear` l'ingresso non si vedeva mai arrivando su una
         Home già in ordine (il v-if è già vero al primo render), ma con
         `appear` sempre vero si vedeva a ogni singolo ritorno su una Home
         pulita — il "traguardo raro" diventava "a ogni visita", il contrario
         di .tab-pulita in AttivitaView.vue (vedi critica del 07/09/2026). Una
         transizione dal vivo (ultima cura completata restando su Home) anima
         comunque, a prescindere da questo valore — `appear` riguarda solo il
         primo render di questo mount. -->
    <Transition name="giardino-in-ordine" :appear="animaTraguardo">
      <div v-if="!store.loading && !store.errore && numPiante > 0 && !daFareOggi.length" class="empty">
        <Icon name="foglia" />
        <p><b>Tutto in ordine!</b>Nessuna cura urgente oggi</p>
      </div>
    </Transition>

    <!-- Il giardino -->
    <div class="slabel">Il giardino</div>
    <div class="destlist">
      <RouterLink v-for="card in homeCards" :key="card.to" class="dest" :to="card.to">
        <Icon :name="card.icona" class="dest__ic" />
        <span class="dest__n">{{ card.label }}</span>
        <span v-if="card.count != null" class="dest__c" :class="{ urg: card.urgent }">{{ card.count }}</span>
        <Icon name="back" class="dest__chev" style="transform:rotate(180deg)" />
      </RouterLink>
    </div>

    <ToastCura ref="toastCura" @errore="e => erroreRegistrazione = { key: `${e.id}-${e.tipo}`, messaggio: e.messaggio }" />
  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useAuth } from '@/composables/useAuth'
import { usePianteApi } from '@/composables/usePianteApi'
import { valutaCura, cureUrgentiPianta, stagione } from '@/composables/useCure'
import { iconaCura } from '@/composables/useCureVisual'
import { programmaIrrigazioneEffettivo } from '@/composables/useIrrigazioneAuto'
import { concimeConsigliato } from '@/composables/useConcimi'
import { tappeAttese } from '@/composables/useProgetti'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import ToastCura from '@/components/ToastCura.vue'
import HeroAiuola from '@/components/HeroAiuola.vue'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

// Variabile di modulo, non di componente: si azzera solo con un reload vero,
// non a ogni rimontaggio di HomeView (che avviene a ogni navigazione, vedi
// App.vue). "Tutto in ordine" deve animarsi ed emettere il battito di Zorba
// solo la prima volta che si verifica in questa sessione di pagina — altrimenti
// il "raro traguardo" diventava "a ogni ritorno su una Home già pulita" (vedi
// critica del 07/09/2026).
let giardinoGiaVistoInOrdine = false

const store = useDatiStore()
const pianteApi = usePianteApi()
const { utente, nomeUtente } = useAuth()
// Rif. a ZorbaLogo per due reazioni distinte (vedi ZorbaLogo.vue): un
// battito lento quando HeroAiuola segnala un cambio reale di stagione/luce
// (raro, "Zorba nota il cambiamento"), e un battito normale ad ogni cura
// registrata con successo (frequente, "Zorba conferma" — resta leggero
// anche alla decima cura della sessione).
const zorbaLogo = ref(null)

const oggi = new Date().toLocaleDateString('it-IT', { weekday:'long', day:'numeric', month:'long' })

// Prefisso per fascia oraria: un "Buongiorno" fisso alle 19 di sera rompe il
// ritmo "da fine giornata in giardino" che l'app vuole avere.
function prefissoOra() {
  const ora = new Date().getHours()
  if (ora < 12) return 'Buongiorno'
  if (ora < 18) return 'Buon pomeriggio'
  return 'Buonasera'
}

// Il saluto usa il nome scelto dall'utente in fase di registrazione
// (user_metadata.nome, vedi useAuth.js). Fallback alla parte locale dell'email
// per gli account creati prima dell'introduzione del campo, o se lasciato
// vuoto: mai un nome hardcoded, che era corretto solo per l'unico utente
// iniziale e sbagliato per chiunque altro ora che l'app è multiutente.
const saluto = computed(() => {
  const prefisso = prefissoOra()
  if (nomeUtente.value) return `${prefisso}, ${nomeUtente.value}`
  const locale = utente.value?.email?.split('@')[0]
  if (!locale) return prefisso
  const nome = locale.split(/[._-]+/).filter(Boolean)
    .map(s => s.charAt(0).toUpperCase() + s.slice(1)).join(' ')
  return nome ? `${prefisso}, ${nome}` : prefisso
})

// Il meteo di oggi viene dallo store (già caricato una volta da
// caricaTutto() e condiviso con AttivitaView.vue): prima questa vista aveva
// una propria istanza di useMeteo() che duplicava la stessa chiamata di rete,
// col rischio che le due fonti divergessero proprio nel calcolo dell'urgenza
// di irrigazione in caso di pioggia.
const meteoOggi = computed(() => store.meteo?.[0] ?? null)

// `adesso` esiste solo per rendere reattive stagione/luce al passare del
// tempo reale: senza questo, i due computed leggono `new Date()` ma non
// hanno alcuna dipendenza reattiva che li rivaluti, quindi in una sessione
// tenuta aperta a cavallo del tramonto la scena dell'hero non passerebbe
// mai da giorno a notte da sola (vedi il ridisegno a china su cambio stato
// in HeroAiuola.vue, altrimenti quasi mai raggiungibile).
const adesso = ref(new Date())
const intervalloOrologio = setInterval(() => { adesso.value = new Date() }, 60_000)
onUnmounted(() => clearInterval(intervalloOrologio))

// Stagione dal mese corrente (stessa euristica di useCure.js per le urgenze
// di cura). Luce da alba/tramonto di oggi (Open-Meteo, via store.meteo) — finché
// il meteo non è ancora arrivato si mostra "giorno" come default ragionevole.
const stagioneCorrente = computed(() => stagione(adesso.value))
const luceScena = computed(() => {
  const g = meteoOggi.value
  if (!g?.alba || !g?.tramonto) return 'giorno'
  return (adesso.value >= new Date(g.alba) && adesso.value < new Date(g.tramonto)) ? 'giorno' : 'notte'
})

// Forzatura manuale di stagione/luce per il pannello di QA visiva qui sotto
// — assente in produzione (vedi modalitaSviluppo). null = usa il valore
// reale calcolato sopra.
const modalitaSviluppo = import.meta.env.DEV
const stagioneForzata = ref(null)
const luceForzata = ref(null)
const stagioneEffettiva = computed(() => stagioneForzata.value ?? stagioneCorrente.value)
const luceEffettiva = computed(() => luceForzata.value ?? luceScena.value)

const numPiante   = computed(() => store.piante   ? Object.keys(store.piante).length   : null)
const numZone     = computed(() => store.zone     ? Object.keys(store.zone).length     : null)
const numConcimi  = computed(() => store.concimi  ? Object.keys(store.concimi).length  : null)
const numProgetti = computed(() => store.progetti ? Object.keys(store.progetti).length : null)
// Contesto per pianta (stesso pattern di AttivitaView.vue): senza questo,
// valutaCura non sa distinguere una pianta esterna da una in casa e non può
// sospendere l'irrigazione quando la riga meteo qui sopra mostra pioggia in
// arrivo — le due sezioni potevano contraddirsi a vista.
function contestoPianta(p, id) {
  const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, p.sottozona, store.programmiIrrigazione)?.ogniGiorni ?? null
  return { meteo: store.meteo, esterno: store.zone?.[p.zona]?.tipo === 'esterno', programmaAutomatico }
}

const numUrgenti = computed(() => {
  if (!store.piante) return null
  let count = 0
  for (const [id, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie] ?? null
    if (cureUrgentiPianta(p, sp, contestoPianta(p, id)).length > 0) count++
  }
  return count
})

// "mai registrata" restituisce giorni: Infinity (vedi useCure.js): una pianta
// mai curata è più urgente di una scaduta da N giorni, non meno — la mappiamo
// a un rango finito molto negativo invece di usare -Infinity per evitare che
// due elementi "mai registrata" producano NaN nel comparatore (Infinity -
// Infinity), che lascerebbe il loro ordine reciproco indefinito.
function rangoUrgenza(giorni) {
  return giorni === Infinity ? -1e15 : giorni
}

// Una riga per progetto, non una per tappa: più tappe scadute sullo stesso
// progetto affollerebbero i 5 posti di "Da fare oggi" a scapito di piante e
// altri progetti (vedi critica del 07/09/2026). La tappa più scaduta
// rappresenta il progetto; le altre si contano in "+N altre" sulla riga.
const tappeUrgentiOggi = computed(() => {
  const gruppi = new Map()
  for (const t of tappeAttese(store.progetti)) {
    if (!t.urgente) continue
    if (!gruppi.has(t.progettoId)) gruppi.set(t.progettoId, [])
    gruppi.get(t.progettoId).push(t)
  }
  const righe = []
  for (const [progettoId, lista] of gruppi) {
    lista.sort((a, b) => a.giorni - b.giorni)
    const [principale, ...altre] = lista
    righe.push({
      key: `tappa-${progettoId}-${principale.indice}`,
      tipo: 'tappa',
      progettoId,
      progettoTitolo: principale.progettoTitolo,
      label: `${principale.tappa.descrizione} — scaduta ${Math.abs(principale.giorni)} gg fa`,
      giorni: principale.giorni,
      extra: altre.length,
    })
  }
  return righe
})

const daFareOggi = computed(() => {
  if (!store.piante) return []
  const items = []
  for (const [id, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie] ?? null
    const nomeSpecie = sp?.nome ?? p.specie
    const contesto = contestoPianta(p, id)
    // Potatura non è più una cura a urgenza (resta registrabile nella scheda
    // pianta): il feed valuta solo irrigazione, concimazione e — per le poche
    // specie con beneficio documentato — calcio.
    const tipi = ['irrigazione', 'concimazione']
    if (sp?.manutenzione?.calcio) tipi.push('calcio')
    for (const tipo of tipi) {
      const c = valutaCura(p, sp, tipo, contesto)
      if (!c.urgente) continue
      // Stessa chiamata di AttivitaView.vue: le due viste non devono poter
      // consigliare concimi diversi per lo stesso fabbisogno (vedi critica
      // del 07/09/2026 — prima Home non mostrava alcun suggerimento).
      const suggerimento = tipo === 'concimazione'
        ? concimeConsigliato(sp?.manutenzione?.npk?.[stagioneCorrente.value], store.concimi)
        : null
      items.push({ key: `${id}-${tipo}`, piantaId: id, tipo, nomeSpecie, label: c.label, giorni: c.giorni, suggerimento })
    }
  }
  items.push(...tappeUrgentiOggi.value)
  // La più scaduta per prima (cure e tappe competono sulla stessa scala di
  // giorni di ritardo reali, decisione dell'utente del 07/09/2026): senza
  // questo, la lista (troncata alle prime 5 in template) seguiva l'ordine
  // di creazione delle piante, potendo nascondere una cura o una tappa
  // scaduta da settimane dietro una scaduta da un giorno.
  items.sort((a, b) => rangoUrgenza(a.giorni) - rangoUrgenza(b.giorni))
  return items
})

// Calcolato una sola volta, alla creazione di questa istanza: governa solo se
// il riquadro "Tutto in ordine" deve animarsi già al primo render di QUESTO
// mount (Transition `appear`, che non ha effetto su una transizione dal vivo
// più avanti — quella anima comunque). Se il completamento dell'ultima cura
// avviene mentre si è già su Home, resta una transizione dal vivo naturale e
// anima sempre, a prescindere da questo valore: qui si decide solo se un
// arrivo su una Home già pulita replica lo stesso ingresso o no.
const animaTraguardo = !giardinoGiaVistoInOrdine

// Se lo svuotamento avviene dal vivo (ultima cura completata restando su
// Home) segna comunque il traguardo come "già visto", altrimenti un
// successivo ritorno su Home (stessa sessione) lo animerebbe di nuovo da capo.
// Nessun battito qui: registra() ne ha già emesso uno per il salvataggio.
watch(() => daFareOggi.value.length, (n) => {
  if (n === 0 && numPiante.value > 0) giardinoGiaVistoInOrdine = true
})

// Zorba deve sentirsi collegato allo stesso giardino che l'utente vede sopra,
// non un rimando statico e sempre uguale (vedi critica del 06/09/2026): la
// riga "Zorba dice" nomina la pianta o la tappa più scadute (daFareOggi è già
// ordinata per urgenza) invece di un invito generico sempre identico.
const zorbaDiceSottotitolo = computed(() => {
  const fallback = 'Chiedi un consiglio, identifica una specie, pianifica un progetto'
  if (store.loading || !store.piante) return fallback
  const n = daFareOggi.value.length
  // Zero piante è l'inizio, non un arretrato azzerato: non riusa la riga
  // "il giardino è in ordine" (vedi critica del 06/09/2026). Zero zone e
  // zone-già-create-ma-zero-piante sono due situazioni diverse (vedi critica
  // del 07/09/2026): a chi ha già una zona non si dice di crearne una. Solo
  // se non c'è nemmeno una tappa in ritardo (!n): zero piante non vuol dire
  // zero da fare (vedi critica del 07/09/2026).
  if (numPiante.value === 0 && !n) {
    return numZone.value === 0
      ? "Non c'è ancora nulla da monitorare: aggiungi una zona per iniziare"
      : "Non c'è ancora nessuna pianta da monitorare: aggiungine una per iniziare"
  }
  if (n === 0) return 'Il giardino è in ordine: chiedimi comunque un consiglio, o pianifica qualcosa di nuovo'
  if (n === 1) {
    const item = daFareOggi.value[0]
    return item.tipo === 'tappa'
      ? `Ho notato che il progetto "${item.progettoTitolo}" ha una tappa scaduta`
      : `Ho notato che ${item.nomeSpecie} aspetta ancora una cura`
  }
  return `Ho notato ${n} cose in attesa nel giardino — vuoi un consiglio?`
})

const salvando = ref(null)
const erroreRegistrazione = ref(null)
const toastCura = ref(null)
async function registra(item) {
  if (salvando.value) return
  salvando.value = item.key
  erroreRegistrazione.value = null
  const valorePrecedente = store.piante?.[item.piantaId]?.ultima_cura?.[item.tipo] ?? null
  try {
    await pianteApi.registraCura(item.piantaId, item.tipo)
    zorbaLogo.value?.confermaCura?.()
    toastCura.value?.apri(item.piantaId, item.tipo, valorePrecedente)
  } catch {
    erroreRegistrazione.value = { key: item.key, messaggio: 'Non sono riuscito a registrare la cura. Riprova.' }
  } finally {
    salvando.value = null
  }
}

// Lista "Il giardino": stesso ordine della NavBar (Home e Meteo escluse —
// Home è questa pagina, Meteo ha già la sua riga qui sopra).
const homeCards = computed(() => {
  const n = daFareOggi.value.length
  return [
    // Zero non ottiene un badge (non solo "!== null"): un "0" nudo qui
    // contrasterebbe con il resto della pagina, scaldato apposta per il primo
    // avvio nelle righe sopra (vedi critica del 07/09/2026) — nessuna badge
    // non si legge come un errore, uno zero sì.
    { to: '/zone',     icona: 'pin',        label: 'Zone',     count: numZone.value ? `${numZone.value}` : null, urgent: false },
    { to: '/piante',   icona: 'foglia',     label: 'Piante',   count: numUrgenti.value ? `${numUrgenti.value} da curare` : (numPiante.value ? `${numPiante.value}` : null), urgent: !!numUrgenti.value },
    // Numero di progetti (non di tappe) in ritardo: coerente con come Piante
    // conta piante urgenti, non cure urgenti (vedi critica del 07/09/2026 —
    // prima "urgent" era fisso a false, indipendentemente da cosa fosse
    // davvero scaduto).
    { to: '/progetti', icona: 'lampadina',  label: 'Progetti', count: tappeUrgentiOggi.value.length ? `${tappeUrgentiOggi.value.length} in ritardo` : (numProgetti.value !== null ? `${numProgetti.value} apert${numProgetti.value === 1 ? 'o' : 'i'}` : null), urgent: tappeUrgentiOggi.value.length > 0 },
    { to: '/concimi',  icona: 'provetta',   label: 'Concimi',  count: numConcimi.value !== null ? `${numConcimi.value}` : null, urgent: false },
    { to: '/attivita', icona: 'campanella', label: 'Attività', count: n ? `${n} urgent${n === 1 ? 'e' : 'i'}` : 'tutto ok', urgent: n > 0 },
    { to: '/gallery',  icona: 'cornice',    label: 'Gallery',  count: null, urgent: false },
  ]
})

onMounted(async () => {
  await store.caricaTutto()
  // Battito normale di Zorba solo se si arriva già a giardino curato (non
  // se semplicemente non ci sono ancora piante, che è un altro stato): la
  // stessa conferma leggera usata per una cura registrata, riusata qui come
  // ricompensa quotidiana per il traguardo "Tutto in ordine!" qui sotto,
  // invece di lasciarlo comparire senza nessuna reazione (vedi critica del
  // 06/09/2026). Il salvataggio di una cura in registra() ha già il suo
  // battito: non se ne aggiunge un secondo se lo svuotamento avviene lì.
  // Solo la prima volta in sessione (vedi animaTraguardo/critica del
  // 07/09/2026): altrimenti il battito ripartirebbe a ogni ritorno su una
  // Home già pulita, disallineandosi di nuovo dal riquadro che non rianima.
  if (animaTraguardo && numPiante.value > 0 && daFareOggi.value.length === 0) {
    zorbaLogo.value?.confermaCura?.()
    giardinoGiaVistoInOrdine = true
  }
})
</script>

<style scoped>
/* L'hero arriva a filo dei bordi di .app-main (padding 28px 16px). */
.hero { margin: -28px -16px 0; }

/* --rose-ink (non --rose-dark): stesso motivo di .care-act--rose in main.css —
   qui su sfondo --cream --rose-dark scende sotto 4.5:1 in light mode. */
.task__d--err { color: var(--rose-ink); }

/* Bottone nel primo-avvio (.empty riusata da AttivitaView.vue non ha mai un
   CTA sotto il testo): margine solo qui, non nella classe condivisa. */
.empty__cta { margin-top: 14px; text-decoration: none; }

/* Pannello di QA visiva per la scena, vedi commento nel template. */
.hero-debug {
  display: flex; flex-direction: column; gap: 6px;
  margin: 10px 0 18px; padding: 10px 12px;
  border: 1px dashed var(--rose-light); border-radius: 14px;
  background: var(--rose-pale);
}
.hero-debug__label {
  font: 700 10px/1 var(--font-sans); letter-spacing: .08em; text-transform: uppercase;
  color: var(--rose-dark);
}
.hero-debug__row { display: flex; gap: 6px; flex-wrap: wrap; }

/* "Tutto in ordine!": stesso trattamento di .tab-pulita in AttivitaView.vue
   (600ms invece di --motion-quick/--motion-sheet, vedi Motion in DESIGN.md)
   — un momento raro che merita di essere notato, non un cambio di stato
   qualsiasi. Duplicata invece di condivisa: le due viste non importano CSS
   scoped a vicenda, e sono sei righe. */
.giardino-in-ordine-enter-active { transition: opacity .6s var(--ease-standard), transform .6s var(--ease-standard); }
.giardino-in-ordine-enter-from { opacity: 0; transform: translateY(14px) scale(.96); }
@media (prefers-reduced-motion: reduce) {
  .giardino-in-ordine-enter-active { transition: opacity .3s var(--ease-standard); }
  .giardino-in-ordine-enter-from { transform: none; }
}
</style>
