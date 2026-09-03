<template>
  <div class="dossier-pianta">
    <p class="dossier-pianta__zona">
      <Icon :name="store.iconaZona(pianta.zona)" /> {{ pianta.zona }}<span v-if="pianta.sottozona"> · {{ pianta.sottozona }}</span>
      <span v-if="pianta.varieta"> — {{ pianta.varieta }}</span>
    </p>

    <div class="slabel">Stato cure</div>
    <div class="care">
      <div v-for="tipo in tipiCura" :key="tipo" class="care__row">
        <span class="care__ic" :class="`care__ic--${tipo}`"><Icon :name="iconaCura(tipo)" /></span>
        <span class="care__m">
          <span class="care__n">{{ LABEL_CURA[tipo] ?? tipo }}</span>
          <span class="care__d">{{ valutaCura(pianta, specie, tipo, contestoCura).label ?? 'Non configurata' }}</span>
        </span>
        <button class="care-act" type="button" @click="registraCuraTipo(tipo)" :disabled="salvandoTipo === tipo">
          <Spinner v-if="salvandoTipo === tipo" /><span v-else>Fatto</span>
        </button>
      </div>
    </div>

    <template v-if="fabbisognoNpk && classificaConcimiPianta.length">
      <div class="slabel">Concimi consigliati</div>
      <p class="prose feed-nb">Fabbisogno attuale: {{ fabbisognoNpk }}</p>
      <div class="feedlist">
        <div v-for="(c, i) in classificaConcimiPianta" :key="c.id" class="feed">
          <span class="feed__rank" :class="{ 'feed__rank--dim': i > 0 }">{{ i + 1 }}</span>
          <div class="feed__m"><div class="feed__n">{{ c.nome }}<span v-if="c.disponibile === false" class="feed__tag">terminato</span></div></div>
          <span class="feed__npk">{{ c.npk.n }}-{{ c.npk.p }}-{{ c.npk.k }}</span>
        </div>
      </div>
    </template>

    <template v-if="specie?.esigenze && Object.keys(specie.esigenze).length">
      <div class="slabel">Esigenze</div>
      <div class="kv">
        <div v-for="(val, chiave) in specie.esigenze" :key="chiave">
          <span class="k"><Icon :name="iconaEsigenza(chiave)" />{{ capitalizza(chiave) }}</span><span class="v">{{ val }}</span>
        </div>
      </div>
    </template>

    <template v-if="specie?.alert?.length">
      <div class="slabel">Note tecniche</div>
      <ul class="notelist"><li v-for="a in specie.alert" :key="a">{{ a }}</li></ul>
    </template>

    <template v-if="pianta.note">
      <div class="slabel">Note</div>
      <p class="prose">{{ pianta.note }}</p>
    </template>

    <RouterLink :to="`/piante/${piantaId}`" class="dossier-pianta__link">Apri la scheda completa →</RouterLink>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { usePianteApi } from '@/composables/usePianteApi'
import { valutaCura, stagione } from '@/composables/useCure'
import { classificaConcimiPerFabbisogno } from '@/composables/useConcimi'
import { iconaCura, LABEL_CURA, iconaEsigenza, capitalizza } from '@/composables/useCureVisual'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const props = defineProps({ piantaId: { type: String, required: true } })
const store = useDatiStore()
const pianteApi = usePianteApi()

const pianta = computed(() => store.piante?.[props.piantaId] ?? null)
const specie = computed(() => pianta.value ? (store.specie?.[pianta.value.specie] ?? null) : null)
const nomeSpecie = computed(() => specie.value?.nome ?? pianta.value?.specie ?? '')

// "calcio" riguarda solo le poche specie con un beneficio documentato (vedi
// PiantaView): mostrarlo per tutte le altre come "Non configurata" sarebbe
// rumore, a differenza di irrigazione/concimazione sempre pertinenti.
const tipiCura = computed(() => {
  const base = ['irrigazione', 'concimazione']
  if (specie.value?.manutenzione?.calcio) base.push('calcio')
  return base
})
const contestoCura = computed(() => ({
  esterno: store.zone?.[pianta.value?.zona]?.tipo === 'esterno',
  meteo: store.meteo,
}))
const fabbisognoNpk = computed(() => specie.value?.manutenzione?.npk?.[stagione()] ?? null)
const classificaConcimiPianta = computed(() =>
  fabbisognoNpk.value ? classificaConcimiPerFabbisogno(fabbisognoNpk.value, store.concimi).slice(0, 3) : []
)

const salvandoTipo = ref(null)
async function registraCuraTipo(tipo) {
  if (!pianta.value || salvandoTipo.value) return
  salvandoTipo.value = tipo
  try { await pianteApi.registraCura(props.piantaId, tipo) }
  finally { salvandoTipo.value = null }
}
</script>

<style scoped>
.dossier-pianta { padding: 4px 16px 24px; }
.dossier-pianta__zona {
  display: flex; align-items: center; gap: 6px;
  font: 400 12px/1.4 var(--font-sans); color: var(--ink-soft); margin: 0 0 6px;
}
.dossier-pianta__zona svg { width: 14px; height: 14px; flex: none; }
.dossier-pianta .slabel:first-of-type { margin-top: 4px; }
.dossier-pianta__link {
  display: inline-block; margin-top: 18px;
  font: 600 12px/1 var(--font-sans); color: var(--sage-dark); text-decoration: none;
}
</style>
