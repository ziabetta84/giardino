<template>
  <figure class="tavola tavola--cure">
    <span class="etichetta-esempio">Esempio</span>
    <p class="cure__titolo">Da fare oggi</p>
    <TransitionGroup tag="ul" name="cura" class="cure__elenco">
      <li v-for="c in cure" :key="c.nome" class="cura" :class="{ 'cura--urgente': c.urgente && !c.fatta, 'is-fatta': c.fatta }">
        <svg class="cura__icona" :class="`cura__icona--${c.colore}`" viewBox="0 0 256 256" aria-hidden="true"><use :href="`#i-${c.icona}`" /></svg>
        <span class="cura__testo">
          <span class="nome">{{ c.nome }}</span>
          <span class="cura__cosa">{{ c.tipo }} · {{ c.fatta ? 'registrata oggi' : c.stato }}</span>
        </span>
        <button type="button" class="fatto" :aria-pressed="c.fatta" @click="c.fatta = !c.fatta">
          {{ c.fatta ? 'Segnata' : 'Fatto' }}
        </button>
      </li>
    </TransitionGroup>
    <figcaption class="mano tavola__nota">prova a segnarne una</figcaption>
  </figure>
</template>

<script setup>
import { reactive } from 'vue'

// Tavola dimostrativa: «Fatto» segna la cura come nell'app, e la riga si sposta in fondo.
const cure = reactive([
  { nome: 'Lavanda', tipo: 'Irrigazione', stato: "l'ultima 12 giorni fa", icona: 'goccia', colore: 'acqua', fatta: false },
  { nome: 'Limone', tipo: 'Concimazione', stato: "l'ultima 5 settimane fa", icona: 'concimazione', colore: 'olive', fatta: false },
  { nome: "Rosa 'Gertrude Jekyll'", tipo: 'Potatura', stato: 'in ritardo di 6 giorni', icona: 'potatura', colore: 'rose', urgente: true, fatta: false },
])
</script>
