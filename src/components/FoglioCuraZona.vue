<template>
  <div class="fcz foglio-form">
    <p class="fcz__sotto">
      {{ totale }} {{ totale === 1 ? 'pianta' : 'piante' }}<template v-if="sottozoneComprese.length">, comprese quelle di {{ elenco(sottozoneComprese) }}</template> · {{ dataOggi }}
    </p>

    <!-- Concimazione o calcio: due segmenti nella tinta della propria cura. -->
    <div v-if="tipiDisponibili.length > 1" class="fcz__tipi" role="radiogroup" aria-label="Cura da registrare">
      <button v-for="t in tipiDisponibili" :key="t" type="button" role="radio" :aria-checked="tipo === t"
        class="fcz__tipo" :class="[`fcz__tipo--${t}`, { 'fcz__tipo--attivo': tipo === t }]" @click="tipo = t">
        <Icon :name="iconaCura(t)" />{{ LABEL_CURA[t] }}
      </button>
    </div>

    <!-- Concime: una riga sola con il prodotto scelto; «Cambia» apre l'elenco
         a filetti. Si sceglie prima delle piante perché decide le spunte. -->
    <template v-if="tipo === 'concimazione'">
      <div class="slabel">Concime usato</div>
      <div v-if="!sceltaConcimeAperta" class="fcz__concime-scelto">
        <span class="care__ic care__ic--concimazione"><Icon name="concimazione" /></span>
        <span class="fcz__concime-n">{{ concimeScelto ? concimeScelto.nome : 'Senza indicare il prodotto' }}</span>
        <span v-if="concimeScelto" class="fcz__npk">{{ formattaNPK(concimeScelto.npk) }}</span>
        <button type="button" class="fcz__cambia" :aria-expanded="false" @click="sceltaConcimeAperta = true">Cambia</button>
      </div>
      <ul v-else class="fcz__concimi" role="radiogroup" aria-label="Concime usato">
        <li v-for="c in opzioniConcime" :key="c.id ?? 'nessuno'">
          <button type="button" role="radio" :aria-checked="concimeId === c.id" class="fcz__concime"
            :class="{ 'fcz__concime--terminato': c.disponibile === false }" @click="scegliConcime(c.id)">
            <span class="fcz__radio" :class="{ 'fcz__radio--on': concimeId === c.id }" aria-hidden="true"></span>
            <span class="fcz__concime-n">{{ c.nome }}<span v-if="c.disponibile === false" class="fcz__tag">terminato</span></span>
            <span v-if="c.npk" class="fcz__npk">{{ formattaNPK(c.npk) }}</span>
          </button>
        </li>
      </ul>
    </template>

    <p v-if="pioggia" class="fcz__avviso fcz__avviso--acqua" role="note"><Icon name="goccia" />È prevista pioggia nei prossimi due giorni: l'irrigazione si può rimandare.</p>
    <p v-if="concimeInadatto" class="fcz__avviso fcz__avviso--gold" role="note"><Icon name="allerta" />{{ concimeScelto.nome }} non è adatto a nessuna di queste piante. Scegli un altro concime, oppure spunta a mano le piante che hai concimato.</p>

    <template v-for="sezione in sezioni" :key="sezione.chiave">
      <template v-if="sezione.voci.length">
        <div class="slabel">{{ sezione.titolo }}</div>
        <ul class="fcz__lista" :class="`fcz__lista--${sezione.chiave}`">
          <li v-for="v in sezione.voci" :key="v.piantaId">
            <label v-if="sezione.chiave !== 'escluse'" class="fcz__riga">
              <input type="checkbox" class="fcz__check" :checked="scelte.has(v.piantaId)" @change="alterna(v.piantaId)">
              <span class="fcz__m">
                <span class="fcz__nome"><NomeScientifico :nome="v.nome" /><span v-if="v.varieta" class="fcz__var">{{ v.varieta }}</span></span>
                <span class="fcz__motivo"><template v-if="!sottozona && v.sottozona">{{ v.sottozona }} · </template>{{ v.motivo }}</span>
                <span v-if="v.avviso && !concimeInadatto" class="fcz__motivo fcz__motivo--avviso">{{ v.avviso }}</span>
              </span>
            </label>
            <div v-else class="fcz__riga fcz__riga--esclusa">
              <span class="fcz__fuori" aria-hidden="true"></span>
              <span class="fcz__m">
                <span class="fcz__nome"><NomeScientifico :nome="v.nome" /><span v-if="v.varieta" class="fcz__var">{{ v.varieta }}</span></span>
                <span class="fcz__motivo"><template v-if="!sottozona && v.sottozona">{{ v.sottozona }} · </template>{{ v.motivo }}</span>
              </span>
            </div>
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
// proposte da curaZona.js, e registra la cura sulle piante spuntate. La cura
// scelta (intestazione del foglio) la mostra AttivitaView, che riceve il tipo
// con l'evento «tipo».
import { ref, computed, watch } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { classificaCuraZona, pianteDellaZona } from '@/utils/curaZona'
import { tipiCuraPianta, pioggiaInArrivo, stagione } from '@/composables/useCure'
import { concimeConsigliato, formattaNPK } from '@/composables/useConcimi'
import { LABEL_CURA, iconaCura } from '@/composables/useCureVisual'
import Icon from '@/components/Icon.vue'
import NomeScientifico from '@/components/NomeScientifico.vue'
import Spinner from '@/components/Spinner.vue'

