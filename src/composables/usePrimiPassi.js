// Primi passi di un nuovo iscritto (PrimiPassi.vue in Home): dove si trova il
// giardino, la prima zona, la prima pianta. Lo stato di ogni passo si legge
// dai dati veri dello store, mai da una spunta salvata a parte: una zona
// cancellata riapre il suo passo, un account che ha già tutto non lo vede.
//
// In localStorage, per utente, resta solo se la guida è in corso o chiusa:
// - nessun valore + tutti i passi fatti = account di prima della guida, che
//   non la vede mai;
// - 'in-corso' = qualche passo mancava quando l'ha vista la prima volta: a
//   passi finiti resta il riquadro di chiusura finché non lo si chiude;
// - 'chiuso' = chiusa a mano (o finita): non torna più.

import { computed, ref, watch } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useAuth } from '@/composables/useAuth'

const PREFISSO = 'giardino_primi_passi_'

function leggi(chiave) {
  try { return localStorage.getItem(chiave) } catch { return null }
}
function scrivi(chiave, valore) {
  try { localStorage.setItem(chiave, valore) } catch { /* storage non disponibile: vale per questa sessione */ }
}

// Condiviso a livello di modulo: Home e PrimiPassi.vue devono vedere lo
// stesso stato (Home nasconde i vecchi inviti quando la guida è visibile).
const statoSalvato = ref(null)
let utenteLetto = null

export function usePrimiPassi() {
  const store = useDatiStore()
  const { utente } = useAuth()

  const chiave = computed(() => utente.value?.id ? PREFISSO + utente.value.id : null)
  // Un altro utente nella stessa scheda (uscita e nuovo accesso) ha il suo stato.
  watch(chiave, (c) => {
    if (c === utenteLetto) return
    utenteLetto = c
    statoSalvato.value = c ? leggi(c) : null
  }, { immediate: true })

  const pronto = computed(() => !!store.piante && !!store.zone)
  const posizioneFatta = computed(() => store.settings?.location?.lat != null && store.settings?.location?.lon != null)
  const zonaFatta = computed(() => Object.keys(store.zone ?? {}).length > 0)
  const piantaFatta = computed(() => Object.keys(store.piante ?? {}).length > 0)
  const tuttoFatto = computed(() => posizioneFatta.value && zonaFatta.value && piantaFatta.value)

  // La prima volta che i dati arrivano con un passo ancora da fare, la guida
  // parte: da lì in poi resta fino alla chiusura, anche a passi completati.
  watch([pronto, tuttoFatto], ([p, fatto]) => {
    if (!p || !chiave.value || statoSalvato.value) return
    if (!fatto) {
      statoSalvato.value = 'in-corso'
      scrivi(chiave.value, 'in-corso')
    }
  }, { immediate: true })

  const visibile = computed(() => pronto.value && !store.errore && statoSalvato.value === 'in-corso')

  function chiudi() {
    statoSalvato.value = 'chiuso'
    if (chiave.value) scrivi(chiave.value, 'chiuso')
  }

  return { visibile, posizioneFatta, zonaFatta, piantaFatta, tuttoFatto, chiudi }
}
