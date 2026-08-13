<template>
  <svg viewBox="0 0 24 24" aria-hidden="true"><use :href="`#i-${name}`" /></svg>
</template>

<script setup>
defineProps({
  name: { type: String, required: true },
})
</script>
