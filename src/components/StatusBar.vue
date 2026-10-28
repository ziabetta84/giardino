<template>
  <div class="statusbar" :class="`stato-${stato}`" :style="{ bottom: offsetInferiore + 'px' }">
    <!-- Aggiornamento dell'app pronto (service worker): ha la precedenza,
         altrimenti chi non ricarica resta su una versione vecchia. -->
    <template v-if="stato === 'nuova-versione'">
      <div class="statusbar__msg">
        <span class="dot-glow"></span>
        <span class="statusbar__testo">Nuova versione disponibile</span>
      </div>
      <button class="btn btn-ghost statusbar__btn" @click="applicaAggiornamento">Ricarica</button>
    </template>

    <template v-else-if="stato === 'caricamento'">
      <div class="statusbar__msg">
        <span class="dot-glow"></span>
        <span class="statusbar__testo">Caricamento…</span>
      </div>
    </template>

    <!-- Invito al contributo volontario durante la beta (Ko-fi). -->
    <template v-else-if="linkContributo">
      <div class="statusbar__msg">
        <Icon name="erba-gatta" class="statusbar__icona" />
        <span class="statusbar__testo">
          <span class="statusbar__nome">Erba gatta per Zorba</span>
          <span class="statusbar__nota"> · aiuta il giardino a crescere</span>
        </span>
      </div>
      <a :href="linkContributo" target="_blank" rel="noopener noreferrer" class="btn btn-ghost statusbar__btn"
        aria-label="Regala un ciuffo d'erba gatta: contributo su Ko-fi (si apre in una nuova scheda)">Regala</a>
    </template>

    <template v-else>
      <div class="statusbar__msg">
        <span class="dot-glow"></span>
        <span class="statusbar__testo">Pronto</span>
      </div>
    </template>
  </div>
</template>

<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue'
import Icon from '@/components/Icon.vue'
import { useDatiStore } from '@/stores/dati'
import { useAppUpdate } from '@/composables/useAppUpdate'
import { linkContributo } from '@/composables/useContributo'

const store = useDatiStore()
const { needRefresh, applicaAggiornamento, controllaAggiornamento } = useAppUpdate()

// La barra non legge più lo stato del repository su GitHub: l'unico segnale
// di aggiornamento è il service worker (needRefresh), che si controlla
// all'avvio e quando l'app torna in primo piano.
const stato = computed(() =>
  needRefresh.value ? 'nuova-versione' : store.loading ? 'caricamento' : 'invito')

function alRitorno() { if (document.visibilityState === 'visible') controllaAggiornamento() }

const offsetInferiore = ref(0)
function aggiornaOffset() {
  const nav = document.querySelector('.bottomnav')
  const visibile = nav && getComputedStyle(nav).display !== 'none'
  offsetInferiore.value = visibile ? nav.getBoundingClientRect().height : 0
}
onMounted(() => {
  aggiornaOffset()
  window.addEventListener('resize', aggiornaOffset)
  document.addEventListener('visibilitychange', alRitorno)
  controllaAggiornamento()
})
onUnmounted(() => {
  window.removeEventListener('resize', aggiornaOffset)
  document.removeEventListener('visibilitychange', alRitorno)
})
</script>

<style scoped>
.statusbar {
  position: fixed; bottom: 0; left: 0; right: 0; height: 44px; z-index: 50;
  background: rgba(250,247,242,0.95);
  backdrop-filter: blur(16px);
  border-top: 1px solid var(--cream-dark);
  display: flex; align-items: center; justify-content: space-between; padding: 0 16px;
  gap: 10px;
}
@media (max-width: 640px) {
  .statusbar { height: 38px; padding: 0 12px; }
}

.statusbar__msg { display: flex; align-items: center; gap: 8px; min-width: 0; }
.statusbar__testo { font-size: 12px; color: var(--ink-soft); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.statusbar__nome { font: 600 13px/1 var(--font-display); color: var(--ink-mid); }
.statusbar__icona { width: 18px; height: 18px; flex: none; }
.statusbar__btn {
  padding: 5px 14px; font-size: 11px; border-radius: 8px; min-height: 32px; flex-shrink: 0;
  text-decoration: none; display: inline-flex; align-items: center;
}
@media (max-width: 400px) { .statusbar__nota { display: none; } }

.stato-caricamento .dot-glow {
  background: var(--gold); box-shadow: 0 0 6px rgba(224,184,74,0.7);
  animation: statusbar-pulse 1.1s ease-in-out infinite;
}
.stato-nuova-versione .dot-glow { background: var(--rose); box-shadow: 0 0 6px rgba(204,110,110,0.7); }

@keyframes statusbar-pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.35; }
}
</style>
