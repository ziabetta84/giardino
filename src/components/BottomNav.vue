<template>
  <nav class="bottomnav">
    <RouterLink to="/" exact-active-class="on">
      <span class="bn-ic"><Icon name="casa" /></span>
      Home
    </RouterLink>
    <RouterLink to="/zone" active-class="on">
      <span class="bn-ic"><Icon name="pin" /></span>
      Zone
    </RouterLink>
    <RouterLink to="/piante" active-class="on">
      <span class="bn-ic"><Icon name="foglia" /></span>
      Piante
    </RouterLink>
    <RouterLink to="/concimi" active-class="on">
      <span class="bn-ic"><Icon name="provetta" /></span>
      Concimi
    </RouterLink>
    <RouterLink to="/attivita" active-class="on">
      <span class="bn-ic"><Icon name="campanella" /></span>
      Attività
    </RouterLink>
    <RouterLink to="/agente" active-class="on">
      <span class="bn-ic is-zorba"><Icon name="gatto" /></span>
      Zorba dice
    </RouterLink>
  </nav>
</template>

<script setup>
import Icon from '@/components/Icon.vue'
</script>

<style scoped>
/* La barra vive fissa in fondo alla finestra (le classi visive .bottomnav /
   .bn-ic stanno in main.css); su schermi larghi lascia il posto alla sidebar. */
.bottomnav {
  position: fixed; bottom: 0; left: 0; right: 0; z-index: 60;
}
@media (min-width: 640px) {
  .bottomnav { display: none; }
}
</style>
