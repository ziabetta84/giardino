<template>
  <div style="margin-bottom:16px;">
    <div class="attgz-hd">
      <span class="attgz-nome">
        <Icon :name="store.iconaZona(gruppo.zona)" style="width:12px;height:12px;flex-shrink:0;" />{{ etichettaZona }}
        <span class="attgz-conteggio">({{ gruppo.items.length }})</span>
      </span>
      <button @click="$emit('registraGruppo', gruppo)" :disabled="salvandoGruppo === gruppo.chiave"
        :class="['care-act', { 'care-act--rose': variante === 'urgente' }]">
        <Spinner v-if="salvandoGruppo === gruppo.chiave" /><span v-else>Segna tutto fatto</span>
      </button>
    </div>
    <div v-if="erroreAzione?.chiave === gruppo.chiave" class="attgz-err" role="alert">{{ erroreAzione.messaggio }}</div>
    <TransitionGroup name="stagger" tag="div" style="display:flex;flex-direction:column;gap:8px;position:relative;">
      <AttivitaRiga
        v-for="(item, i) in gruppo.items"
        :key="item.key"
        :item="item"
        :variante="variante"
        :disabled="salvando === item.key || salvandoGruppo === gruppo.chiave"
        :errore="erroreAzione?.chiave === item.key ? erroreAzione.messaggio : null"
        :style="`--stagger-delay:${Math.min(i,6) * 0.06}s;`"
        @registra="$emit('registra', $event)"
        @apri-dossier="$emit('apri-dossier', $event)"
      />
    </TransitionGroup>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import AttivitaRiga from './AttivitaRiga.vue'
import Spinner from './Spinner.vue'
import Icon from './Icon.vue'

const props = defineProps({
  gruppo: { type: Object, required: true },
  variante: { type: String, required: true },
  salvando: { type: String, default: null },
  salvandoGruppo: { type: String, default: null },
  erroreAzione: { type: Object, default: null },
})
defineEmits(['registra', 'registraGruppo', 'apri-dossier'])

const store = useDatiStore()

const etichettaZona = computed(() =>
  props.gruppo.sottozona ? `${props.gruppo.zona} – ${props.gruppo.sottozona}` : props.gruppo.zona
)
</script>

<style scoped>
.attgz-hd { display: flex; align-items: center; gap: 10px; margin-bottom: 6px; padding: 0 2px; }
/* Zona/sottozona è un nome (Regola del Nome in Fraunces, DESIGN.md): prima
   viveva dentro .slabel (DM Sans maiuscolo tracciato, stile da etichetta di
   servizio) — solo il conteggio resta in quello stile, il nome passa al
   font display come ogni altro nome dell'app (vedi .tappa-riga__t poco
   sotto in AttivitaView.vue, che lo fa già correttamente). */
.attgz-nome { flex: 1; display: flex; align-items: center; gap: 6px; min-width: 0;
  font: 600 13px/1.25 var(--font-display); color: var(--ink); }
.attgz-conteggio { font: 700 11px/1 var(--font-sans); color: var(--ink-soft); letter-spacing: 0.04em; }
.attgz-err { color: var(--rose-ink); font: 400 11px/1.4 var(--font-sans); margin: -2px 2px 8px; }
</style>
