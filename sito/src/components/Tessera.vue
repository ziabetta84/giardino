<template>
  <!-- Le icone ad acquerello dell'app (src/components/IconDefs.vue) dentro una
       tessera nella tinta della tappa: un colore per icona, come nell'app. -->
  <span class="tessera" :class="[`tinta--${colore}`, `tessera--${misura}`]" aria-hidden="true">
    <svg viewBox="0 0 256 256" focusable="false"><use :href="`#i-${icona}`" /></svg>
  </span>
</template>

<script setup>
defineProps({
  icona: { type: String, required: true },
  colore: { type: String, required: true },
  misura: { type: String, default: 'media' },
})
</script>
