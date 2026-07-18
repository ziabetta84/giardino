<template>
  <div class="statusbar">
    <div style="display:flex;align-items:center;gap:8px;">
      <span class="dot-glow"></span>
      <span style="font-size:12px;color:var(--ink-soft);">{{ store.loading ? 'Caricamento…' : 'Pronto' }}</span>
    </div>
    <button class="btn btn-ghost" style="padding:5px 14px;font-size:11px;border-radius:8px;min-height:32px;"
      @click="store.aggiorna()">
      Aggiorna
    </button>
  </div>
</template>

<script setup>
import { useDatiStore } from '@/stores/dati'
const store = useDatiStore()
</script>

<style scoped>
.statusbar {
  position: fixed; bottom: 0; left: 0; right: 0; height: 44px; z-index: 50;
  background: rgba(250,247,242,0.95);
  backdrop-filter: blur(16px);
  border-top: 1px solid var(--cream-dark);
  display: flex; align-items: center; justify-content: space-between; padding: 0 16px;
}
@media (max-width: 640px) { .statusbar { display: none; } }
</style>
