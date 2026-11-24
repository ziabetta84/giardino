<template>
  <div class="fsp foglio-form">
    <p class="fsp__sotto">{{ introduzione }}</p>

    <div class="slabel">Zona</div>
    <ul class="fsp__lista" role="radiogroup" aria-label="Zona di arrivo">
      <li v-for="z in zone" :key="z.nome">
        <button type="button" role="radio" :aria-checked="zona === z.nome" class="fsp__voce" @click="scegliZona(z.nome)">
          <span class="fsp__radio" :class="{ 'fsp__radio--on': zona === z.nome }" aria-hidden="true"></span>
          <Icon :name="store.iconaZona(z.nome)" class="fsp__ico" />
          <span class="fsp__n">{{ z.nome }}</span>
          <span class="fsp__tipo">{{ z.esterna ? 'all\'aperto' : 'al chiuso' }}</span>
        </button>
      </li>
    </ul>

    <template v-if="zona && sottozone.length">
      <div class="slabel">Sottozona</div>
      <ul class="fsp__lista" role="radiogroup" aria-label="Sottozona di arrivo">
        <li>
          <button type="button" role="radio" :aria-checked="sottozona === null" class="fsp__voce" @click="sottozona = null">
            <span class="fsp__radio" :class="{ 'fsp__radio--on': sottozona === null }" aria-hidden="true"></span>
            <span class="fsp__n">Nessuna sottozona</span>
          </button>
        </li>
        <li v-for="s in sottozone" :key="s.nome">
          <button type="button" role="radio" :aria-checked="sottozona === s.nome" class="fsp__voce" @click="sottozona = s.nome">
            <span class="fsp__radio" :class="{ 'fsp__radio--on': sottozona === s.nome }" aria-hidden="true"></span>
            <Icon :name="store.iconaSottozona(zona, s.nome)" class="fsp__ico" />
            <span class="fsp__n">{{ s.nome }}</span>
            <span class="fsp__tipo">{{ s.esterna ? 'all\'aperto' : 'al chiuso' }}</span>
          </button>
        </li>
      </ul>
    </template>

    <template v-if="zona">
      <p v-if="giaLi === ids.length" class="fsp__avviso fsp__avviso--neutro" role="note"><Icon name="pin" />{{ ids.length === 1 ? 'La pianta è già qui.' : 'Le piante sono già tutte qui.' }}</p>
      <p v-else-if="giaLi" class="fsp__avviso fsp__avviso--neutro" role="note"><Icon name="pin" />{{ piante(giaLi) }} {{ giaLi === 1 ? 'è' : 'sono' }} già qui e {{ giaLi === 1 ? 'resta' : 'restano' }} dov'{{ giaLi === 1 ? 'è' : 'sono' }}.</p>
      <p v-if="alChiuso.length" class="fsp__avviso fsp__avviso--acqua" role="note"><Icon name="casa" />{{ piante(alChiuso.length) }} {{ alChiuso.length === 1 ? 'passa' : 'passano' }} al chiuso: la pioggia non conterà più come irrigazione.</p>
      <p v-if="allAperto.length" class="fsp__avviso fsp__avviso--acqua" role="note"><Icon name="pioggia" />{{ piante(allAperto.length) }} {{ allAperto.length === 1 ? 'passa' : 'passano' }} all'aperto: conterà come irrigazione la pioggia che cadrà da domani, non quella dei giorni scorsi. Dopo un periodo al chiuso le foglie si scottano facilmente: {{ allAperto.length === 1 ? 'abituala' : 'abituale' }} al sole pieno per gradi.</p>
      <p v-if="cambioProgramma" class="fsp__avviso fsp__avviso--gold" role="note"><Icon name="orologio" />{{ cambioProgramma }}</p>
      <label v-if="inTerra.length" class="fsp__vaso">
        <input type="checkbox" class="fsp__check" v-model="segnaInVaso">
        <span>{{ inTerra.length === 1 ? 'Una pianta risulta coltivata' : `${inTerra.length} piante risultano coltivate` }} in piena terra. Segnala come {{ inTerra.length === 1 ? 'coltivata' : 'coltivate' }} in vaso.</span>
      </label>
    </template>

    <div class="fsp__piede">
      <p v-if="errore" class="fsp__err" role="alert">{{ errore }}</p>
      <button type="button" class="btn btn-sage fsp__sposta" :disabled="!daSpostare.length || salvando" @click="sposta">
        {{ salvando ? 'Sposto…' : etichettaPulsante }}
      </button>
    </div>
  </div>
</template>

