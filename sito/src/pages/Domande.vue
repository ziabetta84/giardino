<template>
  <div class="pagina pagina--tappa">
    <TestaTappa>
      <template #titolo>Domande frequenti</template>
      Le risposte brevi a quello che chiede di solito chi scopre l'app. Per il resto, la cosa più semplice è
      provarla.
    </TestaTappa>

    <div class="domande">
      <details v-for="(q, i) in DOMANDE" :key="q.d" class="domanda" :open="i === 0">
        <summary>{{ q.d }}</summary>
        <p>{{ q.r }}</p>
      </details>
    </div>

    <section class="cancello cancello--fine" aria-labelledby="t-inizia">
      <Zorba class="zorba--grande" etichetta="Zorba, un gatto nero" />
      <div class="cancello__testo">
        <h2 id="t-inizia" class="cancello__titolo">Il giro finisce qui</h2>
        <p>Il resto lo scopri nel tuo giardino.</p>
        <InvitoFinale />
      </div>
    </section>

    <ProssimaTappa />
  </div>
</template>

<script setup>
import { usePagina } from '../seo.js'
import { DOMANDE } from '../domande.js'
import Zorba from '../components/Zorba.vue'
import TestaTappa from '../components/TestaTappa.vue'
import InvitoFinale from '../components/InvitoFinale.vue'
import ProssimaTappa from '../components/ProssimaTappa.vue'

usePagina({
  titolo: 'Domande frequenti · Zorba in giardino',
  descrizione: "Quanto costa Zorba in giardino, se va installata, se va bene per orto e vasi, da dove vengono le schede, quanto fidarsi di Zorba e che fine fanno i tuoi dati.",
  percorso: '/domande/',
  jsonld: {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: DOMANDE.map((q) => ({ '@type': 'Question', name: q.d, acceptedAnswer: { '@type': 'Answer', text: q.r } })),
  },
})
</script>
