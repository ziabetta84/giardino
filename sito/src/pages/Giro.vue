<template>
  <div class="pagina">
    <section class="apertura" aria-labelledby="titolo">
      <div class="apertura__testo">
        <h1 id="titolo" class="apertura__titolo">Il diario del tuo giardino, che sa cosa fare e&nbsp;quando.</h1>
        <p class="apertura__lede">
          <strong>Zorba in giardino</strong> è un'app italiana e gratuita per chi cura un giardino, un orto
          o le piante del balcone. Segni le tue piante e lei ti dice quando irrigare, concimare e potare,
          secondo la specie e la stagione. Quando hai un dubbio, Zorba ti risponde guardando proprio le tue piante.
        </p>
        <div class="azioni">
          <a class="bottone" :href="REGISTRATI">Crea il tuo giardino</a>
          <a class="collegamento-giro" href="#giro">
            Fai il giro
            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 4v15m0 0-6-6m6 6 6-6" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
          </a>
        </div>
        <p class="apertura__nota">Si usa dal browser, su telefono e computer. Niente pubblicità.</p>
      </div>
      <figure class="apertura__tavola">
        <picture>
          <source media="(prefers-color-scheme: dark)" :srcset="hero.notte">
          <img :src="hero.giorno" width="1536" height="768" fetchpriority="high" :alt="hero.alt">
        </picture>
        <Zorba class="zorba--apertura" etichetta="Zorba, il gatto nero, sul bordo del giardino" />
        <figcaption class="mano apertura__didascalia">Zorba ti fa strada</figcaption>
      </figure>
    </section>

    <div id="giro" class="giro">

      <section class="tappa tinta--rose" aria-labelledby="t-aiuole">
        <div class="tappa__testo">
          <Tessera icona="zona-tulipano" colore="rose" misura="grande" />
          <h2 id="t-aiuole" class="tappa__titolo">Il tuo giardino, aiuola per aiuola</h2>
          <p>
            Dividi il giardino in zone e sottozone, come lo vivi davvero: davanti casa, l'orto, i vasi sul
            terrazzo. Ogni pianta ha il suo posto, la sua specie, le sue foto e la sua storia di cure, e
            sai sempre se sta in terra, in vaso o in acqua.
          </p>
          <RouterLink class="avanti" to="/aiuole/">Zone, piante e progetti<Freccia /></RouterLink>
        </div>
        <TavolaTaccuino v-rivela />
      </section>

      <section class="tappa tinta--olive" aria-labelledby="t-schede">
        <div class="tappa__testo">
          <Tessera icona="foglia" colore="olive" misura="grande" />
          <h2 id="t-schede" class="tappa__titolo">Una scheda per ogni pianta, in italiano</h2>
          <p>
            Quando aggiungi una pianta la scegli da un catalogo di <strong>oltre 14.500 schede</strong> e
            <strong>quasi 200.000 cultivar</strong>, dalla rosa 'Gertrude Jekyll' al pomodoro 'San Marzano'.
            Ogni scheda dice di che cosa ha bisogno la pianta, stagione per stagione.
          </p>
          <RouterLink class="avanti" to="/schede/">Come sono fatte le schede<Freccia /></RouterLink>
        </div>
        <TavolaScheda v-rivela />
      </section>

      <section class="tappa tinta--acqua" aria-labelledby="t-cure">
        <div class="tappa__testo">
          <Tessera icona="goccia" colore="acqua" misura="grande" />
          <h2 id="t-cure" class="tappa__titolo">Le cure, al momento giusto</h2>
          <p>
            L'app incrocia la scheda di ogni pianta con la stagione e con l'ultima volta che te ne sei
            occupato, e ti mostra cosa è da fare oggi. Fatta un'irrigazione, la segni con un tocco e il
            conto riparte.
          </p>
          <RouterLink class="avanti" to="/cure/">Cure, concimi e meteo<Freccia /></RouterLink>
        </div>
        <TavolaCure v-rivela />
      </section>

      <section class="tappa tinta--gold" aria-labelledby="t-zorba">
        <div class="tappa__testo">
          <Tessera icona="gatto" colore="gold" misura="grande" />
          <h2 id="t-zorba" class="tappa__titolo">Zorba risponde sulle tue piante</h2>
          <p>
            Zorba è l'assistente dell'app. Prima di rispondere legge le tue piante, le cure che hai
            registrato, i concimi che hai e il meteo: non ti dà un consiglio buono per chiunque, parte da
            quello che sa del tuo giardino. E quando non è sicuro, lo dice.
          </p>
          <RouterLink class="avanti" to="/zorba/">Che cosa sa fare Zorba<Freccia /></RouterLink>
        </div>
        <TavolaDialogo v-rivela />
      </section>

      <div class="altro" role="region" aria-labelledby="t-altro">
        <h2 id="t-altro" class="altro__titolo">E poi, tutto il resto</h2>
        <p class="altro__lede">Il diario e le cure sono il cuore dell'app. Intorno ci sono gli attrezzi per tutto quello che succede in giardino durante l'anno.</p>
        <ul class="altro__elenco">
          <li v-for="f in funzioni" :key="f.nome" :class="`tinta--${f.colore}`">
            <RouterLink class="altro__voce" :to="f.dove">
              <Tessera :icona="f.icona" :colore="f.colore" />
              <span>
                <span class="altro__nome">{{ f.nome }}</span>
                <span class="altro__testo">{{ f.testo }}</span>
              </span>
            </RouterLink>
          </li>
        </ul>
      </div>

      <section class="tappa tappa--quieta tinta--uovo" aria-labelledby="t-dati">
        <div class="tappa__testo">
          <Tessera icona="chiave" colore="uovo" misura="grande" />
          <h2 id="t-dati" class="tappa__titolo">Il giardino resta tuo</h2>
          <p>
            Le tue piante, le tue foto e le tue domande le vedi solo tu. L'app vive del lavoro di chi la fa
            e del sostegno di chi la usa, non dei tuoi dati.
          </p>
          <RouterLink class="avanti" to="/dati/">Dove stanno i tuoi dati<Freccia /></RouterLink>
        </div>
        <Promesse v-rivela />
      </section>

      <section class="cancello" aria-labelledby="t-zorba-gatto">
        <figure class="ritratto">
          <img :src="foto480" :srcset="`${foto480} 480w, ${foto900} 900w`" sizes="(min-width: 900px) 300px, 62vw"
               width="1080" height="1350" loading="lazy" decoding="async"
               alt="Zorba, un gatto nero con gli occhi verdi e la coda dritta, cammina sul muretto di pietra accanto al prato del giardino.">
          <figcaption class="mano">Zorba, nel suo giardino</figcaption>
        </figure>
        <div class="cancello__testo">
          <h2 id="t-zorba-gatto" class="cancello__titolo">Chi è Zorba</h2>
          <p>
            Zorba era un gatto nero, e riposa nel giardino dove quest'app è nata. Oggi presta il nome alla
            voce che ti risponde: dà del tu, tiene alla precisione e, quando non è sicuro, lo dice.
          </p>
          <InvitoFinale />
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { HERO, stagioneDi } from '../stagioni.js'
import Tessera from '../components/Tessera.vue'
import foto480 from '../assets/zorba-in-giardino-480.webp'
import foto900 from '../assets/zorba-in-giardino-900.webp'
import { REGISTRATI } from '../percorso.js'
import { usePagina } from '../seo.js'
import Zorba from '../components/Zorba.vue'
import Freccia from '../components/Freccia.vue'
import TavolaTaccuino from '../components/TavolaTaccuino.vue'
import TavolaScheda from '../components/TavolaScheda.vue'
import TavolaCure from '../components/TavolaCure.vue'
import TavolaDialogo from '../components/TavolaDialogo.vue'
import Promesse from '../components/Promesse.vue'
import InvitoFinale from '../components/InvitoFinale.vue'

