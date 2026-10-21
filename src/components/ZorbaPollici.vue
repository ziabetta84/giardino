<template>
  <div class="zp">
    <button type="button" class="zp__b" :class="{ on: messaggio.voto === 1 }" aria-label="Risposta utile" @click="emit('vota', 1)">
      <Icon name="pollice-su" />
    </button>
    <button type="button" class="zp__b" :class="{ on: messaggio.voto === -1 }" aria-label="Risposta non utile" @click="apriGiu">
      <Icon name="pollice-giu" />
    </button>
    <div v-if="aperto" class="zp__giu">
      <div class="reqchips">
        <button v-for="m in MOTIVI" :key="m.v" type="button" class="reqchip" :class="{ on: motivo === m.v }" @click="motivo = m.v">{{ m.l }}</button>
      </div>
      <input v-model="commento" class="form-input" maxlength="500" placeholder="Vuoi aggiungere qualcosa? (facoltativo)">
      <button type="button" class="btn btn-ghost zp__invia" @click="conferma">Invia</button>
    </div>
    <p class="zp__nota">Le risposte che valuti possono essere lette da chi cura Zorba, per migliorarlo.</p>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import Icon from '@/components/Icon.vue'

const props = defineProps({ messaggio: { type: Object, required: true } })
const emit = defineEmits(['vota'])
const MOTIVI = [
  { v: 'sbagliata', l: 'Sbagliata' }, { v: 'poco_chiara', l: 'Poco chiara' },
  { v: 'non_centra', l: 'Non c\'entra' }, { v: 'troppo_generica', l: 'Troppo generica' },
]
const aperto = ref(false)
const motivo = ref(props.messaggio.voto_motivo)
const commento = ref(props.messaggio.voto_commento ?? '')

function apriGiu() { aperto.value = true }
function conferma() {
  emit('vota', -1, motivo.value, commento.value)
  aperto.value = false
}
</script>

<style scoped>
.zp { display: flex; flex-wrap: wrap; align-items: center; gap: 6px; margin-top: 8px; }
.zp__b { appearance: none; background: none; border: 1px solid var(--cream-dark); border-radius: 999px; width: 30px; height: 30px; display: inline-flex; align-items: center; justify-content: center; cursor: pointer; color: var(--ink-soft); }
.zp__b svg { width: 14px; height: 14px; }
.zp__b.on { background: var(--sage-pale); border-color: var(--sage); color: var(--sage-dark); }
.zp__giu { flex-basis: 100%; display: flex; flex-direction: column; gap: 8px; margin-top: 6px; }
.zp__invia { align-self: flex-start; min-height: 32px; padding: 4px 12px; font-size: 12px; }
.zp__nota { flex-basis: 100%; font: 400 10.5px/1.4 var(--font-sans); color: var(--ink-faint); margin: 2px 0 0; }
</style>
