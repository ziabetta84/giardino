<template>
  <!-- Primi passi di un nuovo iscritto (usePrimiPassi.js): tre pagine del
       taccuino da riempire in ordine, ognuna con una sola azione. Il passo
       corrente è aperto, quelli fatti dicono cosa Zorba ha imparato, quelli
       dopo restano chiusi: si vede la strada senza doverla leggere tutta. -->
  <section class="pp" :class="{ 'pp--finito': tuttoFatto }" aria-labelledby="pp-titolo">
    <header class="pp__hd">
      <ZorbaLogo ref="zorba" mini />
      <div class="pp__hd-m">
        <h2 id="pp-titolo" class="pp__t">{{ tuttoFatto ? 'Il cancello è aperto' : 'Tre passi e si entra in giardino' }}</h2>
        <p class="pp__s">
          <template v-if="tuttoFatto">D'ora in poi tengo io il conto di irrigazioni e concimazioni di {{ nomePrima }}: quando è il momento, le trovi qui sotto in «Da fare oggi».</template>
          <template v-else-if="appenaConfermato">Indirizzo confermato: il cancello è aperto. Sono Zorba: raccontami il tuo giardino e alle cure ci penso io.</template>
          <template v-else>Sono Zorba. Raccontami il tuo giardino e alle cure ci penso io.</template>
        </p>
      </div>
      <button v-if="!tuttoFatto" type="button" class="pp__nascondi" @click="chiudi">Più tardi</button>
    </header>

    <ol v-if="!tuttoFatto" class="pp__passi">
      <li v-for="(p, i) in passi" :key="p.id" class="pp__passo"
        :class="{ 'is-fatto': p.fatto, 'is-ora': p.id === corrente }"
        :aria-current="p.id === corrente ? 'step' : undefined">
        <span class="pp__segno" aria-hidden="true">
          <svg v-if="p.fatto" viewBox="0 0 24 24"><path d="M5.5 12.5l4.2 4.2L18.5 7.8" /></svg>
          <span v-else>{{ i + 1 }}</span>
        </span>

        <div class="pp__m">
          <p class="pp__n">{{ p.titolo }}<span v-if="p.fatto" class="sr-only"> (fatto)</span></p>
          <p v-if="p.fatto && p.riepilogo" class="pp__r">{{ p.riepilogo }}</p>

          <template v-if="p.id === corrente">
            <p class="pp__d">{{ p.testo }}</p>

            <!-- Passo 1, dentro la pagina: la posizione è un tocco, non vale
                 una visita alle impostazioni. -->
            <div v-if="p.id === 'posizione'" class="pp__az">
              <button type="button" class="btn btn-sage" :disabled="salvando" @click="usaPosizione">
                <Spinner v-if="salvando === 'gps'" />
                {{ salvando === 'gps' ? 'Ti cerco sulla mappa…' : 'Usa la mia posizione' }}
              </button>
              <form class="pp__cerca" role="search" @submit.prevent="cerca">
                <label for="pp-luogo" class="sr-only">Paese o indirizzo del giardino</label>
                <input id="pp-luogo" v-model="query" type="text" class="form-input"
                  placeholder="Oppure scrivi il paese" autocomplete="address-level2" :disabled="!!salvando">
                <button type="submit" class="btn btn-ghost" :disabled="!query.trim() || !!salvando">
                  <Spinner v-if="salvando === 'cerca'" /><span v-else>Cerca</span>
                </button>
              </form>
              <ul v-if="risultati.length" class="pp__risultati" aria-label="Luoghi trovati">
                <li v-for="r in risultati" :key="`${r.lat},${r.lon}`">
                  <button type="button" :disabled="!!salvando" @click="scegli(r)">{{ r.display_name }}</button>
                </li>
              </ul>
              <p v-if="erroreGeo" class="pp__err" role="alert">{{ erroreGeo }}</p>
            </div>

            <div v-else class="pp__az">
              <RouterLink class="btn btn-sage" :to="p.link">{{ p.azione }}</RouterLink>
            </div>
          </template>
        </div>
      </li>
    </ol>

    <div v-else class="pp__fine">
      <RouterLink class="btn btn-sage" :to="linkDomanda">Chiedimi qualcosa su {{ nomePrima }}</RouterLink>
      <button type="button" class="btn btn-ghost" @click="chiudi">Grazie, Zorba</button>
    </div>
  </section>
