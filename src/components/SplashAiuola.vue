<template>
  <div ref="box" class="splash" role="dialog" aria-modal="true" aria-label="Il tuo giardino"
    tabindex="-1" @click.self="salta" @keydown.esc="salta">

    <div class="splash__scene">
      <HeroAiuola :stagione="stagione" :luce="luce" />
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
// 0 = solo scena+Zorba, 1 = saluto/data, 2 = pillole — scandito sui tempi
// dell'animazione di mount di ZorbaLogo.vue (tratteggio ~1.2s, battito a
// 1.6s, coda a 2.0s) così saluto e pillole non anticipano Zorba che deve
// ancora "arrivare" nella scena.
const fase = ref(0)
let timers = []

onMounted(() => {
  nextTick(() => box.value?.focus())
  timers.push(setTimeout(() => { fase.value = 1 }, 600))
  timers.push(setTimeout(() => { fase.value = 2 }, 1400))
  timers.push(setTimeout(salta, 3400))
})
onUnmounted(() => timers.forEach(clearTimeout))

function salta() {
  emit('fine')
}
</script>

<style scoped>
.splash {
  position: fixed; inset: 0; z-index: 480; /* sotto BootLogo (500): HomeView aspetta bootCompletato prima di montarmi, ma resto comunque al riparo se i due dovessero mai sovrapporsi */
  overflow: hidden;
  background: var(--sage-bg);
  display: flex; flex-direction: column; justify-content: flex-end;
  cursor: pointer;
}
.splash__scene { position: absolute; inset: 0; }
.splash__scrim {
  position: absolute; inset: 0; pointer-events: none;
  background: linear-gradient(to top, rgba(20,16,8,.55), transparent 55%);
}

.splash__z {
  position: relative; z-index: 2; align-self: flex-end;
  width: 116px; height: 116px;
  margin: 0 22px 6px 0;
}
.splash .splash__z--giorno { filter: drop-shadow(0 4px 8px rgba(122,90,21,.35)); }
.splash .splash__z--notte  { filter: drop-shadow(0 0 6px rgba(242,232,216,.65)); }

.splash__txt { position: relative; z-index: 2; padding: 0 22px 30px; cursor: default; }
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
  position: absolute; z-index: 3; cursor: pointer;
  top: max(16px, env(safe-area-inset-top)); right: 16px;
  background: rgba(20,16,8,.35); color: #fff; border: none; border-radius: 999px;
  padding: 8px 16px; font: 600 12px/1 var(--font-sans);
}

.splash-riga-enter-active { transition: opacity .5s var(--ease-standard), transform .5s var(--ease-standard); }
.splash-riga-enter-from { opacity: 0; transform: translateY(10px); }

@media (prefers-reduced-motion: reduce) {
  .splash-riga-enter-active { transition: opacity .3s var(--ease-standard); }
  .splash-riga-enter-from { transform: none; }
}
</style>
