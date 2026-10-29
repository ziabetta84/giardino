import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useMeteo, posizioneGiardino } from '@/composables/useMeteo'
import { useSupabase } from '@/composables/useSupabase'
import { irrigazioneDaRegistrareOggi } from '@/composables/useCure'
import { programmaIrrigazioneEffettivo } from '@/composables/useIrrigazioneAuto'
import { chiavePianta } from '@/utils/catalogo'

// Catalogo (fase 6 del modello tassonomico): le piante puntano a un taxon o a una cultivar, e il database calcola per
// ognuno una «voce» (nome mostrato, nome scientifico, campi della scheda ereditati campo per campo dal livello sopra,
// vedi la migration 20261021100000_tassonomia_fase6_catalogo.sql). I campi hanno gli stessi nomi di prima (nome,
// specie, descrizione, esigenze, manutenzione, coltivazione…), quindi le viste cambiano solo il modo di trovarla:
// store.vocePianta(p) invece della vecchia ricerca per slug. Le voci delle piante si chiedono con una GET (in cache nel
// service worker: restano consultabili offline). La vecchia tabella specie è solo un archivio (fase 7).
async function rpcGet(supabase, funzione, argomenti) {
  const { data, error } = await supabase.rpc(funzione, argomenti, { get: true })
  if (error) throw error
  return data ?? {}
}


// Zone/sottozone/piante (Fase 5): tabelle Supabase con FK a UUID, ma lo
// store espone la stessa forma keyed-by-nome di sempre (store.zone["Est"],
// pianta.zona === "Est") — le ~15 view che leggono zona/sottozona come
// stringa non cambiano. Ogni voce zona/sottozona porta con sé anche `id`
// (non presente prima): serve solo al livello di scrittura (usePianteApi.js
// e le view di zone/sottozone), nessuna view esistente lo usa nel template.
export function mappaZone(righeZone) {
  return Object.fromEntries(righeZone.map(z => [z.nome, {
    id: z.id,
    nome: z.nome,
    descrizione: z.descrizione,
    esposizione: z.esposizione,
    microclima: z.microclima,
    criticita: z.criticita,
    manutenzione: z.manutenzione,
    tipo: z.tipo,
    icona: z.icona,
  }]))
}

export function mappaSottozone(righeSottozone, zonaNomePerId) {
  const risultato = {}
  for (const sz of righeSottozone) {
    const nomeZona = zonaNomePerId[sz.zona_id]
    if (!nomeZona) continue  // zona_id orfano: non dovrebbe succedere (FK), ignorata per sicurezza
    if (!risultato[nomeZona]) risultato[nomeZona] = {}
    risultato[nomeZona][sz.nome] = {
      id: sz.id,
      nome: sz.nome,
      descrizione: sz.descrizione,
      esposizione: sz.esposizione,
      microclima: sz.microclima,
      criticita: sz.criticita,
      manutenzione: sz.manutenzione,
      tipo: sz.tipo,
      icona: sz.icona,
    }
  }
  return risultato
}

export function mappaPiante(righePiante, zonaNomePerId, sottozonaNomePerId) {
  return Object.fromEntries(righePiante.map(p => [p.id, {
    voce: chiavePianta(p),
    zona: zonaNomePerId[p.zona_id] ?? null,
    sottozona: p.sottozona_id ? (sottozonaNomePerId[p.sottozona_id] ?? null) : null,
    varieta: p.varieta,
    impianto: p.impianto,
    impianto_circa: p.impianto_circa,
    note: p.note,
    coltivato_in: p.coltivato_in,
    ultima_cura: p.ultima_cura ?? {},
  }]))
}

