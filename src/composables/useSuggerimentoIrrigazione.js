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
// Frasi che indicano un riposo vegetativo vero e proprio (non solo "nessun
// dato"), usate SOLO quando dal testo non si riesce a estrarre un numero
// (vedi sotto: parseGiorni ha sempre la precedenza) — così una parola
// qualificatrice come "ridotta" accanto a una cadenza reale ("ogni 15-20
// giorni, ridotta per il riposo estivo") non scarta il numero vero. `mai\b`
// è stato tolto perché nel linguaggio reale delle schede specie compare
// quasi sempre in note di tecnica che vogliono dire il contrario di
// "riposo" ("mai secco", "mai il tubero direttamente" per il ciclamino: la
// pianta è in piena crescita e va irrigata regolarmente).
const RIPOSO_REGEX = /nessun|sospes|non necessari|ridott|dirad/i

export function suggerimentoIrrigazione(piante, specie) {
  const stagCorrente = stagione()
  const voci = piante
    .map(p => {
      const sp = specie?.[p.specie]
      const testo = sp?.manutenzione?.irrigazione?.[stagCorrente]
      if (!testo) return null
      const nomeSpecie = sp?.nome ?? p.specie
      const intervallo = parseGiorni(testo)
      if (intervallo) return { nomeSpecie, intervallo, riposo: false }
      if (RIPOSO_REGEX.test(testo)) return { nomeSpecie, riposo: true }
      return null
    })
    .filter(Boolean)

  if (!voci.length) return null

  const numeriche = voci.filter(v => !v.riposo)
  const inRiposo = voci.filter(v => v.riposo)

  // Un mix di "ha bisogno regolare d'acqua" e "in riposo" è divergente per
  // definizione, indipendentemente dalla soglia numerica sotto — un numero
  // solo bagnerebbe chi non ne ha bisogno.
  if (inRiposo.length && numeriche.length) {
    const piuEsigente = numeriche.reduce((a, b) => (a.intervallo < b.intervallo ? a : b))
    return {
      tipo: 'divergente',
      piuEsigente: piuEsigente.nomeSpecie,
      minGiorni: piuEsigente.intervallo,
      menoEsigente: inRiposo[0].nomeSpecie,
      maxGiorni: null,
    }
  }

  if (!numeriche.length) return null

  const intervalli = numeriche.map(v => v.intervallo)
  const min = Math.min(...intervalli)
  const max = Math.max(...intervalli)

  if (numeriche.length > 1 && max >= min * SOGLIA_DIVERGENZA_IRRIGAZIONE) {
    return {
      tipo: 'divergente',
      piuEsigente: numeriche.find(v => v.intervallo === min).nomeSpecie,
      minGiorni: min,
      menoEsigente: numeriche.find(v => v.intervallo === max).nomeSpecie,
      maxGiorni: max,
    }
  }

  return {
    tipo: 'numero',
    ogniGiorni: min,
    // Quante delle piante passate hanno davvero contribuito al numero (le
    // rimanenti non hanno un dato utilizzabile per questa stagione, non
    // sono "in riposo" — quel caso è già gestito sopra). Se sono meno del
    // totale, l'interfaccia lo dichiara invece di sembrare più sicura di
    // quanto i dati permettano.
    copertura: { conteggio: numeriche.length, totale: piante.length },
  }
}
