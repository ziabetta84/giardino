// CRUD piante su Supabase (Fase 5). Centralizza qui la logica comune agli
// 8 punti di scrittura sparsi in EditPiantaView/PianteView/PiantaView/
// AttivitaRiga/AttivitaView/SelettoreSpecie, invece di duplicarla: ognuno
// diventava un update/insert/delete quasi identico una volta lasciato il
// pattern "riscrivi l'intero piante.json" (saveJSON).

import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'

function oggi() {
  return new Date().toISOString().split('T')[0]
}

export function usePianteApi() {
  const store = useDatiStore()
  const supabase = useSupabase()

  // isNuova: se true, id è generato dal chiamante (stesso formato
  // "slug-timestamp" di sempre) e la riga viene creata; altrimenti id
  // identifica una riga esistente da aggiornare.
  async function salvaPianta({ id, isNuova, specie, zona, sottozona, coltivato_in, varieta, impianto, impianto_circa, note }) {
    const zonaId = store.zone?.[zona]?.id ?? null
    const sottozonaId = sottozona ? (store.sottozone?.[zona]?.[sottozona]?.id ?? null) : null
    const riga = {
      specie, zona_id: zonaId, sottozona_id: sottozonaId,
      varieta: varieta || '', impianto: impianto || '', impianto_circa: impianto_circa || '',
      note: note || '', coltivato_in: coltivato_in || null,
    }

    if (isNuova) {
      const { error } = await supabase.from('piante').insert({ id, ...riga, ultima_cura: {} })
      if (error) throw error
    } else {
      const { error } = await supabase.from('piante').update(riga).eq('id', id)
      if (error) throw error
    }

    store.piante = {
      ...store.piante,
      [id]: {
        specie, zona, sottozona: sottozona || null,
        varieta: riga.varieta, impianto: riga.impianto, impianto_circa: riga.impianto_circa,
        note: riga.note, coltivato_in: riga.coltivato_in,
        ultima_cura: isNuova ? {} : (store.piante?.[id]?.ultima_cura ?? {}),
      },
    }
  }

  async function eliminaPianta(id) {
    const { error } = await supabase.from('piante').delete().eq('id', id)
    if (error) throw error
    const nuove = { ...store.piante }
    delete nuove[id]
    store.piante = nuove
  }

  async function registraCura(id, tipo, data = oggi()) {
    const piantaEsistente = store.piante?.[id] ?? {}
    const ultima_cura = { ...(piantaEsistente.ultima_cura || {}), [tipo]: data }
    const { error } = await supabase.from('piante').update({ ultima_cura }).eq('id', id)
    if (error) throw error
    store.piante = { ...store.piante, [id]: { ...piantaEsistente, ultima_cura } }
  }

  // Raggruppa per pianta prima di scrivere: un gruppo può contenere più voci
  // per la stessa pianta (es. irrigazione E concimazione insieme), e ognuna
  // deve arrivare a un'unica riga jsonb finale — chiamare registraCura in
  // parallelo per la stessa pianta perderebbe una delle due (entrambe
  // leggerebbero lo stesso ultima_cura di partenza prima di scrivere).
  async function registraCuraMultipla(voci, data = oggi()) {
    const perPianta = new Map()
    for (const { piantaId, tipo } of voci) {
      if (!perPianta.has(piantaId)) perPianta.set(piantaId, { ...(store.piante?.[piantaId]?.ultima_cura ?? {}) })
      perPianta.get(piantaId)[tipo] = data
    }
    await Promise.all([...perPianta.entries()].map(async ([id, ultima_cura]) => {
      const { error } = await supabase.from('piante').update({ ultima_cura }).eq('id', id)
      if (error) throw error
      store.piante = { ...store.piante, [id]: { ...store.piante[id], ultima_cura } }
    }))
  }

  return { salvaPianta, eliminaPianta, registraCura, registraCuraMultipla }
}
