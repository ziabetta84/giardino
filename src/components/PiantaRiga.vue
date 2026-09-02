<template>
  <RouterLink :to="`/piante/${pianta.id}`" class="card hover-card pr">
    <div class="pr__thumb" :style="urgente ? 'background:var(--rose-tile)' : 'background:var(--olive-tile)'">
      <img v-if="thumbEffettivo" :src="thumbEffettivo" alt="" loading="lazy">
      <Icon v-else :name="urgente ? 'campanella' : 'foglia'" class="pr__thumb-ico" />
      <div v-if="thumbEffettivo && urgente" class="pr__badge">
        <Icon name="campanella" class="pr__badge-ico" />
      </div>
    </div>
    <div class="pr__body">
      <div class="pr__name">
        {{ specie?.nome ?? pianta.specie }}
      </div>
      <div v-if="pianta.varieta" class="pr__var">
        {{ pianta.varieta }}
      </div>
      <div class="pr__zona">
        <Icon :name="store.iconaZona(pianta.zona)" class="pr__zona-ico" /><span>{{ pianta.zona }}{{ pianta.sottozona ? ' · ' + pianta.sottozona : '' }}</span>
      </div>
      <div v-if="urgente && cureUrgenti.length" class="pr__urg">
        {{ cureUrgenti.map(c => c.label).join(' · ') }}
      </div>
    </div>
    <button @click.prevent="$emit('elimina')" class="pr__del" title="Elimina">×</button>
  </RouterLink>
</template>

<script setup>
import { computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { cureUrgentiPianta } from '@/composables/useCure'
import { urlMiniatura } from '@/composables/useWikimedia'
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
// Senza foto personali, ripiega sull'immagine hero della specie (stesso
// criterio di PiantaView.vue): l'attribuzione richiesta dalla licenza si
// vede aprendo la scheda pianta, a cui questa riga fa già da link.
const thumbEffettivo = computed(() => props.thumbUrl || (specie.value?.immagine?.url ? urlMiniatura(specie.value.immagine.url, 160) : null))
</script>

<style scoped>
.pr {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 12px 16px;
  text-decoration: none;
  color: inherit;
}
.pr__thumb {
  width: 48px;
  height: 48px;
  border-radius: 14px;
  flex-shrink: 0;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}
.pr__thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.pr__thumb-ico {
  width: 22px;
  height: 22px;
}
.pr__badge {
  position: absolute;
  bottom: -2px;
  right: -2px;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: var(--rose-tile);
  border: 2px solid var(--white);
  display: flex;
  align-items: center;
  justify-content: center;
}
.pr__badge-ico {
  width: 10px;
  height: 10px;
}
.pr__body {
  flex: 1;
  min-width: 0;
}
.pr__name {
  font-family: var(--font-display);
  font-weight: 600;
  font-size: 14px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.pr__var {
  font-family: var(--font-display);
  font-style: italic;
  font-size: 11px;
  color: var(--ink-faint);
  margin-top: 1px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.pr__zona {
  font-size: 11px;
  color: var(--ink-soft);
  font-weight: 400;
  margin-top: 2px;
  display: flex;
  align-items: center;
  gap: 4px;
}
.pr__zona-ico {
  width: 11px;
  height: 11px;
  flex-shrink: 0;
}
.pr__zona span {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.pr__urg {
  font-size: 11px;
  color: var(--rose-dark);
  font-weight: 500;
  margin-top: 3px;
}
.pr__del {
  padding: 8px 10px;
  border-radius: 8px;
  border: none;
  background: transparent;
  color: var(--ink-faint);
  cursor: pointer;
  font-size: 18px;
  line-height: 1;
  flex-shrink: 0;
}
</style>