const props = defineProps({
  zona: { type: String, required: true },
  sottozona: { type: String, default: null },
  tab: { type: String, required: true },   // 'irrigazione' | 'concimi'
  salvando: { type: Boolean, default: false },
  errore: { type: String, default: null },
})
const emit = defineEmits(['registra', 'tipo'])

const store = useDatiStore()
const dataOggi = new Date().toLocaleDateString('it-IT', { day: 'numeric', month: 'long' })

const piante = computed(() => pianteDellaZona(store.piante, props.zona, props.sottozona))
const totale = computed(() => piante.value.length)
const sottozoneComprese = computed(() =>
  props.sottozona ? [] : [...new Set(piante.value.map(([, p]) => p.sottozona).filter(Boolean))].sort((a, b) => a.localeCompare(b, 'it'))
)
function elenco(nomi) {
  return nomi.length < 2 ? nomi.join('') : `${nomi.slice(0, -1).join(', ')} e ${nomi.at(-1)}`
}

// Nella scheda Concimi il calcio compare solo se almeno una pianta lo prevede.
const tipiDisponibili = computed(() => {
  if (props.tab === 'irrigazione') return ['irrigazione']
  const conCalcio = piante.value.some(([, p]) => tipiCuraPianta(p, store.vocePianta(p)).includes('calcio'))
  return conCalcio ? ['concimazione', 'calcio'] : ['concimazione']
})
const tipo = ref(tipiDisponibili.value[0])
watch(tipo, t => emit('tipo', t), { immediate: true })

const concimiOrdinati = computed(() =>
  Object.entries(store.concimi ?? {})
    .map(([id, c]) => ({ id, ...c }))
    .sort((a, b) => (a.disponibile === false) - (b.disponibile === false) || a.nome.localeCompare(b.nome, 'it'))
)
const opzioniConcime = computed(() => [...concimiOrdinati.value, { id: null, nome: 'Senza indicare il prodotto' }])

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
const concimeScelto = computed(() => concimeId.value ? { id: concimeId.value, ...store.concimi?.[concimeId.value] } : null)
// Senza una proposta l'elenco parte aperto: c'è da scegliere.
const sceltaConcimeAperta = ref(concimeId.value === null && concimiOrdinati.value.length > 0)
function scegliConcime(id) {
  concimeId.value = id
  sceltaConcimeAperta.value = false
}

const gruppi = computed(() => classificaCuraZona({
  piante: store.piante, zona: props.zona, sottozona: props.sottozona, tipo: tipo.value,
  vocePianta: store.vocePianta, nomePianta: store.nomePianta,
  programmi: store.programmiIrrigazione, concimi: store.concimi,
  riceveLaPioggia: store.piantaRiceveLaPioggia, pioggiaCaduta: store.pioggiaCaduta,
  concimeId: tipo.value === 'concimazione' ? concimeId.value : null,
}))

const sezioni = computed(() => [
  { chiave: 'daFare', titolo: 'Da fare', voci: gruppi.value.daFare },
  { chiave: 'possono', titolo: 'Possono riceverla', voci: gruppi.value.possono },
  { chiave: 'escluse', titolo: 'Escluse', voci: gruppi.value.escluse },
])

