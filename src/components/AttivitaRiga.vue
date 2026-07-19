<template>
  <div class="card" :style="cardStyle">
    <div :style="iconStyle">{{ icona(item.tipo) }}</div>
    <div style="flex:1;min-width:0;">
      <div class="title-serif" style="font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
        {{ item.nomeSpecie }}
      </div>
      <div :style="labelStyle">{{ item.label }}</div>
    </div>
    <button @click="$emit('registra', item)" :disabled="disabled"
      :class="['btn', variante === 'urgente' ? 'btn-rose' : 'btn-ghost']"
      style="font-size:11px;padding:5px 10px;min-height:30px;flex-shrink:0;">
      {{ disabled ? '⏳' : '✓ Fatto' }}
    </button>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  item: { type: Object, required: true },
  variante: { type: String, required: true },
  disabled: { type: Boolean, default: false },
})
defineEmits(['registra'])

function icona(tipo) {
  return tipo === 'irrigazione' ? '💧' : tipo === 'concimazione' ? '🌱' : '✂️'
}

const cardStyle = computed(() => {
  const base = 'display:flex;align-items:center;gap:12px;padding:12px 16px;'
  return props.variante === 'urgente'
    ? base + 'border-color:var(--rose-light);background:var(--rose-pale);'
    : base
})

const iconStyle = computed(() => {
  const base = 'width:40px;height:40px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;'
  return base + (props.variante === 'urgente' ? 'background:var(--rose-light);' : 'background:var(--gold-pale);')
})

const labelStyle = computed(() => {
  const base = 'font-size:11px;margin-top:2px;'
  return base + (props.variante === 'urgente' ? 'color:var(--rose-dark);' : 'color:var(--ink-soft);')
})
</script>
