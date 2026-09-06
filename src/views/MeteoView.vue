<template>
  <div>
    <h1 class="page-title" :style="{ marginBottom: aggiornatoAlle ? '4px' : '20px' }">Meteo</h1>
    <p v-if="aggiornatoAlle" class="meteo-aggiornato">Aggiornato alle {{ aggiornatoAlle }}</p>

    <div v-if="loading" class="ledger">
      <div v-for="i in 6" :key="i" class="day-skel">
        <div class="skeleton day-skel__ic"></div>
        <div class="day-skel__m">
          <div class="skeleton" style="height:12px;width:55%"></div>
          <div class="skeleton" style="height:10px;width:80%;margin-top:8px"></div>
        </div>
      </div>
    </div>

    <div v-else-if="errore" class="card" style="padding:24px;text-align:center;color:var(--rose-ink);">
      <div style="width:44px;height:44px;border-radius:50%;background:var(--rose-tile);display:flex;align-items:center;justify-content:center;margin:0 auto 10px;">
        <Icon name="meteo-errore" style="width:22px;height:22px;" />
      </div>
      <p>{{ errore }}</p>
      <button type="button" class="btn btn-ghost" style="margin-top:14px;" @click="caricaMeteo">Riprova</button>
    </div>

    <template v-else>
      <template v-if="adessoMeteo">
        <div class="slabel">Oggi</div>
        <div class="adesso" role="button" tabindex="0"
          @click="apriDettaglio(giorni[0])" @keydown.enter="apriDettaglio(giorni[0])" @keydown.space.prevent="apriDettaglio(giorni[0])">
          <span class="adesso__ic">
            <Icon :name="adessoMeteo.icona" />
            <span v-if="haAvviso(giorni[0])" class="adesso__flag" aria-hidden="true"></span>
          </span>
          <span v-if="haAvviso(giorni[0])" class="sr-only">Attenzione: vedi avvisi meteo</span>
          <div class="adesso__m">
            <div class="adesso__label">adesso</div>
            <div class="adesso__temp">{{ adessoMeteo.temp }}<sup>°</sup></div>
            <div class="adesso__desc">
              <b>{{ adessoMeteo.descrizione }}</b><template v-if="adessoMeteo.umidita != null"> · umidità {{ adessoMeteo.umidita }}%</template><template v-if="adessoMeteo.vento != null"> · vento {{ adessoMeteo.vento }} km/h</template>
            </div>
          </div>
        </div>
        <p v-if="irrigazioneSospesa" class="meteo-nota">
          <Icon name="goccia" /> Irrigazione delle piante esterne sospesa: {{ pioggiaPrevista2gg.toFixed(1) }} mm di pioggia previsti nei prossimi 2 giorni
        </p>
      </template>

      <template v-if="orarieDaAdesso.length">
        <div class="slabel">Le prossime ore</div>
        <div class="ribbon">
          <div v-for="o in orarieDaAdesso" :key="o.ora" class="hour" :class="{ now: oraCorrente(o) }">
            <div class="hour__t">{{ o.label }}<span v-if="oraCorrente(o)" class="sr-only"> (ora attuale)</span></div>
            <span class="hour__i"><Icon :name="o.icona" /></span>
            <div class="hour__d">{{ o.temp }}°</div>
            <div class="hour__cond">{{ o.descrizione }}</div>
            <div v-if="o.pioggiaProb !== null" class="hour__r"><Icon name="goccia" />{{ o.pioggiaProb }}%</div>
          </div>
        </div>
      </template>

      <div v-if="avvisi.length" class="alertbox alertbox--rose">
        <span class="alertbox__ic"><Icon name="allerta" /></span>
        <div class="alertbox__main">
          <div class="alertbox__title">Occhio a questi giorni</div>
          <div class="alertbox__rows">
            <div v-for="a in avvisi" :key="a.key" class="alert-meteo__row">
              <Icon :name="a.icona" /><span><b>{{ a.giorno }}</b> — {{ a.testo }}</span>
            </div>
          </div>
        </div>
      </div>

      <template v-if="giorniSuccessivi.length">
        <div class="slabel">I prossimi giorni</div>
        <div class="ledger">
          <div v-for="g in giorniSuccessivi" :key="g.data" class="day" role="button" tabindex="0"
            @click="apriDettaglio(g)" @keydown.enter="apriDettaglio(g)" @keydown.space.prevent="apriDettaglio(g)">
            <span v-if="haAvviso(g)" class="day__flag" aria-hidden="true"></span>
            <span v-if="haAvviso(g)" class="sr-only">Attenzione: vedi avvisi meteo</span>
            <div class="day__gut">
              <div class="day__wd">{{ g.wd }}</div>
              <div class="day__dm">{{ g.dm }}</div>
            </div>
            <span class="day__i"><Icon :name="g.icona" /></span>
            <div class="day__desc">
              <span class="nm">{{ g.descrizione }}</span>
              <span class="day__rain">{{ g.pioggia }} mm</span>
            </div>
            <div class="exc">
              <span class="exc__lo">{{ g.tMin }}°</span>
              <span class="exc__track"><span class="exc__fill" :style="excStyle(g)"></span></span>
              <span class="exc__hi">{{ g.tMax }}°</span>
            </div>
          </div>
        </div>
      </template>
    </template>

    <FoglioLaterale
      :model-value="!!giornoSelezionato"
      @update:model-value="v => { if (!v) chiudiDettaglio() }"
      :titolo="giornoSelezionato ? titoloGiorno(giornoSelezionato) : ''"
    >
      <MeteoGiorno v-if="giornoSelezionato" :giorno="giornoSelezionato" :avvisi="avvisiGiorno(giornoSelezionato)" />
    </FoglioLaterale>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted, ref, computed } from 'vue'
