<template>
  <div class="statusbar" :class="`stato-${statoEffettivo}`" :style="{ bottom: offsetInferiore + 'px' }">
    <div style="display:flex;align-items:center;gap:8px;min-width:0;">
      <span class="dot-glow"></span>
      <span style="font-size:12px;color:var(--ink-soft);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">{{ testoStato }}</span>
    </div>
    <button class="btn btn-ghost" style="padding:5px 14px;font-size:11px;border-radius:8px;min-height:32px;flex-shrink:0;"
      @click="onClick">
      {{ pronto ? 'Ricarica' : 'Aggiorna' }}
    </button>
  </div>
</template>

<script setup>
import { computed, ref, watch, onMounted, onUnmounted } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useRepoStatus } from '@/composables/useRepoStatus'
import { useAppUpdate } from '@/composables/useAppUpdate'

const store = useDatiStore()
const repo  = useRepoStatus()
const { needRefresh, applicaAggiornamento, controllaAggiornamento } = useAppUpdate()

// "Nuova versione disponibile" (da useRepoStatus, confronto commit su
// GitHub) può comparire prima che QUESTO service worker se ne sia accorto:
// solo needRefresh dice se c'è davvero un aggiornamento pronto da applicare
// con un reload. Finché non lo è, il bottone resta "Aggiorna" (dati) invece
// di promettere una ricarica che non cambierebbe nulla.
const pronto = computed(() => repo.stato.value === 'nuova-versione' && needRefresh.value)

watch(() => repo.stato.value, (nuovo) => {
  if (nuovo === 'nuova-versione') controllaAggiornamento()
}, { immediate: true })

// Priorità: il caricamento iniziale dei dati locali copre lo stato del
// repository (che nel frattempo può ben essere "aggiornato"), perché mentre
// i JSON non sono ancora arrivati non ha senso mostrare altro.
const statoEffettivo = computed(() => store.loading ? 'caricamento' : repo.stato.value)

const testoStato = computed(() => ({
  caricamento:        'Caricamento…',
  sincronizzazione:   'Sincronizzazione in corso…',
  'nuova-versione':   'Nuova versione disponibile',
  aggiornato:         'Aggiornato',
  sconosciuto:        'Pronto',
}[statoEffettivo.value]))

function onClick() {
  if (pronto.value) {
    applicaAggiornamento()
  } else {
    store.aggiorna()
  }
}

// Su schermi stretti la BottomNav occupa il fondo pagina: la statusbar deve
// stare appena sopra, con un offset misurato dal vero elemento a schermo
// (safe-area e altezza reale variano da dispositivo a dispositivo) invece
// che da un valore fisso indovinato in CSS.
const offsetInferiore = ref(0)
function aggiornaOffset() {
  const nav = document.querySelector('.bottom-nav')
  const visibile = nav && getComputedStyle(nav).display !== 'none'
  offsetInferiore.value = visibile ? nav.getBoundingClientRect().height : 0
}
onMounted(() => {
  aggiornaOffset()
  window.addEventListener('resize', aggiornaOffset)
})
onUnmounted(() => window.removeEventListener('resize', aggiornaOffset))
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

.stato-sincronizzazione .dot-glow {
  background: var(--gold); box-shadow: 0 0 6px rgba(224,184,74,0.7);
  animation: statusbar-pulse 1.1s ease-in-out infinite;
}
.stato-nuova-versione .dot-glow { background: var(--rose); box-shadow: 0 0 6px rgba(204,110,110,0.7); }

@keyframes statusbar-pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.35; }
}
</style>
