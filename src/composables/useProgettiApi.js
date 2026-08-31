// CRUD progetti/tappe su Supabase (completamento Fase 5). registraTappa
// aggiorna una singola riga tappe per id: a differenza di salvaProgetto
// (che riconcilia l'intero form), è pensato per essere sicuro sotto
// scritture concorrenti — vedi la spec per il motivo della tabella tappe
// separata invece di un campo jsonb su progetti.

import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'

export function useProgettiApi() {
  const store = useDatiStore()
  const supabase = useSupabase()

  // dati.tappe: array locale (form) con { id?, data, descrizione, esito }.
  // Tappe senza id sono nuove (insert); quelle con id il cui contenuto è
  // cambiato rispetto allo snapshot originale vengono aggiornate; quelle
  // presenti nello snapshot ma assenti dall'array locale vengono eliminate.
  async function salvaProgetto(id, dati, isNuova = false) {
    try {
      const riga = {
        titolo: dati.titolo, descrizione: dati.descrizione || null,
        zona: dati.zona || null, stato: dati.stato, creato: dati.creato,
      }

      let progettoId = id
      if (isNuova) {
        const { data, error } = await supabase.from('progetti').insert(riga).select().single()
        if (error) throw error
        progettoId = data.id
      } else {
        const { error } = await supabase.from('progetti').update(riga).eq('id', id)
        if (error) throw error
      }

      const originali = new Map((store.progetti?.[id]?.tappe ?? []).map(t => [t.id, t]))
      const localiConId = new Set((dati.tappe ?? []).filter(t => t.id).map(t => t.id))

      for (const [tappaId] of originali) {
        if (!localiConId.has(tappaId)) {
          const { error } = await supabase.from('tappe').delete().eq('id', tappaId)
          if (error) throw error
        }
      }

      const tappeFinali = []
      for (const t of (dati.tappe ?? [])) {
        const rigaTappa = { data: t.data, descrizione: t.descrizione.trim(), esito: t.esito || 'atteso' }
        if (t.id) {
          const originale = originali.get(t.id)
          const patch = {}
          if (!originale || originale.data !== rigaTappa.data) patch.data = rigaTappa.data
          if (!originale || originale.descrizione !== rigaTappa.descrizione) patch.descrizione = rigaTappa.descrizione
          if (!originale || originale.esito !== rigaTappa.esito) patch.esito = rigaTappa.esito
          if (Object.keys(patch).length) {
            const { error } = await supabase.from('tappe').update(patch).eq('id', t.id)
            if (error) throw error
          }
          tappeFinali.push({
            id: t.id,
            data: 'data' in patch ? patch.data : originale.data,
            descrizione: 'descrizione' in patch ? patch.descrizione : originale.descrizione,
            esito: 'esito' in patch ? patch.esito : originale.esito,
          })
        } else {
          const { data, error } = await supabase.from('tappe')
            .insert({ ...rigaTappa, progetto_id: progettoId }).select().single()
          if (error) throw error
          tappeFinali.push({ id: data.id, ...rigaTappa })
        }
      }
      tappeFinali.sort((a, b) => (a.data || '').localeCompare(b.data || ''))

      store.progetti = {
        ...store.progetti,
        [progettoId]: { ...riga, tappe: tappeFinali },
      }
      return progettoId
    } catch (e) {
      await store.aggiorna()
      throw e
    }
  }

  async function eliminaProgetto(id) {
    const { error } = await supabase.from('progetti').delete().eq('id', id)
    if (error) throw error
    const nuovi = { ...store.progetti }
    delete nuovi[id]
    store.progetti = nuovi
  }

  // Aggiorna una singola tappa per id — atomico, nessuna race con salvaProgetto.
  async function registraTappa(tappaId, esito = 'riuscito') {
    const { error } = await supabase.from('tappe').update({ esito }).eq('id', tappaId)
    if (error) throw error
    const nuovi = { ...store.progetti }
    for (const pid of Object.keys(nuovi)) {
      const tappe = nuovi[pid].tappe
      const i = tappe.findIndex(t => t.id === tappaId)
      if (i !== -1) {
        nuovi[pid] = { ...nuovi[pid], tappe: tappe.map((t, idx) => idx === i ? { ...t, esito } : t) }
        break
      }
    }
    store.progetti = nuovi
  }

  return { salvaProgetto, eliminaProgetto, registraTappa }
}