import { useMeteo } from '@/composables/useMeteo'
import { pioggiaInArrivo, pioggiaCumulata2gg } from '@/composables/useCure'
import { useDatiStore } from '@/stores/dati'
import Icon from '@/components/Icon.vue'
import FoglioLaterale from '@/components/FoglioLaterale.vue'
import MeteoGiorno from '@/components/MeteoGiorno.vue'

const { giorni, orarieOggi, avvisi, loading, errore, aggiornatoAlle, carica } = useMeteo()
const store = useDatiStore()

const giorniSuccessivi = computed(() => giorni.value.slice(1))

const adesso = ref(new Date())
let timer = null
onMounted(() => { timer = setInterval(() => { adesso.value = new Date() }, 60000) })
onUnmounted(() => { if (timer) clearInterval(timer) })

function chiaveOra(d) {
  const oggiStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
  const oraStr = String(d.getHours()).padStart(2, '0')
  return `${oggiStr}T${oraStr}:00`
}

const orarieDaAdesso = computed(() => {
  const chiave = chiaveOra(adesso.value)
  return orarieOggi.value.filter(o => o.ora >= chiave)
})
const adessoMeteo = computed(() => orarieDaAdesso.value[0] ?? null)
function oraCorrente(o) { return o.ora === chiaveOra(adesso.value) }

// Range termico dei 7 giorni: la barra d'escursione di ogni giorno è
// posizionata su questo intervallo, così i giorni più caldi slittano a destra.
const rangeSettimana = computed(() => {
  const gs = giorni.value
  if (!gs.length) return { min: 0, max: 1 }
  let min = Infinity, max = -Infinity
  for (const g of gs) {
    if (g.tMin < min) min = g.tMin
    if (g.tMax > max) max = g.tMax
  }
  if (min === max) max = min + 1
  return { min, max }
})
function excStyle(g) {
  const { min, max } = rangeSettimana.value
  const span = max - min
  return {
    left: `${((g.tMin - min) / span) * 100}%`,
    right: `${((max - g.tMax) / span) * 100}%`,
  }
}

function haAvviso(g) {
  return avvisi.value.some(a => a.key.startsWith(`${g.data}-`))
}
function avvisiGiorno(g) {
  return avvisi.value.filter(a => a.key.startsWith(`${g.data}-`))
}

// Stesso criterio (5mm cumulati su oggi+domani) usato da useCure.js per
// sospendere l'irrigazione delle piante esterne: qui si mostra esplicitamente
// perché altrimenti la connessione resterebbe visibile solo come cure "già
// saltate" altrove nell'app, senza spiegazione nella pagina dedicata al meteo.
const irrigazioneSospesa = computed(() => pioggiaInArrivo(giorni.value))
const pioggiaPrevista2gg = computed(() => pioggiaCumulata2gg(giorni.value))
function titoloGiorno(g) {
  return new Date(g.data).toLocaleDateString('it-IT', { weekday: 'long', day: 'numeric', month: 'long' })
}

const giornoSelezionato = ref(null)
function apriDettaglio(g) { giornoSelezionato.value = g }
function chiudiDettaglio() { giornoSelezionato.value = null }

function caricaMeteo() {
  const s = store.settings
  carica(s?.location?.lat ?? 43.8309, s?.location?.lon ?? 12.9860)
}

onMounted(async () => {
  await store.caricaTutto()
  caricaMeteo()
})
</script>

<style scoped>
/* Discreta di proposito (--ink-faint, 11px): un promemoria di freschezza
   dato, non un avviso — il tono "quieto" del taccuino non deve suggerire
   che il meteo stia invecchiando mentre lo si guarda. */
.meteo-aggiornato { font-size: 11px; color: var(--ink-faint); margin: 0 0 16px; }

/* Apertura "Adesso" */
.adesso { display: flex; align-items: center; gap: 18px; padding: 2px 2px 4px; cursor: pointer; }
.adesso__ic { position: relative; width: 76px; height: 76px; flex: none; }
/* Stesso pallino di .day__flag nella lista giorni (senza, "oggi" era l'unico
   giorno a non segnalare mai un proprio avviso attivo), ma ancorato all'icona
   stessa — non alla riga .adesso intera, che è larga quanto la colonna di
   pagina e non ha una superficie propria su cui il pallino possa "posarsi"
   (a differenza di .day, che è una riga a griglia piena larghezza). Bordo
   colore pagina (--cream), stesso principio di .pr__badge: resta leggibile
   sopra qualunque icona sottostante. */
