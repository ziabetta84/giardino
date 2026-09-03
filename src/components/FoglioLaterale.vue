<template>
  <Teleport to="body">
    <div class="foglio-dim" :class="{ open: modelValue }" @click="chiudi"></div>
    <div class="foglio" :class="{ open: modelValue }" role="dialog" aria-modal="true"
      tabindex="-1" ref="pannello" @keydown.esc="chiudi">
      <div class="foglio__grab" aria-hidden="true"></div>
      <div class="foglio__hd">
        <slot name="intestazione"><h3 v-if="titolo">{{ titolo }}</h3><span v-else></span></slot>
        <button type="button" class="foglio__x" aria-label="Chiudi" @click="chiudi">×</button>
      </div>
      <div class="foglio__body"><slot /></div>
    </div>
  </Teleport>
</template>

<script setup>
import { watch, nextTick, ref, onBeforeUnmount } from 'vue'

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  titolo: { type: String, default: '' },
})
const emit = defineEmits(['update:modelValue'])
const pannello = ref(null)

function chiudi() { emit('update:modelValue', false) }

// Blocca lo scroll del body mentre il foglio è aperto e sposta il focus sul
// pannello (per Esc / lettori di schermo). Nessun focus-trap completo:
// coerente con le modali esistenti dell'app.
watch(() => props.modelValue, async (aperto) => {
  document.body.style.overflow = aperto ? 'hidden' : ''
  if (aperto) { await nextTick(); pannello.value?.focus() }
})
onBeforeUnmount(() => { document.body.style.overflow = '' })
</script>
