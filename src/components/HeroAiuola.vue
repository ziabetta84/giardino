<template>
  <div class="zc-scene" :class="{ play: animare, 'ingresso-lento': usaIngressoLento, 'zoom-in': cameraAttiva }" :style="stileFuoco" :data-light="luceVisibile">
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

    <!-- Prototipo "contorno che si compone": sagome vere della scena
         (autunno-giorno, unica tela tracciata finora — vedi
         src/assets/hero/contorni/), non una forma decorativa inventata.
         Attivo solo quando ingressoLento=true (lo splash a schermo intero,
         non la striscia della Home) e solo per una scena che ha davvero un
         tracciato: le altre 7 restano sulla dissolvenza rapida invariata
         finché non vengono tracciate a loro volta. -->
    <div v-if="usaIngressoLento" ref="contornoEl" class="zc-contorno" :class="{ visibile: contornoVisibile }" aria-hidden="true">
      <svg viewBox="0 0 1536 1024" preserveAspectRatio="xMidYMax slice">
        <g v-html="contornoSvg"></g>
      </svg>
    </div>

    <!-- Bagliore caldo dal cancello: si accende quando il colore prende il
         sopravvento (stessa soglia di .play), non un elemento permanente
         della scena. mix-blend-mode:screen invece di un'opacità piatta —
         schiarisce quello che c'è sotto come luce vera, non vela il dipinto
         con un velo uniforme. -->
    <div v-if="usaIngressoLento" class="zc-bloom" aria-hidden="true"></div>
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
import contornoAutunnoGiornoRaw from '@/assets/hero/contorni/autunno-giorno.svg?raw'

