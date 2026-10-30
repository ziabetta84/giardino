<template>
  <!-- Campo password con «Mostra»/«Nascondi»: da telefono la password si
       scrive una volta sola, e senza poterla rileggere un errore di battitura
       diventa un account con una password che nessuno conosce (critica del
       30/10/2026). Il pulsante sta dentro il campo, a destra. -->
  <div class="campo-password">
    <input :id="id" :value="modelValue" :type="visibile ? 'text' : 'password'"
      :autocomplete="autocomplete" class="form-input campo-password__input"
      autocapitalize="off" autocorrect="off" spellcheck="false"
      v-bind="$attrs" @input="emit('update:modelValue', $event.target.value)">
    <button type="button" class="campo-password__mostra" :aria-pressed="visibile"
      :aria-label="visibile ? 'Nascondi la password' : 'Mostra la password'"
      :aria-controls="id" @click="visibile = !visibile">
      {{ visibile ? 'Nascondi' : 'Mostra' }}
    </button>
  </div>
</template>

<script setup>
import { ref } from 'vue'

defineOptions({ inheritAttrs: false })
defineProps({
  id: { type: String, required: true },
  modelValue: { type: String, default: '' },
  autocomplete: { type: String, default: 'current-password' },
})
const emit = defineEmits(['update:modelValue'])
const visibile = ref(false)
</script>

<style scoped>
.campo-password { position: relative; }
.campo-password__input { width: 100%; padding-right: 92px; }
.campo-password__mostra {
  position: absolute; top: 0; right: 0; bottom: 0;
  min-width: 44px; padding: 0 16px;
  background: none; border: none; border-radius: 0 14px 14px 0;
  font: 600 12px/1 var(--font-sans); letter-spacing: .02em;
  color: var(--ink-mid); cursor: pointer;
}
.campo-password__mostra:hover { color: var(--ink); }
.campo-password__mostra:focus-visible { outline: 2px solid var(--gold); outline-offset: -4px; }
</style>
