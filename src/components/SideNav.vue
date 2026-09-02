<template>
  <nav class="sidebar">
    <span class="sidebar__mark">
      <ZorbaLogo mini />
      Il Giardino di Zorba
    </span>

    <RouterLink to="/" exact-active-class="on">
      <Icon name="casa" /><span>Home</span>
    </RouterLink>
    <RouterLink to="/meteo" active-class="on">
      <Icon name="meteo" /><span>Meteo</span>
    </RouterLink>
    <RouterLink to="/zone" active-class="on">
      <Icon name="pin" /><span>Zone</span>
    </RouterLink>
    <RouterLink to="/piante" active-class="on">
      <Icon name="foglia" /><span>Piante</span>
    </RouterLink>
    <RouterLink to="/progetti" active-class="on">
      <Icon name="lampadina" /><span>Progetti</span>
    </RouterLink>
    <RouterLink to="/concimi" active-class="on">
      <Icon name="provetta" /><span>Concimi</span>
    </RouterLink>
    <RouterLink to="/attivita" active-class="on">
      <Icon name="campanella" /><span>Attività</span>
    </RouterLink>
    <RouterLink to="/agente" active-class="on">
      <Icon name="gatto" class="is-zorba" /><span>Zorba dice</span>
    </RouterLink>
    <RouterLink to="/gallery" active-class="on">
      <Icon name="cornice" /><span>Gallery</span>
    </RouterLink>

    <span class="sidebar__spacer"></span>

    <RouterLink to="/impostazioni" active-class="on">
      <Icon name="chiave" /><span>Impostazioni</span>
    </RouterLink>
    <RouterLink to="/account" active-class="on">
      <Icon name="persona" /><span>Account</span>
    </RouterLink>
  </nav>
</template>

<script setup>
import Icon from '@/components/Icon.vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
</script>
