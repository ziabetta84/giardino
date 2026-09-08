// CRUD dei programmi di irrigazione automatica (tabella
// programmi_irrigazione). A differenza di usePianteApi.js non fa mai
// upsert: gli indici unique sono uno per livello (vedi la migration), e
// PostgREST non sa abbinare un ON CONFLICT a un indice unique parziale —
// un insert/update esplicito in base all'id già noto (o assente) resta più
// semplice e chiaro.
import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'

// target: 'giardino' | { zona: nomeZona } | { zona: nomeZona, sottozona: nomeSottozona } | { pianta: piantaId }
// La chiave composta "<zona>|<sottozona>" (stesso separatore di
// raggruppaAttivita.js) evita di dover annidare un altro livello di
// oggetti solo per questa mappa: i nomi di sottozona sono unici solo
// dentro la propria zona, non globalmente.
function chiaviTarget(target) {
  if (target === 'giardino') return { chiave: 'giardino', chiaveVoce: null }
  if (target.pianta) return { chiave: 'piante', chiaveVoce: target.pianta }
  if (target.sottozona) return { chiave: 'sottozone', chiaveVoce: `${target.zona}|${target.sottozona}` }
  return { chiave: 'zone', chiaveVoce: target.zona }
}

export function useIrrigazioneApi() {
  const store = useDatiStore()
  const supabase = useSupabase()

  function programmaEsistente(chiave, chiaveVoce) {
    return chiave === 'giardino'
      ? store.programmiIrrigazione?.giardino ?? null
      : store.programmiIrrigazione?.[chiave]?.[chiaveVoce] ?? null
  }

  function patchStore(chiave, chiaveVoce, voce) {
    // store.programmiIrrigazione può essere null (caricamento iniziale da
    // Supabase fallito, vedi stores/dati.js) o comunque privo di uno dei tre
    // livelli: senza normalizzare qui, uno spread lascerebbe mancante
    // giardino/zone/piante e ogni lettura successiva del resolver
    // (useIrrigazioneAuto.js) esploderebbe in tutta l'app.
    const base = store.programmiIrrigazione ?? { giardino: null, zone: {}, piante: {} }
    if (chiave === 'giardino') {
      store.programmiIrrigazione = { ...base, giardino: voce }
      return
    }
    const copia = { ...base[chiave] }
    if (voce) copia[chiaveVoce] = voce
    else delete copia[chiaveVoce]
    store.programmiIrrigazione = { ...base, [chiave]: copia }
  }

  async function salvaProgramma(target, ogniGiorni) {
    const { chiave, chiaveVoce } = chiaviTarget(target)
    const esistente = programmaEsistente(chiave, chiaveVoce)

    const riga = {
      zona_id: target !== 'giardino' && target.zona && !target.sottozona ? (store.zone?.[target.zona]?.id ?? null) : null,
      sottozona_id: target !== 'giardino' && target.sottozona ? (store.sottozone?.[target.zona]?.[target.sottozona]?.id ?? null) : null,
      pianta_id: target !== 'giardino' && target.pianta ? target.pianta : null,
      ogni_giorni: ogniGiorni,
    }

    let id = esistente?.id ?? null
    if (id) {
      const { error } = await supabase.from('programmi_irrigazione').update(riga).eq('id', id)
      if (error) throw error
    } else {
      const { data, error } = await supabase.from('programmi_irrigazione').insert(riga).select().single()
      if (error) throw error
      id = data.id
    }

    patchStore(chiave, chiaveVoce, { id, ogniGiorni })
  }

  async function rimuoviProgramma(target) {
    const { chiave, chiaveVoce } = chiaviTarget(target)
    const esistente = programmaEsistente(chiave, chiaveVoce)
    if (!esistente) return

    const { error } = await supabase.from('programmi_irrigazione').delete().eq('id', esistente.id)
    if (error) throw error

    patchStore(chiave, chiaveVoce, null)
  }

  return { salvaProgramma, rimuoviProgramma }
}
