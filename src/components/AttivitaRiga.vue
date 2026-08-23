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
        <div v-if="pianta" style="display:flex;flex-direction:column;gap:8px;padding-top:12px;margin-top:12px;border-top:1px solid var(--cream-dark);">
          <div style="display:flex;gap:6px;flex-wrap:wrap;">
            <span class="badge badge-gold">{{ pianta.zona }}</span>
            <span v-if="pianta.sottozona" class="badge" style="background:var(--sage-pale);color:var(--sage-dark);">{{ pianta.sottozona }}</span>
          </div>
          <p v-if="specie?.specie || pianta.varieta" class="title-serif" style="font-size:12px;color:var(--ink-soft);font-style:italic;margin:0;">
            {{ specie?.specie }}<span v-if="pianta.varieta"> — {{ pianta.varieta }}</span>
          </p>
          <div v-if="specie?.esigenze" style="display:flex;flex-direction:column;gap:4px;">
            <div v-for="(val, chiave) in specie.esigenze" :key="chiave" style="display:flex;gap:8px;font-size:12px;">
              <span style="color:var(--ink-faint);text-transform:capitalize;min-width:70px;flex-shrink:0;">{{ chiave }}</span>
              <span class="text-light" style="color:var(--ink-mid);">{{ val }}</span>
            </div>
          </div>
          <p v-if="pianta.note" class="text-light" style="font-size:12px;color:var(--ink-mid);line-height:1.5;margin:0;">{{ pianta.note }}</p>
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
const pianta = computed(() => store.piante?.[props.item.piantaId] ?? null)
const specie = computed(() => pianta.value ? (store.specie?.[pianta.value.specie] ?? null) : null)

const ICONE_CURA = { irrigazione: 'goccia', concimazione: 'concimazione', potatura: 'potatura', calcio: 'provetta' }
const TINTE_CURA = { irrigazione: 'acqua', concimazione: 'olive', potatura: 'rose', calcio: 'sage' }
function icona(tipo) {
  return ICONE_CURA[tipo] ?? 'foglia'
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
