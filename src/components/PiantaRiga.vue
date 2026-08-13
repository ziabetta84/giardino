<template>
  <RouterLink :to="`/piante/${pianta.id}`" class="card hover-card"
    style="display:flex;align-items:center;gap:14px;padding:12px 16px;text-decoration:none;color:inherit;">
    <div style="width:48px;height:48px;border-radius:14px;flex-shrink:0;position:relative;display:flex;align-items:center;justify-content:center;overflow:hidden;"
      :style="urgente ? 'background:var(--rose-tile)' : 'background:var(--olive-tile)'">
      <img v-if="thumbUrl" :src="thumbUrl" alt="" style="width:100%;height:100%;object-fit:cover;" loading="lazy">
      <Icon v-else :name="urgente ? 'campanella' : 'foglia'" style="width:22px;height:22px;" />
      <div v-if="thumbUrl && urgente" style="position:absolute;bottom:-2px;right:-2px;width:18px;height:18px;border-radius:50%;background:var(--rose-tile);border:2px solid var(--white);display:flex;align-items:center;justify-content:center;">
        <Icon name="campanella" style="width:10px;height:10px;" />
      </div>
    </div>
    <div style="flex:1;min-width:0;">
      <div class="title-serif" style="font-size:14px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
        {{ specie?.nome ?? pianta.specie }}
      </div>
      <div v-if="pianta.varieta" class="title-serif" style="font-size:11px;color:var(--ink-faint);font-style:italic;margin-top:1px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
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
import Icon from '@/components/Icon.vue'

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
