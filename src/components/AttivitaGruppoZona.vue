<template>
  <div style="margin-bottom:16px;">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px;padding:0 2px;">
      <span style="font-size:12px;font-weight:600;color:var(--ink-soft);">
        {{ etichettaZona }} ({{ gruppo.items.length }})
      </span>
      <button @click="$emit('registraGruppo', gruppo)" :disabled="salvandoGruppo === gruppo.chiave"
        :class="['btn', variante === 'urgente' ? 'btn-rose' : 'btn-ghost']"
        style="font-size:11px;padding:4px 9px;min-height:26px;">
        {{ salvandoGruppo === gruppo.chiave ? '⏳' : '✓ Segna tutto fatto' }}
      </button>
    </div>
    <TransitionGroup name="stagger" tag="div" style="display:flex;flex-direction:column;gap:8px;position:relative;">
      <AttivitaRiga
        v-for="(item, i) in gruppo.items"
        :key="item.key"
        :item="item"
        :variante="variante"
        :disabled="salvando === item.key || salvandoGruppo === gruppo.chiave"
        :style="`transition-delay:${Math.min(i,6) * 0.06}s;`"
        @registra="$emit('registra', $event)"
      />
    </TransitionGroup>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import AttivitaRiga from './AttivitaRiga.vue'

const props = defineProps({
  gruppo: { type: Object, required: true },
  variante: { type: String, required: true },
  salvando: { type: String, default: null },
  salvandoGruppo: { type: String, default: null },
})
defineEmits(['registra', 'registraGruppo'])

const etichettaZona = computed(() =>
  props.gruppo.sottozona ? `${props.gruppo.zona} – ${props.gruppo.sottozona}` : props.gruppo.zona
)
</script>
