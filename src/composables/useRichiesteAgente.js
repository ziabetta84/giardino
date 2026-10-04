import { useApi } from '@/composables/useApi'
// Richieste Zorba dice (richieste-agente.json): logica condivisa tra
// AgenteView.vue (storico completo, nel Foglio) e ZorbaDiceSidebar.vue (le
// ultime poche, su schermi larghi) — estratta da AgenteView.vue perché la
// sidebar ha bisogno della stessa mappa tipo→icona/etichetta e dello stesso
// titolo per riga, non di una propria versione che rischierebbe di
// disallinearsi (es. un'icona diversa per lo stesso tipo nei due posti).

export const TIPI_RICHIESTA = [
  { value: 'identifica_specie',      label: 'Identifica da foto',        icon: 'foglia',       hint: 'Carica una foto: Zorba prova a riconoscere la specie.' },
  { value: 'revisione_specie',       label: 'Revisiona/completa specie', icon: 'matita',        hint: 'Zorba controlla i campi mancanti o incompleti della scheda e li completa.' },
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

// store: istanza di useDatiStore(), passata esplicita invece di richiamata
// qui dentro — questo composable resta puro, senza un proprio accoppiamento
// nascosto al Pinia store.
export function titoloRichiesta(r, store) {
  if (r.tipo === 'revisione_specie' && r.specie) return store.specie?.[r.specie]?.nome ?? r.specie
  if (r.tipo === 'pianifica_progetto') {
    if (r.progetto) return store.progetti?.[r.progetto]?.titolo ?? infoTipo(r.tipo).label
    if (r.titolo_progetto) return r.titolo_progetto
  }
  return r.messaggio || infoTipo(r.tipo).label
}

export function formatData(iso) {
  if (!iso) return ''
  return new Date(iso).toLocaleDateString('it-IT', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })
}

// BASE_URL (non import.meta.env.BASE_URL diretto): lo stesso valore usato da
// AgenteView.vue, qui dentro perché questo file può essere importato anche
// fuori da un componente.
const BASE = import.meta.env.BASE_URL

// Prima da GitHub (sempre coerente con l'ultimo salvataggio, senza aspettare
// build+deploy), poi fallback sulla copia statica pubblicata. Niente
// `?t=${Date.now()}` sul fallback: quella query string disattiva la regola
// NetworkFirst del service worker (vite.config.js), pensata per restare
// consultabili offline/con rete debole.
export async function caricaRichiesteAgente() {
  const { loadJSON } = useApi()
  try {
    return await loadJSON('richieste-agente.json')
  } catch {
    try {
      const res = await fetch(`${BASE}data/richieste-agente.json`)
      return res.ok ? await res.json() : {}
    } catch {
      return {}
    }
  }
}
