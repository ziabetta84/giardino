<template>
  <div class="mg">
    <div class="mg__hd">
      <span class="mg__ic"><Icon :name="giorno.icona" /></span>
      <div class="mg__cond">{{ giorno.descrizione }}</div>
    </div>

    <div class="exc exc--lg">
      <span class="exc__lo">{{ giorno.tMin }}°</span>
      <span class="exc__track"><span class="exc__fill"></span></span>
      <span class="exc__hi">{{ giorno.tMax }}°</span>
    </div>

    <div class="kv mg__kv">
      <div v-for="s in stat" :key="s.label">
        <span class="k"><Icon :name="s.icona" />{{ s.label }}</span><span class="v">{{ s.valore }}</span>
      </div>
    </div>

    <div v-if="chart" class="mg-chart">
      <div class="mg-chart__lab">Ora per ora</div>
      <svg :viewBox="`0 0 ${chart.W} ${chart.H}`" preserveAspectRatio="none"
        role="img" aria-label="Andamento orario di temperatura, umidità e probabilità di pioggia">
        <rect class="mg-chart__band" :x="chart.bandX" :y="chart.bandY" :width="chart.bandW" :height="chart.bandH" />
        <line class="mg-chart__base" :x1="chart.x0" :y1="chart.base" :x2="chart.xN" :y2="chart.base" />
        <path class="mg-chart__rain" :d="chart.rainArea" />
        <polyline v-if="chart.umidPoints" class="mg-chart__umid" fill="none" :points="chart.umidPoints" />
        <polyline class="mg-chart__temp" fill="none" :points="chart.tempPoints" />
        <circle class="mg-chart__dot" :cx="chart.first.x" :cy="chart.first.y" r="3" />
        <circle class="mg-chart__dot" :cx="chart.last.x" :cy="chart.last.y" r="3" />
      </svg>
      <div class="mg-chart__leg">
        <span v-for="l in legenda" :key="l.cls" class="mg-chart__leg-i" :class="`mg-chart__leg-i--${l.cls}`">{{ l.label }}</span>
      </div>
      <div class="mg-chart__x"><span>00</span><span>06</span><span>12</span><span>18</span><span>23</span></div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import Icon from '@/components/Icon.vue'

const props = defineProps({
  giorno: { type: Object, required: true },
})

// Statistiche del giorno: pioggia e vento sempre, le altre solo se presenti
// (stessa logica del vecchio statisticheDettaglio in MeteoView).
const stat = computed(() => {
  const g = props.giorno
  const s = [
    { icona: 'goccia', label: 'Pioggia', valore: `${g.pioggia} mm` },
    { icona: 'vento', label: 'Vento max', valore: `${g.vento} km/h` },
  ]
  if (g.umidita != null) s.push({ icona: 'umidita', label: 'Umidità aria', valore: `${g.umidita}%` })
  if (g.umiditaSuolo != null) s.push({ icona: 'umidita-suolo', label: 'Umidità suolo', valore: `${g.umiditaSuolo}%` })
  if (g.evapotraspirazione != null) s.push({ icona: 'evapotraspirazione', label: 'Evapotraspirazione', valore: `${g.evapotraspirazione} mm` })
  return s
})

