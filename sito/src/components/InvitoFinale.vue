<template>
  <div class="invito">
    <div class="azioni azioni--centro">
      <a class="bottone" :href="REGISTRATI">Crea il tuo giardino</a>
      <a class="bottone bottone--secondario" :href="KOFI" target="_blank" rel="noopener">
        <svg viewBox="0 0 256 256" aria-hidden="true"><use href="#i-erba-gatta" /></svg>
        Dona un ciuffo d'erba gatta
      </a>
    </div>
    <p class="invito__nota">
      Zorba in giardino è un progetto indipendente. Se ti è utile puoi sostenerlo su Ko-fi:
      non è un abbonamento, scegli tu quanto.
    </p>
  </div>
</template>

<script setup>
import { REGISTRATI, KOFI } from '../percorso.js'
</script>
