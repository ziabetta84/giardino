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

const visibile = ref(true)

onMounted(() => {
  // durata totale animazione: 3s, poi dissolvenza verso il contenuto dell'app
  setTimeout(() => {
    visibile.value = false
  }, 3000)
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

.boot-fade-leave-active { transition: opacity 0.4s ease; }
.boot-fade-leave-to { opacity: 0; }
</style>
