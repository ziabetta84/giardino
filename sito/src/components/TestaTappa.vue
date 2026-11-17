<template>
  <header class="intesta">
    <Tessera :icona="t.icona" :colore="t.colore" misura="grande" />
    <h1 class="intesta__titolo"><slot name="titolo" /></h1>
    <p class="intesta__lede"><slot /></p>
  </header>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { tappa } from '../percorso.js'
import Tessera from './Tessera.vue'

const route = useRoute()
const t = computed(() => tappa(route.name))
</script>
