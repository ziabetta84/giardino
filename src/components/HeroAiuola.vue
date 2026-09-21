<template>
  <div ref="contenitoreEl" class="zc-scene" :class="{ play: animare, 'ingresso-lento': usaIngressoLento, 'zoom-in': cameraAttiva }" :style="stileFuoco" :data-light="luceVisibile">
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

    <!-- "Contorno che si compone": sagome vere della scena (autotrace sulla
         tela corrispondente, vedi src/assets/hero/contorni/), non una forma
         decorativa inventata. Attivo solo quando ingressoLento=true (lo
         splash a schermo intero, non la striscia della Home) — tutte e 8 le
         combinazioni stagione×luce hanno oggi un tracciato reale. -->
    <div v-if="usaIngressoLento" ref="contornoEl" class="zc-contorno" :class="{ visibile: contornoVisibile }" aria-hidden="true">
      <svg :viewBox="viewBoxContorno" preserveAspectRatio="none">
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
// Import pigro, non `?raw` statico: 8 file da 76-136KB (812KB in tutto)
// importati come stringa finivano TUTTI incorporati nel bundle JS di
// HomeView (che monta questo componente), anche se ne serve visualizzato
// uno solo per volta — misurato dal vivo: 840KB/315KB gzip sul chunk
// HomeView, segnalato da Vite stesso come "chunk troppo grande". Su una
// connessione lenta/instabile (registrazione reale 21/09/2026, 6-80 KB/s)
// bastava questo a spiegare 4-10s di schermo bianco prima che l'app
// mostrasse qualunque cosa — letto per errore come "l'animazione non è
// fluida", ma il vero collo di bottiglia era il download, non il
// rendering. import.meta.glob senza eager:true crea un chunk separato per
// ciascun file, scaricato solo quando avviaIngressoLento lo richiede
// davvero per la scena attiva.
const contornoModuli = import.meta.glob('@/assets/hero/contorni/*.svg', { query: '?raw', import: 'default' })

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
// Tutte e 8 le combinazioni hanno un tracciato reale (autotrace -centerline
// sulla tela corrispondente, sottopercorsi con lunghezza precalcolata —
// vedi cronologia). Le tele "vanno bene così come sono" (autunno-notte,
// estate-notte) sono tracciate sull'immagine originale, invariata; le altre
// 5 sono state rigenerate (cielo azzurro, cancello aperto, prato+vialetto)
// e ritracciate su quella nuova versione — 20/09/2026.
async function caricaContorno(stagione, luce) {
  const carica = contornoModuli[`/src/assets/hero/contorni/${stagione}-${luce}.svg`]
  if (!carica) return null // non dovrebbe succedere: tutte e 8 esistono
  return estraiContenutoSvg(await carica())
}

// Risoluzione nativa di ciascuna tela (il tracciato è in quelle coordinate
// esatte, autotrace lavora sui pixel reali dell'immagine): 3 delle 8 tele
// rigenerate sono uscite da Gemini/ChatGPT a 1264×NNN invece di 1536×1024
// come le altre 5. Un viewBox fisso "0 0 1536 1024" per tutte, come prima,
// faceva apparire il contorno di quelle 3 rimpicciolito e ancorato in alto a
// sinistra invece di riempire lo schermo come il dipinto sottostante (che
// invece scala sempre a piena pagina via object-fit:cover, indifferente
// alla risoluzione) — bug segnalato dal vivo il 20/09/2026.
const dimensioniTela = {
  primavera: { giorno: [1264, 843], notte: [1264, 848] },
  estate: { giorno: [1264, 842], notte: [1536, 1024] },
  autunno: { giorno: [1536, 1024], notte: [1536, 1024] },
  inverno: { giorno: [1536, 1024], notte: [1536, 1024] },
}
// Il contorno deve mostrare ESATTAMENTE la stessa finestra di ritaglio del
// dipinto sottostante — altrimenti le due tele si disallineano appena il
// riquadro non ha il rapporto nativo della tela (bug reale, trovato dal
// vivo il 20/09/2026 dopo aver corretto solo .zc-painting: object-position
// segue --fx, ma preserveAspectRatio="xMidYMax slice" dell'SVG resta
// centrato per costruzione — preserveAspectRatio non supporta un ancoraggio
// a percentuale arbitraria, solo le 9 combinazioni xMin/Mid/Max×Min/Mid/Max).
// Si calcola quindi a mano la stessa finestra che produrrebbe
// object-fit:cover + object-position:"fx% bottom" su questa risoluzione
// nativa, e si usa come viewBox — nessun preserveAspectRatio speciale
// necessario, la finestra ha già lo stesso rapporto del riquadro per
// costruzione (vw/vh = cw/ch sempre).
const viewBoxContorno = computed(() => {
  const [iw, ih] = dimensioniTela[stagioneVisibile.value]?.[luceVisibile.value] ?? [1536, 1024]
  const cw = contenitoreW.value
  const ch = contenitoreH.value
  if (!cw || !ch) return `0 0 ${iw} ${ih}` // prima della prima misura del ResizeObserver
  const scale = Math.max(cw / iw, ch / ih)
  const vw = cw / scale // larghezza della finestra visibile, in pixel nativi della tela
  const vh = ch / scale
  const xStart = (iw - vw) * (puntoFuoco.value.x / 100) // stessa formula di object-position-x = fx
  const yStart = ih - vh // object-position-y fissa a "bottom", come .zc-painting
  return `${xStart} ${yStart} ${vw} ${vh}`
})

