<template>
  <div class="fcz foglio-form">
    <p class="fcz__sotto">{{ totale }} {{ totale === 1 ? 'pianta' : 'piante' }} · {{ dataOggi }}</p>

    <div v-if="tipiDisponibili.length > 1" class="fcz__scelta" role="radiogroup" aria-label="Cura da registrare">
      <button v-for="t in tipiDisponibili" :key="t" type="button" role="radio" :aria-checked="tipo === t"
        class="pill tab-icona" :class="{ active: tipo === t }" @click="tipo = t">
        <Icon :name="iconaCura(t)" />{{ LABEL_CURA[t] }}
      </button>
    </div>

    <!-- Concime: si sceglie prima, perché decide quali piante spuntare. -->
    <template v-if="tipo === 'concimazione'">
      <div class="slabel">Concime usato</div>
      <div class="fcz__concimi" role="radiogroup" aria-label="Concime usato">
        <button v-for="c in concimiOrdinati" :key="c.id" type="button" role="radio" :aria-checked="concimeId === c.id"
          class="fcz__concime" :class="{ 'fcz__concime--attivo': concimeId === c.id }" @click="concimeId = c.id">
          <span class="fcz__concime-n">{{ c.nome }}<span v-if="c.disponibile === false" class="fcz__tag">terminato</span></span>
          <span class="fcz__concime-npk">{{ formattaNPK(c.npk) }}</span>
        </button>
        <button type="button" role="radio" :aria-checked="concimeId === null"
          class="fcz__concime" :class="{ 'fcz__concime--attivo': concimeId === null }" @click="concimeId = null">
          <span class="fcz__concime-n">Senza indicare il prodotto</span>
        </button>
      </div>
    </template>

    <p v-if="pioggia" class="fcz__avviso" role="note"><Icon name="goccia" />È prevista pioggia nei prossimi due giorni: l'irrigazione si può rimandare.</p>

    <template v-for="sezione in sezioni" :key="sezione.chiave">
      <template v-if="sezione.voci.length">
        <div class="slabel">{{ sezione.titolo }}</div>
        <ul class="fcz__lista">
          <li v-for="v in sezione.voci" :key="v.piantaId">
            <label class="fcz__riga" :class="{ 'fcz__riga--esclusa': sezione.chiave === 'escluse' }">
              <input type="checkbox" :checked="scelte.has(v.piantaId)" :disabled="sezione.chiave === 'escluse'"
                @change="alterna(v.piantaId)">
              <span class="fcz__m">
                <span class="fcz__nome">{{ v.nome }}<span v-if="v.varieta" class="fcz__var"> — {{ v.varieta }}</span><span v-if="!sottozona && v.sottozona" class="fcz__sz"> · {{ v.sottozona }}</span></span>
                <span class="fcz__motivo">{{ v.motivo }}</span>
                <span v-if="v.avviso" class="fcz__motivo fcz__motivo--avviso">{{ v.avviso }}</span>
              </span>
            </label>
          </li>
        </ul>
      </template>
    </template>

    <div class="fcz__piede">
      <p v-if="errore" class="fcz__err" role="alert">{{ errore }}</p>
      <button type="button" class="btn btn-sage fcz__registra" :disabled="!scelte.size || salvando" @click="registra">
        <Spinner v-if="salvando" /><span v-else>{{ testoPulsante }}</span>
      </button>
    </div>
  </div>
</template>

<script setup>
// Foglio «cura per zona» (Attività → Per zona): elenca le piante di una zona
// o sottozona divise in da fare / possono riceverla / escluse, con le spunte
// proposte da curaZona.js, e registra la cura sulle piante spuntate.
import { ref, computed, watch } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { classificaCuraZona, pianteDellaZona } from '@/utils/curaZona'
import { tipiCuraPianta, pioggiaInArrivo, stagione } from '@/composables/useCure'
import { concimeConsigliato, formattaNPK } from '@/composables/useConcimi'
import { LABEL_CURA, iconaCura } from '@/composables/useCureVisual'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const props = defineProps({
  zona: { type: String, required: true },
  sottozona: { type: String, default: null },
  tab: { type: String, required: true },   // 'irrigazione' | 'concimi'
  salvando: { type: Boolean, default: false },
  errore: { type: String, default: null },
})
const emit = defineEmits(['registra'])

