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
          <div class="greet">{{ saluto }}</div>
          <div class="stat">
            <template v-if="store.loading">
              <span class="skeleton" style="width:64px;height:22px;border-radius:999px;"></span>
              <span class="skeleton" style="width:52px;height:22px;border-radius:999px;"></span>
              <span class="skeleton" style="width:76px;height:22px;border-radius:999px;"></span>
            </template>
            <template v-else>
              <span>{{ numPiante }} piante</span>
              <span>{{ numZone }} zone</span>
              <span><b>{{ numUrgenti }} da curare</b></span>
            </template>
          </div>
        </div>
      </div>

      <ZorbaLogo ref="zorbaLogo" class="hero__z" />
    </div>

    <!-- TEMPORANEO: pannello per forzare stagione/luce e vedere a comando il
         ridisegno cinematico e le altre scene, senza aspettare un vero
         cambio di stagione/tramonto. Fuori da .hero apposta: .hero ha
         overflow:hidden e un'altezza pensata solo per la scena, qualunque
         cosa aggiunta lì dentro viene ritagliata via e resta invisibile.
         Solo in sviluppo (assente in build di produzione): da rimuovere
         quando non serve più. -->
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
        <span class="zdice__s">Chiedi un consiglio, identifica una specie, pianifica un progetto</span>
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
          <Icon :name="icona(a.tipo)" class="task__ic" />
          <div class="task__m">
            <div class="task__n">{{ a.nomeSpecie }}</div>
            <div class="task__d">{{ a.label }}</div>
            <div v-if="erroreRegistrazione?.key === a.key" class="task__d task__d--err">{{ erroreRegistrazione.messaggio }}</div>
          </div>
          <button class="care-act" type="button" @click="registra(a)" :disabled="salvando === a.key">
            <Spinner v-if="salvando === a.key" /><span v-else>Fatto</span>
          </button>
        </div>
      </div>
      <RouterLink v-if="daFareOggi.length > 5" class="seeall" to="/attivita">
        Vedi tutte le {{ daFareOggi.length }} attività →
      </RouterLink>
    </template>

    <p v-else class="prose">Nessuna cura urgente oggi.</p>

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
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useAuth } from '@/composables/useAuth'
import { usePianteApi } from '@/composables/usePianteApi'
import { valutaCura, cureUrgentiPianta, stagione } from '@/composables/useCure'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import ToastCura from '@/components/ToastCura.vue'
import HeroAiuola from '@/components/HeroAiuola.vue'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const store = useDatiStore()
const pianteApi = usePianteApi()
const { utente } = useAuth()
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

// Nessun profilo con nome proprio in Supabase Auth (solo email/password, vedi
// useAuth.js): il saluto usa la parte locale dell'email come nome di
// cortesia invece di un nome hardcoded, che era corretto solo per un unico
// utente e sbagliato per chiunque altro ora che l'app è multiutente.
const saluto = computed(() => {
  const prefisso = prefissoOra()
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

// TEMPORANEO: forzatura manuale di stagione/luce per il pannello di test
// qui sotto — assente in produzione (vedi modalitaSviluppo). null = usa il
// valore reale calcolato sopra.
const modalitaSviluppo = import.meta.env.DEV
const stagioneForzata = ref(null)
const luceForzata = ref(null)
const stagioneEffettiva = computed(() => stagioneForzata.value ?? stagioneCorrente.value)
const luceEffettiva = computed(() => luceForzata.value ?? luceScena.value)

// Potatura non è più una cura a urgenza (resta registrabile nella scheda pianta):
// il feed "Da fare oggi" valuta solo irrigazione, concimazione e — per le poche
// specie con beneficio documentato — calcio.
const ICONE_CURA = { irrigazione: 'goccia', concimazione: 'concimazione', calcio: 'provetta' }
function icona(tipo) {
  return ICONE_CURA[tipo] ?? 'goccia'
}

const numPiante   = computed(() => store.piante   ? Object.keys(store.piante).length   : null)
const numZone     = computed(() => store.zone     ? Object.keys(store.zone).length     : null)
const numConcimi  = computed(() => store.concimi  ? Object.keys(store.concimi).length  : null)
const numProgetti = computed(() => store.progetti ? Object.keys(store.progetti).length : null)
// Contesto per pianta (stesso pattern di AttivitaView.vue): senza questo,
// valutaCura non sa distinguere una pianta esterna da una in casa e non può
// sospendere l'irrigazione quando la riga meteo qui sopra mostra pioggia in
// arrivo — le due sezioni potevano contraddirsi a vista.
function contestoPianta(p) {
  return { meteo: store.meteo, esterno: store.zone?.[p.zona]?.tipo === 'esterno' }
}

const numUrgenti = computed(() => {
  if (!store.piante) return null
  let count = 0
  for (const [, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie] ?? null
    if (cureUrgentiPianta(p, sp, contestoPianta(p)).length > 0) count++
  }
  return count
})

const daFareOggi = computed(() => {
  if (!store.piante) return []
  const items = []
  for (const [id, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie] ?? null
    const nomeSpecie = sp?.nome ?? p.specie
    const contesto = contestoPianta(p)
    const tipi = ['irrigazione', 'concimazione']
    if (sp?.manutenzione?.calcio) tipi.push('calcio')
    for (const tipo of tipi) {
      const c = valutaCura(p, sp, tipo, contesto)
      if (c.urgente) items.push({ key: `${id}-${tipo}`, piantaId: id, tipo, nomeSpecie, label: c.label })
    }
  }
  return items
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
    { to: '/zone',     icona: 'pin',        label: 'Zone',     count: numZone.value !== null ? `${numZone.value}` : null, urgent: false },
    { to: '/piante',   icona: 'foglia',     label: 'Piante',   count: numUrgenti.value ? `${numUrgenti.value} da curare` : (numPiante.value !== null ? `${numPiante.value}` : null), urgent: !!numUrgenti.value },
    { to: '/progetti', icona: 'lampadina',  label: 'Progetti', count: numProgetti.value !== null ? `${numProgetti.value} apert${numProgetti.value === 1 ? 'o' : 'i'}` : null, urgent: false },
    { to: '/concimi',  icona: 'provetta',   label: 'Concimi',  count: numConcimi.value !== null ? `${numConcimi.value}` : null, urgent: false },
    { to: '/attivita', icona: 'campanella', label: 'Attività', count: n ? `${n} urgent${n === 1 ? 'e' : 'i'}` : 'tutto ok', urgent: n > 0 },
    { to: '/gallery',  icona: 'cornice',    label: 'Gallery',  count: null, urgent: false },
  ]
})

onMounted(() => {
  store.caricaTutto()
})
</script>

<style scoped>
/* L'hero arriva a filo dei bordi di .app-main (padding 28px 16px). */
.hero { margin: -28px -16px 0; }

.task__d--err { color: var(--rose-dark); }

/* TEMPORANEO: pannello di test scena, vedi commento nel template. */
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
</style>
