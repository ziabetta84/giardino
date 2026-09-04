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
      <div class="mg-chart__lab">Temperatura e probabilità di pioggia, ora per ora</div>
      <svg :viewBox="`0 0 ${chart.W} ${chart.H}`" preserveAspectRatio="none"
        role="img" aria-label="Andamento orario di temperatura e probabilità di pioggia">
        <g class="mg-chart__rain">
          <rect v-for="(b, i) in chart.rainBars" :key="i" :x="b.x" :y="b.y" width="8" :height="b.h" />
        </g>
        <polyline class="mg-chart__temp" fill="none" :points="chart.tempPoints" />
        <circle class="mg-chart__dot" :cx="chart.first.x" :cy="chart.first.y" r="3" />
        <circle class="mg-chart__dot" :cx="chart.last.x" :cy="chart.last.y" r="3" />
      </svg>
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

// Mini-grafico orario: sparkline della temperatura + barrette della
// probabilità di pioggia nella banda inferiore. viewBox fisso, il CSS lo
// scala a larghezza piena.
const chart = computed(() => {
  const ore = props.giorno?.ore ?? []
  if (ore.length < 2) return null
  const W = 320, H = 88, pad = 6, bandaPioggia = 22
  const temps = ore.map(o => o.temp)
  const tMin = Math.min(...temps)
  const tMax = Math.max(...temps)
  const tSpan = (tMax - tMin) || 1
  const x = i => pad + (i / (ore.length - 1)) * (W - 2 * pad)
  const y = t => pad + (1 - (t - tMin) / tSpan) * (H - 2 * pad - bandaPioggia)
  const tempPoints = ore.map((o, i) => `${x(i).toFixed(1)},${y(o.temp).toFixed(1)}`).join(' ')
  const rainBars = ore.map((o, i) => {
    const h = ((o.pioggiaProb ?? 0) / 100) * bandaPioggia
    return { x: (x(i) - 4).toFixed(1), y: (H - pad - h).toFixed(1), h: h.toFixed(1) }
  })
  return {
    W, H, tempPoints, rainBars,
    first: { x: x(0).toFixed(1), y: y(ore[0].temp).toFixed(1) },
    last: { x: x(ore.length - 1).toFixed(1), y: y(ore[ore.length - 1].temp).toFixed(1) },
  }
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
.mg-chart__temp { stroke: var(--gold-dark); stroke-width: 2.5; stroke-linecap: round; stroke-linejoin: round; }
.mg-chart__rain rect { fill: var(--acqua); opacity: .28; }
.mg-chart__dot { fill: var(--gold-dark); }
.mg-chart__x { display: flex; justify-content: space-between; font-size: 9px; color: var(--ink-faint); margin-top: 3px; padding: 0 2px; }
</style>
