// CRUD piante su Supabase (Fase 5). Centralizza qui la logica comune agli
// 8 punti di scrittura sparsi in EditPiantaView/PianteView/PiantaView/
// AttivitaRiga/AttivitaView/SelettoreSpecie, invece di duplicarla: ognuno
// diventava un update/insert/delete quasi identico una volta lasciato il
// pattern "riscrivi l'intero piante.json" (saveJSON).

import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'
import { colonneDaChiave } from '@/utils/catalogo'

function oggi() {
  return new Date().toISOString().split('T')[0]
}

export function usePianteApi() {
  const store = useDatiStore()
  const supabase = useSupabase()

  // isNuova: se true, id è generato dal chiamante (stesso formato
  // "slug-timestamp" di sempre) e la riga viene creata; altrimenti id
  // identifica una riga esistente da aggiornare. voce è la chiave del catalogo
  // ("t:<uuid>" o "c:<uuid>", fase 6 del modello tassonomico): la pianta punta
  // a un taxon o a una cultivar (la vecchia colonna specie è stata tolta nella
  // fase 7).
  async function salvaPianta({ id, isNuova, voce, zona, sottozona, coltivato_in, varieta, impianto, impianto_circa, note }) {
    const colonne = colonneDaChiave(voce)
    if (!colonne) throw new Error('voce del catalogo mancante')
    const zonaId = store.zone?.[zona]?.id ?? null
    const sottozonaId = sottozona ? (store.sottozone?.[zona]?.[sottozona]?.id ?? null) : null
    const precedente = store.piante?.[id]
    const riga = {
      ...colonne, zona_id: zonaId, sottozona_id: sottozonaId,
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
        voce, zona, sottozona: sottozona || null,
        varieta: riga.varieta, impianto: riga.impianto, impianto_circa: riga.impianto_circa,
        note: riga.note, coltivato_in: riga.coltivato_in,
        ultima_cura: isNuova ? {} : (precedente?.ultima_cura ?? {}),
        ultimo_concime_id: isNuova ? null : (precedente?.ultimo_concime_id ?? null),
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

  // Una concimazione registrata da sola non dice con quale prodotto: azzera
  // ultimo_concime_id, che altrimenti indicherebbe il concime della volta prima.
  async function registraCura(id, tipo, data = oggi()) {
    const piantaEsistente = store.piante?.[id] ?? {}
    const ultima_cura = { ...(piantaEsistente.ultima_cura || {}), [tipo]: data }
    const modifica = tipo === 'concimazione' ? { ultima_cura, ultimo_concime_id: null } : { ultima_cura }
    const { error } = await supabase.from('piante').update(modifica).eq('id', id)
    if (error) throw error
    store.piante = { ...store.piante, [id]: { ...piantaEsistente, ...modifica } }
  }

  // Inverso di registraCura: ripristina il valore precedente di ultima_cura[tipo]
  // (o rimuove del tutto la chiave se la cura non era mai stata registrata prima),
  // per il toast "Annulla" dopo un "Fatto" — evita di lasciare l'unico dato usato
  // per calcolare le urgenze (Home, Attività) sovrascritto senza via di recupero.
  // Per la concimazione ripristina anche il concime usato: senza il quarto
  // argomento resta quello della pianta prima dell'annullamento.
  async function annullaCura(id, tipo, valorePrecedente, concimePrecedente) {
    const piantaEsistente = store.piante?.[id] ?? {}
    const ultima_cura = { ...(piantaEsistente.ultima_cura || {}) }
    if (valorePrecedente == null) delete ultima_cura[tipo]
    else ultima_cura[tipo] = valorePrecedente
    const modifica = tipo === 'concimazione' && concimePrecedente !== undefined
      ? { ultima_cura, ultimo_concime_id: concimePrecedente }
      : { ultima_cura }
    const { error } = await supabase.from('piante').update(modifica).eq('id', id)
    if (error) throw error
    store.piante = { ...store.piante, [id]: { ...piantaEsistente, ...modifica } }
  }

  // Raggruppa per pianta prima di scrivere: un gruppo può contenere più voci
  // per la stessa pianta (es. irrigazione E concimazione insieme), e ognuna
  // deve arrivare a un'unica riga jsonb finale — chiamare registraCura in
  // parallelo per la stessa pianta perderebbe una delle due (entrambe
  // leggerebbero lo stesso ultima_cura di partenza prima di scrivere).
  // concimeId: il prodotto usato per le voci di concimazione (cure per zona);
  // se manca, come per registraCura, il concime registrato si azzera.
  async function registraCuraMultipla(voci, data = oggi(), { concimeId = null } = {}) {
    const perPianta = new Map()
    for (const { piantaId, tipo } of voci) {
      if (!perPianta.has(piantaId)) perPianta.set(piantaId, { ultima_cura: { ...(store.piante?.[piantaId]?.ultima_cura ?? {}) } })
      const modifica = perPianta.get(piantaId)
      modifica.ultima_cura[tipo] = data
      if (tipo === 'concimazione') modifica.ultimo_concime_id = concimeId
    }
    await Promise.all([...perPianta.entries()].map(async ([id, modifica]) => {
      const { error } = await supabase.from('piante').update(modifica).eq('id', id)
      if (error) throw error
      store.piante = { ...store.piante, [id]: { ...store.piante[id], ...modifica } }
    }))
  }

  return { salvaPianta, eliminaPianta, registraCura, annullaCura, registraCuraMultipla }
}
