<template>
  <Transition name="boot-fade">
    <div v-if="visibile" class="boot-overlay">
      <ZorbaLogo class="boot-logo" />
    </div>
  </Transition>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import { bootCompletato, splashInArrivo } from '@/composables/useBootSequence'

const visibile = ref(true)

onMounted(() => {
  // Quando sta per partire SplashAiuola.vue (fascia del saluto nuova, non
  // "riduci movimento"), il logo-solo da 3s diventerebbe una seconda
  // schermata d'ingresso subito prima di quella vera — ridondante e confuso
  // (verificato live 16/09/2026). Resta solo il tempo minimo per coprire il
  // primo paint della pagina; il resto del "benvenuto" lo fa la scena
  // dipinta dello splash, non questo logo da solo.
  const durata = splashInArrivo() ? 400 : 3000
  setTimeout(() => {
    visibile.value = false
    bootCompletato.value = true
  }, durata)
})
</script>

<style scoped>
.boot-overlay {
  position: fixed;
  inset: 0;
  z-index: 500; /* sopra tutto lo stack esistente (max precedente: .foglio a 321) */
  background: var(--cream);
  display: flex;
  align-items: center;
  justify-content: center;
}
.boot-logo {
  width: 140px;
  height: 140px;
}

.boot-fade-leave-active { transition: opacity 0.4s var(--ease-standard); }
.boot-fade-leave-to { opacity: 0; }
</style>