const store = useDatiStore()
const dataOggi = new Date().toLocaleDateString('it-IT', { day: 'numeric', month: 'long' })

const piante = computed(() => pianteDellaZona(store.piante, props.zona, props.sottozona))
const totale = computed(() => piante.value.length)

// Nella scheda Concimi il calcio compare solo se almeno una pianta lo prevede.
const tipiDisponibili = computed(() => {
  if (props.tab === 'irrigazione') return ['irrigazione']
  const conCalcio = piante.value.some(([, p]) => tipiCuraPianta(p, store.vocePianta(p)).includes('calcio'))
  return conCalcio ? ['concimazione', 'calcio'] : ['concimazione']
})
const tipo = ref(tipiDisponibili.value[0])

const concimiOrdinati = computed(() =>
  Object.entries(store.concimi ?? {})
    .map(([id, c]) => ({ id, ...c }))
    .sort((a, b) => (a.disponibile === false) - (b.disponibile === false) || a.nome.localeCompare(b.nome, 'it'))
)

// Proposta iniziale: il concime consigliato al maggior numero di piante della
// zona per il fabbisogno di questa stagione (a parità, il primo in elenco).
function concimePiuConsigliato() {
  const conteggi = new Map()
  const s = stagione()
  // Solo i concimi ancora in dispensa: proporre un prodotto terminato non aiuta.
  const disponibili = Object.fromEntries(Object.entries(store.concimi ?? {}).filter(([, c]) => c.disponibile !== false))
  for (const [, p] of piante.value) {
    const npk = store.vocePianta(p)?.manutenzione?.npk?.[s]
    const c = concimeConsigliato(npk, disponibili)
    if (c) conteggi.set(c.id, (conteggi.get(c.id) ?? 0) + 1)
  }
  let migliore = null
  for (const c of concimiOrdinati.value) {
    if ((conteggi.get(c.id) ?? 0) > (conteggi.get(migliore) ?? 0)) migliore = c.id
  }
  return migliore
}
const concimeId = ref(concimePiuConsigliato())

const gruppi = computed(() => classificaCuraZona({
  piante: store.piante, zona: props.zona, sottozona: props.sottozona, tipo: tipo.value,
  vocePianta: store.vocePianta, nomePianta: store.nomePianta,
  programmi: store.programmiIrrigazione, concimi: store.concimi,
  concimeId: tipo.value === 'concimazione' ? concimeId.value : null,
}))

const sezioni = computed(() => [
  { chiave: 'daFare', titolo: 'Da fare', voci: gruppi.value.daFare },
  { chiave: 'possono', titolo: 'Possono riceverla', voci: gruppi.value.possono },
  { chiave: 'escluse', titolo: 'Escluse', voci: gruppi.value.escluse },
])

// Le spunte ripartono dalla proposta quando cambiano cura o concime.
const scelte = ref(new Set())
watch([tipo, concimeId], () => {
  scelte.value = new Set([...gruppi.value.daFare, ...gruppi.value.possono].filter(v => v.spuntata).map(v => v.piantaId))
}, { immediate: true })

function alterna(id) {
  const nuove = new Set(scelte.value)
  if (nuove.has(id)) nuove.delete(id)
  else nuove.add(id)
  scelte.value = nuove
}

const esterna = computed(() => {
  const tipoSz = props.sottozona ? store.sottozone?.[props.zona]?.[props.sottozona]?.tipo : null
  return (tipoSz ?? store.zone?.[props.zona]?.tipo) === 'esterno'
})
const pioggia = computed(() => tipo.value === 'irrigazione' && esterna.value && pioggiaInArrivo(store.meteo))

const testoPulsante = computed(() => {
  const n = scelte.value.size
  const chi = n === 1 ? '1 pianta' : `${n} piante`
  if (!n) return 'Nessuna pianta scelta'
  if (tipo.value === 'irrigazione') return `Registra l'irrigazione per ${chi}`
  if (tipo.value === 'calcio') return `Registra il calcio per ${chi}`
  return `Registra la concimazione per ${chi}`
})

