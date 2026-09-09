import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useMeteo, LOCATION_FALLBACK } from '@/composables/useMeteo'
import { useApi } from '@/composables/useApi'
import { useSupabase } from '@/composables/useSupabase'
import { irrigazioneDaRegistrareOggi } from '@/composables/useCure'
import { programmaIrrigazioneEffettivo } from '@/composables/useIrrigazioneAuto'

const BASE = import.meta.env.BASE_URL

async function caricaStatico(file) {
  const res = await fetch(`${BASE}data/${file}`)
  if (!res.ok) throw new Error(`Errore caricamento ${file}`)
  return res.json()
}

// Legge sempre prima da GitHub (stessa fonte usata dai salvataggi, senza
// cache): così le modifiche sono visibili subito, senza aspettare che build
// e deploy pubblichino una nuova copia statica su GitHub Pages. Se GitHub
// non è raggiungibile (offline, in giardino senza campo) ripiega sull'ultima
// copia statica pubblicata, che il service worker può servire da cache.
async function caricaJSON(file) {
  const { loadJSON } = useApi()
  try {
    return await loadJSON(file)
  } catch {
    return caricaStatico(file)
  }
}
// Pilota Fase 2: le specie vengono da Supabase (sola lettura), non più dal
// JSON statico — ma la forma dell'oggetto resta identica a prima (stessa
// chiave slug, stessi nomi di campo "specie" e "coltivazione") perché tutto
// il resto dell'app si aspetta ancora quella forma. Le scritture (creare o
// modificare una specie da SelettoreSpecie) restano su GitHub per ora: la
// migrazione delle scritture è compito di una fase successiva, non di questa.
// Se Supabase non risponde, ripiega sul JSON statico come le altre risorse.

export const COLONNE_SPECIE =
  'id, slug, nome, nome_scientifico, descrizione, esigenze, alert, manutenzione, ciclo_colturale, ciclo_vitale, stato_verifica, vaso, immagine, specie_padre_id'

// Riusata anche da SelettoreSpecie.vue per mappare i risultati della ricerca
// live su Supabase, così le due fonti (caricamento iniziale e ricerca)
// producono record identici nello store.
export function mappaSpecie(righe) {
  return Object.fromEntries(
    righe.map(riga => [
      riga.slug,
      {
        id: riga.id,
        slug: riga.slug,
        nome: riga.nome,
        specie: riga.nome_scientifico,
        descrizione: riga.descrizione,
        esigenze: riga.esigenze,
        alert: riga.alert,
        manutenzione: riga.manutenzione,
        coltivazione: riga.ciclo_colturale,
        ciclo_vitale: riga.ciclo_vitale,
        stato_verifica: riga.stato_verifica,
        vaso: riga.vaso,
        immagine: riga.immagine,
        specie_padre_id: riga.specie_padre_id,
      }
    ])
  )
}

// Campi di "cura/conoscenza" (+ immagine hero) che un cultivar eredita
// dalla specie madre quando non ha un proprio dato (la stragrande
// maggioranza: i ~196k cultivar importati da RHS hanno solo il nome,
// vedi issue #153) — non i campi identitari (nome, slug, nome_scientifico,
// famiglia), quelli restano sempre del cultivar stesso anche quando
// eredita tutto il resto.
const CAMPI_EREDITABILI = ['descrizione', 'esigenze', 'alert', 'manutenzione', 'coltivazione', 'vaso', 'ciclo_vitale', 'immagine']

function campoVuoto(v) {
  if (v == null) return true
  if (Array.isArray(v)) return v.length === 0
  if (typeof v === 'object') return Object.keys(v).length === 0
  return false
}

// Risolve i campi mancanti di un cultivar con quelli della specie madre.
// Va richiamata ovunque un cultivar venga aggiunto allo store (qui e in
// SelettoreSpecie.vue) così i ~9 punti dell'app che leggono store.specie[…]
// (PiantaRiga, PiantaView, AttivitaView, GalleryView, ecc.) vedono già il
// dato "effettivo" senza doverlo risolvere ciascuno per conto proprio.
export function fondiEredita(record, madre) {
  if (!record.specie_padre_id || !madre) return record
  const risultato = { ...record }
  for (const campo of CAMPI_EREDITABILI) {
    if (campoVuoto(record[campo])) risultato[campo] = madre[campo]
  }
  return risultato
}

