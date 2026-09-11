<template>
  <div class="zc-scene" :class="{ play: animare }" :data-light="luceVisibile">
    <img
      ref="imgEl"
      :src="immagineCorrente"
      class="zc-painting"
      :class="{ 'zc-painting--errore': erroreImg }"
      width="1536"
      height="1024"
      decoding="async"
      fetchpriority="high"
      alt=""
      aria-hidden="true"
      @load="onImgCaricata"
      @error="onImgErrore"
    />

    <!-- Sole/luna sono dipinti dentro ogni scena (vedi src/assets/hero/): qui
         restano solo gli elementi che devono muoversi, sovrapposti al dipinto
         e indipendenti dal suo crop — nuvole di giorno, stelle di notte. -->
    <svg class="zc-sky" viewBox="0 0 400 250" preserveAspectRatio="xMidYMax slice" aria-hidden="true">
      <defs>
        <filter id="zcCloudBlur" x="-60%" y="-60%" width="220%" height="220%">
          <feGaussianBlur stdDeviation="1.6"/>
        </filter>
      </defs>
      <!-- Nuvole: foschia sfumata (niente contorno a china, sarebbe
           ridondante sopra un dipinto già così deciso), tenute in una
           fascia alta e stretta del cielo per non passare mai sopra
           testo o pillole. -->
      <g class="zc-clouds">
        <g class="zc-cloud zc-cloud--a">
          <circle cx="0" cy="0" r="7"/>
          <circle cx="6" cy="1" r="5"/>
          <circle cx="-6" cy="1.5" r="4.5"/>
        </g>
        <g class="zc-cloud zc-cloud--b">
          <circle cx="0" cy="0" r="5"/>
          <circle cx="5" cy="1" r="3.6"/>
          <circle cx="-4.5" cy="1" r="3.3"/>
        </g>
      </g>
      <g class="zc-stars">
        <circle class="zc-twinkle" cx="70" cy="30" r="1.6" style="animation-duration:2.4s"/>
        <circle class="zc-twinkle" cx="120" cy="55" r="1.3" style="animation-duration:3.1s"/>
        <circle class="zc-twinkle" cx="270" cy="24" r="1.5" style="animation-duration:2.8s"/>
        <circle class="zc-twinkle" cx="230" cy="70" r="1.2" style="animation-duration:3.6s"/>
        <circle class="zc-twinkle" cx="40" cy="90" r="1.4" style="animation-duration:2.2s"/>
        <circle class="zc-twinkle" cx="180" cy="18" r="1.3" style="animation-duration:2.9s"/>
      </g>
    </svg>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import primaveraGiorno from '@/assets/hero/primavera-giorno.webp'
import primaveraNotte from '@/assets/hero/primavera-notte.webp'
import estateGiorno from '@/assets/hero/estate-giorno.webp'
import estateNotte from '@/assets/hero/estate-notte.webp'
import autunnoGiorno from '@/assets/hero/autunno-giorno.webp'
import autunnoNotte from '@/assets/hero/autunno-notte.webp'
import invernoGiorno from '@/assets/hero/inverno-giorno.webp'
import invernoNotte from '@/assets/hero/inverno-notte.webp'

// stagione: 'primavera' | 'estate' | 'autunno' | 'inverno'
// luce: 'giorno' | 'notte'
const props = defineProps({
  stagione: { type: String, required: true },
  luce: { type: String, required: true },
})
// Emesso quando stagione/luce cambiano davvero (non al mount): HomeView lo
// usa per far "notare" il cambiamento a Zorba (un battito di ciglia più
// lento), invece di aggiungere un'animazione decorativa qui.
const emit = defineEmits(['cambio-scena'])

// Un dipinto ad acquerello/china per ogni combinazione stagione × luce
// (generati una tantum, vedi src/assets/hero/): a differenza della vecchia
// scena SVG, qui giorno e notte sono due dipinti distinti (sole/luna dipinti
// dentro ciascuno), non lo stesso disegno con un velo di colore — il velo
// provato in fase di bozza appiattiva troppo i fiori e lasciava intravedere
// il sole anche di notte.
const immagini = {
  primavera: { giorno: primaveraGiorno, notte: primaveraNotte },
  estate: { giorno: estateGiorno, notte: estateNotte },
  autunno: { giorno: autunnoGiorno, notte: autunnoNotte },
  inverno: { giorno: invernoGiorno, notte: invernoNotte },
}

const animare = ref(false)
const erroreImg = ref(false)
const imgEl = ref(null)

// La dissolvenza d'ingresso parte quando il dipinto è davvero decodificato
// (evento load, o già .complete se arrivava dalla cache del browser), non a
// un timer fisso indipendente dal caricamento: su una rete lenta un timer
// fisso mostrerebbe uno scatto secco invece della dissolvenza prevista.
function onImgCaricata() {
  animare.value = true
}
// Un dipinto mancante non deve lasciare la scena bloccata invisibile in
// attesa di un evento load che non arriverà mai: si passa comunque allo
// stato "play" (mostra il fondo chiaro sotto) e si segnala l'errore per lo
// stile, senza inventare un fallback visivo più elaborato per un caso raro.
function onImgErrore() {
  erroreImg.value = true
  animare.value = true
}

