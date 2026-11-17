<template>
  <!-- Nome scientifico con le convenzioni botaniche (utils/nomeScientifico.js): corsivo solo dove va -->
  <span class="nome-sci"><template v-for="(p, i) in parti" :key="i"><i v-if="p.corsivo">{{ p.testo }}</i><template v-else>{{ p.testo }}</template></template></span>
</template>

<script setup>
import { computed } from 'vue'
import { partiNomeScientifico } from '@/utils/nomeScientifico'

const props = defineProps({ nome: { type: String, default: '' } })
const parti = computed(() => partiNomeScientifico(props.nome))
</script>

<style scoped>
/* Il corsivo eredita peso e dimensione del titolo che lo contiene */
.nome-sci i { font-style: italic; font-weight: inherit; }
</style>
