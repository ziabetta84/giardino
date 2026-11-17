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
          <source media="(prefers-color-scheme: dark)" :srcset="heroNotte">
          <img :src="heroGiorno" width="1536" height="768" fetchpriority="high"
               alt="Un giardino in primavera dipinto ad acquerello: tulipani e margherite in primo piano, un sentiero di pietre bianche che si perde tra gli alberi.">
        </picture>
        <Zorba class="zorba--apertura" etichetta="Zorba, il gatto nero, sul bordo del giardino" />
        <figcaption class="mano apertura__didascalia">Zorba ti fa strada</figcaption>
      </figure>
    </section>

    <div id="giro" ref="giro" class="giro">
      <svg class="sentiero" aria-hidden="true" focusable="false">
        <defs>
          <mask id="sentiero-maschera" maskUnits="userSpaceOnUse">
            <path ref="rivelaEl" class="sentiero__rivela" fill="none" stroke="#fff" stroke-width="14" stroke-linecap="round" />
          </mask>
        </defs>
        <path ref="tracciaEl" class="sentiero__traccia" fill="none" mask="url(#sentiero-maschera)" />
      </svg>

      <section class="tappa" aria-labelledby="t-aiuole">
        <span class="tappa__pietra" aria-hidden="true"></span>
        <div class="tappa__testo">
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

      <section class="tappa" aria-labelledby="t-schede">
        <span class="tappa__pietra" aria-hidden="true"></span>
        <div class="tappa__testo">
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

      <section class="tappa" aria-labelledby="t-cure">
        <span class="tappa__pietra" aria-hidden="true"></span>
        <div class="tappa__testo">
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

      <section class="tappa" aria-labelledby="t-zorba">
        <span class="tappa__pietra" aria-hidden="true"></span>
        <div class="tappa__testo">
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

      <section class="tappa tappa--quieta" aria-labelledby="t-dati">
        <span class="tappa__pietra" aria-hidden="true"></span>
        <div class="tappa__testo">
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
        <span class="tappa__pietra tappa__pietra--ultima" aria-hidden="true"></span>
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
import { ref, onMounted, onBeforeUnmount } from 'vue'
import heroGiorno from '@app/assets/hero/hero-primavera-giorno.webp'
import heroNotte from '@app/assets/hero/hero-primavera-notte.webp'
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

// Il sentiero che unisce le pietre delle tappe e si disegna scorrendo.
// Senza JavaScript (e nell'HTML statico) restano le pietre.
const giro = ref(null)
const tracciaEl = ref(null)
const rivelaEl = ref(null)
let lunghezza = 0
let attesa = 0
let osservatore = null

function disegna() {
  const el = giro.value
  if (!el) return
  const base = el.getBoundingClientRect()
  const punti = [...el.querySelectorAll('.tappa__pietra')].map((p) => {
    const r = p.getBoundingClientRect()
    return { x: r.left + r.width / 2 - base.left, y: r.top + r.height / 2 - base.top }
  })
  if (punti.length < 2) return
  // Prima del cancello il sentiero scende lungo la sua colonna e piega solo all'ultimo.
  const ultimo = punti[punti.length - 1]
  const penultimo = punti[punti.length - 2]
  if (Math.abs(ultimo.x - penultimo.x) > 24) punti.splice(punti.length - 1, 0, { x: penultimo.x, y: ultimo.y - 56 })
  let prec = { x: punti[0].x, y: 0 }
  let d = `M ${prec.x} ${prec.y}`
  for (const p of punti) {
    const dy = p.y - prec.y
    d += ` C ${prec.x} ${prec.y + dy * 0.55}, ${p.x} ${p.y - dy * 0.55}, ${p.x} ${p.y}`
    prec = p
  }
  const svg = tracciaEl.value.ownerSVGElement
  svg.setAttribute('width', base.width)
  svg.setAttribute('height', base.height)
  svg.setAttribute('viewBox', `0 0 ${base.width} ${base.height}`)
  tracciaEl.value.setAttribute('d', d)
  rivelaEl.value.setAttribute('d', d)
  lunghezza = rivelaEl.value.getTotalLength()
  rivelaEl.value.style.strokeDasharray = `${lunghezza} ${lunghezza}`
  avanza()
}

function avanza() {
  if (!lunghezza || !giro.value) return
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) { rivelaEl.value.style.strokeDashoffset = '0'; return }
  const r = giro.value.getBoundingClientRect()
  const quota = Math.min(1, Math.max(0, (window.innerHeight * 0.78 - r.top) / r.height))
  rivelaEl.value.style.strokeDashoffset = String(lunghezza * (1 - quota))
}

function alScorrere() {
  if (attesa) return
  attesa = requestAnimationFrame(() => { attesa = 0; avanza() })
}

onMounted(async () => {
  await document.fonts?.ready
  osservatore = new ResizeObserver(disegna)
  osservatore.observe(giro.value)
  window.addEventListener('scroll', alScorrere, { passive: true })
})
onBeforeUnmount(() => {
  osservatore?.disconnect()
  window.removeEventListener('scroll', alScorrere)
})
</script>
