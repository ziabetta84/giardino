<template>
  <!-- Teleport a body: montato da HomeView.vue, quindi dentro .app-main, che
       ha position:relative + z-index:1 (stacking context) — senza Teleport
       lo splash resta intrappolato in quel contesto, e la StatusBar (fuori
       da .app-main, z-index:50) gli passerebbe sopra nonostante il suo
       z-index:480 locale. Stesso motivo/stesso pattern di LightboxFoto.vue. -->
  <Teleport to="body">
  <!-- Transition qui dentro, non attorno a <SplashAiuola> in HomeView.vue
       come prima: un Transition non può animare un componente la cui radice
       è un <Teleport> (Vue lo segnala anche a console, "renders non-element
       root node that cannot be animated") — la dissolvenza in uscita non
       scattava mai davvero, il componente spariva di scatto. Qui il
       Transition avvolge l'elemento vero, dentro il Teleport: funziona, e
       HomeView smonta il componente solo a transizione finita (@after-leave
       → emit('fine')), non subito al click su "Salta". Trovato e corretto
       il 20/09/2026. -->
  <Transition name="splash-esce" @after-leave="onUscitaCompleta">
  <div v-if="visibile" ref="box" class="splash" role="dialog" aria-modal="true" aria-label="Il tuo giardino"
    tabindex="-1" @keydown.esc="salta">

    <!-- @click qui, non @click.self su .splash: .splash__scene è a piena
         pagina (inset:0) e intercetta ogni click prima che raggiunga
         .splash stesso — .self quindi non scattava MAI, verificato con
         elementFromPoint in critica del 20/09/2026 (il click sulla scena
         sembrava cliccabile, cursor:pointer ereditato da .splash, ma non
         faceva nulla). Testo/Zorba/bottone restano sopra come fratelli,
         quindi un click su di loro non attraversa mai .splash__scene e non
         chiude lo splash per sbaglio mentre si legge o si tocca "Salta". -->
    <div class="splash__scene" @click="salta">
      <HeroAiuola :stagione="stagione" :luce="luce" ingresso-lento />
    </div>
    <div class="splash__scrim"></div>

    <ZorbaLogo class="splash__z" :class="luce === 'notte' ? 'splash__z--notte' : 'splash__z--giorno'" />

    <div class="splash__txt">
      <Transition name="splash-riga" appear>
        <div v-if="fase >= 1" class="date">{{ dataOggi }}</div>
      </Transition>
      <Transition name="splash-riga" appear>
        <h1 v-if="fase >= 1" class="greet">{{ saluto }}</h1>
      </Transition>
      <Transition name="splash-riga" appear>
        <div v-if="fase >= 2" class="stat splash__stat">
          <template v-if="loading">
            <span class="skeleton" style="width:64px;height:22px;border-radius:999px;"></span>
            <span class="skeleton" style="width:52px;height:22px;border-radius:999px;"></span>
            <span class="skeleton" style="width:76px;height:22px;border-radius:999px;"></span>
          </template>
          <template v-else-if="errore">
            <span>Dati non disponibili</span>
          </template>
          <template v-else-if="numPiante === 0">
            <span>{{ numZone === 0 ? 'Pronto per iniziare' : 'Aggiungi una pianta' }}</span>
          </template>
          <template v-else>
            <span>{{ numPiante }} piante</span>
            <span>{{ numZone }} zone</span>
            <span><b :class="{ urg: numUrgenti }">{{ numUrgenti }} piante da curare</b></span>
          </template>
        </div>
      </Transition>
    </div>

    <button type="button" class="splash__salta" @click="salta">Salta</button>
  </div>
  </Transition>
  </Teleport>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import HeroAiuola from '@/components/HeroAiuola.vue'

// Momento d'ingresso a schermo intero, una volta per fascia del saluto (vedi
// HomeView.vue): riusa le stesse 8 tele stagione×luce di HeroAiuola.vue, qui
// a piena pagina invece che ritagliate nella striscia della Home. Zorba non
// riceve qui nessun battito manuale: la sua animazione d'ingresso (tratteggio
// del motivo, battito di ciglia, coda) parte già da sola al mount di
// ZorbaLogo.vue, pensata esattamente per un momento come questo.
const props = defineProps({
  stagione:   { type: String, required: true },
  luce:       { type: String, required: true },
  saluto:     { type: String, required: true },
  dataOggi:   { type: String, required: true },
  numPiante:  { type: Number, default: null },
  numZone:    { type: Number, default: null },
  numUrgenti: { type: Number, default: null },
  loading:    { type: Boolean, default: false },
  errore:     { type: Boolean, default: false },
})
const emit = defineEmits(['fine'])

const box = ref(null)
// Controlla il v-if interno (vedi Transition nel template): salta() lo
// mette a false per avviare l'uscita animata; onUscitaCompleta (@after-leave,
// a transizione CSS finita) emette 'fine' verso HomeView, che solo allora
// smonta davvero il componente. Prima "salta" emetteva 'fine' subito e
// HomeView smontava tutto all'istante, senza lasciare il tempo a nessuna
// dissolvenza di scattare.
const visibile = ref(true)
// 0 = solo scena+Zorba, 1 = saluto/data, 2 = pillole — scandito sui tempi
// dell'animazione di mount di ZorbaLogo.vue (tratteggio ~1.2s, battito a
// 1.6s, coda a 2.0s) così saluto e pillole non anticipano Zorba che deve
// ancora "arrivare" nella scena. Tempi allungati dopo verifica live
// (16/09/2026): 600/1400/3400ms lasciava leggere a malapena il saluto prima
// di sparire — un rituale d'apertura raro (una volta per fascia) può
// permettersi di restare fermo più a lungo, coerente col "ritmo lento da
// fine giornata in giardino" di DESIGN.md.
const fase = ref(0)
let timers = []

onMounted(() => {
  nextTick(() => box.value?.focus())
  timers.push(setTimeout(() => { fase.value = 1 }, 700))
  timers.push(setTimeout(() => { fase.value = 2 }, 1900))
  timers.push(setTimeout(salta, 5200))
})
onUnmounted(() => timers.forEach(clearTimeout))

function salta() {
  visibile.value = false
}
function onUscitaCompleta() {
  emit('fine')
}
</script>

<style scoped>
.splash {
  position: fixed; inset: 0; z-index: 480; /* sotto BootLogo (500): HomeView aspetta bootCompletato prima di montarmi, ma resto comunque al riparo se i due dovessero mai sovrapporsi */
  overflow: hidden;
  background: var(--sage-bg);
  cursor: pointer;
}
.splash__scene { position: absolute; inset: 0; }
.splash__scrim {
  position: absolute; inset: 0; pointer-events: none;
  /* .55 che sfumava già a partire da 0% non bastava dove vive davvero il
     testo: misurato dal vivo (critica del 20/09/2026 + verifica pixel reale,
     non solo getComputedStyle) che a ~11% di altezza dal fondo — dove cade
     la data — il contrasto reale era 2.49:1 contro un minimo di 4.5:1,
     perché il gradiente aveva già perso metà della sua forza a quel punto.
     Ora un pianerottolo pieno fino al 28% (copre data/saluto/pillole su
     qualunque altezza di schermo ragionevole) prima di sfumare a 0 al 58%:
     verificato che porta il contrasto della data a 5:1. */
  background: linear-gradient(to top,
    rgba(20,16,8,.68) 0%, rgba(20,16,8,.68) 28%, transparent 58%);
}

/* Due blocchi assoluti indipendenti, non una colonna flex: con flex
   sarebbero finiti impilati uno sopra l'altro (Zorba sopra il testo) invece
   che affiancati sullo stesso bordo inferiore. */
.splash__z {
  position: absolute; z-index: 2; right: 22px; bottom: 26px;
  width: 116px; height: 116px;
}
.splash .splash__z--giorno { filter: drop-shadow(0 4px 8px rgba(122,90,21,.35)); }
.splash .splash__z--notte  { filter: drop-shadow(0 0 6px rgba(242,232,216,.65)); }

.splash__txt {
  position: absolute; z-index: 2; left: 0; right: 0; bottom: 0;
  padding: 0 152px 30px 22px; cursor: default; /* padding destro: spazio riservato a Zorba */
}
.splash__txt .date {
  font: 400 21px/1 var(--font-hand); color: #e9dfca;
}
.splash__txt .greet {
  font: 600 32px/1.12 var(--font-display); letter-spacing: -0.01em;
  margin: 5px 0 16px; color: #fff; text-wrap: balance;
}
.splash__stat span {
  background: rgba(255,255,255,.16); border-color: transparent; color: #f3ecdc;
}
.splash__stat b.urg { color: #f3c9c2; }

.splash__salta {
  /* min-height:44px + flex per centrare, non padding a mano: stesso
     pattern di .btn in main.css. Prima era alto 28px (8px di padding +
     12px di riga), sotto il minimo di tocco che il sistema stesso impone —
     ed era anche l'unico modo affidabile di chiudere lo splash su touch
     finché il click sulla scena non funzionava (P0, corretto a parte).
     Misurato dal vivo: ora 44px esatti. */
  position: absolute; z-index: 3; cursor: pointer;
  display: inline-flex; align-items: center; justify-content: center;
  min-height: 44px;
  top: max(16px, env(safe-area-inset-top)); right: 16px;
  background: rgba(20,16,8,.35); color: #fff; border: none; border-radius: 999px;
  padding: 0 18px; font: 600 12px/1 var(--font-sans);
}

.splash-riga-enter-active { transition: opacity .5s var(--ease-standard), transform .5s var(--ease-standard); }
.splash-riga-enter-from { opacity: 0; transform: translateY(10px); }

/* Uscita verso la Home: dissolvenza più uno zoom impercettibile che
   continua nella stessa direzione della spinta di camera dell'ingresso
   lento (HeroAiuola.vue, scale 1→1.03) invece di invertirla — la scena
   prosegue ad aprirsi, non "torna indietro", mentre sfuma. Durata più
   generosa dei 0.26s di --motion-sheet (qui vive in scoped, non più in
   main.css: era attorno a <SplashAiuola> in HomeView.vue, ma un Transition
   non anima un componente la cui radice è un Teleport — non scattava mai
   davvero, vedi commento nel template). */
.splash-esce-leave-active { transition: opacity .42s var(--ease-standard), transform .42s var(--ease-standard); }
.splash-esce-leave-to { opacity: 0; transform: scale(1.03); }

@media (prefers-reduced-motion: reduce) {
  .splash-riga-enter-active { transition: opacity .3s var(--ease-standard); }
  .splash-riga-enter-from { transform: none; }
  .splash-esce-leave-active { transition: none; }
}
</style>
