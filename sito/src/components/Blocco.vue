<template>
  <section class="blocco" :class="{ 'blocco--solo': !$slots.tavola }" :aria-labelledby="id">
    <div class="blocco__testo">
      <h2 :id="id" class="blocco__titolo">{{ titolo }}</h2>
      <slot />
    </div>
    <div v-if="$slots.tavola" v-rivela class="blocco__tavola"><slot name="tavola" /></div>
  </section>
</template>

<script setup>
defineProps({ id: { type: String, required: true }, titolo: { type: String, required: true } })
</script>
