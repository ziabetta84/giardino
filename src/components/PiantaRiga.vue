<template>
  <RouterLink :to="`/piante/${pianta.id}`" class="card hover-card"
    style="display:flex;align-items:center;gap:14px;padding:12px 16px;text-decoration:none;color:inherit;">
    <div style="width:48px;height:48px;border-radius:14px;flex-shrink:0;position:relative;display:flex;align-items:center;justify-content:center;font-size:22px;overflow:hidden;"
      :style="urgente ? 'background:var(--rose-pale)' : 'background:var(--sage-pale)'">
      <img v-if="thumbUrl" :src="thumbUrl" alt="" style="width:100%;height:100%;object-fit:cover;" loading="lazy">
      <template v-else>{{ urgente ? '⚠️' : '🌿' }}</template>
      <span v-if="thumbUrl && urgente" style="position:absolute;bottom:-2px;right:-2px;font-size:13px;">⚠️</span>
    </div>
    <div style="flex:1;min-width:0;">
      <div class="title-serif" style="font-size:14px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
        {{ specie?.nome ?? pianta.specie }}
      </div>
      <div v-if="pianta.varieta" style="font-size:11px;color:var(--ink-faint);font-style:italic;margin-top:1px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
        {{ pianta.varieta }}
      </div>
      <div style="font-size:11px;color:var(--ink-soft);margin-top:2px;">
        {{ pianta.zona }}{{ pianta.sottozona ? ' · ' + pianta.sottozona : '' }}
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
  pianta:   { type: Object,  required: true },
  urgente:  { type: Boolean, default: false },
  thumbUrl: { type: String,  default: null },
})
defineEmits(['elimina'])

const store = useDatiStore()
const specie = computed(() => store.specie?.[props.pianta.specie] ?? null)
const cureUrgenti = computed(() =>
  props.urgente ? cureUrgentiPianta(props.pianta, specie.value) : []
)
</script>
