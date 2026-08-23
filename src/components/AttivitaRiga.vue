<template>
  <div class="card attivita-riga" :style="cardStyle">
    <div class="attivita-riga-testata" @click="espansa = !espansa">
      <div :style="iconStyle"><Icon :name="icona(item.tipo)" style="width:18px;height:18px;" /></div>
      <div style="flex:1;min-width:0;">
        <div class="title-serif" style="font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
          {{ item.nomeSpecie }}
        </div>
        <div :style="labelStyle">{{ item.label }}</div>
        <div v-if="item.tipo === 'concimazione' && item.suggerimento" style="display:flex;align-items:center;gap:4px;font-size:11px;color:var(--sage-dark);margin-top:2px;">
          <Icon name="concimazione" style="width:12px;height:12px;flex-shrink:0;" />Consigliato: {{ item.suggerimento.nome }} ({{ item.suggerimento.npk.n }}-{{ item.suggerimento.npk.p }}-{{ item.suggerimento.npk.k }})
        </div>
      </div>
      <span class="attivita-riga-chevron" :class="{ aperta: espansa }">›</span>
      <button @click.stop="$emit('registra', item)" :disabled="disabled"
        :class="['btn', variante === 'urgente' ? 'btn-rose' : 'btn-ghost']"
        style="font-size:11px;padding:5px 10px;min-height:30px;flex-shrink:0;">
        <Spinner v-if="disabled" /><span v-else>✓ Fatto</span>
      </button>
    </div>
    <div class="attivita-riga-dettagli-wrap" :class="{ aperta: espansa }">
      <div class="attivita-riga-dettagli">
        <div v-if="pianta" style="display:flex;flex-direction:column;gap:14px;padding-top:12px;margin-top:12px;border-top:1px solid var(--cream-dark);">
          <div>
            <p class="section-label" style="margin-bottom:8px;">Stato cure</p>
            <div style="display:flex;flex-direction:column;gap:10px;">
              <div v-for="tipo in tipiCura" :key="tipo" style="display:flex;align-items:center;gap:10px;">
                <div :style="`width:30px;height:30px;border-radius:9px;display:flex;align-items:center;justify-content:center;flex-shrink:0;background:var(--${TINTE_CURA[tipo] ?? 'sage'}-tile);`">
                  <Icon :name="ICONE_CURA[tipo] ?? 'foglia'" style="width:14px;height:14px;" />
                </div>
                <div style="flex:1;min-width:0;">
                  <div style="font-size:12px;font-weight:500;text-transform:capitalize;">{{ tipo }}</div>
                  <div style="font-size:11px;color:var(--ink-soft);margin-top:1px;">{{ valutaCura(pianta, specie, tipo, contestoCura).label ?? 'Non configurata' }}</div>
                </div>
                <button @click.stop="registraCuraTipo(tipo)" :disabled="salvandoTipo === tipo" class="btn btn-sage"
                  style="font-size:10px;padding:4px 9px;min-height:26px;flex-shrink:0;">
                  <Spinner v-if="salvandoTipo === tipo" /><span v-else>✓ Fatto</span>
                </button>
              </div>
            </div>
          </div>

          <div v-if="fabbisognoNpk && classificaConcimiPianta.length">
            <p class="section-label" style="margin-bottom:2px;">Concimi consigliati</p>
            <p style="font-size:10.5px;color:var(--ink-faint);margin:0 0 8px;">Fabbisogno attuale: {{ fabbisognoNpk }}</p>
            <div style="display:flex;flex-direction:column;gap:6px;">
              <div v-for="(c, i) in classificaConcimiPianta" :key="c.id"
                :style="`display:flex;align-items:center;gap:8px;padding:6px 8px;border-radius:10px;${i === 0 ? 'background:var(--sage-pale);' : ''}`">
                <span :style="`width:18px;height:18px;border-radius:50%;flex-shrink:0;display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:700;${i === 0 ? 'background:var(--sage);color:white;' : 'background:var(--cream-dark);color:var(--ink-soft);'}`">
                  {{ i + 1 }}
                </span>
                <span style="flex:1;min-width:0;font-size:12px;font-weight:500;line-height:1.4;">{{ c.nome }}</span>
                <span class="badge" style="background:var(--white);color:var(--ink-soft);border:1px solid var(--cream-dark);flex-shrink:0;font-size:10px;">
                  {{ c.npk.n }}-{{ c.npk.p }}-{{ c.npk.k }}
                </span>
              </div>
            </div>
          </div>

          <div v-if="specie?.esigenze">
            <p class="section-label" style="margin-bottom:6px;">Esigenze</p>
            <div style="display:flex;flex-direction:column;gap:4px;">
              <div v-for="(val, chiave) in specie.esigenze" :key="chiave" style="display:flex;gap:8px;font-size:12px;">
                <span style="color:var(--ink-faint);text-transform:capitalize;min-width:70px;flex-shrink:0;">{{ chiave }}</span>
                <span class="text-light" style="color:var(--ink-mid);">{{ val }}</span>
              </div>
            </div>
          </div>

          <RouterLink :to="`/piante/${item.piantaId}`" style="font-size:12px;font-weight:600;color:var(--sage-dark);text-decoration:none;">
            Vedi scheda completa →
          </RouterLink>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'
