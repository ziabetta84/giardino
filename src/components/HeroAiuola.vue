<template>
  <div ref="contenitoreEl" class="zc-scene" :class="{ play: animare, 'ingresso-lento': usaIngressoLento, 'zoom-in': cameraAttiva, 'con-foglie': foglieAttive }" :style="stileFuoco" :data-light="luceVisibile">
    <img
      ref="imgEl"
      :src="immagineCorrente"
      class="zc-painting"
      :class="{ 'zc-painting--errore': erroreImg }"
      :width="dimensioniCorrenti[0]"
      :height="dimensioniCorrenti[1]"
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

    <!-- Bagliore caldo dal cancello: si accende insieme al cerchio che
         rivela il colore (stessa soglia di .play), non un elemento permanente
         della scena. mix-blend-mode:screen invece di un'opacità piatta —
         schiarisce quello che c'è sotto come luce vera, non vela il dipinto
         con un velo uniforme. -->
    <div v-if="usaIngressoLento" class="zc-bloom" aria-hidden="true"></div>

    <!-- "Vento d'autunno": foglie in diagonale e, ogni tanto, una che si posa
         sulla testa di Zorba (vedi composables/useFoglie.js). Sostituisce le
         nuvole vettoriali nella scena autunno/giorno. -->
    <canvas v-if="foglieAttive" ref="foglieEl" class="zc-foglie" aria-hidden="true"></canvas>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { useFoglie } from '@/composables/useFoglie'
import placeholderTela from '@/assets/hero/splash-autunno-giorno.webp'
// stagione: 'primavera' | 'estate' | 'autunno' | 'inverno'
// luce: 'giorno' | 'notte'
const props = defineProps({
  stagione: { type: String, required: true },
  luce: { type: String, required: true },
  // Ingresso "il cancello si apre" (cerchio di colore dal cancello, vedi
  // CSS .ingresso-lento): solo lo splash a schermo intero lo usa, una volta per fascia del giorno — la striscia
  // hero della Home, rimontata a ogni apertura, resta sulla dissolvenza
  // rapida per non appesantire l'uso quotidiano (deciso in brainstorming
  // 19/09/2026, non un'omissione).
  ingressoLento: { type: Boolean, default: false },
  // Dove si posa la foglia speciale del vento d'autunno: la posizione di
  // Zorba nel contenitore che ospita questo componente, in px dal bordo
  // destro/basso del riquadro; `dim` è il lato di Zorba (numero, o funzione
  // dell'altezza del riquadro quando scala con la striscia). Senza questa
  // prop le foglie cadono comunque, ma nessuna si posa.
  zorba: { type: Object, default: null },
})
// Emesso quando stagione/luce cambiano davvero (non al mount): HomeView lo
// usa per far "notare" il cambiamento a Zorba (un battito di ciglia più
// lento), invece di aggiungere un'animazione decorativa qui.
const emit = defineEmits(['cambio-scena', 'foglia-su-zorba'])

// Una tela per ogni combinazione stagione × luce. PLACEHOLDER: per ora tutte
// e 8 puntano alla tela verticale 896×1216 di autunno/giorno (cancello rosso,
// sentiero chiaro, da cui `SplashAiuola.vue` parte a schermo intero); man
// mano che arrivano le tele vere basta sostituire la riga della combinazione
// con la sua immagine e i suoi valori. Per ogni tela:
// - src, dim: file e risoluzione nativa (serve a fuocoYRenderizzato per
//   ritrovare il cancello dopo object-fit:cover);
// - fuoco: il cancello, fulcro compositivo (la soglia del giardino) da cui
//   partono il cerchio di colore, il bloom e la spinta di camera dello
//   splash, in % dell'immagine (x anche del ritaglio, vedi sotto);
// - striscia: posizione verticale (%, object-position-y) del ritaglio 4.5:1
//   mostrato nella Home. Una tela verticale non entra intera in una striscia
//   larga: qui si mostra la fascia del cancello e del sentiero, a ~39% (cioè
//   circa dal pixel 400 al 600 su 1216).
const telaPlaceholder = { src: placeholderTela, dim: [896, 1216], fuoco: { x: 53.5, y: 40 }, striscia: 39 }
const tele = {
  primavera: { giorno: telaPlaceholder, notte: telaPlaceholder },
  estate: { giorno: telaPlaceholder, notte: telaPlaceholder },
  autunno: { giorno: telaPlaceholder, notte: telaPlaceholder },
  inverno: { giorno: telaPlaceholder, notte: telaPlaceholder },
}
const puntoFuoco = computed(() => tela.value.fuoco)

