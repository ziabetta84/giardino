import { computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { cureUrgentiPianta } from '@/composables/useCure'
import { programmaIrrigazioneEffettivo } from '@/composables/useIrrigazioneAuto'

// Quante piante hanno almeno una cura urgente oggi: stesso calcolo della
// card «Piante · N da curare» della Home, usato anche dal menù su telefono
// (pallino sul pulsante, «N da curare» sulla riga Attività) e dalla sidebar.
export function useUrgenze() {
  const store = useDatiStore()

  // Contesto per pianta (come in HomeView/AttivitaView): esterno o in casa,
  // pioggia prevista, programma d'irrigazione automatica.
  function contestoPianta(p, id) {
    const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, p.sottozona, store.programmiIrrigazione)?.ogniGiorni ?? null
    return { meteo: store.meteo, esterno: store.zone?.[p.zona]?.tipo === 'esterno', programmaAutomatico }
  }

  const numUrgenti = computed(() => {
    if (!store.piante) return null
    let n = 0
    for (const [id, p] of Object.entries(store.piante)) {
      if (cureUrgentiPianta(p, store.vocePianta(p), contestoPianta(p, id)).length > 0) n++
    }
    return n
  })

  return { numUrgenti, contestoPianta }
}
