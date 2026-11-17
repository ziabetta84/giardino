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
      <span class="nav-sentiero__zorba" :class="{ 'is-pronto': pronto, 'is-cammina': cammina, 'is-indietro': indietro }"
            :style="{ transform: `translateX(${x}px)` }" aria-hidden="true">
        <span class="nav-sentiero__passo"><Zorba /></span>
      </span>
    </div>
  </nav>
</template>

<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { useRoute } from 'vue-router'
import { TAPPE } from '../percorso.js'
import Zorba from './Zorba.vue'
import Tessera from './Tessera.vue'

// Il menu: una tessera ad acquerello per pagina, ognuna nel suo colore; il
// piccolo Zorba cammina fino a quella della pagina aperta, e si gira quando torni indietro.
const route = useRoute()
const attiva = computed(() => route.name)
const striscia = ref(null)
const x = ref(0)
const pronto = ref(false)
const cammina = ref(false)
const indietro = ref(false)
let fine = 0

function posizione() {
  const voce = striscia.value?.querySelector(`[data-tappa="${attiva.value}"] .nav-sentiero__tessera`)
  if (!voce) return null
  const base = striscia.value.getBoundingClientRect()
  const r = voce.getBoundingClientRect()
  return r.left - base.left + striscia.value.scrollLeft + r.width / 2
}

function vai(animato) {
  const nuova = posizione()
  if (nuova == null) return
  const fermo = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  if (animato && !fermo && Math.abs(nuova - x.value) > 2) {
    indietro.value = nuova < x.value
    cammina.value = true
    clearTimeout(fine)
    fine = setTimeout(() => { cammina.value = false }, 720)
  }
  x.value = nuova
  // Sul telefono la striscia scorre: la tessera della pagina resta in vista.
  const s = striscia.value
  if (s.scrollWidth > s.clientWidth) {
    const voce = s.querySelector(`[data-tappa="${attiva.value}"]`)
    const sinistra = voce.offsetLeft - (s.clientWidth - voce.offsetWidth) / 2
    s.scrollTo({ left: sinistra, behavior: animato && !fermo ? 'smooth' : 'auto' })
  }
}

const riallinea = () => vai(false)
watch(attiva, () => nextTick(() => vai(true)))
onMounted(async () => {
  await document.fonts?.ready
  vai(false)
  requestAnimationFrame(() => { pronto.value = true })
  window.addEventListener('resize', riallinea)
})
onBeforeUnmount(() => window.removeEventListener('resize', riallinea))
</script>
