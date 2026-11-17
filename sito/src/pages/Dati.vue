<template>
  <div class="pagina pagina--tappa">
    <TestaTappa>
      <template #titolo>Il giardino resta tuo</template>
      Le tue piante, le tue foto e le tue domande a Zorba le vedi solo tu. L'app vive del lavoro di chi
      la fa e del sostegno di chi la usa, non dei tuoi dati.
    </TestaTappa>

    <Blocco id="b-promesse" icona="chiave" titolo="Quattro cose che non cambiano">
      <Promesse />
    </Blocco>

    <Blocco id="b-dove" icona="pin" titolo="Dove stanno">
      <p>
        Il database, gli account e le foto stanno su server nell'Unione europea, a Stoccolma. Ogni
        persona vede solo il proprio giardino: la separazione è nel database stesso, non solo
        nell'app.
      </p>
      <p>
        Non ci sono statistiche di visita né cookie di profilazione. Il browser tiene solo quello che
        serve a farti restare collegato, il tema chiaro o scuro e una copia del giardino per usarlo
        senza rete. Per questo non vedi banner sui cookie.
      </p>
    </Blocco>

    <Blocco id="b-chi" icona="persona" titolo="A chi passano, e perché">
      <p>I dati non vengono diffusi. Li ricevono solo i servizi che fanno funzionare l'app, ciascuno per la sua parte:</p>
      <ul class="fornitori">
        <li v-for="f in fornitori" :key="f.nome"><strong>{{ f.nome }}</strong> {{ f.cosa }}</li>
      </ul>
    </Blocco>

    <Blocco id="b-fine" icona="zona-sentiero" titolo="Se vuoi andartene">
      <p>
        Puoi cancellare quando vuoi una pianta, una foto o una conversazione con Zorba. Eliminando
        l'account dalla sua pagina sparisce tutto, foto comprese, e prima di confermare l'app ti mostra
        l'elenco di quello che verrà cancellato.
      </p>
      <p>
        Tutti i dettagli sono nell'<a :href="PRIVACY">informativa sulla privacy</a>.
      </p>
    </Blocco>

    <ProssimaTappa />
  </div>
</template>

<script setup>
import { PRIVACY } from '../percorso.js'
import { usePagina } from '../seo.js'
import TestaTappa from '../components/TestaTappa.vue'
import Blocco from '../components/Blocco.vue'
import Promesse from '../components/Promesse.vue'
import ProssimaTappa from '../components/ProssimaTappa.vue'

usePagina({
  titolo: 'I tuoi dati e la privacy · Zorba in giardino',
  descrizione: "Zorba in giardino non ha pubblicità né profilazione: i dati stanno su server nell'Unione europea, non vengono venduti né usati per addestrare intelligenze artificiali, e si cancellano con l'account.",
  percorso: '/dati/',
})

// Gli stessi fornitori dell'informativa (src/views/PrivacyView.vue): se cambia lì, cambia qui.
const fornitori = [
  { nome: 'Supabase:', cosa: "database, account e foto, su server nell'Unione europea." },
  { nome: 'Cloudflare:', cosa: "ospita l'app e fa la verifica anti-robot." },
  { nome: 'Anthropic:', cosa: "il modello di intelligenza artificiale che scrive le risposte di Zorba; riceve la domanda, le foto e i dati del giardino che servono a rispondere." },
  { nome: 'Pl@ntNet:', cosa: 'riconosce le piante dalle foto mandate a Zorba.' },
  { nome: 'Brevo:', cosa: "spedisce le mail dell'account." },
  { nome: 'Open-Meteo e OpenStreetMap:', cosa: 'ricevono la posizione del giardino, per il meteo e la mappa.' },
]
</script>
