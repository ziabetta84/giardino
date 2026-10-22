<template>
  <div v-if="motivo === 'prova'" class="zav zav--prova" role="status">
    <ZorbaLogo class="zav__logo" />
    <div class="zav__corpo">
      <p class="zav__titolo">Le risposte di prova sono finite</p>
      <p>Con l'abbonamento Zorba ti risponde fino a 30 volte al mese: identifica, diagnostica, consiglia e pianifica guardando le tue piante, le cure registrate e il meteo di casa tua.</p>
      <p>Per attivarlo chiedi a chi gestisce l'app. Le risposte che hai già ricevuto restano nello storico.</p>
      <button v-if="conStorico" type="button" class="btn btn-ghost zav__azione" @click="emit('storico')">Rileggi le risposte</button>
    </div>
  </div>
  <div v-else-if="motivo" class="zav" role="status">{{ TESTI[motivo] }}</div>
</template>

<script setup>
import { computed } from 'vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'

// Perché in questo momento non si può scrivere a Zorba: lo stesso avviso nella richiesta nuova e al posto del
// riquadro di risposta di una conversazione, così il riquadro non sparisce mai senza una spiegazione.
// motivo: 'offline' | 'pausa' | 'prova' | 'mese' | null
const props = defineProps({
  motivo: { type: String, default: null },
  ripartenza: { type: String, default: '' },
  conStorico: { type: Boolean, default: false },
})
const emit = defineEmits(['storico'])
const TESTI = computed(() => ({
  offline: 'Sei offline: lo storico resta consultabile, per scrivere a Zorba serve la connessione.',
  pausa: 'Zorba è in pausa in questo momento: riprova più tardi.',
  mese: `Hai usato tutte le risposte di questo mese: si riparte il ${props.ripartenza}.`,
}))
</script>

<style scoped>
.zav {
  border: 1px solid var(--gold-light); background: var(--gold-pale); border-radius: 14px;
  padding: 12px 14px; margin-bottom: 14px; font: 400 12.5px/1.5 var(--font-sans); color: var(--gold-ink);
}
.zav--prova { display: flex; gap: 12px; align-items: flex-start; padding: 16px; }
.zav__logo { width: 36px; height: 36px; flex: none; }
.zav__corpo p { margin: 0 0 8px; }
.zav__titolo { font: 600 16px/1.25 var(--font-display); color: var(--ink); }
.zav__azione { margin-top: 4px; min-height: 40px; padding: 6px 14px; font-size: 12px; }
</style>
