<template>
  <nav class="cambio-tappa" aria-label="Continua il giro">
    <RouterLink v-if="prima" :to="prima.percorso" class="cambio-tappa__voce cambio-tappa__voce--prima">
      <Tessera :icona="prima.icona" :colore="prima.colore" />
      <span class="cambio-tappa__testo">
        <span class="cambio-tappa__verso">Tappa precedente</span>
        <span class="cambio-tappa__nome">{{ prima.etichetta }}</span>
      </span>
    </RouterLink>
    <RouterLink v-if="dopo" :to="dopo.percorso" class="cambio-tappa__voce cambio-tappa__voce--dopo">
      <span class="cambio-tappa__testo">
        <span class="cambio-tappa__verso">Prossima tappa</span>
        <span class="cambio-tappa__nome">{{ dopo.etichetta }}</span>
      </span>
      <Tessera :icona="dopo.icona" :colore="dopo.colore" />
    </RouterLink>
  </nav>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { TAPPE, indiceTappa } from '../percorso.js'
import Tessera from './Tessera.vue'

const route = useRoute()
const i = computed(() => indiceTappa(route.name))
const prima = computed(() => TAPPE[i.value - 1])
const dopo = computed(() => TAPPE[i.value + 1])
</script>