// progetti/tappe (completamento Fase 5): stesso pattern di mappaZone/
// mappaSottozone — righe piatte da Supabase, ricostruite nella forma
// keyed-by-id con tappe annidate che le view già conoscono.
export function mappaProgetti(righeProgetti, righeTappe) {
  const tappePerProgetto = {}
  for (const t of righeTappe) {
    (tappePerProgetto[t.progetto_id] ??= []).push({
      id: t.id, data: t.data, descrizione: t.descrizione, esito: t.esito,
    })
  }
  for (const lista of Object.values(tappePerProgetto)) {
    lista.sort((a, b) => (a.data || '').localeCompare(b.data || ''))
  }
  return Object.fromEntries(righeProgetti.map(p => [p.id, {
    titolo: p.titolo, descrizione: p.descrizione, zona: p.zona,
    stato: p.stato, creato: p.creato,
    tappe: tappePerProgetto[p.id] ?? [],
  }]))
}

export function mappaConcimi(righeConcimi) {
  return Object.fromEntries(righeConcimi.map(c => [c.id, {
    nome: c.nome, npk: c.npk, disponibile: c.disponibile, descrizione: c.descrizione,
  }]))
}

// Irrigazione automatica: righe piatte da Supabase ricostruite come cascata
// pronta all'uso — pianta_id/sottozona_id/zona_id tutti null = livello
// giardino; sottozona_id ha priorità su zona_id quando entrambi sarebbero
// applicabili (vedi programmaIrrigazioneEffettivo in useIrrigazioneAuto.js).
// sottozona_id/zona_id orfani ignorati per sicurezza, stesso criterio di
// mappaSottozone.
export function mappaProgrammiIrrigazione(righeProgrammi, zonaNomePerId, sottozonaInfoPerId) {
  const risultato = { giardino: null, zone: {}, sottozone: {}, piante: {} }
  for (const r of righeProgrammi) {
    const voce = { id: r.id, ogniGiorni: r.ogni_giorni }
    if (r.pianta_id) {
      risultato.piante[r.pianta_id] = voce
    } else if (r.sottozona_id) {
      const info = sottozonaInfoPerId[r.sottozona_id]
      if (info?.zonaNome) risultato.sottozone[`${info.zonaNome}|${info.nome}`] = voce
    } else if (r.zona_id) {
      const nomeZona = zonaNomePerId[r.zona_id]
      if (nomeZona) risultato.zone[nomeZona] = voce
    } else {
      risultato.giardino = voce
    }
  }
  return risultato
}

export function mappaSettings(rigaSettings) {
  if (!rigaSettings) return null
  return {
    location: rigaSettings.location, units: rigaSettings.units,
    meteo: rigaSettings.meteo, ui: rigaSettings.ui,
    zona_climatica_id: rigaSettings.zona_climatica_id,
  }
}

