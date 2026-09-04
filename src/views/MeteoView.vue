<template>
  <div>
    <h1 class="page-title" style="margin-bottom:20px">Meteo</h1>

    <div v-if="loading" class="ledger">
      <div v-for="i in 6" :key="i" class="day-skel">
        <div class="skeleton day-skel__ic"></div>
        <div class="day-skel__m">
          <div class="skeleton" style="height:12px;width:55%"></div>
          <div class="skeleton" style="height:10px;width:80%;margin-top:8px"></div>
        </div>
      </div>
    </div>

    <div v-else-if="errore" class="card" style="padding:24px;text-align:center;color:var(--rose-dark);">
      <div style="width:44px;height:44px;border-radius:50%;background:var(--rose-tile);display:flex;align-items:center;justify-content:center;margin:0 auto 10px;">
        <Icon name="meteo-errore" style="width:22px;height:22px;" />
      </div>
      <p>{{ errore }}</p>
    </div>

    <template v-else>
      <template v-if="adessoMeteo">
        <div class="slabel">Oggi</div>
        <div class="adesso" role="button" tabindex="0"
          @click="apriDettaglio(giorni[0])" @keydown.enter="apriDettaglio(giorni[0])" @keydown.space.prevent="apriDettaglio(giorni[0])">
          <span class="adesso__ic"><Icon :name="adessoMeteo.icona" /></span>
          <div class="adesso__m">
            <div class="adesso__label">adesso</div>
            <div class="adesso__temp">{{ adessoMeteo.temp }}<sup>°</sup></div>
            <div class="adesso__desc">
              <b>{{ adessoMeteo.descrizione }}</b><template v-if="adessoMeteo.umidita != null"> · umidità {{ adessoMeteo.umidita }}%</template><template v-if="adessoMeteo.vento != null"> · vento {{ adessoMeteo.vento }} km/h</template>
            </div>
          </div>
        </div>
      </template>

      <template v-if="orarieDaAdesso.length">
        <div class="slabel">Le prossime ore</div>
        <div class="ribbon">
          <div v-for="o in orarieDaAdesso" :key="o.ora" class="hour" :class="{ now: oraCorrente(o) }">
            <div class="hour__t">{{ o.label }}</div>
            <span class="hour__i"><Icon :name="o.icona" /></span>
            <div class="hour__d">{{ o.temp }}°</div>
            <div v-if="o.pioggiaProb !== null" class="hour__r"><Icon name="goccia" />{{ o.pioggiaProb }}%</div>
          </div>
        </div>
      </template>

      <div v-if="avvisi.length" class="alert-meteo">
        <span class="alert-meteo__ic"><Icon name="allerta" /></span>
        <div class="alert-meteo__main">
          <div class="alert-meteo__title">Occhio a questi giorni</div>
          <div class="alert-meteo__rows">
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
      <MeteoGiorno v-if="giornoSelezionato" :giorno="giornoSelezionato" />
    </FoglioLaterale>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted, ref, computed } from 'vue'
import { useMeteo } from '@/composables/useMeteo'
import { useDatiStore } from '@/stores/dati'
import Icon from '@/components/Icon.vue'
import FoglioLaterale from '@/components/FoglioLaterale.vue'
import MeteoGiorno from '@/components/MeteoGiorno.vue'

const { giorni, orarieOggi, avvisi, loading, errore, carica } = useMeteo()
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
function titoloGiorno(g) {
  return new Date(g.data).toLocaleDateString('it-IT', { weekday: 'long', day: 'numeric', month: 'long' })
}

const giornoSelezionato = ref(null)
function apriDettaglio(g) { giornoSelezionato.value = g }
function chiudiDettaglio() { giornoSelezionato.value = null }

onMounted(async () => {
  await store.caricaTutto()
  const s = store.settings
  carica(s?.location?.lat ?? 43.8309, s?.location?.lon ?? 12.9860)
})
</script>

