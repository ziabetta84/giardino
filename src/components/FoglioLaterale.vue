<template>
  <Teleport to="body">
    <div class="foglio-dim" :class="{ open: modelValue }" @click="chiudi"></div>
    <div class="foglio" :class="{ open: modelValue }" role="dialog" aria-modal="true"
      :inert="!modelValue" tabindex="-1" ref="pannello" @keydown.esc="chiudi">
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
import { watch, nextTick, ref, onBeforeUnmount, onMounted } from 'vue'

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  titolo: { type: String, default: '' },
})
const emit = defineEmits(['update:modelValue'])
const pannello = ref(null)

function chiudi() { emit('update:modelValue', false) }

// Blocca lo scroll del body mentre il foglio è aperto, sposta il focus sul
// pannello (per Esc / lettori di schermo) e lo riporta all'elemento di
// partenza alla chiusura. Nessun focus-trap completo: coerente con le modali
// esistenti dell'app.
let elemPrecedente = null
watch(() => props.modelValue, async (aperto) => {
  document.body.style.overflow = aperto ? 'hidden' : ''
  if (aperto) {
    elemPrecedente = document.activeElement
    await nextTick()
    pannello.value?.focus()
  } else {
    elemPrecedente?.focus?.()
    elemPrecedente = null
  }
})
// Difensivo: il componente può essere montato quando è già aperto (es. una
// view che lo istanzia con v-model già true). Il watch sopra non è
// { immediate: true } di proposito — così facendo azzererebbe overflow ad
// ogni mount, calpestando un eventuale scroll-lock di una modale sottostante.
onMounted(() => {
  if (props.modelValue) {
    document.body.style.overflow = 'hidden'
    nextTick(() => pannello.value?.focus())
  }
})
onBeforeUnmount(() => { document.body.style.overflow = '' })
</script>