function registra() {
  if (!scelte.value.size || props.salvando) return
  emit('registra', {
    voci: [...scelte.value].map(piantaId => ({ piantaId, tipo: tipo.value })),
    concimeId: tipo.value === 'concimazione' ? concimeId.value : null,
  })
}
</script>

<style scoped>
.fcz__sotto { font:400 12px/1.4 var(--font-sans); color:var(--ink-soft); margin:-4px 0 14px; }
.fcz__scelta { display:flex; gap:6px; flex-wrap:wrap; margin-bottom:6px; }
.tab-icona { display:inline-flex; align-items:center; gap:5px; }
.tab-icona :deep(svg) { width:14px; height:14px; flex-shrink:0; }

.fcz__concimi { display:flex; flex-direction:column; gap:6px; }
.fcz__concime { display:flex; align-items:center; gap:10px; width:100%; min-height:44px; padding:8px 12px; text-align:left;
  background:var(--white); border:1px solid var(--cream-dark); border-radius:12px; cursor:pointer; color:var(--ink);
  font:500 13px/1.3 var(--font-sans); transition:border-color var(--motion-quick) var(--ease-standard), background var(--motion-quick) var(--ease-standard); }
.fcz__concime--attivo { border-color:var(--sage); background:var(--sage-pale); box-shadow:inset 0 0 0 1px var(--sage); }
.fcz__concime:focus-visible { outline:none; box-shadow:0 0 0 3px var(--gold); }
.fcz__concime-n { flex:1; min-width:0; }
.fcz__concime-npk { flex:none; font:600 12px/1 var(--font-sans); color:var(--ink-mid); font-variant-numeric:tabular-nums; }
.fcz__tag { margin-left:6px; font:600 10px/1 var(--font-sans); color:var(--rose-ink); text-transform:uppercase; letter-spacing:.06em; }

.fcz__avviso { display:flex; gap:8px; align-items:flex-start; margin:16px 0 0; padding:10px 12px; border-radius:12px;
  background:var(--acqua-bg); color:var(--acqua-ink); font:400 12px/1.45 var(--font-sans); }
.fcz__avviso :deep(svg) { width:14px; height:14px; flex:none; margin-top:2px; }

.fcz__lista { list-style:none; margin:0; padding:0; }
.fcz__lista li + li { border-top:1px solid var(--cream-dark); }
.fcz__riga { display:flex; align-items:flex-start; gap:12px; padding:10px 2px; cursor:pointer; min-height:44px; }
.fcz__riga input { flex:none; width:20px; height:20px; margin:1px 0 0; accent-color:var(--sage); cursor:pointer; }
.fcz__riga--esclusa { cursor:default; }
.fcz__riga--esclusa input { cursor:default; }
.fcz__riga--esclusa .fcz__nome { color:var(--ink-soft); }
.fcz__m { flex:1; min-width:0; display:flex; flex-direction:column; gap:2px; }
.fcz__nome { font:600 13px/1.3 var(--font-display); color:var(--ink); }
.fcz__var { font-weight:400; }
.fcz__sz { font:400 11px/1 var(--font-sans); color:var(--ink-soft); }
.fcz__motivo { font:400 11px/1.4 var(--font-sans); color:var(--ink-soft); }
.fcz__motivo--avviso { color:var(--gold-ink); }

/* Il pulsante resta in vista in fondo al foglio anche con molte piante. */
.fcz__piede { position:sticky; bottom:0; margin:16px -16px -22px; padding:12px 16px 16px;
  background:linear-gradient(to bottom, transparent, var(--white) 30%); }
.fcz__registra { width:100%; min-height:48px; display:inline-flex; align-items:center; justify-content:center; }
.fcz__registra:disabled { opacity:.55; cursor:default; box-shadow:none; }
.fcz__err { margin:0 0 8px; color:var(--rose-ink); font:400 12px/1.4 var(--font-sans); }
</style>