// Le coordinate sopra sono state calibrate a occhio su schermate desktop
// (rapporto vicino a quello nativo della tela, ~1.5): su un riquadro con un
// rapporto molto diverso — un telefono in verticale, o la striscia
// larghissima della Home — la stessa % non cade più nello stesso punto
// dello schermo, perché object-fit:cover ritaglia in modo diverso a seconda
// del rapporto. Bug reale trovato in critica del 20/09/2026: su un iPhone
// verticale (390×844) il cancello di autunno/giorno finiva del tutto fuori
// dal ritaglio visibile.
//
// Asse X: risolto senza calcoli — impostando object-position-x sullo stesso
// --fx già calibrato (vedi CSS .zc-painting), il punto a frazione fx
// dell'immagine finisce SEMPRE alla stessa frazione fx del riquadro
// renderizzato, qualunque sia il ritaglio. È una proprietà della formula di
// object-position, non un'approssimazione: verificato algebricamente prima
// di scriverlo (xPx = cw·fx per costruzione, si semplifica il termine di
// scala). Impossibile per l'asse Y allo stesso modo, perché lì l'ancoraggio
// resta fisso su "bottom" (non su fy) per continuare a mostrare la base
// della scena: va ricalcolato davvero in base al riquadro renderizzato.
const contenitoreEl = ref(null)
const contenitoreW = ref(1536)
const contenitoreH = ref(1024)
let smettiOsservazione = null

function fuocoYRenderizzato(fyPercent, iw, ih, cw, ch) {
  if (!cw || !ch || !iw || !ih) return fyPercent
  const scale = Math.max(cw / iw, ch / ih)
  const alturaScalata = ih * scale
  const offsetY = ch - alturaScalata // object-position-y fissa a "bottom" (100%)
  const yPx = offsetY + (fyPercent / 100) * alturaScalata
  return (yPx / ch) * 100
}

const stileFuoco = computed(() => {
  const [iw, ih] = dimensioniCorrenti.value
  const fy = fuocoYRenderizzato(puntoFuoco.value.y, iw, ih, contenitoreW.value, contenitoreH.value)
  return {
    '--fx': puntoFuoco.value.x + '%',
    '--fy': fy + '%',
    '--oy': props.ingressoLento ? '100%' : tela.value.striscia + '%',
  }
})

const animare = ref(false)
const erroreImg = ref(false)
const imgEl = ref(null)
// Resta true per tutta la sequenza d'ingresso: la spinta di camera (da 1.08
// a 1) parte con l'immagine e non deve tornare indietro a metà.
const cameraAttiva = ref(false)

// Dipende solo dall'intento del chiamante e dalla preferenza di movimento.
const usaIngressoLento = computed(() => props.ingressoLento && !ridottoMovimento())

