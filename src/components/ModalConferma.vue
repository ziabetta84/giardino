<template>
  <Teleport to="body">
    <div v-if="aperto" class="overlay" @click.self="$emit('annulla')">
      <div class="modal-box" role="alertdialog" aria-modal="true" tabindex="-1"
        ref="box" @keydown.esc="$emit('annulla')">
        <h3 class="mc-titolo">{{ titolo }}</h3>
        <p style="font-size:13px;color:var(--ink-soft);line-height:1.5;">{{ messaggio }}</p>
        <div style="display:flex;gap:10px;margin-top:20px;justify-content:flex-end;">
          <button class="btn btn-ghost" style="min-height:40px;padding:8px 18px;" @click="$emit('annulla')">Annulla</button>
          <button class="btn" style="min-height:40px;padding:8px 18px;background:var(--rose);color:white;" @click="$emit('conferma')" :disabled="caricamento">
            <Spinner v-if="caricamento" />{{ caricamento ? 'Eliminazione…' : 'Elimina' }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { ref, watch, nextTick } from 'vue'
import Spinner from './Spinner.vue'

const props = defineProps({
  aperto:     { type: Boolean, default: false },
  titolo:     { type: String,  default: 'Conferma eliminazione' },
  messaggio:  { type: String,  default: 'Questa azione non può essere annullata.' },
  caricamento:{ type: Boolean, default: false },
})
defineEmits(['conferma', 'annulla'])

const box = ref(null)
watch(() => props.aperto, (v) => {
  if (v) nextTick(() => box.value?.focus())
})
</script>

<style scoped>
.overlay {
  position: fixed; inset: 0; z-index: 400;
  background: rgba(42,34,24,0.4);
  display: flex; align-items: center; justify-content: center;
  padding: 16px;
}
.modal-box {
  background: var(--white);
  border-radius: 22px;
  padding: 24px;
  width: 100%; max-width: 360px;
  box-shadow: 0 20px 60px rgba(42,34,24,0.2);
  animation: mc-in 150ms ease;
}
.mc-titolo {
  font: 600 16px/1.2 var(--font-display);
  color: var(--ink);
  margin: 0 0 8px;
}
@keyframes mc-in {
  from { opacity: 0; transform: translateY(8px) scale(.98); }
  to   { opacity: 1; transform: none; }
}
@media (prefers-reduced-motion: reduce) {
  .modal-box { animation: none; }
}
</style>
