<template>
  <div class="pagina pagina--tappa">
    <TestaTappa>
      <template #titolo>Il tuo giardino, aiuola per aiuola</template>
      Nell'app il giardino è diviso come lo vivi tu: le zone, le aiuole dentro le zone, e in ognuna le
      sue piante. Da lì partono le cure, le foto e i lavori che hai in mente.
    </TestaTappa>

    <Blocco id="b-zone" icona="zona-recinto" titolo="Zone e sottozone">
      <p>
        Una zona è una parte del giardino che riconosci a colpo d'occhio: davanti casa, il retro, il
        terrazzo, l'orto. Dentro una zona metti le sottozone, cioè le aiuole, i filari, il gruppo di vasi
        vicino alla porta.
      </p>
      <p>
        Ogni pianta sta in una sottozona e sa se è coltivata in terra, in vaso o in acqua. Quando sposti
        il limone dal terrazzo alla serra d'inverno, lo sposti anche nell'app.
      </p>
      <template #tavola><TavolaTaccuino /></template>
    </Blocco>

    <Blocco id="b-pianta" icona="cornice" titolo="La pagina di ogni pianta">
      <p>
        Ogni pianta ha la sua scheda botanica, le cure registrate, le foto che le hai fatto nel tempo e le
        note che vuoi tenere: quando l'hai messa a dimora, da quale vivaio viene, come ha passato l'inverno.
      </p>
      <p>
        Le foto si caricano dal telefono e vengono ridotte e alleggerite prima di partire, senza la
        posizione GPS. Sfogliandole una dopo l'altra vedi la pianta crescere.
      </p>
    </Blocco>

    <Blocco id="b-progetti" icona="calendario" titolo="I progetti, divisi in tappe">
      <p>
        Rifare un'aiuola, preparare l'orto d'estate, rinvasare le piante del terrazzo: un lavoro grande
        diventa un progetto con le sue tappe e le sue date. Segni ogni tappa quando è fatta e l'app ti
        ricorda la prossima.
      </p>
      <p>
        Se non sai da dove cominciare puoi chiederlo a Zorba, che propone le tappe guardando le piante
        che hai già e la stagione, e le salva come progetto.
      </p>
      <template #tavola>
        <figure class="tavola tavola--progetto">
          <span class="etichetta-esempio">Esempio</span>
          <p class="progetto__nome">Rifare l'aiuola delle aromatiche</p>
          <ol class="progetto__tappe">
            <li v-for="t in tappe" :key="t.nome" :class="{ 'is-fatta': t.fatta }">
              <span class="progetto__segno" aria-hidden="true"></span>
              <span class="progetto__tappa">{{ t.nome }}</span>
              <span class="progetto__quando">{{ t.quando }}</span>
            </li>
          </ol>
        </figure>
      </template>
    </Blocco>

    <Blocco id="b-meteo" icona="meteo" titolo="Il meteo del tuo giardino">
      <p>
        Indichi dove si trova il giardino e l'app mostra il tempo di lì: le previsioni dei prossimi
        giorni e la pioggia caduta o in arrivo, che conta quando decidi se irrigare. Dalla posizione ricava anche la zona climatica, che puoi
        correggere a mano se il tuo angolo è più riparato o più esposto del resto della zona.
      </p>
    </Blocco>

    <ProssimaTappa />
  </div>
</template>

<script setup>
import { usePagina } from '../seo.js'
import TestaTappa from '../components/TestaTappa.vue'
import Blocco from '../components/Blocco.vue'
import TavolaTaccuino from '../components/TavolaTaccuino.vue'
import ProssimaTappa from '../components/ProssimaTappa.vue'

usePagina({
  titolo: 'Zone, piante e progetti · Zorba in giardino',
  descrizione: "Con Zorba in giardino dividi il giardino in zone e aiuole, tieni per ogni pianta scheda, cure, foto e note, organizzi i lavori in progetti a tappe e segui il meteo del tuo giardino.",
  percorso: '/aiuole/',
})

const tappe = [
  { nome: 'Togliere la salvia secca e vangare', quando: '3 marzo', fatta: true },
  { nome: 'Aggiungere sabbia e compost', quando: '10 marzo', fatta: true },
  { nome: 'Mettere a dimora lavanda e timo', quando: '24 marzo', fatta: false },
  { nome: 'Pacciamare con corteccia', quando: '7 aprile', fatta: false },
]
</script>
