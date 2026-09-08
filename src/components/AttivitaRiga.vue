<template>
  <div class="attivita-riga" :class="{ 'attivita-riga--urgente': variante === 'urgente' }">
    <!-- Il bottone "Fatto" resta fratello dell'area cliccabile che apre il
         dossier, mai figlio: un <button> reale annidato in un div[role=button]
         è l'anti-pattern ARIA che DESIGN.md vieta esplicitamente (stesso
         principio già applicato in GalleryView.vue per l'Album Polaroid). -->
    <div class="attivita-riga__click" role="button" tabindex="0"
      :aria-label="`Apri il dossier di ${item.nomeSpecie}`"
      @click="$emit('apri-dossier', item)" @keydown.enter="$emit('apri-dossier', item)" @keydown.space.prevent="$emit('apri-dossier', item)">
      <span class="care__ic" :class="`care__ic--${item.tipo}`"><Icon :name="iconaCura(item.tipo)" /></span>
      <div class="attivita-riga__m">
        <div class="attivita-riga__nome">{{ item.nomeSpecie }}</div>
        <div class="attivita-riga__label" :class="{ 'attivita-riga__label--urgente': variante === 'urgente' }">{{ item.label }}</div>
        <div v-if="item.tipo === 'concimazione' && item.suggerimento" class="attivita-riga__sugg">
          <Icon name="concimazione" /> Consigliato: {{ item.suggerimento.nome }} ({{ item.suggerimento.npk.n }}-{{ item.suggerimento.npk.p }}-{{ item.suggerimento.npk.k }})
          <Icon v-if="item.suggerimento.disponibile === false" name="allerta" class="attivita-riga__sugg-warn" aria-label="Terminato" />
        </div>
        <div v-if="errore" class="attivita-riga__err" role="alert">{{ errore }}</div>
      </div>
    </div>
    <button @click="$emit('registra', item)" :disabled="disabled"
      :class="['care-act', { 'care-act--rose': variante === 'urgente' }]">
      <Spinner v-if="disabled" /><span v-else>Fatto</span>
    </button>
  </div>
</template>

<script setup>
import { iconaCura } from '@/composables/useCureVisual'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

defineProps({
  item: { type: Object, required: true },
  variante: { type: String, required: true },
  disabled: { type: Boolean, default: false },
  errore: { type: String, default: null },
})
defineEmits(['registra', 'apri-dossier'])
</script>

<style scoped>
.attivita-riga { display:flex; align-items:center; gap:12px; padding:12px 2px; }
.attivita-riga + .attivita-riga { border-top:1px solid var(--cream-dark); }
.attivita-riga--urgente { padding:12px; background:var(--rose-pale); border-radius:12px; }
.attivita-riga__click { display:flex; align-items:center; gap:12px; flex:1; min-width:0; cursor:pointer; border-radius:12px; }
.attivita-riga__click:focus-visible { outline:none; box-shadow: inset 0 0 0 3px var(--gold); }
.attivita-riga .care__ic { width:40px; height:40px; }   /* la classe globale è 34px */
.attivita-riga__m { flex:1; min-width:0; }
.attivita-riga__nome { font:600 13px/1.25 var(--font-display); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.attivita-riga__label { font:400 11px/1.4 var(--font-sans); color:var(--ink-mid); margin-top:2px; }
.attivita-riga__label--urgente { color:var(--rose-dark); }
.attivita-riga__err { color:var(--rose-ink); font:400 11px/1.4 var(--font-sans); margin-top:2px; }
</style>
