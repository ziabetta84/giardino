<template>
  <div class="zp" role="status">
    <span class="visually-hidden">Zorba sta preparando la risposta</span>
    <p class="zp__riga" aria-hidden="true">
      <svg class="zp__germoglio" viewBox="0 0 16 16">
        <path class="zp__fusto" d="M8 15 V7.5" pathLength="1" />
        <path class="zp__foglia zp__foglia--sx" d="M8 10.5 C5.2 10.6 3.6 8.9 3.4 6.4 C6 6.4 7.7 7.9 8 10.5 Z" />
        <path class="zp__foglia zp__foglia--dx" d="M8 8.6 C10.6 8.4 12.3 6.6 12.6 4 C10 4.1 8.3 5.8 8 8.6 Z" />
      </svg>
      <Transition name="zp-frase" mode="out-in">
        <span :key="frase" class="zp__frase">{{ frase }}…</span>
      </Transition>
      <span v-if="secondi >= 4" class="zp__tempo">{{ secondi }} s</span>
    </p>
    <Transition name="zp-frase" mode="out-in">
      <p v-if="stato" :key="stato" class="zp__passo" aria-live="polite">{{ maiuscola(stato) }}</p>
    </Transition>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'

// Attesa della risposta di Zorba, alla maniera di un terminale che «pensa»: un verbo di giardino che cambia ogni
// pochi secondi e il tempo trascorso. Sotto, il passo reale (dagli eventi `stato` della funzione), che resta vero:
// le frasi sono solo voce, il passo dice cosa sta succedendo davvero.
defineProps({ stato: { type: String, default: null } })

const FRASI = [
  'Zappettando', 'Germogliando', 'Rinvasando', 'Pacciamando', 'Sarchiando', 'Rastrellando', 'Seminando',
  'Trapiantando', 'Innestando', 'Impollinando', 'Fotosintetizzando', 'Radicando', 'Sbocciando', 'Diradando',
  'Cimando', 'Vangando', 'Compostando', 'Stratificando', 'Interrando i bulbi', 'Contando le gemme',
  'Fiutando il terriccio', 'Sbirciando sotto le foglie', 'Ascoltando le api', 'Seguendo una lumaca',
  'Acciambellandosi al sole', 'Facendo le fusa al basilico', 'Affilando le cesoie', 'Leggendo le nuvole',
]

// Ordine casuale senza ripetizioni finché non le ha dette tutte; il primo verbo non ripete l'ultimo del giro prima
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
const maiuscola = (s) => s.charAt(0).toUpperCase() + s.slice(1)

let tFrase, tTempo
onMounted(() => {
  const inizio = Date.now()
  tTempo = setInterval(() => { secondi.value = Math.floor((Date.now() - inizio) / 1000) }, 1000)
  tFrase = setInterval(() => {
    if (!coda.length) coda = mescola(frase.value)
    frase.value = coda.shift()
  }, 2800)
})
onBeforeUnmount(() => { clearInterval(tFrase); clearInterval(tTempo) })
</script>

<style scoped>
.zp { display: flex; flex-direction: column; gap: 3px; min-height: 22px; }
.zp__riga { display: flex; align-items: center; gap: 7px; margin: 0; font: 500 13.5px/1.5 var(--font-sans); color: var(--sage-ink); }
.zp__frase { display: inline-block; }
.zp__tempo { font: 400 11px/1 var(--font-sans); color: var(--ink-soft); font-variant-numeric: tabular-nums; }

/* Il germoglio: il fusto si disegna, le due foglie si aprono una dopo l'altra, poi tutto sfuma e ricomincia */
.zp__germoglio { width: 18px; height: 18px; flex: none; overflow: visible; }
.zp__fusto { fill: none; stroke: var(--sage-dark); stroke-width: 1.6; stroke-linecap: round; stroke-dasharray: 1; stroke-dashoffset: 1;
  animation: zp-fusto 2.8s ease-in-out infinite; }
.zp__foglia { fill: var(--sage); transform-box: fill-box; transform: scale(0); animation: zp-foglia 2.8s ease-in-out infinite; }
.zp__foglia--sx { transform-origin: 100% 100%; animation-delay: .18s; }
.zp__foglia--dx { transform-origin: 0% 100%; animation-delay: .42s; fill: var(--olive); }
@keyframes zp-fusto {
  0% { stroke-dashoffset: 1; opacity: 1; }
  30%, 80% { stroke-dashoffset: 0; opacity: 1; }
  100% { stroke-dashoffset: 0; opacity: 0; }
}
@keyframes zp-foglia {
  0%, 22% { transform: scale(0); opacity: 1; }
  48%, 80% { transform: scale(1); opacity: 1; }
  100% { transform: scale(1); opacity: 0; }
}

.zp__passo { margin: 0 0 0 25px; font: italic 400 12px/1.45 var(--font-sans); color: var(--ink-soft); }

.zp-frase-enter-active, .zp-frase-leave-active { transition: opacity var(--motion-sheet) var(--ease-standard), transform var(--motion-sheet) var(--ease-standard); }
.zp-frase-enter-from { opacity: 0; transform: translateY(3px); }
.zp-frase-leave-to { opacity: 0; transform: translateY(-3px); }

.visually-hidden { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }

@media (prefers-reduced-motion: reduce) {
  .zp__fusto { animation: none; stroke-dashoffset: 0; }
  .zp__foglia { animation: none; transform: scale(1); }
  .zp-frase-enter-active, .zp-frase-leave-active { transition: opacity var(--motion-quick) linear; }
  .zp-frase-enter-from, .zp-frase-leave-to { transform: none; }
}
</style>