// Un avviso solo, sopra le sezioni, quando il concime scelto non va bene per
// nessuna pianta giudicabile: ripeterlo riga per riga copriva l'elenco.
const concimeInadatto = computed(() => {
  if (tipo.value !== 'concimazione' || !concimeScelto.value) return false
  const giudicate = [...gruppi.value.daFare, ...gruppi.value.possono].filter(v => v.adatto !== null)
  return giudicate.length > 0 && giudicate.every(v => v.adatto === false)
})

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
  const sz = props.sottozona ? store.sottozone?.[props.zona]?.[props.sottozona] : null
  const zona = store.zone?.[props.zona]
  // All'aperto e non al riparo dalla pioggia: solo allora l'avviso della pioggia prevista ha senso.
  return (sz?.tipo ?? zona?.tipo) === 'esterno' && !zona?.riparo_pioggia && !sz?.riparo_pioggia
})
const pioggia = computed(() => tipo.value === 'irrigazione' && esterna.value && pioggiaInArrivo(store.meteo))

const testoPulsante = computed(() => {
  const n = scelte.value.size
  if (!n) return 'Spunta almeno una pianta'
  const chi = n === 1 ? '1 pianta' : `${n} piante`
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
/* Colonna che occupa tutto il foglio: il pulsante resta in fondo anche con
   poche piante (su computer il foglio è alto quanto la finestra). */
.fcz { display:flex; flex-direction:column; min-height:100%; box-sizing:border-box; }
.fcz__sotto { font:400 12.5px/1.45 var(--font-sans); color:var(--ink-mid); margin:-6px 0 6px; }

/* Concimazione / Calcio */
.fcz__tipi { display:flex; gap:6px; margin:10px 0 0; }
.fcz__tipo { flex:1; display:inline-flex; align-items:center; justify-content:center; gap:6px; min-height:44px; padding:0 14px;
  border-radius:12px; border:1px solid var(--cream-dark); background:var(--white); color:var(--ink-mid); cursor:pointer;
  font:600 13px/1 var(--font-sans);
  transition: background var(--motion-quick) var(--ease-standard), color var(--motion-quick) var(--ease-standard), border-color var(--motion-quick) var(--ease-standard); }
.fcz__tipo :deep(svg) { width:16px; height:16px; flex:none; }
.fcz__tipo--concimazione.fcz__tipo--attivo { background:var(--olive-bg); color:var(--olive-ink); border-color:var(--olive); }
.fcz__tipo--calcio.fcz__tipo--attivo { background:var(--uovo-bg); color:var(--uovo-ink); border-color:var(--uovo); }
.fcz__tipo:focus-visible { outline:none; box-shadow:0 0 0 3px var(--gold); }

/* Concime scelto, su una riga */
.fcz__concime-scelto { display:flex; align-items:center; gap:12px; padding:2px 2px 4px; }
.fcz__concime-scelto .care__ic { flex:none; }
.fcz__concime-n { flex:1; min-width:0; font:600 14px/1.3 var(--font-sans); color:var(--ink); }
.fcz__npk { flex:none; font:600 12.5px/1 var(--font-sans); color:var(--ink-mid); font-variant-numeric:tabular-nums; letter-spacing:.02em; }
.fcz__cambia { flex:none; min-height:44px; padding:0 4px 0 10px; background:none; border:none; cursor:pointer;
  font:600 13px/1 var(--font-sans); color:var(--sage-ink); text-decoration:underline; text-underline-offset:3px; text-decoration-thickness:1px; }
.fcz__cambia:focus-visible { outline:none; box-shadow:0 0 0 3px var(--gold); border-radius:8px; }

/* Elenco dei concimi, a filetti */
.fcz__concimi { list-style:none; margin:0; padding:0; }
.fcz__concimi li + li { border-top:1px solid var(--cream-dark); }
.fcz__concime { display:flex; align-items:center; gap:12px; width:100%; min-height:48px; padding:0 2px; text-align:left;
  background:none; border:none; cursor:pointer; color:var(--ink); }
.fcz__concime .fcz__concime-n { font-weight:500; }
.fcz__concime--terminato .fcz__concime-n { color:var(--ink-mid); }
.fcz__concime:focus-visible { outline:none; box-shadow:inset 0 0 0 3px var(--gold); border-radius:8px; }
.fcz__radio { flex:none; width:20px; height:20px; border-radius:999px; border:1.5px solid var(--ink-faint); background:var(--white);
  box-sizing:border-box; transition: border-color var(--motion-quick) var(--ease-standard), box-shadow var(--motion-quick) var(--ease-standard); }
.fcz__radio--on { border-color:var(--olive); box-shadow: inset 0 0 0 4px var(--white), inset 0 0 0 10px var(--olive); }
.fcz__tag { margin-left:8px; font:400 12px/1 var(--font-sans); color:var(--ink-soft); font-style:italic; }

/* Avvisi: uno per foglio, mai ripetuti riga per riga */
.fcz__avviso { display:flex; gap:10px; align-items:flex-start; margin:16px 0 0; padding:12px 14px; border-radius:14px;
  font:400 12.5px/1.5 var(--font-sans); }
.fcz__avviso :deep(svg) { width:16px; height:16px; flex:none; margin-top:1px; }
.fcz__avviso--acqua { background:var(--acqua-bg); color:var(--acqua-ink); }
.fcz__avviso--gold { background:var(--gold-bg); color:var(--gold-ink); }

/* Piante */
.fcz__lista { list-style:none; margin:0; padding:0; }
.fcz__lista li + li { border-top:1px solid var(--cream-dark); }
/* «Da fare» come le righe urgenti di «Per urgenza»: carta rosa, senza filetti. */
.fcz__lista--daFare { display:flex; flex-direction:column; gap:6px; }
.fcz__lista--daFare li + li { border-top:none; }
.fcz__lista--daFare .fcz__riga { padding:12px; background:var(--rose-pale); border-radius:12px; }
.fcz__riga { display:flex; align-items:flex-start; gap:12px; padding:12px 2px; cursor:pointer; }
.fcz__riga--esclusa { cursor:default; }
.fcz__riga--esclusa .fcz__nome { color:var(--ink-mid); }
.fcz__m { flex:1; min-width:0; display:flex; flex-direction:column; gap:3px; }
.fcz__nome { font:600 14px/1.3 var(--font-display); color:var(--ink); }
.fcz__var { font-weight:400; color:var(--ink-mid); margin-left:.3em; }
.fcz__motivo { font:400 12px/1.45 var(--font-sans); color:var(--ink-mid); }
.fcz__motivo--avviso { color:var(--gold-ink); }

/* Casella disegnata: carta e cuscino, spunta salvia. */
.fcz__check { appearance:none; -webkit-appearance:none; flex:none; width:22px; height:22px; margin:0; border-radius:6px;
  border:1.5px solid var(--ink-faint); background:var(--white) center / 14px 14px no-repeat; cursor:pointer;
  transition: background-color var(--motion-quick) var(--ease-standard), border-color var(--motion-quick) var(--ease-standard); }
.fcz__check:checked { background-color:var(--sage); border-color:var(--sage);
  background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Cpath d='M3.5 8.5l3 3 6-7' fill='none' stroke='white' stroke-width='2.2' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E"); }
.fcz__check:focus-visible { outline:none; box-shadow:0 0 0 3px var(--gold); }
/* Esclusa: nessuna casella da toccare, solo un trattino che dice «fuori». */
.fcz__fuori { flex:none; width:22px; height:22px; position:relative; }
.fcz__fuori::after { content:""; position:absolute; left:5px; right:5px; top:10px; height:2px; background:var(--ink-faint); }

/* Il pulsante resta in fondo al foglio, anche con molte piante. */
.fcz__piede { position:sticky; bottom:0; margin:auto -16px -22px; padding:14px 16px 16px;
  background:linear-gradient(to bottom, transparent, var(--white) 26%); }
.fcz__lista:last-of-type, .fcz__avviso:last-of-type { margin-bottom:8px; }
.fcz__registra { width:100%; min-height:48px; display:inline-flex; align-items:center; justify-content:center; font-size:14px; }
.fcz__registra:disabled { opacity:.55; cursor:default; box-shadow:none; }
.fcz__err { margin:0 0 8px; color:var(--rose-ink); font:400 12.5px/1.4 var(--font-sans); }
</style>