// Il catalogo specie cresce continuamente (import da PFAF, ~8700 righe e
// oltre) e caricarlo tutto ad ogni avvio — anche paginando oltre il limite
// di 1000 righe di PostgREST — non scala (issue #142). Il resto dell'app fa
// solo lookup per slug delle specie delle piante possedute, quindi basta
// caricare in anticipo: quelle referenziate (piante + richieste di revisione
// in coda) e le poche specie verificate (i suggerimenti a campo vuoto nel
// selettore). Il resto del catalogo si carica su richiesta con la ricerca
// live in SelettoreSpecie.vue, che unisce i risultati allo store.
async function caricaSpecie(slugReferenziati = []) {
  try {
    const supabase = useSupabase()

    const query = [
      // i cultivar (specie_padre_id valorizzato) non vanno mai nel bootstrap:
      // sono ~196k righe quasi tutte 'bozza' (nessun dato di cura proprio),
      // vanno cercati solo sotto la specie madre già scelta, mai in anticipo
      supabase.from('specie').select(COLONNE_SPECIE).eq('stato_verifica', 'verificato').is('specie_padre_id', null),
    ]
    if (slugReferenziati.length) {
      query.push(supabase.from('specie').select(COLONNE_SPECIE).in('slug', slugReferenziati))
    }

    const risultati = await Promise.all(query)
    const tutte = []
    for (const { data, error } of risultati) {
      if (error) throw error
      if (data) tutte.push(...data)
    }

    // Se tra le referenziate c'è un cultivar, la specie madre serve per
    // l'eredità dei campi di cura (fondiEredita sotto) ma potrebbe non
    // essere già tra le righe prese (non è detto sia lei stessa referenziata
    // o verificata) — va recuperata a parte in quel caso.
    const idPresenti = new Set(tutte.map(r => r.id))
    const idMadriMancanti = [...new Set(
      tutte.filter(r => r.specie_padre_id && !idPresenti.has(r.specie_padre_id)).map(r => r.specie_padre_id)
    )]
    if (idMadriMancanti.length) {
      const { data: madri, error } = await supabase.from('specie').select(COLONNE_SPECIE).in('id', idMadriMancanti)
      if (error) throw error
      if (madri) tutte.push(...madri)
    }

    const mappate = mappaSpecie(tutte)
    const perId = Object.fromEntries(Object.values(mappate).map(s => [s.id, s]))
    for (const slug of Object.keys(mappate)) {
      if (mappate[slug].specie_padre_id) mappate[slug] = fondiEredita(mappate[slug], perId[mappate[slug].specie_padre_id])
    }
    return mappate

  } catch (e) {
    console.error('Supabase non risponde, uso il fallback specie.json', e)
    return caricaStatico('specie.json')
  }
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
    specie: p.specie,
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
  const specie    = ref(null)
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

      const [righeZone, righeSottozone, righePiante, richiesteData, righeProgetti, righeTappe, righeSettings, righeConcimi, righeProgrammiIrrigazione] =
        await Promise.all([
          query(supabase.from('zone').select('*')),
          query(supabase.from('sottozone').select('*')),
          query(supabase.from('piante').select('*')),
          caricaJSON('richieste-agente.json'),
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

      // Slug delle specie da caricare subito: quelle delle piante possedute
      // più quelle citate da richieste di revisione ancora in coda (mostrate
      // per nome nello storico di AgenteView).
      const slugPiante = Object.values(piante.value ?? {}).map(p => p.specie).filter(Boolean)
      const slugRichieste = Object.values(richiesteData ?? {})
        .filter(r => r.tipo === 'revisione_specie' && r.specie)
        .map(r => r.specie)
      const slugReferenziati = [...new Set([...slugPiante, ...slugRichieste])]

      specie.value = await caricaSpecie(slugReferenziati)

      // Previsioni meteo (solo oggi/domani): usate da useCure per sospendere
      // l'irrigazione delle piante esterne quando è prevista pioggia
      // sufficiente. Dentro il try, non dopo: useMeteo().carica() cattura già
      // i propri errori di rete internamente (non li rilancia, vedi
      // useMeteo.js) quindi non può far scattare il catch qui sotto — ma
      // deve restare coperta da `loading` insieme al resto, altrimenti
      // loading torna false prima che il meteo sia arrivato e la riga meteo
      // in Home mostra "non disponibile" invece di "in caricamento" per la
      // finestra in cui sta ancora arrivando (vedi critica del 07/09/2026).
      // Fallback su LOCATION_FALLBACK (stesso di MeteoView.vue) se l'utente
      // non ha ancora impostato una location in /impostazioni: prima non
      // c'era alcun fallback qui, quindi un utente nuovo non vedeva mai il
      // meteo su Home né la sospensione dell'irrigazione in caso di pioggia,
      // anche se /meteo stesso funzionava già grazie al proprio fallback
      // locale (vedi critica del 07/09/2026).
      const lat = settings.value?.location?.lat ?? LOCATION_FALLBACK.lat
      const lon = settings.value?.location?.lon ?? LOCATION_FALLBACK.lon
      const { giorni, carica } = useMeteo()
      await carica(lat, lon, 2)
      meteo.value = giorni.value

      // Irrigazione sospesa (pioggia prevista o programma automatico) ma
      // comunque dovuta oggi: la registriamo da soli invece di continuare a
      // segnalarla come cura da fare — l'utente ha già delegato quella
      // decisione scegliendo un programma automatico, o la pioggia la copre
      // di fatto. Gira una sola volta per sessione (stessa guardia di
      // caricaTutto()), dopo che piante/specie/zone/programmi/meteo sono
      // tutti pronti. Try/catch proprio: un fallimento di rete isolato qui
      // non deve trasformarsi in un errore che nasconde dati già caricati
      // con successo (stesso principio già applicato al meteo qui sopra).
      try {
        const daRegistrare = []
        for (const [id, p] of Object.entries(piante.value)) {
          const sp = specie.value?.[p.specie] ?? null
          const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, p.sottozona, programmiIrrigazione.value)?.ogniGiorni ?? null
          const esterno = zone.value?.[p.zona]?.tipo === 'esterno'
          if (irrigazioneDaRegistrareOggi(p, sp, { programmaAutomatico, esterno, meteo: meteo.value })) {
            daRegistrare.push(id)
          }
        }
        if (daRegistrare.length) {
          const oggiStr = new Date().toISOString().split('T')[0]
          await Promise.all(daRegistrare.map(async id => {
            const ultima_cura = { ...(piante.value[id].ultima_cura ?? {}), irrigazione: oggiStr }
            const { error } = await supabase.from('piante').update({ ultima_cura }).eq('id', id)
            if (error) throw error
            piante.value = { ...piante.value, [id]: { ...piante.value[id], ultima_cura } }
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

  return { piante, specie, zone, sottozone, progetti, settings, concimi, programmiIrrigazione, meteo, loading, errore, caricaTutto, aggiorna, iconaZona, iconaSottozona }
})
