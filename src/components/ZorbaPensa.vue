<template>
  <div class="zp" role="status">
    <span class="visually-hidden" aria-live="polite">{{ annuncio }}</span>
    <p class="zp__riga" aria-hidden="true">
      <Transition name="zp-frase" mode="out-in">
        <span :key="frase" class="zp__frase">{{ frase }}…</span>
      </Transition>
      <span v-if="secondi >= 4" class="zp__tempo">{{ secondi }} s</span>
    </p>
  </div>
</template>

<script setup>
import { ref, watch, onMounted, onBeforeUnmount } from 'vue'

// Attesa della risposta di Zorba, alla maniera di un terminale che «pensa»: una riga sola con il tempo trascorso.
// Quando la funzione segnala un passo reale (evento `stato`: «sbircio il meteo…») la riga lo mostra per qualche
// secondo; nel resto dell'attesa scorrono verbi di giardino. Mai due frasi insieme: il passo vero e la voce
// d'atmosfera si alternano nello stesso posto. Il movimento lo fa Zorba (coda e occhio, vedi ZorbaLogo `pensa`).
const props = defineProps({ stato: { type: String, default: null } })

const FRASI = [
  'Zappettando', 'Germogliando', 'Rinvasando', 'Pacciamando', 'Sarchiando', 'Rastrellando', 'Seminando',
  'Trapiantando', 'Innestando', 'Impollinando', 'Fotosintetizzando', 'Radicando', 'Sbocciando', 'Diradando',
  'Cimando', 'Vangando', 'Compostando', 'Stratificando', 'Interrando i bulbi', 'Contando le gemme',
  'Fiutando il terriccio', 'Sbirciando sotto le foglie', 'Ascoltando le api', 'Seguendo una lumaca',
  'Acciambellandosi al sole', 'Facendo le fusa al basilico', 'Affilando le cesoie', 'Leggendo le nuvole',
]
const GIRO = 2800        // ogni quanto cambia il verbo
const TENUTA_PASSO = 3600 // quanto resta in vista un passo reale prima che tornino i verbi

function mescola(prima) {
  const a = FRASI.filter(f => f !== prima)
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]]
  }
  return a
}
let coda = mescola()
const frase = ref(coda.shift())
const secondi = ref(0)
const annuncio = ref('Zorba sta preparando la risposta')
let tenutaFino = 0

// «sbircio il meteo…» → «Sbircio il meteo» (i puntini li aggiunge la riga)
const passo = (s) => { const t = s.replace(/[.…\s]+$/, ''); return t.charAt(0).toUpperCase() + t.slice(1) }
watch(() => props.stato, (s) => {
  if (!s) return
  frase.value = passo(s)
  annuncio.value = passo(s)
  tenutaFino = Date.now() + TENUTA_PASSO
}, { immediate: true })

let tFrase, tTempo
onMounted(() => {
  const inizio = Date.now()
  tTempo = setInterval(() => { secondi.value = Math.floor((Date.now() - inizio) / 1000) }, 1000)
  tFrase = setInterval(() => {
    if (Date.now() < tenutaFino) return
    if (!coda.length) coda = mescola(frase.value)
    frase.value = coda.shift()
  }, GIRO)
})
onBeforeUnmount(() => { clearInterval(tFrase); clearInterval(tTempo) })
</script>

<style scoped>
.zp { min-height: 21px; display: flex; align-items: center; }
.zp__riga { display: flex; align-items: baseline; gap: 8px; margin: 0; font: 500 13.5px/1.55 var(--font-sans); color: var(--sage-ink); }
.zp__frase { display: inline-block; }
.zp__tempo { font: 400 11px/1 var(--font-sans); color: var(--ink-soft); font-variant-numeric: tabular-nums; }

.zp-frase-enter-active, .zp-frase-leave-active { transition: opacity var(--motion-sheet) var(--ease-standard), transform var(--motion-sheet) var(--ease-standard); }
.zp-frase-enter-from { opacity: 0; transform: translateY(3px); }
.zp-frase-leave-to { opacity: 0; transform: translateY(-3px); }

.visually-hidden { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }

@media (prefers-reduced-motion: reduce) {
  .zp-frase-enter-active, .zp-frase-leave-active { transition: opacity var(--motion-quick) linear; }
  .zp-frase-enter-from, .zp-frase-leave-to { transform: none; }
}
</style>
