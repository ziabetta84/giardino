<template>
  <figure class="tavola tavola--taccuino">
    <span class="etichetta-esempio">Esempio</span>
    <p class="taccuino__zona">Davanti casa</p>
    <template v-for="s in sottozone" :key="s.nome">
      <p class="taccuino__sottozona">{{ s.nome }}</p>
      <ul class="taccuino__piante">
        <li v-for="p in s.piante" :key="p[0]">
          <span class="nome">{{ p[0] }}</span> <i>{{ p[1] }}</i> <span class="dove">{{ p[2] }}</span>
        </li>
      </ul>
    </template>
  </figure>
</template>

<script setup>
const sottozone = [
  { nome: 'Aiuola delle aromatiche', piante: [
    ['Lavanda', 'Lavandula angustifolia', 'in terra'],
    ['Rosmarino', 'Salvia rosmarinus', 'in terra'],
    ['Salvia', 'Salvia officinalis', 'in terra'],
  ] },
  { nome: 'Vasi sul terrazzo', piante: [
    ['Limone', 'Citrus limon', 'in vaso'],
    ['Basilico', 'Ocimum basilicum', 'in vaso'],
  ] },
]
</script>
