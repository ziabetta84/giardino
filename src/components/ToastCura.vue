<template>
  <Teleport to="body">
    <div v-if="toastCura" class="cura-toast" :style="{ bottom: offset + 'px' }" role="status">
      <span>{{ messaggioToast }}</span>
      <button type="button" class="cura-toast__annulla" @click="annulla">{{ toastCura.kind === 'cura-lotto' ? 'Annulla tutte' : 'Annulla' }}</button>
    </div>
  </Teleport>
</template>

<script setup>
// Rete di sicurezza condivisa per "Fatto" (.care-act su PiantaView, Home,
// Attività, Dossier pianta): sovrascrive silenziosamente l'unico dato di
// ultima_cura[tipo] (o, per una tappa, l'esito) usato per calcolare le
// urgenze/il progresso in tutta l'app, senza conferma preventiva (voluta,
// per restare a basso attrito) — il toast offre qualche secondo per
// annullare invece di riaprire un dialogo che contraddirebbe quell'attrito
// basso. Componente unico invece di ricopiato per vista (una sola volta,
// non quattro varianti che divergono nel tempo); ogni vista lo monta con
// un ref e chiama apri()/apriLotto()/apriTappa() dopo una scrittura
// riuscita, stesso pattern di ZorbaLogo.reagisci().
//
// Tre "kind" di voce in coda, stesso meccanismo di annullamento:
// - 'cura': una singola cura (apri, firma invariata per compatibilità con
//   PiantaView.vue/DossierPianta.vue, che non conoscono le altre varianti).
// - 'cura-lotto': "Segna tutto fatto" su un gruppo (apriLotto) — un solo
//   toast per l'intero gruppo invece di uno per pianta, altrimenti una zona
//   di 10 piante aprirebbe 10 toast in coda.
// - 'tappa': completamento di una tappa progetto (apriTappa) — registraTappa
//   è già generico sull'esito, quindi l'annullamento è la stessa funzione
//   richiamata con l'esito precedente, non una nuova API.
import { ref, onBeforeUnmount, computed } from 'vue'
import { usePianteApi } from '@/composables/usePianteApi'
import { useProgettiApi } from '@/composables/useProgettiApi'
import { LABEL_CURA } from '@/composables/useCureVisual'

const emit = defineEmits(['errore'])
const pianteApi = usePianteApi()
const progettiApi = useProgettiApi()

const messaggioToast = computed(() => {
  const t = toastCura.value
  if (!t) return ''
  if (t.kind === 'cura-lotto') return `${t.voci.length} cure registrate`
  if (t.kind === 'tappa') return 'Tappa registrata'
  return `${LABEL_CURA[t.tipo] ?? t.tipo} registrata`
})

const DURATA = 6000
const coda = ref([])
const toastCura = ref(null)
const offset = ref(90)
let timer = null

// Sopra BottomNav + StatusBar: entrambe fisse in fondo, la StatusBar si
// impila già sopra la BottomNav (vedi StatusBar.vue, offsetInferiore) — qui
// basta leggere la posizione reale della StatusBar invece di indovinare un
// valore fisso che ignorerebbe l'una o l'altra a seconda del viewport.
function calcolaOffset() {
  const rect = document.querySelector('.statusbar')?.getBoundingClientRect()
  return rect ? Math.max(0, window.innerHeight - rect.top) + 12 : 90
}

function mostraProssimo() {
  toastCura.value = coda.value.shift() ?? null
  if (!toastCura.value) return
  offset.value = calcolaOffset()
  clearTimeout(timer)
  timer = setTimeout(mostraProssimo, DURATA)
}

function apri(id, tipo, valorePrecedente) {
  coda.value.push({ kind: 'cura', id, tipo, valorePrecedente, chiave: `${id}-${tipo}` })
  if (!toastCura.value) mostraProssimo()
}

function apriLotto(voci, chiave) {
  coda.value.push({ kind: 'cura-lotto', voci, chiave })
  if (!toastCura.value) mostraProssimo()
}

function apriTappa(tappaId, espitoPrecedente, chiave) {
  coda.value.push({ kind: 'tappa', tappaId, espitoPrecedente, chiave })
  if (!toastCura.value) mostraProssimo()
}

async function annulla() {
  if (!toastCura.value) return
  const voce = toastCura.value
  clearTimeout(timer)
  try {
    if (voce.kind === 'cura-lotto') {
      await Promise.all(voce.voci.map(v => pianteApi.annullaCura(v.id, v.tipo, v.valorePrecedente)))
    } else if (voce.kind === 'tappa') {
      await progettiApi.registraTappa(voce.tappaId, voce.espitoPrecedente)
    } else {
      await pianteApi.annullaCura(voce.id, voce.tipo, voce.valorePrecedente)
    }
  } catch {
    const messaggio = voce.kind === 'cura-lotto'
      ? 'Non sono riuscito ad annullare tutte le cure. Ricontrolla lo storico.'
      : voce.kind === 'tappa'
        ? 'Non sono riuscito ad annullare la tappa. Riprova.'
        : 'Non sono riuscito ad annullare la cura. Riprova.'
    emit('errore', { id: voce.id, tipo: voce.tipo, chiave: voce.chiave, messaggio })
  } finally {
    mostraProssimo()
  }
}

defineExpose({ apri, apriLotto, apriTappa })

onBeforeUnmount(() => clearTimeout(timer))
</script>

<style scoped>
.cura-toast {
  position: fixed; left: 50%; transform: translateX(-50%); z-index: 150;
  display: flex; align-items: center; gap: 14px;
  background: var(--ink); color: var(--cream);
  border-radius: 20px; padding: 12px 14px 12px 18px;
  box-shadow: 0 10px 30px rgba(42,34,24,0.28);
  font: 500 13px/1.2 var(--font-sans); white-space: nowrap;
  animation: cura-toast-in var(--motion-sheet) var(--ease-standard);
}
.cura-toast__annulla {
  flex: none; background: none; border: none; cursor: pointer;
  font: 600 13px/1 var(--font-sans); color: var(--gold);
  padding: 4px 2px; min-height: 44px; display: inline-flex; align-items: center;
}
@keyframes cura-toast-in {
  from { opacity: 0; transform: translateX(-50%) translateY(8px); }
  to   { opacity: 1; transform: translateX(-50%) translateY(0); }
}
@media (prefers-reduced-motion: reduce) {
  .cura-toast { animation: none; }
}
</style>