// La rivelazione parte quando il dipinto è davvero decodificato (evento
// load, o già .complete se arrivava dalla cache del browser), non a un timer
// fisso indipendente dal caricamento: su una rete lenta un timer fisso
// mostrerebbe uno scatto secco invece della dissolvenza prevista.
function onImgCaricata() {
  animare.value = true
  cameraAttiva.value = true
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

// Tela attiva (src, dimensioni native, punto di fuoco, ritaglio striscia)
// per la scena visibile: vedi `tele` sopra.
const tela = computed(() => tele[stagioneVisibile.value][luceVisibile.value])
const dimensioniCorrenti = computed(() => tela.value.dim)
const immagineCorrente = computed(() => tela.value.src)

function ridottoMovimento() {
  return window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false
}

// Vento d'autunno (solo autunno/giorno, e mai con "riduci movimento"): al
// posto delle nuvole, vedi composables/useFoglie.js. Parte quando il dipinto
// è già visibile (animare), così le foglie non cadono su una scena vuota.
const foglieEl = ref(null)
const foglieAttive = computed(() =>
  stagioneVisibile.value === 'autunno' && luceVisibile.value === 'giorno' && !ridottoMovimento())
useFoglie({
  canvasEl: foglieEl,
  attivo: computed(() => foglieAttive.value && animare.value),
  dim: () => ({ w: contenitoreW.value, h: contenitoreH.value }),
  // Testa di Zorba: nel suo riquadro quadrato, a circa 27% dal bordo destro e
  // 88% dal basso (misurato sull'SVG di ZorbaLogo).
  testa: () => {
    const z = props.zorba
    if (!z) return null
    const lato = typeof z.dim === 'function' ? z.dim(contenitoreH.value) : z.dim
    return { x: contenitoreW.value - z.destra - 0.27 * lato, y: contenitoreH.value - z.basso - 0.88 * lato }
  },
  onAtterra: () => emit('foglia-su-zorba'),
})

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
  if (imgEl.value?.complete) onImgCaricata()

  // Misura reale del riquadro per fuocoYRenderizzato sopra: la striscia
  // della Home e lo splash a schermo intero hanno rapporti larghezza/altezza
  // molto diversi, e possono cambiare (resize finestra, rotazione telefono,
  // .app-main che passa a due colonne da 640px) mentre il componente resta
  // montato — un ResizeObserver invece di leggere le dimensioni una sola
  // volta al mount.
  if (contenitoreEl.value && window.ResizeObserver) {
    const osservatore = new ResizeObserver((voci) => {
      const box = voci[0]?.contentBoxSize?.[0]
      if (box) {
        contenitoreW.value = box.inlineSize
        contenitoreH.value = box.blockSize
      } else {
        // Safari meno recenti: niente contentBoxSize, si torna a contentRect.
        const rect = voci[0]?.contentRect
        if (rect) { contenitoreW.value = rect.width; contenitoreH.value = rect.height }
      }
    })
    osservatore.observe(contenitoreEl.value)
    smettiOsservazione = () => osservatore.disconnect()
  }
})
onUnmounted(() => {
  transizioneCorrente?.skipTransition()
  smettiOsservazione?.()
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
  object-fit: cover;
  /* var(--fx), non "center": ritaglia sempre centrato sul cancello invece
     che sul centro geometrico della tela — su un riquadro molto più stretto
     (telefono in verticale) "center" tagliava il cancello fuori dallo
     schermo del tutto (bug reale, critica del 20/09/2026). Con
     object-position-x = --fx il punto a quella frazione dell'immagine
     finisce sempre alla stessa frazione del riquadro, qualunque il
     ritaglio — vedi commento esteso su stileFuoco nello script. */
  object-position: var(--fx, 50%) var(--oy, 100%);
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

/* Ingresso lento (solo splash): "il cancello si apre". Il colore non
   dissolve a velo uniforme: irrompe da un cerchio che si allarga a partire
   dal cancello (--fx/--fy, vedi puntoFuoco), la soglia del giardino, con un
   lampo di luce calda nel varco (.zc-bloom) e una spinta di camera da 1.08 a
   1. clip-path invece di mask-image: interpola nativamente via transizione
   CSS in ogni motore (Chromium, Firefox/LibreWolf, Safari) senza @property. */
.zc-scene.ingresso-lento .zc-painting {
  opacity: 1; filter: none; transform: none;
  clip-path: circle(0% at var(--fx, 50%) var(--fy, 50%));
  /* ease-in-out apposta, non cubic-bezier(.22,1,.36,1) del fade normale:
     quella curva è tarata per un'opacità (aggressiva all'inizio, quasi
     invisibile alla fine) e su un raggio spaziale faceva "scattare" il
     cerchio quasi subito invece di farlo crescere in modo percepibile
     — verificato congelando la transizione con getAnimations(), non a
     occhio sullo schermo. */
  transition: clip-path 1.5s ease-in-out .25s;
}
.zc-scene.ingresso-lento.play .zc-painting {
  clip-path: circle(140% at var(--fx, 50%) var(--fy, 50%));
}

/* Spinta di camera: da 1.08 a 1 sul cancello, una sola spinta continua che
   si assesta in ease-out, senza rimbalzi. Il riquadro resta sempre almeno
   grande quanto lo schermo, quindi non scopre mai i bordi. */
.zc-scene.ingresso-lento {
  transform: scale(1.08);
  transform-origin: var(--fx, 50%) var(--fy, 50%);
  transition: transform 2.6s cubic-bezier(.22,1,.36,1) .25s;
}
.zc-scene.ingresso-lento.zoom-in { transform: none; }

.zc-bloom {
  position: absolute; left: var(--fx, 50%); top: var(--fy, 50%);
  translate: -50% -50%;
  width: 46%; aspect-ratio: 1; border-radius: 50%;
  background: radial-gradient(circle, rgba(255,224,158,.9) 0%, rgba(255,224,158,0) 70%);
  opacity: 0; pointer-events: none; mix-blend-mode: screen;
}
.zc-scene.ingresso-lento.play .zc-bloom { animation: zc-bloom-in 1.8s ease-out .3s forwards; }
@keyframes zc-bloom-in { 0%{opacity:0;} 30%{opacity:.9;} 100%{opacity:0;} }

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

/* Vento d'autunno: il canvas copre tutto il riquadro, sopra il dipinto e
   senza intercettare click (lo splash chiude al tocco sulla scena). Le
   nuvole di giorno cedono il posto alle foglie. */
.zc-foglie { position: absolute; inset: 0; width: 100%; height: 100%; pointer-events: none; }
.zc-scene.con-foglie .zc-clouds { opacity: 0; }

@media (prefers-reduced-motion: reduce) {
  .zc-painting { transition: none; opacity: 1; transform: none; filter: none; }
  .zc-cloud, .zc-twinkle { animation: none !important; }
  .zc-clouds, .zc-stars { transition: none; }
}
</style>
