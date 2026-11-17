<template>
  <div class="pz">
    <div v-for="voce in voci" :key="voce.chiave" class="pz__riga" :class="{ 'pz__riga--sotto': voce.sottozona }">
      <span class="pz__ic"><Icon :name="voce.icona" /></span>
      <div class="pz__m">
        <div class="pz__nome">{{ voce.sottozona ?? voce.zona }}</div>
        <div class="pz__d" :class="{ 'pz__d--urgente': voce.daFare }">
          {{ voce.daFare ? `${voce.daFare} da fare su ${voce.totale}` : `Niente in scadenza · ${voce.totale} ${voce.totale === 1 ? 'pianta' : 'piante'}` }}
        </div>
      </div>
      <button type="button" class="care-act" :class="{ 'care-act--rose': voce.daFare }"
        :aria-label="`${azione} ${voce.sottozona ? `${voce.zona} – ${voce.sottozona}` : voce.zona}`"
        @click="$emit('apri', { zona: voce.zona, sottozona: voce.sottozona })">{{ azione }}</button>
    </div>
    <div v-if="!voci.length" class="empty">
      <Icon name="foglia" />
      <p><b>Nessuna zona con piante</b>Aggiungi le piante alle zone per curarle insieme</p>
    </div>
  </div>
</template>

<script setup>
// Elenco di zone e sottozone per «Per zona» in Attività: ogni riga apre il
// foglio che registra la cura su tutte le piante scelte (FoglioCuraZona).
// Il conteggio «da fare» usa lo stesso criterio del foglio (curaZona.js).
import { computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { classificaCuraZona, pianteDellaZona } from '@/utils/curaZona'
import Icon from '@/components/Icon.vue'

const props = defineProps({
  tipo: { type: String, required: true },   // 'irrigazione' | 'concimazione'
})
defineEmits(['apri'])

const store = useDatiStore()
const azione = computed(() => props.tipo === 'irrigazione' ? 'Irriga' : 'Concima')

function conta(zona, sottozona) {
  const totale = pianteDellaZona(store.piante, zona, sottozona).length
  if (!totale) return null
  const g = classificaCuraZona({
    piante: store.piante, zona, sottozona, tipo: props.tipo,
    vocePianta: store.vocePianta, nomePianta: store.nomePianta,
    programmi: store.programmiIrrigazione, concimi: store.concimi,
  })
  return { totale, daFare: g.daFare.length }
}

const voci = computed(() => {
  if (!store.piante || !store.zone) return []
  const risultato = []
  const nomiZone = Object.keys(store.zone).sort((a, b) => a.localeCompare(b, 'it'))
  for (const zona of nomiZone) {
    const intera = conta(zona, null)
    if (!intera) continue
    risultato.push({ chiave: zona, zona, sottozona: null, icona: store.iconaZona(zona), ...intera })
    const sottozone = Object.keys(store.sottozone?.[zona] ?? {}).sort((a, b) => a.localeCompare(b, 'it'))
    for (const sz of sottozone) {
      const c = conta(zona, sz)
      if (!c) continue
      risultato.push({ chiave: `${zona}|${sz}`, zona, sottozona: sz, icona: store.iconaSottozona(zona, sz), ...c })
    }
  }
  return risultato
})
</script>

<style scoped>
.pz { display:flex; flex-direction:column; margin-bottom:24px; }
.pz__riga { display:flex; align-items:center; gap:12px; padding:12px 2px; }
.pz__riga + .pz__riga { border-top:1px solid var(--cream-dark); }
/* Le sottozone rientrano sotto la loro zona: la zona intera le comprende. */
.pz__riga--sotto { padding-left:26px; }
.pz__ic { flex:none; width:40px; height:40px; border-radius:12px; display:flex; align-items:center; justify-content:center;
  background:var(--sage-bg); color:var(--sage-ink); }
.pz__riga--sotto .pz__ic { width:32px; height:32px; border-radius:10px; }
.pz__ic svg { width:18px; height:18px; }
.pz__m { flex:1; min-width:0; }
.pz__nome { font:600 13px/1.25 var(--font-display); color:var(--ink); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.pz__d { font:400 11px/1.4 var(--font-sans); color:var(--ink-soft); margin-top:2px; }
.pz__d--urgente { color:var(--rose-dark); }
</style>
