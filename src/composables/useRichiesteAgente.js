// Fili di Zorba dice (tabelle Supabase, vedi useZorba.js): logica condivisa tra
// AgenteView.vue (storico completo, nel Foglio) e ZorbaDiceSidebar.vue (le
// ultime poche, su schermi larghi) — estratta da AgenteView.vue perché la
// sidebar ha bisogno della stessa mappa tipo→icona/etichetta e dello stesso
// titolo per riga, non di una propria versione che rischierebbe di
// disallinearsi (es. un'icona diversa per lo stesso tipo nei due posti).

export const TIPI_RICHIESTA = [
  { value: 'identifica_specie',      label: 'Identifica da foto',        icon: 'foglia',       hint: 'Carica una foto: Zorba prova a riconoscere la specie.' },
  { value: 'segnalazione_scheda',    label: 'Segnala un problema nella scheda', icon: 'matita', hint: 'Scegli la pianta del catalogo e scrivi cosa non torna: Zorba ti dà un primo parere e la segnalazione passa a chi cura il catalogo.' },
  { value: 'consiglio_cura',         label: 'Consiglio per cura',        icon: 'goccia',        hint: 'Descrivi la pianta o il problema: Zorba consiglia come curarla.' },
  { value: 'consiglio_concimazione', label: 'Consiglio concimazione',    icon: 'concimazione',  hint: 'Zorba suggerisce quale concime della dispensa usare e con che dose.' },
  { value: 'diagnosi',               label: 'Diagnosi problema',         icon: 'cerca',         hint: 'Foto o descrizione di un problema: Zorba prova a capire cosa non va.' },
  { value: 'pianifica_progetto',     label: 'Pianifica progetto',        icon: 'lampadina',     hint: 'Descrivi cosa vuoi fare: Zorba genera le tappe con le date attese.' },
  { value: 'altro',                  label: 'Altro',                     icon: null,            hint: 'Qualcosa che non rientra nelle altre categorie.' },
]
const TIPI_MAP = Object.fromEntries(TIPI_RICHIESTA.map(t => [t.value, t]))

export function infoTipo(tipo) {
  return TIPI_MAP[tipo] ?? { label: tipo?.replace(/_/g, ' ') ?? '', icon: null }
}

// store: istanza di useDatiStore(), passata esplicita: questo modulo resta puro.
export function titoloFilo(f, store) {
  if (f.tipo === 'segnalazione_scheda' && f.voce) return f.nome_voce ?? store.catalogo?.[f.voce]?.nome ?? infoTipo(f.tipo).label
  if (f.tipo === 'pianifica_progetto') {
    if (f.progetto_id) return store.progetti?.[f.progetto_id]?.titolo ?? f.titolo_progetto ?? infoTipo(f.tipo).label
    if (f.titolo_progetto) return f.titolo_progetto
  }
  return f.primo_testo || infoTipo(f.tipo).label
}

export function formatData(iso) {
  if (!iso) return ''
  return new Date(iso).toLocaleDateString('it-IT', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })
}