<script setup>
// Foglio «Sposta» della pagina Piante: sceglie zona e sottozona di arrivo per
// le piante selezionate e, prima di confermare, dice che cosa cambia nei
// promemoria. All'aperto o al chiuso si legge come store.piantaEsterna (tipo
// della sottozona se c'è, altrimenti della zona); la data di spostamento la
// scrive il database (trigger piante_data_spostamento).
import { ref, computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { usePianteApi } from '@/composables/usePianteApi'
import { programmaIrrigazioneEffettivo } from '@/composables/useIrrigazioneAuto'
import Icon from '@/components/Icon.vue'

const props = defineProps({
  ids: { type: Array, required: true },
})
const emit = defineEmits(['spostate'])

const store = useDatiStore()
const pianteApi = usePianteApi()

const zona = ref(null)
const sottozona = ref(null)
const segnaInVaso = ref(true)
const salvando = ref(false)
const errore = ref(null)

const piante = (n) => n === 1 ? 'Una pianta' : `${n} piante`

const introduzione = computed(() => props.ids.length === 1
  ? 'Scegli dove hai messo la pianta selezionata.'
  : `Scegli dove hai messo le ${props.ids.length} piante selezionate.`)

const zone = computed(() => Object.values(store.zone ?? {})
  .map(z => ({ nome: z.nome, esterna: z.tipo === 'esterno' })))

const sottozone = computed(() => Object.values(store.sottozone?.[zona.value] ?? {})
  .map(s => ({ nome: s.nome, esterna: (s.tipo ?? store.zone?.[zona.value]?.tipo) === 'esterno' }))
  .sort((a, b) => a.nome.localeCompare(b.nome)))

function scegliZona(nome) {
  if (zona.value !== nome) sottozona.value = null
  zona.value = nome
}

const arrivo = computed(() => zona.value ? { zona: zona.value, sottozona: sottozona.value } : null)
const arrivoEsterno = computed(() => !!arrivo.value && store.piantaEsterna(arrivo.value))

const selezionate = computed(() => props.ids
  .map(id => ({ id, ...(store.piante?.[id] ?? {}) }))
  .filter(p => p.zona))

const daSpostare = computed(() => !arrivo.value ? [] : selezionate.value.filter(p =>
  p.zona !== arrivo.value.zona || (p.sottozona ?? null) !== arrivo.value.sottozona))
const giaLi = computed(() => arrivo.value ? props.ids.length - daSpostare.value.length : 0)

// La pioggia non conta per le piante in acqua, al chiuso o all'aperto che siano.
const sensibiliPioggia = computed(() => daSpostare.value.filter(p => p.coltivato_in !== 'acqua'))
const alChiuso = computed(() => arrivoEsterno.value ? [] : sensibiliPioggia.value.filter(p => store.piantaEsterna(p)))
const allAperto = computed(() => !arrivoEsterno.value ? [] : sensibiliPioggia.value.filter(p => !store.piantaEsterna(p)))
const inTerra = computed(() => arrivoEsterno.value ? [] : daSpostare.value.filter(p => p.coltivato_in === 'terra'))

// Irrigazione automatica: confronta il programma che vale per ogni pianta prima
// e dopo lo spostamento (un programma della pianta stessa non cambia).
const cambioProgramma = computed(() => {
  if (!arrivo.value) return null
  const prog = store.programmiIrrigazione
  const cambiate = []
  for (const p of daSpostare.value) {
    if (p.coltivato_in === 'acqua') continue
    const prima = programmaIrrigazioneEffettivo(p.id, p.zona, p.sottozona, prog)
    const dopo = programmaIrrigazioneEffettivo(p.id, arrivo.value.zona, arrivo.value.sottozona, prog)
    if ((prima?.ogniGiorni ?? null) !== (dopo?.ogniGiorni ?? null)) cambiate.push(dopo)
  }
  if (!cambiate.length) return null
  const n = cambiate.length
  const dopo = cambiate[0]
  if (!dopo) return `${piante(n)} ${n === 1 ? 'esce' : 'escono'} dall'irrigazione automatica: i promemoria torneranno a seguire la scheda.`
  const di = dopo.livello === 'sottozona' ? `della sottozona ${arrivo.value.sottozona}`
    : dopo.livello === 'zona' ? `della zona ${arrivo.value.zona}` : 'del giardino'
  return `${piante(n)} ${n === 1 ? 'seguirà' : 'seguiranno'} il programma d'irrigazione automatica ${di}, ogni ${dopo.ogniGiorni} ${dopo.ogniGiorni === 1 ? 'giorno' : 'giorni'}.`
})

const etichettaPulsante = computed(() => {
  const n = daSpostare.value.length
  if (!arrivo.value) return 'Scegli la zona'
  if (!n) return 'Nessuna pianta da spostare'
  return n === 1 ? 'Sposta la pianta' : `Sposta ${n} piante`
})

async function sposta() {
  if (!daSpostare.value.length || salvando.value) return
  salvando.value = true
  errore.value = null
  try {
    const inVaso = segnaInVaso.value ? inTerra.value.map(p => p.id) : []
    const precedenti = await pianteApi.spostaPiante(daSpostare.value.map(p => p.id), arrivo.value.zona, arrivo.value.sottozona, { inVaso })
    emit('spostate', precedenti)
  } catch {
    errore.value = 'Non sono riuscito a spostare le piante. Riprova.'
  } finally {
    salvando.value = false
  }
}
</script>

<style scoped>
.fsp { display:flex; flex-direction:column; min-height:100%; box-sizing:border-box; }
.fsp__sotto { font:400 12.5px/1.45 var(--font-sans); color:var(--ink-mid); margin:-6px 0 6px; }

/* Zone e sottozone: elenco a filetti con radio, come i concimi della cura per zona */
.fsp__lista { list-style:none; margin:0 0 4px; padding:0; }
.fsp__lista li + li { border-top:1px solid var(--cream-dark); }
.fsp__voce { display:flex; align-items:center; gap:12px; width:100%; min-height:48px; padding:0 2px; text-align:left;
  background:none; border:none; cursor:pointer; color:var(--ink); }
.fsp__voce:focus-visible { outline:none; box-shadow:inset 0 0 0 3px var(--gold); border-radius:8px; }
.fsp__radio { flex:none; width:20px; height:20px; border-radius:999px; border:1.5px solid var(--ink-faint); background:var(--white);
  box-sizing:border-box; transition: border-color var(--motion-quick) var(--ease-standard), box-shadow var(--motion-quick) var(--ease-standard); }
.fsp__radio--on { border-color:var(--sage); box-shadow: inset 0 0 0 4px var(--white), inset 0 0 0 10px var(--sage); }
.fsp__ico { flex:none; width:16px; height:16px; color:var(--ink-mid); }
.fsp__n { flex:1; min-width:0; font:500 14px/1.3 var(--font-sans); overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.fsp__tipo { flex:none; font:400 12px/1 var(--font-sans); color:var(--ink-soft); }

/* Che cosa cambia: un avviso per argomento */
.fsp__avviso { display:flex; gap:10px; align-items:flex-start; margin:12px 0 0; padding:12px 14px; border-radius:14px;
  font:400 12.5px/1.5 var(--font-sans); }
.fsp__avviso :deep(svg) { width:16px; height:16px; flex:none; margin-top:1px; }
.fsp__avviso--acqua { background:var(--acqua-bg); color:var(--acqua-ink); }
.fsp__avviso--gold { background:var(--gold-bg); color:var(--gold-ink); }
.fsp__avviso--neutro { background:var(--cream); color:var(--ink-mid); }

.fsp__vaso { display:flex; gap:12px; align-items:flex-start; margin:14px 0 0; padding:2px; cursor:pointer;
  font:400 13px/1.45 var(--font-sans); color:var(--ink); }
.fsp__check { appearance:none; -webkit-appearance:none; flex:none; width:22px; height:22px; margin:0; border-radius:6px;
  border:1.5px solid var(--ink-faint); background:var(--white) center / 14px 14px no-repeat; cursor:pointer;
  transition: background-color var(--motion-quick) var(--ease-standard), border-color var(--motion-quick) var(--ease-standard); }
.fsp__check:checked { background-color:var(--sage); border-color:var(--sage);
  background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Cpath d='M3.5 8.5l3 3 6-7' fill='none' stroke='white' stroke-width='2.2' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E"); }
.fsp__check:focus-visible { outline:none; box-shadow:0 0 0 3px var(--gold); }

.fsp__piede { position:sticky; bottom:0; margin:auto -16px -22px; padding:14px 16px 16px;
  background:linear-gradient(to bottom, transparent, var(--white) 26%); }
.fsp__sposta { width:100%; min-height:48px; display:inline-flex; align-items:center; justify-content:center; font-size:14px; margin-top:12px; }
.fsp__sposta:disabled { opacity:.55; cursor:default; box-shadow:none; }
.fsp__err { margin:0 0 8px; color:var(--rose-ink); font:400 12.5px/1.4 var(--font-sans); }
</style>
