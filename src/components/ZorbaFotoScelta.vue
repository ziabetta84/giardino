<template>
  <div class="zfs">
    <template v-if="foto">
      <img :src="foto.anteprima" class="zfs__anteprima" alt="Anteprima della foto scelta">
      <button type="button" class="zfs__togli" aria-label="Togli la foto" @click="emit('update:foto', null)">
        <Icon name="chiudi" />
      </button>
    </template>
    <template v-else>
      <!-- Due input separati (fotocamera / libreria): su alcuni telefoni Android un input "accept=image/*" senza
           capture viene comunque risolto verso la fotocamera, saltando la scelta della libreria. -->
      <label class="zfs__b zfs__b--scatta">
        <Icon name="fotocamera" />{{ compatta ? 'Scatta' : 'Fotocamera' }}
        <input type="file" accept="image/*" capture="environment" hidden @change="scegli">
      </label>
      <label class="zfs__b">
        <Icon name="immagine" />Libreria
        <input type="file" accept="image/*" hidden @change="scegli">
      </label>
    </template>
  </div>
</template>

<script setup>
import Icon from '@/components/Icon.vue'
import { ridimensionaFoto } from '@/utils/foto'

// Scelta della foto per Zorba, uguale nella richiesta nuova e nella risposta: fotocamera come azione principale
// (in giardino si scatta), libreria accanto; scelta una foto, al loro posto l'anteprima con il pulsante per toglierla.
defineProps({ foto: { type: Object, default: null }, compatta: { type: Boolean, default: false } })
const emit = defineEmits(['update:foto', 'errore'])

async function scegli(e) {
  const f = e.target.files?.[0]
  e.target.value = ''
  if (!f) return
  emit('errore', null)
  try { emit('update:foto', await ridimensionaFoto(f)) } catch { emit('errore', 'Questa foto non si riesce a leggere: prova con un\'altra.') }
}
</script>

<style scoped>
.zfs { display: flex; flex-wrap: wrap; align-items: center; gap: 6px; }
.zfs__b {
  display: inline-flex; align-items: center; gap: 6px; min-height: 44px; padding: 0 14px;
  border: 1px solid var(--cream-dark); border-radius: 999px; background: var(--white);
  font: 600 12px/1 var(--font-sans); color: var(--ink-mid); cursor: pointer;
  transition: border-color var(--motion-quick) var(--ease-standard), background var(--motion-quick) var(--ease-standard);
}
.zfs__b svg { width: 16px; height: 16px; flex: none; }
.zfs__b:hover { border-color: var(--sage-light); }
.zfs__b--scatta { background: var(--sage-bg); border-color: color-mix(in srgb, var(--sage) 40%, transparent); color: var(--sage-ink); }
.zfs__b:focus-within { outline: 2px solid var(--sage); outline-offset: 2px; }
.zfs__anteprima { width: 44px; height: 44px; object-fit: cover; border-radius: 12px; flex: none; }
.zfs__togli {
  appearance: none; display: inline-flex; align-items: center; justify-content: center; width: 44px; height: 44px;
  background: none; border: none; border-radius: 999px; color: var(--ink-soft); cursor: pointer;
}
.zfs__togli svg { width: 16px; height: 16px; }
.zfs__togli:hover { color: var(--rose-dark); background: var(--rose-pale); }
</style>