</template>

<script setup>
import { computed, ref, watch, onMounted, onUnmounted } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { usePrimiPassi } from '@/composables/usePrimiPassi'
import { useSettingsApi } from '@/composables/useSettingsApi'
import { useGeolocalizzazione } from '@/composables/useGeolocalizzazione'
import { useAuth } from '@/composables/useAuth'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import Spinner from '@/components/Spinner.vue'

const store = useDatiStore()
const { posizioneFatta, zonaFatta, piantaFatta, tuttoFatto, chiudi } = usePrimiPassi()
const settingsApi = useSettingsApi()
const { richiediPosizioneDispositivo, cercaIndirizzo, ottieniAltitudine } = useGeolocalizzazione()
const zorba = ref(null)

// Primo ingresso dal link della mail di conferma (esitoLink in useAuth.js):
// la guida lo dice, e Zorba se ne accorge col battito lento (evento raro,
// «Regola dei Due Battiti»). Vale una volta: lasciando la Home si spegne.
const { esitoLink } = useAuth()
const appenaConfermato = computed(() => esitoLink.value === 'confermato')
onMounted(() => { if (appenaConfermato.value) setTimeout(() => zorba.value?.reagisci(), 600) })
onUnmounted(() => { if (appenaConfermato.value) esitoLink.value = null })

const meteoOggi = computed(() => store.meteo?.[0] ?? null)
const nomiZone = computed(() => Object.values(store.zone ?? {}).map(z => z.nome).filter(Boolean))
const primaPianta = computed(() => Object.values(store.piante ?? {})[0] ?? null)
const nomePrima = computed(() => primaPianta.value ? store.nomePianta(primaPianta.value) : 'la tua pianta')

const passi = computed(() => [
  {
    id: 'posizione',
    fatto: posizioneFatta.value,
    titolo: 'Dimmi dove si trova il giardino',
    testo: 'Così guardo il cielo giusto: pioggia, gelate e caldo cambiano le cure. Finché non lo so, il meteo resta spento e le irrigazioni non vengono rimandate quando piove.',
    riepilogo: meteoOggi.value
      ? `Oggi da te: ${meteoOggi.value.tMax}° / ${meteoOggi.value.tMin}°, ${meteoOggi.value.descrizione.toLowerCase()}.`
      : 'Il meteo ora è quello del tuo giardino.',
  },
  {
    id: 'zona',
    fatto: zonaFatta.value,
    titolo: 'Dai un nome al primo angolo',
    testo: "Un'aiuola, il terrazzo, il davanzale della cucina: ogni posto ha la sua luce, e io ne tengo conto.",
    riepilogo: nomiZone.value.length > 1 ? `${nomiZone.value[0]} e altr${nomiZone.value.length === 2 ? 'o' : 'i'} ${nomiZone.value.length - 1}.` : nomiZone.value[0],
    azione: 'Crea la prima zona',
    link: { path: '/zone', query: { nuova: '1', torna: '/' } },
  },
  {
    id: 'pianta',
    fatto: piantaFatta.value,
    titolo: 'Presentami la prima pianta',
    testo: 'Cercala col nome che usi tu, anche quello comune: dalla sua scheda calcolo quando bagnarla e quando concimarla.',
    riepilogo: primaPianta.value ? nomePrima.value : null,
    azione: 'Aggiungi la prima pianta',
    link: { path: '/piante/nuova', query: { da: 'primi-passi' } },
  },
])

// In ordine, non il primo libero: una pianta ha bisogno di una zona, e la
// posizione cambia già le cure della prima pianta.
const corrente = computed(() => passi.value.find(p => !p.fatto)?.id ?? null)