export const useDatiStore = defineStore('dati', () => {
  const piante    = ref(null)
  const catalogo  = ref(null)
  const zone      = ref(null)
  const sottozone = ref(null)
  const progetti  = ref(null)
  const settings  = ref(null)
  const concimi   = ref(null)
  const programmiIrrigazione = ref(null)
  const meteo     = ref(null)
  const loading   = ref(false)
  const errore    = ref(null)

  // App.vue (all'avvio) e ogni singola view che ne ha bisogno (stesso
  // pattern in tutta l'app) chiamano caricaTutto() nel proprio onMounted:
  // la sessione (che sblocca il mount di App.vue e della prima rotta) si
  // risolve molto prima delle query Supabase qui sotto, quindi la seconda
  // chiamata partiva prima che piante.value fosse valorizzato dalla prima e
  // duplicava l'intero caricamento invece di attendere quello già in corso.
  // Condividendo la stessa promessa fra chiamate concorrenti, la seconda
  // aspetta la prima invece di rilanciarla.
  let promessaCaricamento = null

  async function caricaTutto() {
    if (piante.value) return  // già caricati
    if (promessaCaricamento) return promessaCaricamento
    promessaCaricamento = eseguiCaricamento()
    try {
      await promessaCaricamento
    } finally {
      promessaCaricamento = null
    }
  }

  async function eseguiCaricamento() {
    loading.value = true
    errore.value = null
    try {
      const supabase = useSupabase()
      async function query(builder) {
        const { data, error } = await builder
        if (error) throw error
        return data ?? []
      }

      const [righeZone, righeSottozone, righePiante, righeProgetti, righeTappe, righeSettings, righeConcimi, righeProgrammiIrrigazione] =
        await Promise.all([
          query(supabase.from('zone').select('*')),
          query(supabase.from('sottozone').select('*')),
          query(supabase.from('piante').select('*')),
          query(supabase.from('progetti').select('*')),
          query(supabase.from('tappe').select('*')),
          query(supabase.from('settings').select('*')),
          query(supabase.from('concimi').select('*')),
          query(supabase.from('programmi_irrigazione').select('*')),
        ])

      const zonaNomePerId = Object.fromEntries(righeZone.map(z => [z.id, z.nome]))
      const sottozonaNomePerId = Object.fromEntries(righeSottozone.map(s => [s.id, s.nome]))
      const sottozonaInfoPerId = Object.fromEntries(righeSottozone.map(s => [s.id, { zonaNome: zonaNomePerId[s.zona_id], nome: s.nome }]))
      zone.value      = mappaZone(righeZone)
      sottozone.value = mappaSottozone(righeSottozone, zonaNomePerId)
      piante.value    = mappaPiante(righePiante, zonaNomePerId, sottozonaNomePerId)
      progetti.value  = mappaProgetti(righeProgetti, righeTappe)
      concimi.value   = mappaConcimi(righeConcimi)
      programmiIrrigazione.value = mappaProgrammiIrrigazione(righeProgrammiIrrigazione, zonaNomePerId, sottozonaInfoPerId)
      settings.value  = mappaSettings(righeSettings[0] ?? null)

      // Voci del catalogo: quelle delle piante (una richiesta, filtrata dall'RLS). Senza rete e senza cache: catalogo vuoto, le viste
      // mostrano il nome di riserva (nomePianta) invece di rompersi.
      try {
        catalogo.value = await rpcGet(supabase, 'catalogo_mie_piante')
      } catch (e) {
        console.error('Catalogo non disponibile', e)
        catalogo.value = catalogo.value ?? {}
      }

      // Previsioni meteo (solo oggi/domani): usate da useCure per sospendere
      // l'irrigazione delle piante esterne quando è prevista pioggia
      // sufficiente. Dentro il try, non dopo: useMeteo().carica() cattura già
      // i propri errori di rete internamente (non li rilancia, vedi
      // useMeteo.js) quindi non può far scattare il catch qui sotto — ma
      // deve restare coperta da `loading` insieme al resto, altrimenti
      // loading torna false prima che il meteo sia arrivato e la riga meteo
      // in Home mostra "non disponibile" invece di "in caricamento" per la
      // finestra in cui sta ancora arrivando (vedi critica del 07/09/2026).
      // Senza posizione impostata non c'è meteo (vedi posizioneGiardino in
      // useMeteo.js).
      await caricaMeteo()

      // Programma automatico attivo ma comunque dovuto oggi: lo registriamo
      // da soli invece di continuare a segnalarlo come cura da fare —
      // l'utente ha già delegato quella decisione scegliendo un programma
      // automatico. Gira a ogni caricamento completo dello store (chiamato
      // sia da caricaTutto() che da aggiorna(), non solo alla prima
      // apertura di sessione), dopo che piante/specie/zone/programmi sono
      // tutti pronti — è idempotente (una volta registrata, non risulta più
      // dovuta finché non passa un intero intervallo), quindi rieseguirlo
      // più volte nella stessa giornata non produce scritture ripetute.
      // Try/catch proprio: un fallimento di rete isolato qui non deve
      // trasformarsi in un errore che nasconde dati già caricati con
      // successo (stesso principio già applicato al meteo qui sopra).
      // La sospensione da pioggia prevista NON registra nulla, di proposito
      // (vedi il commento su irrigazioneDaRegistrareOggi in useCure.js):
      // resta pura sospensione del promemoria, come già oggi.
      try {
        const daRegistrare = []
        for (const [id, p] of Object.entries(piante.value)) {
          const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, p.sottozona, programmiIrrigazione.value)?.ogniGiorni ?? null
          if (irrigazioneDaRegistrareOggi(p, { programmaAutomatico })) {
            daRegistrare.push(id)
          }
        }
        if (daRegistrare.length) {
          const oggiStr = new Date().toISOString().split('T')[0]
          await Promise.all(daRegistrare.map(async id => {
            const { data, error } = await supabase.rpc('registra_cura_pianta', { pianta_id: id, tipo_cura: 'irrigazione', data_cura: oggiStr })
            if (error) throw error
            if (!data?.id) return // nessuna riga toccata (RLS, riga sparita altrove): PostgREST serializza una riga composita NULL come oggetto con tutti i campi null, non come null — va controllato un campo (la chiave primaria, mai null su una riga reale), non la verità dell'intero oggetto
            piante.value = { ...piante.value, [id]: { ...piante.value[id], ultima_cura: data.ultima_cura } }
          }))
        }
      } catch (e) {
        console.error('Registrazione automatica irrigazione fallita:', e)
      }
    } catch (e) {
      errore.value = e.message
    } finally {
      loading.value = false
    }
  }

  function aggiungiVoci(voci) {
    catalogo.value = { ...(catalogo.value ?? {}), ...voci }
  }

  // Scarica le voci che mancano (al più 200 per richiesta, il limite di catalogo_voci)
  async function caricaVoci(chiavi) {
    const mancanti = [...new Set(chiavi.filter(k => k && !catalogo.value?.[k]))]
    for (let i = 0; i < mancanti.length; i += 200) {
      aggiungiVoci(await rpcGet(useSupabase(), 'catalogo_voci', { chiavi: mancanti.slice(i, i + 200) }))
    }
  }

  function vocePianta(pianta) {
    return pianta?.voce ? (catalogo.value?.[pianta.voce] ?? null) : null
  }

  // Nome da mostrare per una pianta; senza voce (offline alla prima apertura) «Pianta»
  function nomePianta(pianta) {
    return vocePianta(pianta)?.nome ?? 'Pianta'
  }

  async function caricaMeteo() {
    // Senza posizione: nessuna previsione (lista vuota, non null: «caricato,
    // ma niente da mostrare»), quindi nessuna irrigazione sospesa per pioggia.
    const posizione = posizioneGiardino(settings.value)
    if (!posizione) { meteo.value = []; return }
    const { giorni, carica } = useMeteo()
    await carica(posizione.lat, posizione.lon, 2)
    meteo.value = giorni.value
  }

  async function aggiorna() {
    piante.value = null
    await caricaTutto()
  }

  // Nome <Icon> dell'icona associata a una zona / sottozona (per nome).
  // Ritorna già il nome pronto per <Icon> con prefisso "zona-", oppure "pin"
  // come fallback (stesso comportamento delle card di ZoneView/SottozoneView),
  // così le view che mostrano il nome di una zona possono anteporvi l'icona
  // senza ripetere la logica.
  function iconaZona(nome) {
    const slug = zone.value?.[nome]?.icona
    return slug ? `zona-${slug}` : 'pin'
  }
  function iconaSottozona(zonaNome, szNome) {
    const slug = sottozone.value?.[zonaNome]?.[szNome]?.icona
    return slug ? `zona-${slug}` : 'pin'
  }

  return { piante, catalogo, zone, sottozone, progetti, settings, concimi, programmiIrrigazione, meteo, loading, errore, caricaTutto, aggiorna, caricaMeteo, caricaVoci, aggiungiVoci, vocePianta, nomePianta, iconaZona, iconaSottozona }
})
