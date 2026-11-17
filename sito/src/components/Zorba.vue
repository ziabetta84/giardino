<template>
  <svg class="zorba" viewBox="0 0 512 512" :role="etichetta ? 'img' : undefined"
       :aria-label="etichetta || undefined" :aria-hidden="etichetta ? undefined : 'true'" focusable="false">
    <use href="#zorba" />
  </svg>
</template>

<script setup>
// Zorba, sempre nero (DESIGN.md, «La Regola di Zorba Nero»). Senza etichetta è decorativo.
defineProps({ etichetta: { type: String, default: '' } })
</script>