const linkDomanda = computed(() => ({
  path: '/agente',
  query: { tipo: 'consiglio_cura', testo: `Ho appena aggiunto ${nomePrima.value} al giardino: cosa devo sapere per curarla bene qui dove abito?` },
}))

// Battito lento (raro, una volta per account) quando la guida si chiude da
// sola con l'ultimo passo: vedi «Regola dei Due Battiti» in DESIGN.md.
watch(tuttoFatto, (fatto, prima) => { if (fatto && prima === false) zorba.value?.reagisci?.() })

const query = ref('')
const risultati = ref([])
const salvando = ref(null)   // 'gps' | 'cerca' | 'salva' | null
const erroreGeo = ref(null)

async function usaPosizione() {
  salvando.value = 'gps'
  erroreGeo.value = null
  try {
    const { lat, lon } = await richiediPosizioneDispositivo()
    await salvaPosizione(lat, lon)
  } catch (e) {
    erroreGeo.value = e.message === 'Permesso di geolocalizzazione negato.'
      ? 'Il browser non mi lascia vedere la posizione: scrivi il paese qui sopra.'
      : `${e.message} Puoi anche scrivere il paese qui sopra.`
  } finally {
    salvando.value = null
  }
}

async function cerca() {
  if (!query.value.trim()) return
  salvando.value = 'cerca'
  erroreGeo.value = null
  try {
    risultati.value = await cercaIndirizzo(query.value.trim())
    if (!risultati.value.length) erroreGeo.value = 'Non trovo questo posto: prova con il nome del paese e la provincia.'
  } catch {
    erroreGeo.value = 'La ricerca non risponde: controlla la connessione e riprova.'
  } finally {
    salvando.value = null
  }
}

async function scegli(r) {
  salvando.value = 'salva'
  erroreGeo.value = null
  try {
    await salvaPosizione(r.lat, r.lon)
    risultati.value = []
  } catch (e) {
    erroreGeo.value = e.message
  } finally {
    salvando.value = null
  }
}

// Stessi valori predefiniti di SettingsView.vue per i campi che la guida non chiede.
async function salvaPosizione(lat, lon) {
  let altitude = null
  try { altitude = await ottieniAltitudine(lat, lon) } catch { /* si corregge in Impostazioni */ }
  try {
    await settingsApi.salvaSettings({
      location: { lat, lon, altitude },
      units: store.settings?.units ?? { temperature: 'celsius', wind: 'kmh', precipitation: 'mm' },
      meteo: store.settings?.meteo ?? { provider: 'open-meteo', days: 3 },
      ui: store.settings?.ui ?? { theme: 'light' },
      zona_climatica_id: store.settings?.zona_climatica_id ?? null,
    })
  } catch {
    throw new Error('Non sono riuscito a salvare la posizione: riprova tra poco.')
  }
  await store.caricaMeteo()
}
</script>

<style scoped>
/* Una pagina del taccuino appoggiata sulla Home: carta bianca, filetti tra i
   passi, l'alone d'acquerello del blocco identità di AccountView. */
.pp {
  position: relative; overflow: hidden;
  margin: 18px 0 4px; padding: 18px 18px 8px;
  background: var(--white); border: 1px solid var(--cream-dark); border-radius: 20px;
  box-shadow: 0 2px 12px rgba(42,34,24,0.06);
}
.pp::before {
  content: ''; position: absolute; right: -60px; top: -70px; width: 220px; height: 220px;
  background: radial-gradient(circle, rgba(224,184,74,0.16) 0%, rgba(122,158,130,0.10) 55%, transparent 78%);
  pointer-events: none;
}
.pp > * { position: relative; }
.pp--finito { padding-bottom: 18px; }