// stagione: 'primavera' | 'estate' | 'autunno' | 'inverno'
// luce: 'giorno' | 'notte'
const props = defineProps({
  stagione: { type: String, required: true },
  luce: { type: String, required: true },
  // Sequenza "disegno poi colore" (vedi avviaIngressoLento): solo lo splash a
  // schermo intero la usa, una volta per fascia del giorno — la striscia
  // hero della Home, rimontata a ogni apertura, resta sulla dissolvenza
  // rapida per non appesantire l'uso quotidiano (deciso in brainstorming
  // 19/09/2026, non un'omissione).
  ingressoLento: { type: Boolean, default: false },
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

// Estrae solo il/i <path> dal documento SVG tracciato (autotrace -centerline
// da src/components/HeroAiuola.vue → vedi processo in fonti/), scartando il
// wrapper <svg> del file sorgente: qui il viewBox/preserveAspectRatio è
// quello di .zc-contorno, per allinearsi pixel a pixel all'object-fit:cover
// del dipinto sottostante.
function estraiContenutoSvg(raw) {
  return raw.replace(/^[\s\S]*?<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '')
}
// Solo autunno-giorno ha oggi un tracciato reale (prototipo su una sola
// tela, deciso in brainstorming 19/09/2026): le altre 7 combinazioni restano
// senza voce nella mappa finché non vengono tracciate a loro volta.
const contorni = {
  autunno: { giorno: estraiContenutoSvg(contornoAutunnoGiornoRaw) },
}

// Il cancello è il fulcro compositivo di ogni tela (la soglia del
// giardino): il bloom di colore e la spinta di camera dell'ingresso lento
// partono da lì, non dal centro geometrico dell'immagine. Coordinate in %
// del riquadro renderizzato (object-fit:cover già applicato), calibrate a
// occhio sulla tela tracciata e verificate dal vivo — solo autunno/giorno
// per ora, stesso motivo di `contorni`.
const puntiFuoco = {
  autunno: { giorno: { x: 69, y: 62 } },
}
const puntoFuoco = computed(() => puntiFuoco[stagioneVisibile.value]?.[luceVisibile.value] ?? { x: 50, y: 50 })
const stileFuoco = computed(() => ({
  '--fx': puntoFuoco.value.x + '%',
  '--fy': puntoFuoco.value.y + '%',
}))

const animare = ref(false)
const erroreImg = ref(false)
const imgEl = ref(null)
const contornoEl = ref(null)
const contornoVisibile = ref(false)
// A differenza di contornoVisibile (torna false a fine disegno, per
// dissolvere il contorno) questo flag resta true per tutta la sequenza: la
// spinta di camera deve tenere lo zoom acquisito durante il disegno, non
// tornare a scala 1 proprio mentre arriva il colore (bug trovato dal vivo:
// legare .zoom-in a contornoVisibile annullava la spinta a metà).
const cameraAttiva = ref(false)

const DISEGNO_MS = 2600 // durata del tratteggio del contorno reale

const contornoSvg = computed(() => contorni[stagioneVisibile.value]?.[luceVisibile.value] ?? null)
const usaIngressoLento = computed(() => props.ingressoLento && !!contornoSvg.value && !ridottoMovimento())

// La dissolvenza d'ingresso parte quando il dipinto è davvero decodificato
// (evento load, o già .complete se arrivava dalla cache del browser), non a
// un timer fisso indipendente dal caricamento: su una rete lenta un timer
// fisso mostrerebbe uno scatto secco invece della dissolvenza prevista.
function onImgCaricata() {
  if (usaIngressoLento.value) {
    avviaIngressoLento()
  } else {
    animare.value = true
  }
}
// Un dipinto mancante non deve lasciare la scena bloccata invisibile in
// attesa di un evento load che non arriverà mai: si passa comunque allo
// stato "play" (mostra il fondo chiaro sotto) e si segnala l'errore per lo
// stile, senza inventare un fallback visivo più elaborato per un caso raro.
function onImgErrore() {
  erroreImg.value = true
  animare.value = true
}

let disegnoTimer = null
const DURATA_TRATTO_MS = 220 // ogni sagoma (petalo, foglia, filo d'erba) si disegna in fretta

// Fase 1: il contorno vero si disegna — non un unico stroke-dashoffset sulla
// lunghezza totale (il tracciato è un solo <path> con ~1000 sottopercorsi,
// uno per M di autotrace: il dash-pattern SVG riparte da zero a ogni
// sottopercorso, quindi quel trucco "un valore solo" faceva comparire quasi
// tutto insieme invece di disegnarsi in sequenza — verificato via
// getAnimations()/currentTime, non solo letto nel codice, vedi cronologia).
// Qui ogni sagoma ha la propria lunghezza reale e un ritardo proporzionale
// alla sua posizione nell'ordine di scansione di autotrace, sparso
// sull'intero budget DISEGNO_MS: l'effetto è un'onda di tratti che
// attraversa la scena, non un singolo pennino continuo.
// Fase 2, a disegno completato: il dipinto dissolve dentro esattamente come
// sempre (stessa transizione di .zc-painting) mentre il contorno sparisce —
// le due tele condividono le stesse linee, quindi il passaggio di consegne
// non "salta".
async function avviaIngressoLento() {
  contornoVisibile.value = true
  cameraAttiva.value = true
  await nextTick()
  const tratti = [...(contornoEl.value?.querySelectorAll('path') ?? [])]
  if (tratti.length === 0) { animare.value = true; return } // asset mancante/malformato: fallback alla dissolvenza normale
  const budgetRitardo = Math.max(DISEGNO_MS - DURATA_TRATTO_MS, 0)
  // Web Animations API invece di stroke-dasharray/transition pilotata da CSS:
  // con ~1000 elementi la sequenza "imposta stato pieno, forza un reflow,
  // cambia valore in un rAF successivo" per far scattare una CSS Transition
  // non si innescava in modo affidabile (verificato con getAnimations() su
  // ogni sottopercorso: nessuna transizione risultava mai avviata, il
  // dashoffset saltava a 0 da subito) — .animate() con keyframe espliciti
  // non dipende da quel meccanismo e parte in modo deterministico.
  tratti.forEach((tratto, i) => {
    // Lunghezza precalcolata in fase di build (data-len, vedi
    // scripts/hero-contorno o fonti/) invece di chiamare qui
    // getTotalLength(): su ~1000 sottopercorsi la chiamata sincrona bloccava
    // il thread principale per secondi al mount — verificato dal
    // vero collo di bottiglia, non solo sospettato.
    const lunghezza = Number(tratto.dataset.len) || tratto.getTotalLength()
    const ritardo = tratti.length > 1 ? (i / (tratti.length - 1)) * budgetRitardo : 0
    tratto.style.strokeDasharray = String(lunghezza)
    tratto.animate(
      [{ strokeDashoffset: lunghezza }, { strokeDashoffset: 0 }],
      // fill:'both', non 'forwards': prima che il ritardo scada, 'forwards'
      // NON tiene il primo keyframe (nascosto) — il tratto torna al valore
      // di default (0 = visibile) per l'intera attesa, vanificando lo
      // scaglionamento. Verificato con getAnimations()/effect.getTiming()
      // su singoli sottopercorsi, non solo letto nella spec.
      { duration: DURATA_TRATTO_MS, delay: ritardo, easing: 'linear', fill: 'both' }
    )
  })
  disegnoTimer = setTimeout(() => {
    animare.value = true
    contornoVisibile.value = false
  }, DISEGNO_MS)
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
  if (imgEl.value?.complete) onImgCaricata()
})
onUnmounted(() => {
  clearTimeout(disegnoTimer)
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

/* Ingresso lento (solo splash, solo scene tracciate): il colore non
   dissolve a velo uniforme come nella dissolvenza rapida — "irrompe" da un
   cerchio che si allarga a partire dal cancello (--fx/--fy, vedi
   puntoFuoco), la soglia del giardino, coerente con "si apre il cancello".
   clip-path invece di mask-image: interpola nativamente via transizione CSS
   in ogni motore (Chromium, Firefox/LibreWolf, Safari) senza @property. */
.zc-scene.ingresso-lento .zc-painting {
  opacity: 1; filter: none; transform: none;
  clip-path: circle(0% at var(--fx, 50%) var(--fy, 50%));
  /* ease-in-out apposta, non cubic-bezier(.22,1,.36,1) del fade normale:
     quella curva è tarata per un'opacità (aggressiva all'inizio, quasi
     invisibile alla fine) e su un raggio spaziale faceva "scattare" il
     cerchio quasi subito invece di farlo crescere in modo percepibile
     — verificato congelando la transizione con getAnimations(), non a
     occhio sullo schermo. */
  transition: clip-path 1.3s ease-in-out;
}
.zc-scene.ingresso-lento.play .zc-painting {
  clip-path: circle(140% at var(--fx, 50%) var(--fy, 50%));
}

/* Spinta di camera lenta: uno zoom impercettibile (1 → 1.03) sincronizzato
   sull'intera sequenza disegno+rivelazione, centrato sul cancello come il
   bloom — un'unica spinta continua, non due fasi separate, per restare
   "quieta" (nessun rimbalzo, resta su ease-out) invece che vistosa. */
.zc-scene.ingresso-lento {
  transform: scale(1);
  transform-origin: var(--fx, 50%) var(--fy, 50%);
  transition: transform 3.4s cubic-bezier(.22,1,.36,1);
}
.zc-scene.ingresso-lento.zoom-in { transform: scale(1.03); }

.zc-bloom {
  position: absolute; left: var(--fx, 50%); top: var(--fy, 50%);
  translate: -50% -50%;
  width: 46%; aspect-ratio: 1; border-radius: 50%;
  background: radial-gradient(circle, rgba(255,224,158,.9) 0%, rgba(255,224,158,0) 70%);
  opacity: 0; pointer-events: none; mix-blend-mode: screen;
}
.zc-scene.ingresso-lento.play .zc-bloom { animation: zc-bloom-in 1.6s cubic-bezier(.22,1,.36,1) forwards; }
@keyframes zc-bloom-in { 0%{opacity:0;} 30%{opacity:.4;} 100%{opacity:0;} }

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

/* Prototipo "contorno che si compone" (ingressoLento, solo splash): il
   tratteggio vero e proprio è pilotato da JS (avviaIngressoLento, lunghezza
   reale del tracciato) — qui solo l'aspetto del tratto e la dissolvenza
   finale, quando il dipinto a colori prende il sopravvento. */
.zc-contorno {
  position: absolute; inset: 0; pointer-events: none;
  opacity: 0;
  transition: opacity .9s cubic-bezier(.22,1,.36,1);
}
.zc-contorno.visibile { opacity: 1; transition: none; }
.zc-contorno svg { width: 100%; height: 100%; }
.zc-contorno :deep(path) {
  fill: none;
  /* Non var(--scn-ink) (#5a4e3e, pensato per nuvole/stelle decorative): il
     nero caldo vero del dipinto è molto più scuro — con l'ink-mid il tratto
     sembrava slavato e "scattava" più scuro al passaggio del colore invece
     di restare lo stesso segno. Ricampionato dopo il rifacimento della tela
     (nuova generazione con cielo azzurro/cancello aperto, 20/09/2026):
     #0f1608, i pixel più scuri della nuova versione. */
  stroke: #0f1608;
  stroke-width: 2.5;
  stroke-linecap: round;
  stroke-linejoin: round;
  vector-effect: non-scaling-stroke;
}

@media (prefers-reduced-motion: reduce) {
  .zc-painting { transition: none; opacity: 1; transform: none; filter: none; }
  .zc-cloud, .zc-twinkle { animation: none !important; }
  .zc-clouds, .zc-stars { transition: none; }
}
</style>
