<template>
  <div class="pagina pagina--tappa">
    <TestaTappa>
      <template #titolo>Zorba risponde sulle tue piante</template>
      Zorba è l'assistente dell'app. Gli scrivi come scriveresti a un amico che se ne intende, anche con
      una foto, e lui risponde partendo da quello che sa del tuo giardino.
    </TestaTappa>

    <Blocco id="b-legge" icona="lista" titolo="Prima legge, poi risponde">
      <p>
        Prima di scrivere, Zorba guarda le tue piante e dove stanno, le cure che hai registrato, i
        concimi che hai in dispensa, le schede del catalogo e il meteo del giardino. Per questo può dirti
        che l'ultima concimazione del limone risale a cinque settimane fa, invece di un generico
        «concima regolarmente».
      </p>
      <template #tavola><TavolaDialogo /></template>
    </Blocco>

    <Blocco id="b-chiedere" icona="lampadina" titolo="Che cosa puoi chiedergli">
      <dl class="domande-zorba">
        <div v-for="q in richieste" :key="q.titolo"><dt>{{ q.titolo }}</dt><dd>{{ q.testo }}</dd></div>
      </dl>
    </Blocco>

    <Blocco id="b-onesto" icona="allerta" titolo="Quando non è sicuro, lo dice">
      <p>
        Zorba è un assistente basato sull'intelligenza artificiale e può sbagliare. Quando i dati non
        bastano non tira a indovinare: ti dice che cosa gli manca e ti chiede un dettaglio, una foto in
        più, da quanto tempo succede. Su prodotti fitosanitari e trattamenti rimanda sempre
        all'etichetta.
      </p>
      <p>
        Ogni conversazione è una richiesta con poche repliche, fatta per arrivare a una risposta
        concreta e non per chiacchierare all'infinito.
      </p>
    </Blocco>

    <Blocco id="b-limiti" icona="erba-gatta" titolo="Tre risposte, per ora">
      <p>
        Ogni risposta di Zorba ha un costo reale, perché usa un modello di intelligenza artificiale
        a pagamento. Per questo, per ora, Zorba dà tre risposte a persona. Non ci sono abbonamenti: il
        resto dell'app, cure e schede comprese, è gratuito, e chi vuole può sostenere il progetto con una
        donazione su Ko-fi.
      </p>
    </Blocco>

    <Blocco id="b-nome" icona="zona-orma" titolo="Perché si chiama Zorba">
      <p>
        Zorba era un gatto nero, e riposa nel giardino dove quest'app è nata. Oggi presta il nome alla
        voce che ti risponde: dà del tu, tiene alla precisione e non ha fretta.
      </p>
    </Blocco>

    <ProssimaTappa />
  </div>
</template>

<script setup>
import { usePagina } from '../seo.js'
import TestaTappa from '../components/TestaTappa.vue'
import Blocco from '../components/Blocco.vue'
import TavolaDialogo from '../components/TavolaDialogo.vue'
import ProssimaTappa from '../components/ProssimaTappa.vue'

usePagina({
  titolo: "Zorba, l'assistente del giardino · Zorba in giardino",
  descrizione: "Zorba è l'assistente di Zorba in giardino: riconosce le piante dalle foto, aiuta a capire perché una pianta soffre, consiglia cure e concimi e prepara piani di lavoro, leggendo le piante, le cure e il meteo del tuo giardino.",
  percorso: '/zorba/',
})

const richieste = [
  { titolo: 'Che pianta è?', testo: "Mandi una foto e Zorba la riconosce, con l'aiuto di Pl@ntNet, e ti propone la scheda giusta per aggiungerla al giardino." },
  { titolo: 'Che cosa ha?', testo: 'Foglie gialle, macchie, rami che seccano: Zorba mette insieme la foto, le cure registrate e il meteo e ti dice le cause più probabili, in ordine.' },
  { titolo: 'Come la curo?', testo: 'Quanta acqua, quando potare, quale dei tuoi concimi usare e quando, per quella pianta e in quella stagione.' },
  { titolo: 'Come lo realizzo?', testo: "Un lavoro da fare in giardino diventa un piano a tappe, che puoi salvare come progetto." },
]
</script>