// Mini-grafico orario. Due bande: in alto la temperatura (scala propria);
// in basso la banda "umido" 0–100% condivisa da probabilità di pioggia
// (area) e umidità dell'aria (linea). viewBox fisso, il CSS lo scala a
// larghezza piena.
const chart = computed(() => {
  const ore = props.giorno?.ore ?? []
  if (ore.length < 2) return null
  const W = 320, H = 92, pad = 6, bandaUmido = 34
  const temps = ore.map(o => o.temp)
  const tMin = Math.min(...temps)
  const tMax = Math.max(...temps)
  const tSpan = (tMax - tMin) || 1
  const base = H - pad              // pavimento della banda umido
  const bandaTop = base - bandaUmido
  const x = i => pad + (i / (ore.length - 1)) * (W - 2 * pad)
  const yTemp = t => pad + (1 - (t - tMin) / tSpan) * (bandaTop - pad)
  const yPerc = p => base - (Math.max(0, Math.min(100, p ?? 0)) / 100) * bandaUmido
  const nx = i => x(i).toFixed(1)

  const tempPoints = ore.map((o, i) => `${nx(i)},${yTemp(o.temp).toFixed(1)}`).join(' ')
  // Probabilità di pioggia come area continua: pavimento → profilo → pavimento.
  const rainArea = `M${nx(0)},${base} `
    + ore.map((o, i) => `L${nx(i)},${yPerc(o.pioggiaProb).toFixed(1)}`).join(' ')
    + ` L${nx(ore.length - 1)},${base} Z`
  // Umidità dell'aria come linea, solo se tutte le ore hanno il dato.
  const conUmid = ore.every(o => o.umidita != null)
  const umidPoints = conUmid
    ? ore.map((o, i) => `${nx(i)},${yPerc(o.umidita).toFixed(1)}`).join(' ')
    : null

  return {
    W, H, base,
    bandX: pad.toFixed(1), bandY: bandaTop.toFixed(1),
    bandW: (W - 2 * pad).toFixed(1), bandH: bandaUmido.toFixed(1),
    x0: nx(0), xN: nx(ore.length - 1),
    tempPoints, rainArea, umidPoints,
    first: { x: nx(0), y: yTemp(ore[0].temp).toFixed(1) },
    last: { x: nx(ore.length - 1), y: yTemp(ore[ore.length - 1].temp).toFixed(1) },
  }
})

const legenda = computed(() => {
  const c = chart.value
  if (!c) return []
  const l = [{ cls: 'temp', label: 'Temperatura' }]
  if (c.umidPoints) l.push({ cls: 'umid', label: 'Umidità aria' })
  l.push({ cls: 'rain', label: 'Prob. pioggia' })
  return l
})
</script>

<style scoped>
.mg { padding: 4px 16px 22px; }
@media (min-width: 640px) { .mg { padding: 4px 18px 24px; } }
.mg__hd { display: flex; align-items: center; gap: 14px; margin-bottom: 16px; }
.mg__ic { width: 58px; height: 58px; flex: none; }
.mg__ic svg { width: 100%; height: 100%; display: block; }
.mg__cond { font-size: 13px; color: var(--ink-mid); }
.mg__kv { margin: 18px 0 22px; }
.mg-chart { background: var(--cream); border: 1px solid var(--cream-dark); border-radius: 14px; padding: 12px 12px 10px; }
.mg-chart__lab { font: italic 400 11px/1.3 var(--font-display); color: var(--ink-soft); margin-bottom: 8px; }
.mg-chart svg { width: 100%; height: auto; display: block; }
.mg-chart__band { fill: var(--acqua); opacity: .07; }
.mg-chart__base { stroke: var(--acqua); opacity: .35; stroke-width: 1; }
.mg-chart__rain { fill: var(--acqua); opacity: .38; }
.mg-chart__umid { stroke: var(--sage-dark); stroke-width: 1.5; stroke-linecap: round; stroke-linejoin: round; }
.mg-chart__temp { stroke: var(--gold-dark); stroke-width: 2.5; stroke-linecap: round; stroke-linejoin: round; }
.mg-chart__dot { fill: var(--gold-dark); }
.mg-chart__leg { display: flex; flex-wrap: wrap; gap: 4px 12px; margin-top: 7px; font-size: 9.5px; color: var(--ink-soft); }
.mg-chart__leg-i { display: inline-flex; align-items: center; gap: 5px; }
.mg-chart__leg-i::before { content: ""; width: 12px; height: 2px; border-radius: 2px; flex: none; }
.mg-chart__leg-i--temp::before { background: var(--gold-dark); height: 2.5px; }
.mg-chart__leg-i--umid::before { background: var(--sage-dark); }
.mg-chart__leg-i--rain::before { height: 8px; background: var(--acqua); opacity: .5; }
.mg-chart__x { display: flex; justify-content: space-between; font-size: 9px; color: var(--ink-faint); margin-top: 3px; padding: 0 2px; }
</style>
