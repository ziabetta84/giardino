import { stagione, parseGiorni } from '@/composables/useCure'

// Sopra questa soglia (intervallo più lungo ≥ N volte il più breve tra le
// specie coinvolte), un unico numero per l'intera zona/sottozona finirebbe
// per sotto-irrigare la pianta più esigente o sovra-irrigare quella meno
// esigente in modo eccessivo: meglio consigliare un programma per pianta.
export const SOGLIA_DIVERGENZA_IRRIGAZIONE = 3

// Consiglio di Zorba per il livello pianta/zona/sottozona (mai giardino:
// un intero giardino è quasi sempre troppo eterogeneo per un numero solo,
// vedi IrrigazioneView.vue). `piante` è l'elenco delle piante fisicamente
// coperte dal livello in esame (per una pianta, un array di una sola);
// `specie` è store.specie. Ritorna null quando non c'è abbastanza dato
// per un consiglio (nessuna pianta, o nessuna con manutenzione.irrigazione
// documentata per la stagione corrente).
export function suggerimentoIrrigazione(piante, specie) {
  const stagCorrente = stagione()
  const voci = piante
    .map(p => {
      const sp = specie?.[p.specie]
      const intervallo = parseGiorni(sp?.manutenzione?.irrigazione?.[stagCorrente])
      return intervallo ? { nomeSpecie: sp?.nome ?? p.specie, intervallo } : null
    })
    .filter(Boolean)

  if (!voci.length) return null

  const intervalli = voci.map(v => v.intervallo)
  const min = Math.min(...intervalli)
  const max = Math.max(...intervalli)

  if (voci.length > 1 && max >= min * SOGLIA_DIVERGENZA_IRRIGAZIONE) {
    return {
      tipo: 'divergente',
      piuEsigente: voci.find(v => v.intervallo === min).nomeSpecie,
      minGiorni: min,
      menoEsigente: voci.find(v => v.intervallo === max).nomeSpecie,
      maxGiorni: max,
    }
  }

  return { tipo: 'numero', ogniGiorni: min }
}
