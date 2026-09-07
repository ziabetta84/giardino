<template>
  <svg viewBox="0 0 24 24" :aria-hidden="attrs['aria-label'] ? undefined : 'true'"><use :href="`#i-${name}`" /></svg>
</template>

<script setup>
import { useAttrs } from 'vue'

defineProps({
  name: { type: String, required: true },
})

// aria-hidden="true" fisso rendeva muta qualunque aria-label passata da un
// chiamante (es. l'icona "Terminato" sul concime esaurito, HomeView.vue/
// AttivitaRiga.vue): un elemento aria-hidden è escluso dall'albero di
// accessibilità, quindi la sua aria-label non veniva mai letta da uno
// screen reader (vedi critica del 07/09/2026). Resta aria-hidden per il
// caso comune (icona puramente decorativa, nome accessibile sul contenitore,
// come i bottoni in EditPiantaView.vue), ma si toglie quando il chiamante
// passa esplicitamente un'aria-label a questo componente.
const attrs = useAttrs()
</script>
