<template>
  <div class="card" :style="cardStyle">
    <div :style="iconStyle"><Icon :name="icona(item.tipo)" style="width:18px;height:18px;" /></div>
    <div style="flex:1;min-width:0;">
      <div class="title-serif" style="font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
        {{ item.nomeSpecie }}
      </div>
      <div :style="labelStyle">{{ item.label }}</div>
      <div v-if="item.tipo === 'concimazione' && item.suggerimento" style="font-size:11px;color:var(--sage-dark);margin-top:2px;">
        🌱 Consigliato: {{ item.suggerimento.nome }} ({{ item.suggerimento.npk.n }}-{{ item.suggerimento.npk.p }}-{{ item.suggerimento.npk.k }})
      </div>
    </div>
    <button @click="$emit('registra', item)" :disabled="disabled"
      :class="['btn', variante === 'urgente' ? 'btn-rose' : 'btn-ghost']"
      style="font-size:11px;padding:5px 10px;min-height:30px;flex-shrink:0;">
      <Spinner v-if="disabled" /><span v-else>✓ Fatto</span>
    </button>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const props = defineProps({
  item: { type: Object, required: true },
  variante: { type: String, required: true },
  disabled: { type: Boolean, default: false },
})
defineEmits(['registra'])

const ICONE_CURA = { irrigazione: 'goccia', concimazione: 'concimazione', potatura: 'potatura', calcio: 'provetta' }
const TINTE_CURA = { irrigazione: 'acqua', concimazione: 'olive', potatura: 'rose', calcio: 'sage' }
function icona(tipo) {
  return ICONE_CURA[tipo] ?? 'foglia'
}

const cardStyle = computed(() => {
  const base = 'display:flex;align-items:center;gap:12px;padding:12px 16px;'
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
