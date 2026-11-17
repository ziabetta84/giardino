<template>
  <nav class="nav-sentiero" aria-label="Le tappe del giro">
    <div ref="striscia" class="nav-sentiero__striscia">
      <ol class="nav-sentiero__tappe">
        <li v-for="t in TAPPE" :key="t.nome">
          <RouterLink :to="t.percorso" class="nav-sentiero__voce" :data-tappa="t.nome"
                      :aria-current="t.nome === attiva ? 'page' : undefined">
            <Tessera class="nav-sentiero__tessera" :icona="t.icona" :colore="t.colore" misura="piccola" />
            <span class="nav-sentiero__nome">{{ t.etichetta }}</span>
          </RouterLink>
        </li>
      </ol>
    </div>
  </nav>
</template>

<script setup>
import { ref, computed, watch, onMounted, nextTick } from 'vue'
import { useRoute } from 'vue-router'
import { TAPPE } from '../percorso.js'
import Tessera from './Tessera.vue'

// Il menu: una tessera ad acquerello per pagina, ognuna nel suo colore; quella
// della pagina aperta ha il suo fondo. Sul telefono la striscia scorre e la
// tessera della pagina resta in vista.
const route = useRoute()
const attiva = computed(() => route.name)
const striscia = ref(null)

function mostra(animato) {
  const s = striscia.value
  if (!s || s.scrollWidth <= s.clientWidth) return
  const voce = s.querySelector(`[data-tappa="${attiva.value}"]`)
  if (!voce) return
  const fermo = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  const sinistra = voce.offsetLeft - (s.clientWidth - voce.offsetWidth) / 2
  s.scrollTo({ left: sinistra, behavior: animato && !fermo ? 'smooth' : 'auto' })
}

watch(attiva, () => nextTick(() => mostra(true)))
onMounted(() => mostra(false))
</script>
