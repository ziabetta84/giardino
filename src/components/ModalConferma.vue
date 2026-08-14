<template>
  <Teleport to="body">
    <div v-if="aperto" class="overlay" @click.self="$emit('annulla')">
      <div class="modal-box">
        <h3 style="font-family:var(--font-serif);font-size:16px;font-weight:600;margin-bottom:8px;">{{ titolo }}</h3>
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
import Spinner from './Spinner.vue'

defineProps({
  aperto:     { type: Boolean, default: false },
  titolo:     { type: String,  default: 'Conferma eliminazione' },
  messaggio:  { type: String,  default: 'Questa azione non può essere annullata.' },
  caricamento:{ type: Boolean, default: false },
})
defineEmits(['conferma', 'annulla'])
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
  border-radius: 20px;
  padding: 24px;
  width: 100%; max-width: 360px;
  box-shadow: 0 20px 60px rgba(42,34,24,0.2);
}
</style>
