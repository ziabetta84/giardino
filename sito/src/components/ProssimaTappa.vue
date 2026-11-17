<template>
  <nav class="cambio-tappa" aria-label="Continua il giro">
    <RouterLink v-if="prima" :to="prima.percorso" class="cambio-tappa__voce cambio-tappa__voce--prima">
      <span class="cambio-tappa__verso">Tappa precedente</span>
      <span class="cambio-tappa__nome">{{ prima.etichetta }}</span>
    </RouterLink>
    <RouterLink v-if="dopo" :to="dopo.percorso" class="cambio-tappa__voce cambio-tappa__voce--dopo">
      <span class="cambio-tappa__verso">Prossima tappa</span>
      <span class="cambio-tappa__nome">{{ dopo.etichetta }}</span>
    </RouterLink>
  </nav>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { TAPPE, indiceTappa } from '../percorso.js'

const route = useRoute()
const i = computed(() => indiceTappa(route.name))
const prima = computed(() => TAPPE[i.value - 1])
const dopo = computed(() => TAPPE[i.value + 1])
</script>
