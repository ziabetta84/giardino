<template>
  <ZorbaSimboli />
  <IconDefs />
  <a class="salta" href="#contenuto">Vai al contenuto</a>

  <header class="testata" :class="{ 'is-staccata': staccata }">
    <div class="testata__riga">
      <RouterLink class="marchio" to="/" aria-label="Zorba in giardino, il giro">
        <Zorba class="zorba--mini" />
        <span class="marchio__nome">Zorba in giardino</span>
      </RouterLink>
      <NavSentiero class="testata__nav" />
      <a class="bottone bottone--piccolo" :href="APP">Apri l'app</a>
    </div>
  </header>

  <main id="contenuto" tabindex="-1">
    <RouterView v-slot="{ Component, route }">
      <Transition :name="verso" mode="out-in" @after-enter="annuncia">
        <component :is="Component" :key="route.path" :class="`tinta--${tappa(route.name).colore}`" />
      </Transition>
    </RouterView>
  </main>

  <footer class="piede">
    <p class="piede__nome">Zorba in giardino</p>
    <ul class="piede__voci">
      <li><a :href="APP">Apri l'app</a></li>
      <li><RouterLink to="/domande/">Domande frequenti</RouterLink></li>
      <li><a :href="PRIVACY">Privacy e note legali</a></li>
      <li><a :href="KOFI" target="_blank" rel="noopener">Sostieni su Ko-fi</a></li>
    </ul>
  </footer>
  <p class="vh" aria-live="polite">{{ annuncio }}</p>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'
import { APP, PRIVACY, KOFI, indiceTappa, tappa } from './percorso.js'
import ZorbaSimboli from './components/ZorbaSimboli.vue'
import IconDefs from '@app/components/IconDefs.vue'
import Zorba from './components/Zorba.vue'
import NavSentiero from './components/NavSentiero.vue'

const router = useRouter()

// Avanti lungo il sentiero la pagina nuova arriva da destra, indietro da sinistra.
const verso = ref('avanti')
router.beforeEach((to, from) => {
  verso.value = indiceTappa(to.name) >= indiceTappa(from.name) ? 'avanti' : 'indietro'
})

// Chi usa un lettore di schermo sente il nome della pagina nuova, e il focus
// torna all'inizio del contenuto.
const annuncio = ref('')
function annuncia() {
  annuncio.value = document.title
  document.getElementById('contenuto')?.focus({ preventScroll: true })
}

// La testata prende il filetto solo quando la pagina scorre sotto di lei.
const staccata = ref(false)
const guarda = () => { staccata.value = window.scrollY > 8 }
onMounted(() => { guarda(); window.addEventListener('scroll', guarda, { passive: true }) })
onBeforeUnmount(() => window.removeEventListener('scroll', guarda))
</script>