.adesso__flag { position: absolute; top: -2px; right: -2px; width: 10px; height: 10px; border-radius: 50%; background: var(--rose); border: 2px solid var(--cream); }
.adesso__ic svg { width: 100%; height: 100%; display: block; }
.adesso__m { min-width: 0; }
.adesso__label { font-family: var(--font-sans); font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: .06em; color: var(--ink-soft); line-height: 1; }
.adesso__temp { font-family: var(--font-display); font-weight: 600; font-size: 52px; line-height: .95; letter-spacing: -.02em; margin: 2px 0 3px; }
.adesso__temp sup { font-size: .42em; font-weight: 500; top: -.75em; margin-left: 2px; }
.adesso__desc { font-size: 13px; color: var(--ink-mid); }
.adesso__desc b { color: var(--ink); font-weight: 600; }

/* Nastro orario */
.ribbon { display: flex; gap: 8px; overflow-x: auto; padding: 0 4px 6px; margin: 0 -4px; }
.hour { flex: none; width: 72px; text-align: center; padding: 8px 4px; border-radius: 12px; background: var(--white); border: 1px solid var(--cream-dark); }
.hour.now { background: var(--gold-pale); border-color: var(--gold-light); }
.hour__t { font-size: 10.5px; color: var(--ink-soft); }
.hour__i { display: block; width: 24px; height: 24px; margin: 3px auto 2px; }
.hour__i svg { width: 100%; height: 100%; display: block; }
.hour__d { font-family: var(--font-display); font-weight: 600; font-size: 12.5px; }
/* Descrizione della condizione, non solo icona: prima esisteva solo come
   sr-only, un'incoerenza rispetto alla lista giorni sotto che la mostra
   sempre in chiaro. Clampata a 2 righe per tenere le celle di altezza
   uniforme anche con testi lunghi ("Parzialmente nuvoloso"). */
.hour__cond {
  font-size: 9.5px; line-height: 1.25; color: var(--ink-soft); margin-top: 2px;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
  overflow: hidden; min-height: 2.5em;
}
.hour__r { display: flex; align-items: center; justify-content: center; gap: 2px; font-size: 9px; color: var(--acqua-ink); margin-top: 1px; }
.hour__r svg { width: 8px; height: 8px; }

/* Blocco avvisi: .alertbox/.alertbox--rose/.alert-meteo__row ora tutti
   globali in main.css (quest'ultima riusata anche da MeteoGiorno.vue).
   Margine locale: qui il blocco sta dopo il nastro orario, non subito
   sotto un titolo come in PiantaView. */
.alertbox.alertbox--rose { margin: 22px 0 2px; }

/* Nota "irrigazione sospesa": informativa, non un avviso — stessa tinta
   acqua già usata per pioggia/umidità in questo file (.hour__r/.day__rain),
   non il rosa di .alertbox--rose che qui suonerebbe come un allarme. */
.meteo-nota {
  display: flex; align-items: center; gap: 7px;
  font-size: 12px; color: var(--acqua-ink); margin: 10px 2px 0;
}
.meteo-nota svg { width: 14px; height: 14px; flex: none; }

/* Registro giorni */
.ledger { margin-top: 4px; }
.day { position: relative; display: grid; grid-template-columns: 38px 34px 1fr; grid-template-rows: auto auto;
  column-gap: 12px; align-items: center; padding: 13px 4px; cursor: pointer; }
.day + .day { border-top: 1px solid var(--cream-dark); }
@media (hover: hover) { .day:hover { background: var(--white); } }
.day__flag { position: absolute; top: 10px; right: 2px; width: 6px; height: 6px; border-radius: 50%; background: var(--rose); }
.day__gut { grid-row: 1 / 3; text-align: center; line-height: 1.05; }
.day__wd { font-family: var(--font-sans); font-weight: 600; font-size: 10.5px; text-transform: uppercase; letter-spacing: .04em; color: var(--ink-soft); }
.day__dm { font-family: var(--font-display); font-size: 18px; color: var(--ink); }
.day__i { grid-row: 1 / 3; width: 34px; height: 34px; }
.day__i svg { width: 100%; height: 100%; display: block; }
.day__desc { display: flex; align-items: baseline; gap: 8px; min-width: 0; font-size: 12.5px; color: var(--ink-mid); }
.day__desc .nm { color: var(--ink); font-weight: 500; }
.day__rain { font-size: 10.5px; color: var(--acqua-ink); white-space: nowrap; }

/* Skeleton nella forma del registro */
.day-skel { display: flex; align-items: center; gap: 12px; padding: 13px 4px; }
.day-skel + .day-skel { border-top: 1px solid var(--cream-dark); }
.day-skel__ic { width: 34px; height: 34px; border-radius: 50%; flex: none; }
.day-skel__m { flex: 1; }
</style>