import { valutaCura, stagione } from '@/composables/useCure'
import { classificaConcimiPerFabbisogno } from '@/composables/useConcimi'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const props = defineProps({
  item: { type: Object, required: true },
  variante: { type: String, required: true },
  disabled: { type: Boolean, default: false },
})
defineEmits(['registra'])

const espansa = ref(false)
const store = useDatiStore()
const { saveJSON } = useApi()
const pianta = computed(() => store.piante?.[props.item.piantaId] ?? null)
const specie = computed(() => pianta.value ? (store.specie?.[pianta.value.specie] ?? null) : null)

const ICONE_CURA = { irrigazione: 'goccia', concimazione: 'concimazione', potatura: 'potatura', calcio: 'provetta' }
const TINTE_CURA = { irrigazione: 'acqua', concimazione: 'olive', potatura: 'rose', calcio: 'sage' }
function icona(tipo) {
  return ICONE_CURA[tipo] ?? 'foglia'
}

// "calcio" riguarda solo le poche specie con un beneficio documentato (vedi
// PiantaView): mostrarlo per tutte le altre come "Non configurata" sarebbe
// rumore, a differenza di irrigazione/concimazione/potatura sempre pertinenti.
const tipiCura = computed(() => {
  const base = ['irrigazione', 'concimazione', 'potatura']
  if (specie.value?.manutenzione?.calcio) base.push('calcio')
  return base
})

const contestoCura = computed(() => ({
  esterno: store.zone?.[pianta.value?.zona]?.tipo === 'esterno',
  meteo: store.meteo,
}))

const fabbisognoNpk = computed(() => specie.value?.manutenzione?.npk?.[stagione()] ?? null)
const classificaConcimiPianta = computed(() =>
  fabbisognoNpk.value ? classificaConcimiPerFabbisogno(fabbisognoNpk.value, store.concimi).slice(0, 3) : []
)

const salvandoTipo = ref(null)
async function registraCuraTipo(tipo) {
  if (!pianta.value || salvandoTipo.value) return
  salvandoTipo.value = tipo
  const id = props.item.piantaId
  try {
    const nuove = await saveJSON('piante.json', (correnti) => {
      const base = { ...(correnti ?? store.piante) }
      const piantaEsistente = base[id] || {}
      base[id] = {
        ...piantaEsistente,
        ultima_cura: { ...(piantaEsistente.ultima_cura || {}), [tipo]: new Date().toISOString().split('T')[0] },
      }
      return base
    })
    store.piante = nuove
  } finally {
    salvandoTipo.value = null
  }
}

const cardStyle = computed(() => {
  const base = 'padding:12px 16px;'
  return props.variante === 'urgente'
    ? base + 'border-color:var(--rose-light);background:var(--rose-pale);'
    : base
})

const iconStyle = computed(() => {
  const base = 'width:40px;height:40px;border-radius:12px;display:flex;align-items:center;justify-content:center;flex-shrink:0;'
  return base + `background:var(--${TINTE_CURA[props.item.tipo] ?? 'sage'}-tile);`
})

const labelStyle = computed(() => {
  const base = 'font-size:11px;margin-top:2px;'
  return base + (props.variante === 'urgente' ? 'color:var(--rose-dark);' : 'color:var(--ink-soft);')
})
</script>

<style scoped>
.attivita-riga-testata {
  display: flex; align-items: center; gap: 12px; cursor: pointer;
}
.attivita-riga-chevron {
  flex-shrink: 0; font-size: 16px; color: var(--ink-faint);
  transform: rotate(90deg); transition: transform 0.2s ease;
}
.attivita-riga-chevron.aperta { transform: rotate(-90deg); }

/* Trucco grid-template-rows per animare l'altezza senza conoscerla in
   anticipo (i dettagli hanno lunghezza variabile: esigenze, note, ecc.). */
.attivita-riga-dettagli-wrap {
  display: grid; grid-template-rows: 0fr; transition: grid-template-rows 0.25s ease;
}
.attivita-riga-dettagli-wrap.aperta { grid-template-rows: 1fr; }
.attivita-riga-dettagli { overflow: hidden; min-height: 0; }
@media (prefers-reduced-motion: reduce) {
  .attivita-riga-dettagli-wrap, .attivita-riga-chevron { transition: none !important; }
}
</style>
