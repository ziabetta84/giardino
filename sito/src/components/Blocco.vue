<template>
  <section class="blocco" :class="{ 'blocco--solo': !$slots.tavola }" :aria-labelledby="id">
    <div class="blocco__testo">
      <h2 :id="id" class="blocco__titolo">
        <svg v-if="icona" class="blocco__icona" viewBox="0 0 256 256" aria-hidden="true" focusable="false"><use :href="`#i-${icona}`" /></svg>
        {{ titolo }}
      </h2>
      <slot />
    </div>
    <div v-if="$slots.tavola" v-rivela class="blocco__tavola"><slot name="tavola" /></div>
  </section>
</template>

<script setup>
defineProps({
  id: { type: String, required: true },
  titolo: { type: String, required: true },
  icona: { type: String, default: '' },
})
</script>
