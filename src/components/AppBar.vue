<template>
  <header class="appbar">
    <span class="appbar__mark">
      <ZorbaLogo mini />
      Zorba in giardino
    </span>
    <span class="appbar__actions">
      <RouterLink class="appbar__btn" to="/feedback" aria-label="Scrivi a chi costruisce l'app" title="Scrivi a chi costruisce l'app">
        <Icon name="matita" />
      </RouterLink>
      <RouterLink class="appbar__btn" to="/account" aria-label="Account">
        <Icon name="persona" />
      </RouterLink>
    </span>
  </header>
</template>

<script setup>
import Icon from '@/components/Icon.vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
</script>
