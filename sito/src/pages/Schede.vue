<template>
  <div class="pagina pagina--tappa">
    <TestaTappa>
      <template #titolo>Una scheda per ogni pianta, in italiano</template>
      Il catalogo dell'app ha oltre 14.500 schede di specie e generi e quasi 200.000 cultivar. Quando
      aggiungi una pianta la cerchi per nome comune o scientifico, e la sua scheda ti segue da lì in poi.
    </TestaTappa>

    <Blocco id="b-scheda" titolo="Che cosa c'è in una scheda">
      <p>
        Una descrizione della pianta, le sue esigenze di luce, acqua e terreno, e le cure stagione per
        stagione: ogni quanto irrigare, quando concimare, come e quando potare. Dove serve ci sono gli
        avvisi, per esempio se la pianta è tossica per gli animali di casa.
      </p>
      <p>
        Sono le stesse indicazioni da cui l'app calcola le tue cure: se la scheda dice che d'estate la
        lavanda vuole acqua ogni 7-10 giorni, è lì che l'app ti ricorderà di bagnarla.
      </p>
      <template #tavola><TavolaScheda /></template>
    </Blocco>

    <Blocco id="b-prosa" titolo="Scritte come un'enciclopedia, non tradotte">
      <p>
        Le schede vengono da cataloghi botanici in lingua inglese e sono state riscritte una per una in
        un italiano da enciclopedia di giardinaggio: frasi intere, termini corretti, misure in metri e
        temperature in gradi. Dove l'originale diceva «gruppo di potatura 1», la scheda dice che cosa
        fare in pratica: togliere solo i rami secchi o rovinati, dopo la fioritura.
      </p>
    </Blocco>

    <Blocco id="b-nomi" titolo="I nomi giusti, anche quando cambiano">
      <p>
        I nomi scientifici seguono il <strong>Catalogue of Life</strong>, il riferimento internazionale
        per la classificazione delle specie. Quando i botanici spostano una pianta in un altro genere, la
        trovi comunque cercando il nome che conoscevi, e la scheda ti dice com'era nota prima.
      </p>
      <p>
        Accanto al nome scientifico ci sono i nomi comuni italiani, quello più usato in evidenza e gli
        altri come «detta anche».
      </p>
      <template #tavola>
        <figure class="tavola tavola--nome">
          <p class="nome-voce__nome"><i>Phedimus spurius</i> 'Tricolor'</p>
          <p class="nome-voce__prima">Già nota come <i>Sedum spurium</i> 'Tricolor'</p>
          <p class="nome-voce__nome"><i>Salvia rosmarinus</i></p>
          <p class="nome-voce__prima">Rosmarino · lo trovi anche cercando <i>Rosmarinus officinalis</i></p>
          <figcaption class="mano tavola__nota">due piante che hanno cambiato genere</figcaption>
        </figure>
      </template>
    </Blocco>

    <Blocco id="b-cultivar" titolo="Le cultivar ereditano le cure">
      <p>
        Una cultivar, come la rosa 'Gertrude Jekyll' o il pomodoro 'San Marzano', ha il suo nome e a
        volte la sua descrizione, ma quasi sempre si cura come la specie da cui viene. Quando una
        cultivar non ha un dato proprio, la scheda lo prende dalla specie o dal genere e lo dice
        chiaramente, per esempio «Cure del genere <i>Hedera</i>».
      </p>
    </Blocco>

    <Blocco id="b-limiti" titolo="Indicazioni generali, non una ricetta">
      <p>
        Una scheda descrive come si coltiva bene una specie in condizioni normali. Non conosce il tuo
        terreno, l'esposizione del tuo balcone o il vento che arriva dal mare: le cadenze sono un punto di
        partenza, e la pianta che hai davanti resta il riferimento migliore.
      </p>
    </Blocco>

    <ProssimaTappa />
  </div>
</template>

<script setup>
import { usePagina } from '../seo.js'
import TestaTappa from '../components/TestaTappa.vue'
import Blocco from '../components/Blocco.vue'
import TavolaScheda from '../components/TavolaScheda.vue'
import ProssimaTappa from '../components/ProssimaTappa.vue'

usePagina({
  titolo: 'Le schede delle piante · Zorba in giardino',
  descrizione: "Oltre 14.500 schede botaniche in italiano e quasi 200.000 cultivar: descrizione, esigenze e cure stagione per stagione, con i nomi scientifici del Catalogue of Life e i nomi comuni italiani.",
  percorso: '/schede/',
})
</script>
