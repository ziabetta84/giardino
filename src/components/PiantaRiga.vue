<template>
  <RouterLink :to="`/piante/${pianta.id}`" class="card hover-card"
    style="display:flex;align-items:center;gap:14px;padding:12px 16px;text-decoration:none;color:inherit;">
    <div style="width:48px;height:48px;border-radius:14px;flex-shrink:0;display:flex;align-items:center;justify-content:center;font-size:22px;"
      :style="urgente ? 'background:var(--rose-pale)' : 'background:var(--sage-pale)'">
      {{ urgente ? '⚠️' : '🌿' }}
    </div>
    <div style="flex:1;min-width:0;">
      <div class="title-serif" style="font-size:14px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
        {{ specie?.nome ?? pianta.specie }}
      </div>
      <div style="font-size:11px;color:var(--ink-soft);margin-top:2px;">
        {{ pianta.zona }}{{ pianta.sottozona ? ' · ' + pianta.sottozona : '' }}{{ pianta.varieta ? ' · ' + pianta.varieta : '' }}
      </div>
      <div v-if="urgente && cureUrgenti.length" style="font-size:11px;color:var(--rose-dark);margin-top:3px;font-weight:500;">
        {{ cureUrgenti.map(c => c.label).join(' · ') }}
      </div>
    </div>
    <button @click.prevent="$emit('elimina')"
      style="padding:8px 10px;border-radius:8px;border:none;background:transparent;color:var(--ink-faint);cursor:pointer;font-size:18px;line-height:1;flex-shrink:0;"
      title="Elimina">×</button>
  </RouterLink>
</template>

<script setup>
import { computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { cureUrgentiPianta } from '@/composables/useCure'

const props = defineProps({
  pianta:  { type: Object,  required: true },
  urgente: { type: Boolean, default: false },
})
defineEmits(['elimina'])

const store = useDatiStore()
const specie = computed(() => store.specie?.[props.pianta.specie] ?? null)
const cureUrgenti = computed(() =>
  props.urgente ? cureUrgentiPianta(props.pianta, specie.value) : []
)
</script>
