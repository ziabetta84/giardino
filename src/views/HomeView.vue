<template>
  <div>
    <!-- Hero: aiuola a china, animata, con Zorba -->
    <div class="hero">
      <div class="hero__scene">
        <HeroAiuola :stagione="stagioneCorrente" :luce="luceScena" />
      </div>

      <div class="hero__grid">
        <div class="hero__txt">
          <div class="date">{{ oggi }}</div>
          <div class="greet">Buongiorno, Rob</div>
          <div class="stat">
            <span>{{ numPiante }} specie</span>
            <span>{{ numZone }} zone</span>
            <span><b>{{ numUrgenti }} da curare</b></span>
          </div>
        </div>
      </div>

      <ZorbaLogo class="hero__z" />
    </div>

    <!-- Meteo -->
    <RouterLink class="wxrow" to="/meteo">
      <Icon :name="meteoOggi?.icona ?? 'meteo'" class="wxrow__ic" />
      <span class="wxrow__m">
        <span v-if="meteoOggi" class="wxrow__t">{{ meteoOggi.tMax }}° / {{ meteoOggi.tMin }}° · {{ meteoOggi.descrizione }}</span>
        <span v-else class="wxrow__t">Caricamento meteo…</span>
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

    <template v-else-if="daFareOggi.length">
      <div class="tasklist">
        <div v-for="a in daFareOggi.slice(0, 5)" :key="a.key" class="task">
          <Icon :name="icona(a.tipo)" class="task__ic" />
          <div class="task__m">
            <div class="task__n">{{ a.nomeSpecie }}</div>
            <div class="task__d">{{ a.label }}</div>
          </div>
          <button class="pill-mini" type="button">Fatto</button>
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
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useMeteo } from '@/composables/useMeteo'
import { valutaCura, cureUrgentiPianta, stagione } from '@/composables/useCure'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import HeroAiuola from '@/components/HeroAiuola.vue'
import Icon from '@/components/Icon.vue'

const store = useDatiStore()
const { giorni: meteoGiorni, carica: caricaMeteo } = useMeteo()

const oggi = new Date().toLocaleDateString('it-IT', { weekday:'long', day:'numeric', month:'long' })

const meteoOggi = computed(() => meteoGiorni.value?.[0] ?? null)

// Stagione dal mese corrente (stessa euristica di useCure.js per le urgenze
// di cura). Luce da alba/tramonto di oggi (Open-Meteo, via useMeteo) — finché
// il meteo non è ancora arrivato si mostra "giorno" come default ragionevole.
const stagioneCorrente = computed(() => stagione())
const luceScena = computed(() => {
  const g = meteoOggi.value
  if (!g?.alba || !g?.tramonto) return 'giorno'
  const ora = new Date()
  return (ora >= new Date(g.alba) && ora < new Date(g.tramonto)) ? 'giorno' : 'notte'
})

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
const numUrgenti = computed(() => {
  if (!store.piante) return null
  let count = 0
  for (const [, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie] ?? null
    if (cureUrgentiPianta(p, sp).length > 0) count++
  }
  return count
})

const daFareOggi = computed(() => {
  if (!store.piante) return []
  const items = []
  for (const [id, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie] ?? null
    const nomeSpecie = sp?.nome ?? p.specie
    const tipi = ['irrigazione', 'concimazione']
    if (sp?.manutenzione?.calcio) tipi.push('calcio')
    for (const tipo of tipi) {
      const c = valutaCura(p, sp, tipo)
      if (c.urgente) items.push({ key: `${id}-${tipo}`, tipo, nomeSpecie, label: c.label })
    }
  }
  return items
})

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

onMounted(async () => {
  await store.caricaTutto()
  const s = store.settings
  caricaMeteo(s?.location?.lat ?? 43.8309, s?.location?.lon ?? 12.9860)
})
</script>

<style scoped>
/* L'hero arriva a filo dei bordi di .app-main (padding 28px 16px). */
.hero { margin: -28px -16px 0; }

/* Il bottone "Fatto" qui non ha ancora un handler (nessun @click) — resta
   volutamente non wireato in questo giro. Con .pill-mini ora cursor:pointer
   di base (per gli altri 5 usi, tutti interattivi), qui va tenuto un
   cursore statico per non promettere un'azione che non esiste. */
.task .pill-mini { cursor: default; }
</style>
