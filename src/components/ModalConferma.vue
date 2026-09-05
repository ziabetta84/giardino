<template>
  <Teleport to="body">
    <div v-if="aperto" class="overlay" @click.self="$emit('annulla')">
      <div class="modal-box" role="alertdialog" aria-modal="true" tabindex="-1"
        ref="box" @keydown.esc="$emit('annulla')">
        <h3 class="mc-titolo">{{ titolo }}</h3>
        <p class="prose">{{ messaggio }}</p>
        <p v-if="errore" class="mc-errore">{{ errore }}</p>
        <div style="display:flex;gap:10px;margin-top:20px;justify-content:flex-end;">
          <button class="btn btn-ghost" @click="$emit('annulla')">Annulla</button>
          <button class="btn btn-rose" @click="$emit('conferma')" :disabled="caricamento">
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
  // Messaggio di errore opzionale (es. un fallimento di rete durante la
  // conferma): il modale resta aperto e lo mostra invece di sparire senza
  // spiegazioni. null/assente = nessun errore, nessuna riga mostrata.
  errore:     { type: String,  default: null },
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
  animation: mc-in 150ms var(--ease-standard);
}
.mc-titolo {
  font: 600 16px/1.2 var(--font-display);
  color: var(--ink);
  margin: 0 0 8px;
}
.mc-errore {
  font: 400 12px/1.4 var(--font-sans);
  color: var(--rose-ink);
  margin: -6px 0 4px;
}
@keyframes mc-in {
  from { opacity: 0; transform: translateY(8px) scale(.98); }
  to   { opacity: 1; transform: none; }
}
@media (prefers-reduced-motion: reduce) {
  .modal-box { animation: none; }
}
</style>
