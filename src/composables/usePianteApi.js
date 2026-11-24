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

    // spostata_il la scrive il database (trigger piante_data_spostamento) quando
    // la pianta passa dal chiuso all'aperto o viceversa: si rilegge qui.
    let spostataIl = null
    if (isNuova) {
      const { error } = await supabase.from('piante').insert({ id, ...riga, ultima_cura: {} })
      if (error) throw error
    } else {
      const { data, error } = await supabase.from('piante').update(riga).eq('id', id).select('spostata_il').maybeSingle()
      if (error) throw error
      spostataIl = data ? (data.spostata_il ?? null) : (precedente?.spostata_il ?? null)
    }

    store.piante = {
      ...store.piante,
      [id]: {
        voce, zona, sottozona: sottozona || null,
        varieta: riga.varieta, impianto: riga.impianto, impianto_circa: riga.impianto_circa,
        note: riga.note, coltivato_in: riga.coltivato_in,
        ultima_cura: isNuova ? {} : (precedente?.ultima_cura ?? {}),
        ultimo_concime_id: isNuova ? null : (precedente?.ultimo_concime_id ?? null),
        spostata_il: spostataIl,
      },
    }
  }

  // Sposta più piante insieme in una zona (e sottozona, facoltativa). inVaso:
  // id delle piante da segnare come coltivate in vaso nello stesso passaggio
  // (piante in piena terra portate al chiuso). Restituisce lo stato di prima
  // di ogni pianta toccata, da passare a ripristinaPosizioni per l'«Annulla».
  // Una scrittura per gruppo (con o senza il cambio a vaso): ognuna vale per
  // tutte le piante del gruppo o per nessuna.
  async function spostaPiante(ids, zona, sottozona = null, { inVaso = [] } = {}) {
    const zonaId = store.zone?.[zona]?.id
    if (!zonaId) throw new Error('zona non trovata')
    const sottozonaId = sottozona ? (store.sottozone?.[zona]?.[sottozona]?.id ?? null) : null
    if (sottozona && !sottozonaId) throw new Error('sottozona non trovata')
    const precedenti = ids.map(id => {
      const p = store.piante?.[id] ?? {}
      return { id, zona: p.zona, sottozona: p.sottozona ?? null, coltivato_in: p.coltivato_in ?? null, spostata_il: p.spostata_il ?? null }
    })
    const aVaso = new Set(inVaso)
    const gruppi = [
      { ids: ids.filter(id => aVaso.has(id)), extra: { coltivato_in: 'vaso' } },
      { ids: ids.filter(id => !aVaso.has(id)), extra: {} },
    ].filter(g => g.ids.length)
    const nuove = { ...store.piante }
    for (const g of gruppi) {
      const { data, error } = await supabase.from('piante')
        .update({ zona_id: zonaId, sottozona_id: sottozonaId, ...g.extra })
        .in('id', g.ids).select('id, spostata_il')
      if (error) throw error
      for (const r of data ?? []) {
        nuove[r.id] = { ...nuove[r.id], zona, sottozona: sottozona || null, spostata_il: r.spostata_il ?? null, ...g.extra }
      }
      store.piante = { ...nuove }
    }
    return precedenti
  }

  // Inverso di spostaPiante: rimette zona, sottozona, coltivazione e data di
  // spostamento com'erano (la data esplicita fa da precedente sul trigger).
  async function ripristinaPosizioni(precedenti) {
    await Promise.all(precedenti.map(async (p) => {
      const zonaId = store.zone?.[p.zona]?.id
      if (!zonaId) throw new Error('zona non trovata')
      const sottozonaId = p.sottozona ? (store.sottozone?.[p.zona]?.[p.sottozona]?.id ?? null) : null
      const { error } = await supabase.from('piante')
        .update({ zona_id: zonaId, sottozona_id: sottozonaId, coltivato_in: p.coltivato_in, spostata_il: p.spostata_il })
        .eq('id', p.id)
      if (error) throw error
      store.piante = { ...store.piante, [p.id]: { ...store.piante[p.id], zona: p.zona, sottozona: p.sottozona, coltivato_in: p.coltivato_in, spostata_il: p.spostata_il } }
    }))
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

  return { salvaPianta, eliminaPianta, registraCura, annullaCura, registraCuraMultipla, spostaPiante, ripristinaPosizioni }
}