// Copia interna effettivamente mostrata a schermo: il template non legge mai
// le prop direttamente, per lasciare aprire una View Transition prima che il
// DOM cambi davvero.
const stagioneVisibile = ref(props.stagione)
const luceVisibile = ref(props.luce)

const immagineCorrente = computed(() => immagini[stagioneVisibile.value][luceVisibile.value])

function ridottoMovimento() {
  return window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false
}

let transizioneCorrente = null

watch(() => [props.stagione, props.luce], async ([nuovaStagione, nuovaLuce]) => {
  const cambiata = nuovaStagione !== stagioneVisibile.value || nuovaLuce !== luceVisibile.value
  if (!cambiata) return

  emit('cambio-scena')

  const applica = async () => {
    stagioneVisibile.value = nuovaStagione
    luceVisibile.value = nuovaLuce
    await nextTick()
  }

  // "Riduci movimento": scatto secco e definitivo, senza dissolvenza.
  if (ridottoMovimento() || !document.startViewTransition) {
    await applica()
    return
  }

  transizioneCorrente?.skipTransition()
  transizioneCorrente = document.startViewTransition(applica)
  try {
    await transizioneCorrente.ready
  } catch {
    // transizione saltata da un cambio successivo troppo ravvicinato: nessun problema
  }
})

onMounted(() => {
  // L'immagine può arrivare già dalla cache del browser (visita successiva):
  // in quel caso l'evento load non scatta più una volta montato l'handler,
  // quindi va controllato .complete esplicitamente.
  if (imgEl.value?.complete) animare.value = true
})
onUnmounted(() => {
  transizioneCorrente?.skipTransition()
})
</script>

<style scoped>
.zc-scene {
  position: relative;
  display: block;
  width: 100%;
  height: 100%;
  overflow: hidden;
  view-transition-name: giardino-scena;
  --scn-ink: var(--ink-mid);
}
.zc-scene[data-light="notte"] { --scn-ink: #e9dfca; }

.zc-painting {
  position: absolute; inset: 0; width: 100%; height: 100%;
  object-fit: cover; object-position: center bottom;
  opacity: 0; transform: scale(1.045); filter: blur(7px);
  transition: opacity .9s cubic-bezier(.22,1,.36,1),
              transform .9s cubic-bezier(.22,1,.36,1),
              filter .9s cubic-bezier(.22,1,.36,1);
}
.zc-scene.play .zc-painting { opacity: 1; transform: scale(1); filter: blur(0); }
/* Un dipinto mancante non deve lasciare l'icona "immagine rotta" del
   browser al centro dell'hero: resta solo il fondo tenue di .hero
   (background:var(--sage-bg)) sotto testo/Zorba, coerente con lo stato di
   caricamento invece di un'icona tecnica fuori contesto. */
.zc-painting--errore { opacity: 0 !important; }

.zc-sky { position: absolute; inset: 0; width: 100%; height: 100%; pointer-events: none; }

.zc-clouds, .zc-stars {
  opacity: 0;
  transition: opacity var(--motion-sheet, .26s) var(--ease-standard, ease);
}
.zc-scene[data-light="giorno"] .zc-clouds { opacity: 1; }
.zc-scene[data-light="notte"] .zc-stars { opacity: 1; }

/* Nuvole: foschia bianca sfumata (blur, niente contorno), tenuta in una
   fascia stretta vicino al bordo superiore — sopra il livello di testo e
   pillole, così non passa mai davanti a nulla di leggibile. Scivolano molto
   lentamente da sinistra a destra in loop, senza mai accelerare o rimbalzare
   (curva lineare, propria di un moto atmosferico, non della decelerazione
   standard dei controlli). */
.zc-cloud {
  fill: color-mix(in srgb, white 85%, var(--scn-ink));
  filter: url(#zcCloudBlur);
  opacity: .85;
}
.zc-cloud--a { transform: translate(60px, 24px); animation: zc-drift-a 85s linear infinite; }
.zc-cloud--b { transform: translate(230px, 30px); animation: zc-drift-b 110s linear infinite; animation-delay: -30s; }
@keyframes zc-drift-a { from { translate: -80px 0; } to { translate: 440px 0; } }
@keyframes zc-drift-b { from { translate: -80px 0; } to { translate: 400px 0; } }

.zc-twinkle { fill: var(--scn-ink); animation: zc-twinkle ease-in-out infinite alternate; }
@keyframes zc-twinkle { 0%{opacity:.25;} 100%{opacity:.95;} }

@media (prefers-reduced-motion: reduce) {
  .zc-painting { transition: none; opacity: 1; transform: none; filter: none; }
  .zc-cloud, .zc-twinkle { animation: none !important; }
  .zc-clouds, .zc-stars { transition: none; }
}
</style>