.pp__hd { display: flex; align-items: flex-start; gap: 12px; }
.pp__hd :deep(.zorba-mini) { width: 34px; height: 34px; flex: none; margin-top: 1px; }
.pp__hd-m { flex: 1; min-width: 0; }
.pp__t { font: 600 19px/1.2 var(--font-display); color: var(--ink); text-wrap: balance; }
.pp__s { margin-top: 4px; font: 400 13px/1.5 var(--font-sans); color: var(--ink-mid); max-width: 52ch; }
.pp__nascondi {
  flex: none; min-height: 44px; margin: -12px -8px 0 0; padding: 0 8px;
  background: none; border: none; cursor: pointer;
  font: 500 12px/1 var(--font-sans); color: var(--ink-soft);
  text-decoration: underline; text-underline-offset: 3px;
}
.pp__nascondi:hover { color: var(--ink); }

.pp__passi { list-style: none; margin: 14px 0 0; padding: 0; }
.pp__passo { display: flex; gap: 12px; padding: 14px 0; border-top: 1px solid var(--cream-dark); }

/* Il numero del passo in Caveat, come un appunto a margine; fatto, diventa
   una spunta di china salvia. */
.pp__segno {
  flex: none; width: 30px; height: 30px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font: 400 20px/1 var(--font-hand); color: var(--ink-soft);
  border: 1px dashed var(--ink-faint);
  transition: background-color var(--motion-sheet) var(--ease-standard), border-color var(--motion-sheet) var(--ease-standard);
}
.is-ora .pp__segno { color: var(--gold-ink); border: 1px solid var(--gold); background: var(--gold-pale); }
.is-fatto .pp__segno { border: 1px solid transparent; background: var(--sage-bg); }
.pp__segno svg { width: 18px; height: 18px; fill: none; stroke: var(--sage-ink); stroke-width: 2.4; stroke-linecap: round; stroke-linejoin: round; }
.is-fatto .pp__segno path { stroke-dasharray: 20; stroke-dashoffset: 0; animation: pp-spunta .5s var(--ease-standard) both; }
@keyframes pp-spunta { from { stroke-dashoffset: 20; } }

.pp__m { flex: 1; min-width: 0; padding-top: 5px; }
.pp__n { font: 600 14px/1.3 var(--font-display); color: var(--ink-soft); }
.is-ora .pp__n, .is-fatto .pp__n { color: var(--ink); }
.pp__r { margin-top: 3px; font: 400 12px/1.45 var(--font-sans); color: var(--sage-ink); }
.pp__d { margin-top: 5px; font: 400 13px/1.55 var(--font-sans); color: var(--ink-mid); max-width: 60ch; }

.pp__az { margin-top: 12px; display: flex; flex-direction: column; align-items: flex-start; gap: 10px; }
.pp__az .btn { display: inline-flex; align-items: center; gap: 8px; text-decoration: none; }
.pp__az .btn svg { width: 16px; height: 16px; flex: none; }
.pp__cerca { display: flex; gap: 8px; width: 100%; max-width: 420px; }
.pp__cerca .form-input { flex: 1; min-width: 0; }
.pp__risultati {
  list-style: none; margin: 0; padding: 0; width: 100%; max-width: 420px;
  border: 1px solid var(--cream-dark); border-radius: 14px; overflow: hidden; background: var(--white);
}
.pp__risultati li + li { border-top: 1px solid var(--cream-dark); }
.pp__risultati button {
  display: block; width: 100%; min-height: 44px; padding: 10px 14px; text-align: left;
  background: none; border: none; cursor: pointer;
  font: 400 12.5px/1.4 var(--font-sans); color: var(--ink-mid);
}
.pp__risultati button:hover, .pp__risultati button:focus-visible { outline: none; background: var(--cream); color: var(--ink); }
.pp__err { font: 400 12px/1.45 var(--font-sans); color: var(--rose-ink); }

.pp__fine { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 16px; padding-left: 46px; }
.pp__fine .btn { display: inline-flex; align-items: center; gap: 8px; text-decoration: none; }
.pp__fine .btn svg { width: 16px; height: 16px; flex: none; }
@media (max-width: 480px) {
  .pp__fine { padding-left: 0; }
  .pp__fine .btn { flex: 1 1 100%; justify-content: center; }
}

@media (prefers-reduced-motion: reduce) {
  .is-fatto .pp__segno path { animation: none; }
}
</style>
