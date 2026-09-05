<template>
  <Teleport to="body">
    <div v-if="toastCura" class="cura-toast" :style="{ bottom: offset + 'px' }" role="status">
      <span>{{ LABEL_CURA[toastCura.tipo] ?? toastCura.tipo }} registrata</span>
      <button type="button" class="cura-toast__annulla" @click="annulla">Annulla</button>
    </div>
  </Teleport>
</template>

<script setup>
// Rete di sicurezza condivisa per "Fatto" (.care-act su PiantaView, Home,
// Attività, Dossier pianta): sovrascrive silenziosamente l'unico dato di
// ultima_cura[tipo] usato per calcolare le urgenze in tutta l'app, senza
// conferma preventiva (voluta, per restare a basso attrito) — il toast offre
// qualche secondo per annullare invece di riaprire un dialogo che
// contraddirebbe quell'attrito basso. Componente unico invece di ricopiato
// per vista (una sola volta, non quattro varianti che divergono nel tempo);
// ogni vista lo monta con un ref e chiama apri(id, tipo, valorePrecedente)
// dopo un registraCura riuscito, stesso pattern di ZorbaLogo.reagisci().
import { ref, onBeforeUnmount } from 'vue'
import { usePianteApi } from '@/composables/usePianteApi'
import { LABEL_CURA } from '@/composables/useCureVisual'

const emit = defineEmits(['errore'])
const pianteApi = usePianteApi()

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
  coda.value.push({ id, tipo, valorePrecedente })
  if (!toastCura.value) mostraProssimo()
}

async function annulla() {
  if (!toastCura.value) return
  const { id, tipo, valorePrecedente } = toastCura.value
  clearTimeout(timer)
  try {
    await pianteApi.annullaCura(id, tipo, valorePrecedente)
  } catch {
    emit('errore', { id, tipo, messaggio: 'Non sono riuscito ad annullare la cura. Riprova.' })
  } finally {
    mostraProssimo()
  }
}

defineExpose({ apri })

onBeforeUnmount(() => clearTimeout(timer))
</script>

<style scoped>
.cura-toast {
  position: fixed; left: 50%; transform: translateX(-50%); z-index: 150;
  display: flex; align-items: center; gap: 14px;
  background: var(--ink); color: var(--cream);
  border-radius: 20px; padding: 12px 14px 12px 18px;
  box-shadow: 0 10px 30px rgba(22,16,8,0.28);
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
