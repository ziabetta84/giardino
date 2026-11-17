<template>
  <figure class="tavola tavola--scheda">
    <p class="scheda__nome">Lavanda</p>
    <p class="scheda__latino"><i>Lavandula angustifolia</i></p>
    <ul class="scheda__esigenze" aria-label="Esigenze">
      <li>Pieno sole</li><li>Acqua scarsa</li><li>Terreno sabbioso</li>
    </ul>
    <blockquote class="scheda__descrizione">
      Arbusto aromatico compatto e cespuglioso, molto rustico, alto circa 1 m e leggermente più largo,
      con foglie strette, aromatiche, verde-grigio. Da metà a fine estate produce lunghi steli non
      ramificati che portano spighe corte e dense di fiori profumati, dal viola chiaro al viola intenso.
    </blockquote>
    <table class="scheda__stagioni">
      <caption>Le cure, stagione per stagione</caption>
      <thead>
        <tr><th scope="col"><span class="vh">Cura</span></th><th v-for="s in STAGIONI" :key="s" scope="col">{{ s }}</th></tr>
      </thead>
      <tbody>
        <tr v-for="r in righe" :key="r.cura" :class="r.classe">
          <th scope="row">{{ r.cura }}</th>
          <td v-for="(v, i) in r.valori" :key="i" :data-stagione="STAGIONI[i]">{{ v }}</td>
        </tr>
      </tbody>
    </table>
    <figcaption v-if="nota" class="mano tavola__nota">la scheda vera della lavanda</figcaption>
  </figure>
</template>

<script setup>
// Il testo e le cure sono quelli della scheda mostrata nell'app (catalogo, 17/11/2026).
defineProps({ nota: { type: Boolean, default: true } })
const STAGIONI = ['Primavera', 'Estate', 'Autunno', 'Inverno']
const righe = [
  { cura: 'Irrigazione', classe: 'riga-acqua', valori: ['ogni 10-14 giorni', 'ogni 7-10 giorni', 'ogni 14 giorni', 'nessuna'] },
  { cura: 'Concime', classe: 'riga-olive', valori: ['ogni 30 giorni', 'nessuno', 'sospeso', 'sospeso'] },
  { cura: 'Potatura', classe: 'riga-rose', valori: ['taglio leggero', 'taglio leggero', 'dopo la fioritura', 'nessuna'] },
]
</script>