<style scoped>
/* Apertura "Adesso" */
.adesso { display: flex; align-items: center; gap: 18px; padding: 2px 2px 4px; cursor: pointer; }
.adesso__ic { width: 76px; height: 76px; flex: none; }
.adesso__ic svg { width: 100%; height: 100%; display: block; }
.adesso__m { min-width: 0; }
.adesso__label { font-family: var(--font-hand); font-size: 20px; color: var(--ink-soft); line-height: 1; }
.adesso__temp { font-family: var(--font-display); font-weight: 600; font-size: 52px; line-height: .95; letter-spacing: -.02em; margin: 2px 0 3px; }
.adesso__temp sup { font-size: .42em; font-weight: 500; top: -.75em; margin-left: 2px; }
.adesso__desc { font-size: 13px; color: var(--ink-mid); }
.adesso__desc b { color: var(--ink); font-weight: 600; }

/* Nastro orario */
.ribbon { display: flex; gap: 8px; overflow-x: auto; padding: 0 4px 6px; margin: 0 -4px; }
.hour { flex: none; width: 52px; text-align: center; padding: 8px 4px; border-radius: 12px; background: var(--white); border: 1px solid var(--cream-dark); }
.hour.now { background: var(--gold-pale); border-color: var(--gold-light); }
.hour__t { font-size: 10.5px; color: var(--ink-soft); }
.hour__i { display: block; width: 24px; height: 24px; margin: 3px auto 2px; }
.hour__i svg { width: 100%; height: 100%; display: block; }
.hour__d { font-family: var(--font-display); font-weight: 600; font-size: 12.5px; }
.hour__r { display: flex; align-items: center; justify-content: center; gap: 2px; font-size: 9px; color: var(--acqua-ink); margin-top: 1px; }
.hour__r svg { width: 8px; height: 8px; }

/* Blocco avvisi — stessa struttura di .alert-cura in PiantaView, tinta rosa */
.alert-meteo { display: flex; gap: 12px; align-items: flex-start; padding: 14px 15px; margin: 22px 0 2px;
  background: var(--rose-bg); border: 1px solid color-mix(in srgb, var(--rose) 28%, transparent); border-radius: 16px; }
.alert-meteo__ic { flex: none; width: 36px; height: 36px; border-radius: 11px; display: flex; align-items: center; justify-content: center;
  background: color-mix(in srgb, var(--rose) 16%, var(--cream)); color: var(--rose-ink); }
.alert-meteo__ic svg { width: 20px; height: 20px; }
.alert-meteo__main { flex: 1; min-width: 0; }
.alert-meteo__title { font: 600 14px/1.25 var(--font-display); color: var(--rose-ink); }
.alert-meteo__rows { display: flex; flex-direction: column; gap: 8px; margin-top: 8px; }
.alert-meteo__row { display: flex; align-items: center; gap: 8px; font: 400 12.5px/1.4 var(--font-sans); color: var(--rose-ink); }
.alert-meteo__row svg { width: 15px; height: 15px; flex: none; }

/* Registro giorni */
.ledger { margin-top: 4px; }
.day { position: relative; display: grid; grid-template-columns: 38px 34px 1fr; grid-template-rows: auto auto;
  column-gap: 12px; align-items: center; padding: 13px 4px; cursor: pointer; }
.day + .day { border-top: 1px solid var(--cream-dark); }
@media (hover: hover) { .day:hover { background: var(--white); } }
.day__flag { position: absolute; top: 10px; right: 2px; width: 6px; height: 6px; border-radius: 50%; background: var(--rose); }
.day__gut { grid-row: 1 / 3; text-align: center; line-height: 1.05; }
.day__wd { font-family: var(--font-hand); font-weight: 600; font-size: 12.5px; text-transform: capitalize; color: var(--ink-soft); }
.day__dm { font-family: var(--font-display); font-size: 18px; color: #000; }
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