const funzioni = [
  { nome: 'Progetti a tappe', icona: 'calendario', colore: 'rose', dove: '/aiuole/#b-progetti',
    testo: "Rifare un'aiuola o preparare l'orto diventa un progetto con le sue tappe e le sue date." },
  { nome: 'Che pianta è?', icona: 'fotocamera', colore: 'olive', dove: '/zorba/#b-chiedere',
    testo: 'Mandi una foto a Zorba, che riconosce la pianta e ti propone la scheda per aggiungerla.' },
  { nome: 'Che cosa ha?', icona: 'zona-insetto', colore: 'gold', dove: '/zorba/#b-chiedere',
    testo: 'Foglie gialle o macchie: dalla foto e dalle cure registrate, Zorba ti dice le cause più probabili.' },
  { nome: 'La dispensa dei concimi', icona: 'provetta', colore: 'sage', dove: '/cure/#b-concimi',
    testo: 'Segni i concimi che hai e l\'app ti dice per quali piante va bene ognuno.' },
  { nome: "L'irrigazione automatica", icona: 'goccia', colore: 'acqua', dove: '/cure/#b-impianto',
    testo: "Se hai un impianto, imposti ogni quanti giorni parte e quelle piante escono dalle cure da fare a mano." },
  { nome: 'Il meteo del giardino', icona: 'meteo', colore: 'uovo', dove: '/aiuole/#b-meteo',
    testo: 'Le previsioni e la pioggia di dove sta il tuo giardino, che contano quando decidi se irrigare.' },
  { nome: 'Le foto di ogni pianta', icona: 'cornice', colore: 'rose', dove: '/aiuole/#b-pianta',
    testo: 'Una galleria per pianta: sfogliandola la vedi crescere, stagione dopo stagione.' },
]

