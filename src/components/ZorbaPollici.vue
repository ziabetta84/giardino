<template>
  <div class="zp">
    <button type="button" class="zp__b" :class="{ on: messaggio.voto === 1 }" aria-label="Risposta utile" :aria-pressed="messaggio.voto === 1" @click="votaSu">
      <Icon name="pollice-su" />
    </button>
    <button type="button" class="zp__b" :class="{ on: messaggio.voto === -1 }" aria-label="Risposta non utile" :aria-pressed="messaggio.voto === -1" @click="apriGiu">
      <Icon name="pollice-giu" />
    </button>
    <div v-if="aperto" class="zp__giu">
      <div class="reqchips">
        <button v-for="m in MOTIVI" :key="m.v" type="button" class="reqchip" :class="{ on: motivo === m.v }" @click="motivo = m.v">{{ m.l }}</button>
      </div>
      <input v-model="commento" class="form-input" maxlength="500" placeholder="Vuoi aggiungere qualcosa? (facoltativo)">
      <div class="zp__azioni">
        <button type="button" class="btn btn-ghost zp__invia" @click="conferma">Invia</button>
        <button type="button" class="zp__annulla" @click="aperto = false">Annulla</button>
      </div>
    </div>
    <Transition name="zp-grazie"><span v-if="grazie" class="zp__grazie" role="status">Grazie, Zorba ne terrà conto.</span></Transition>
    <p v-if="nota" class="zp__nota">Le risposte che valuti possono essere lette da chi cura Zorba, per migliorarlo.</p>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import Icon from '@/components/Icon.vue'

// nota: la riga sulla privacy dei voti va mostrata una volta per conversazione, sotto l'ultima risposta
const props = defineProps({ messaggio: { type: Object, required: true }, nota: { type: Boolean, default: false } })
const emit = defineEmits(['vota'])
const MOTIVI = [
  { v: 'sbagliata', l: 'Sbagliata' }, { v: 'poco_chiara', l: 'Poco chiara' },
  { v: 'non_centra', l: 'Non c\'entra' }, { v: 'troppo_generica', l: 'Troppo generica' },
]
const aperto = ref(false)
const motivo = ref(props.messaggio.voto_motivo)
const commento = ref(props.messaggio.voto_commento ?? '')

const grazie = ref(false)
let tGrazie
function ringrazia() {
  grazie.value = true
  clearTimeout(tGrazie)
  tGrazie = setTimeout(() => { grazie.value = false }, 2600)
}
function votaSu() {
  aperto.value = false
  emit('vota', 1)
  ringrazia()
}
function apriGiu() { aperto.value = true }
function conferma() {
  emit('vota', -1, motivo.value, commento.value)
  aperto.value = false
  ringrazia()
}
</script>

<style scoped>
.zp { display: flex; flex-wrap: wrap; align-items: center; gap: 6px; margin-top: 8px; }
.zp__b { appearance: none; background: none; border: 1px solid var(--cream-dark); border-radius: 999px; width: 40px; height: 40px; display: inline-flex; align-items: center; justify-content: center; cursor: pointer; color: var(--ink-soft); }
.zp__b svg { width: 16px; height: 16px; }
.zp__b.on { background: var(--sage-pale); border-color: var(--sage); color: var(--sage-dark); }
.zp__giu { flex-basis: 100%; display: flex; flex-direction: column; gap: 8px; margin-top: 6px; }
.zp__azioni { display: flex; align-items: center; gap: 4px; }
.zp__invia { min-height: 40px; padding: 4px 14px; font-size: 12px; }
.zp__annulla { appearance: none; background: none; border: none; min-height: 40px; padding: 0 12px; font: 600 12px/1 var(--font-sans); color: var(--ink-soft); cursor: pointer; }
.zp__annulla:hover { color: var(--ink); }
.zp__grazie { font: 500 11.5px/1.3 var(--font-sans); color: var(--sage-ink); margin-left: 4px; }
.zp-grazie-enter-active, .zp-grazie-leave-active { transition: opacity var(--motion-sheet) var(--ease-standard); }
.zp-grazie-enter-from, .zp-grazie-leave-to { opacity: 0; }
.zp__nota { flex-basis: 100%; font: 400 10.5px/1.4 var(--font-sans); color: var(--ink-faint); margin: 2px 0 0; }
</style>
