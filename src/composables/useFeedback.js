// Feedback della beta (migration 20261120100000_feedback_beta.sql): invio e lettura dei propri messaggi.
// I client possono solo inserire e leggere le proprie righe; stato e risposta li scrive il curatore.
// Il dispositivo è solo «telefono» o «computer»: niente user agent completo, niente dati più identificativi del necessario.

import { useSupabase } from '@/composables/useSupabase'

export const CATEGORIE = [
  { valore: 'problema', etichetta: 'Qualcosa non funziona' },
  { valore: 'non_riesco', etichetta: 'Non riesco a fare una cosa' },
  { valore: 'idea', etichetta: "Un'idea" },
]

export const ETICHETTE_STATO = {
  nuovo: 'Ricevuto',
  letto: 'Letto',
  risolto: 'Risolto',
  non_previsto: 'Non previsto per ora',
}

export const LIMITE_TESTO = 1000

function dispositivo() {
  const ua = typeof navigator !== 'undefined' ? navigator.userAgent : ''
  return /Mobi|Android|iPhone|iPad/i.test(ua) ? 'telefono' : 'computer'
}

// Messaggi in italiano per gli errori noti; il resto diventa una frase generica, mai il testo tecnico.
function traduci(error) {
  if (String(error?.message ?? '').includes('feedback:limite_giornaliero')) {
    return 'Per oggi hai già inviato 20 messaggi. Puoi scrivere di nuovo domani.'
  }
  if (String(error?.message ?? '').includes('feedback_testo_check')) {
    return 'Scrivi qualcosa prima di inviare.'
  }
  return 'Non siamo riusciti a inviare. Il testo è rimasto qui: riprova tra poco.'
}

export function useFeedback() {
  const supabase = useSupabase()

  // Ultimi 50 messaggi dell'utente, dal più recente.
  async function elenca() {
    const { data, error } = await supabase
      .from('feedback')
      .select('id, categoria, testo, stato, risposta, creato')
      .order('creato', { ascending: false })
      .limit(50)
    if (error) throw error
    return data ?? []
  }

  // pagina: percorso dell'app da cui si scrive, senza parametri. La versione è il commit della build.
  async function invia({ categoria, testo, pagina }) {
    const riga = {
      categoria,
      testo: testo.trim(),
      pagina: (pagina || '').slice(0, 200) || null,
      versione: (typeof __APP_COMMIT__ !== 'undefined' ? String(__APP_COMMIT__) : '').slice(0, 40) || null,
      dispositivo: dispositivo(),
    }
    const { data, error } = await supabase.from('feedback').insert(riga).select().single()
    if (error) throw new Error(traduci(error))
    return data
  }

  return { elenca, invia, traduci }
}