// Il cancello è il fulcro compositivo di ogni tela (la soglia del
// giardino): il bloom di colore e la spinta di camera dell'ingresso lento
// partono da lì, non dal centro geometrico dell'immagine. Coordinate in %
// del riquadro renderizzato (object-fit:cover già applicato), calibrate a
// occhio su ciascuna tela e verificate dal vivo solo su un sottoinsieme
// (autunno/giorno, inverno/notte) — le altre sono una stima a occhio da
// aggiustare se in prova risultano visibilmente sbagliate.
const puntiFuoco = {
  primavera: { giorno: { x: 58, y: 55 }, notte: { x: 63, y: 55 } },
  estate: { giorno: { x: 63, y: 55 }, notte: { x: 73, y: 60 } },
  autunno: { giorno: { x: 69, y: 62 }, notte: { x: 63, y: 55 } },
  inverno: { giorno: { x: 77, y: 55 }, notte: { x: 73, y: 52 } },
}
const puntoFuoco = computed(() => puntiFuoco[stagioneVisibile.value]?.[luceVisibile.value] ?? { x: 50, y: 50 })

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
  const [iw, ih] = dimensioniTela[stagioneVisibile.value]?.[luceVisibile.value] ?? [1536, 1024]
  const fy = fuocoYRenderizzato(puntoFuoco.value.y, iw, ih, contenitoreW.value, contenitoreH.value)
  return {
    '--fx': puntoFuoco.value.x + '%',
    '--fy': fy + '%',
  }
})

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
// Popolato da avviaIngressoLento, non da un computed sincrono: il contenuto
// va scaricato al bisogno (vedi caricaContorno sopra), non può più essere
// letto da una mappa già pronta in memoria.
const contornoSvg = ref(null)

const DISEGNO_MS = 2600 // durata del tratteggio del contorno reale

// Non dipende più dall'esistenza di un contorno già caricato (tutte e 8 le
// scene ce l'hanno, verificato — vedi caricaContorno): dipende solo
// dall'intento del chiamante e dalla preferenza di movimento.
const usaIngressoLento = computed(() => props.ingressoLento && !ridottoMovimento())

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
  // Scaricato solo ora, solo per la scena davvero attiva — non più una
  // mappa con tutte e 8 le tele già pronte in memoria (vedi contornoModuli
  // sopra). Su una connessione lenta questo aggiunge un'attesa reale prima
  // che il contorno inizi a disegnarsi (prima non c'era, il costo era già
  // stato pagato tutto in anticipo dentro il bundle di HomeView) — ma è
  // un'attesa piccola e localizzata (76-136KB, una sola tela) invece di
  // 812KB scaricati sempre, per tutte le scene, solo per aprire la Home.
  const raw = await caricaContorno(stagioneVisibile.value, luceVisibile.value)
  if (!raw) { animare.value = true; return } // non dovrebbe succedere: tutte e 8 le scene hanno un tracciato
  contornoSvg.value = raw
  contornoVisibile.value = true
  cameraAttiva.value = true
  await nextTick()
  const tratti = [...(contornoEl.value?.querySelectorAll('path') ?? [])]
  if (tratti.length === 0) { animare.value = true; return } // asset mancante/malformato: fallback alla dissolvenza normale
  // Ordine per lunghezza decrescente, non l'ordine di scansione grezzo di
  // autotrace (arbitrario, non correlato alla dimensione visiva): senza
  // questo, su alcune tele (estate-giorno, verificato dal vivo) i tanti
  // trattini minuscoli dell'erba finivano sparsi per tutto il budget mentre
  // le sagome grandi (fiori, cancello) restavano quasi invisibili — un
  // effetto "scarabocchio confuso" invece di una forma che si compone. Le
  // sagome grandi ora disegnano per prime, i dettagli piccoli riempiono
  // dopo, come farebbe una mano vera.
  tratti.sort((a, b) => Number(b.dataset.len) - Number(a.dataset.len))
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
  clearTimeout(disegnoTimer)
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
  object-position: var(--fx, 50%) bottom;
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
