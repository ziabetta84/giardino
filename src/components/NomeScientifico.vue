<template>
  <!-- Nome scientifico, nello stesso stile del testo che lo contiene (17/11/2026, Roberta: niente corsivo, come prima
       con i nomi comuni). utils/nomeScientifico.js sa ancora dividere le parti in corsivo, se servisse di nuovo. -->
  <span class="nome-sci">{{ nome }}</span>
</template>

<script setup>
defineProps({ nome: { type: String, default: '' } })
</script>
