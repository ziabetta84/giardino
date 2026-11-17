<template>
  <ul class="pz">
    <li v-for="voce in voci" :key="voce.chiave" class="pz__riga" :class="{ 'pz__riga--sotto': voce.sottozona }">
      <Icon :name="voce.icona" class="pz__ic" />
      <div class="pz__m">
        <div class="pz__nome">{{ voce.sottozona ?? voce.zona }}</div>
        <div class="pz__d">
          <template v-if="voce.daFare"><b class="pz__urg">{{ voce.daFare }} da fare</b> · </template>
          {{ voce.totale }} {{ voce.totale === 1 ? 'pianta' : 'piante' }}<template v-if="voce.conSottozone">, sottozone comprese</template>
        </div>
      </div>
      <button type="button" class="pz__act" :class="`pz__act--${tipo}`"
        :aria-label="`${azione} ${voce.sottozona ? `${voce.zona} – ${voce.sottozona}` : voce.zona}`"
        @click="$emit('apri', { zona: voce.zona, sottozona: voce.sottozona })">
        <Icon :name="iconaCura(tipo)" />{{ azione }}
      </button>
    </li>
  </ul>
  <div v-if="!voci.length" class="empty">
    <Icon name="foglia" />
    <p><b>Nessuna zona con piante</b>Aggiungi le piante alle zone per curarle insieme</p>
  </div>
</template>

<script setup>
// Elenco di zone e sottozone per «Per zona» in Attività: ogni riga apre il
// foglio che registra la cura su tutte le piante scelte (FoglioCuraZona).
// Il conteggio «da fare» usa lo stesso criterio del foglio (curaZona.js).
// Il colore è quello della cura (acqua per l'irrigazione, oliva per la
// concimazione), come nelle righe di «Per urgenza»: il rosa resta al solo
// numero di cure da fare, non a ogni pulsante.
import { computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { classificaCuraZona, pianteDellaZona } from '@/utils/curaZona'
import { iconaCura } from '@/composables/useCureVisual'
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
    const sottozone = Object.keys(store.sottozone?.[zona] ?? {})
      .sort((a, b) => a.localeCompare(b, 'it'))
      .map(sz => ({ sz, c: conta(zona, sz) }))
      .filter(x => x.c)
    risultato.push({ chiave: zona, zona, sottozona: null, icona: store.iconaZona(zona), conSottozone: sottozone.length > 0, ...intera })
    for (const { sz, c } of sottozone) {
      risultato.push({ chiave: `${zona}|${sz}`, zona, sottozona: sz, icona: store.iconaSottozona(zona, sz), ...c })
    }
  }
  return risultato
})
</script>

<style scoped>
.pz { list-style:none; margin:0 0 24px; padding:0; max-width:640px; }
.pz__riga { display:flex; align-items:center; gap:12px; padding:12px 2px; }
.pz__riga + .pz__riga { border-top:1px solid var(--cream-dark); }
/* La sottozona sta dentro la zona: rientra e il filetto parte dal suo nome. */
.pz__riga--sotto { padding-left:34px; }
.pz__riga--sotto + .pz__riga--sotto,
.pz__riga + .pz__riga--sotto { border-top:none; }
.pz__riga + .pz__riga--sotto { padding-top:4px; }
.pz__ic { flex:none; width:28px; height:28px; }
.pz__riga--sotto .pz__ic { width:22px; height:22px; }
.pz__ic :deep(svg) { width:100%; height:100%; }
.pz__m { flex:1; min-width:0; }
.pz__nome { font:600 14px/1.25 var(--font-display); color:var(--ink); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.pz__riga--sotto .pz__nome { font-size:13.5px; }
.pz__d { font:400 12px/1.4 var(--font-sans); color:var(--ink-mid); margin-top:2px; }
.pz__urg { font-weight:600; color:var(--rose-ink); }

/* Azione della zona: pillola nella tinta della cura (stessa famiglia di
   .care-act, ma con icona e colore di dominio). */
.pz__act { flex:none; display:inline-flex; align-items:center; gap:6px; min-height:44px; padding:0 16px 0 13px;
  border-radius:999px; cursor:pointer; font:600 12.5px/1 var(--font-sans);
  transition: background var(--motion-quick) var(--ease-standard), border-color var(--motion-quick) var(--ease-standard); }
.pz__act :deep(svg) { width:15px; height:15px; flex:none; }
.pz__act--irrigazione { background:var(--acqua-bg); color:var(--acqua-ink); border:1px solid transparent; }
.pz__act--irrigazione:hover { border-color:var(--acqua); }
.pz__act--concimazione { background:var(--olive-bg); color:var(--olive-ink); border:1px solid transparent; }
.pz__act--concimazione:hover { border-color:var(--olive); }
.pz__act:active { transform:scale(0.97); }
.pz__act:focus-visible { outline:none; box-shadow:0 0 0 3px var(--gold); }
</style>