usePagina({
  titolo: "Zorba in giardino · l'app italiana per curare giardino, orto e balcone",
  descrizione: "App gratuita e senza pubblicità per tenere il diario del giardino: le tue piante con oltre 14.500 schede in italiano, le cure al momento giusto per specie e stagione, e Zorba, l'assistente che risponde guardando le tue piante.",
  percorso: '/',
  jsonld: {
    '@context': 'https://schema.org',
    '@graph': [
      { '@type': 'WebSite', '@id': 'https://zorbaingiardino.app/#sito', name: 'Zorba in giardino', url: 'https://zorbaingiardino.app/', inLanguage: 'it-IT' },
      {
        '@type': 'WebApplication',
        '@id': 'https://zorbaingiardino.app/#app',
        name: 'Zorba in giardino',
        url: 'https://zorbaingiardino.app/',
        applicationCategory: 'LifestyleApplication',
        applicationSubCategory: 'Giardinaggio',
        operatingSystem: 'Qualsiasi browser moderno (telefono, tablet, computer)',
        inLanguage: 'it-IT',
        isAccessibleForFree: true,
        offers: { '@type': 'Offer', price: '0', priceCurrency: 'EUR' },
        description: "App italiana per tenere il diario del proprio giardino, orto o balcone. Organizza le piante per zone, abbina ogni pianta a una scheda botanica in italiano, calcola quando irrigare, concimare e potare in base alla specie, alla stagione e all'ultima cura registrata, e offre Zorba, un assistente basato sull'intelligenza artificiale che risponde leggendo le piante, le cure, i concimi e il meteo dell'utente.",
        featureList: [
          'Piante organizzate per zone e sottozone, in vaso, in terra o in acqua',
          'Oltre 14.500 schede botaniche in italiano e quasi 200.000 cultivar',
          'Nomi scientifici allineati al Catalogue of Life',
          'Promemoria di irrigazione, concimazione e potatura per specie e stagione',
          "Programmi di irrigazione automatica per giardino, zona o pianta",
          'Dispensa dei concimi con abbinamento ai bisogni delle piante',
          'Progetti del giardino divisi in tappe',
          'Galleria fotografica per pianta e meteo del giardino',
          'Assistente Zorba: riconoscimento da foto, diagnosi, consigli di cura e concimazione, piani di progetto',
          'Consultabile anche senza connessione',
          "Nessuna pubblicità e nessuna profilazione; dati su server nell'Unione europea",
        ],
        screenshot: 'https://zorbaingiardino.app/scopri/anteprima.png',
      },
    ],
  },
})

// L'acquerello d'apertura segue la stagione, come la Home dell'app. L'HTML
// statico esce con la primavera; nel browser si passa alla stagione di oggi.
const hero = ref(HERO.primavera)
onMounted(() => { hero.value = HERO[stagioneDi(new Date())] })
</script>
