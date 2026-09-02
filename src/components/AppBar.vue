<template>
  <header class="appbar">
    <span class="appbar__mark">
      <ZorbaLogo mini />
      Il Giardino di Zorba
    </span>
    <span class="appbar__actions">
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
