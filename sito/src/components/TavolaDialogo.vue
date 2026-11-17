<template>
  <figure class="tavola tavola--dialogo">
    <span class="etichetta-esempio">Esempio di risposta</span>
    <p class="dialogo__domanda">Il limone in vaso ha le foglie gialle, a partire da quelle più vecchie. Cosa può essere?</p>
    <div class="dialogo__risposta">
      <Zorba class="zorba--voce" />
      <div>
        <p class="dialogo__chi">Zorba</p>
        <p>
          L'ultima concimazione che hai segnato risale a cinque settimane fa, e d'estate un agrume in
          vaso ne vuole una ogni due o tre. Se il giallo parte dalle foglie vecchie e prende anche le
          nervature, è probabile che manchi azoto.
        </p>
        <p>
          Se invece le nervature restano verdi, guarda l'acqua: un ristagno dà un ingiallimento simile.
          Il vaso ha i fori sul fondo? Dimmelo e restringiamo il campo.
        </p>
      </div>
    </div>
  </figure>
</template>

<script setup>
import Zorba from './Zorba.vue'
</script>
