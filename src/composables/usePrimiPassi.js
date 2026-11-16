// Primi passi di un nuovo iscritto (PrimiPassi.vue in Home): dove si trova il
// giardino, la prima zona, la prima pianta. Lo stato di ogni passo si legge
// dai dati veri dello store, mai da una spunta salvata a parte: una zona
// cancellata riapre il suo passo, un account che ha già tutto non lo vede.
//
// In localStorage, per utente, resta solo se la guida è in corso o chiusa:
// - nessun valore + tutti i passi fatti = account di prima della guida, che
//   non la vede mai;
// - 'in-corso' = qualche passo mancava quando l'ha vista la prima volta: a
//   passi finiti resta il riquadro di chiusura finché non lo si chiude;
// - 'chiuso' = chiusa a mano (o finita): non torna più.

import { computed, ref, watch } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useAuth } from '@/composables/useAuth'
import { useSupabase } from '@/composables/useSupabase'

const PREFISSO = 'giardino_primi_passi_'

function leggi(chiave) {
  try { return localStorage.getItem(chiave) } catch { return null }
}
function scrivi(chiave, valore) {
  try { localStorage.setItem(chiave, valore) } catch { /* storage non disponibile: vale per questa sessione */ }
}

// Condiviso a livello di modulo: Home e PrimiPassi.vue devono vedere lo
// stesso stato (Home nasconde i vecchi inviti quando la guida è visibile).
const statoSalvato = ref(null)
let utenteLetto = null

const CHIAVE_RIMANDATA = 'giardino_primi_passi_rimandata'
function leggiRimandata() {
  try { return sessionStorage.getItem(CHIAVE_RIMANDATA) === '1' } catch { return false }
}
const rimandata = ref(leggiRimandata())

// I concimi fatti in casa che chiunque ha in cucina: un account nuovo li
// trova già in dispensa, segnati come terminati (il suggerimento li propone
// solo quando l'utente li accende). Stessi nomi, NPK e ricette della
// dispensa del giardino di Centinarola.
const CONCIMI_FATTI_IN_CASA = [
  { nome: 'Fatto in casa - Acqua di buccia di banana (macerato)', npk: { n: 1, p: 3, k: 8 },
    descrizione: "Metti 2-3 bucce di banana a pezzi in un litro d'acqua, lascia macerare 2-3 giorni a temperatura ambiente mescolando ogni tanto, poi filtra. Usa il liquido puro per innaffiare, senza ulteriore diluizione." },
  { nome: 'Fatto in casa - Acqua di cottura verdure', npk: { n: 2, p: 1, k: 4 },
    descrizione: "Riutilizza l'acqua di cottura di verdure (non salata), lasciata raffreddare a temperatura ambiente. Usala pura per innaffiare, senza bisogno di diluizione o macerazione." },
  { nome: 'Fatto in casa - Fondi di caffè (macerato)', npk: { n: 10, p: 2, k: 4 },
    descrizione: "Metti in infusione una tazza di fondi di caffè esausti (freddi) in un litro d'acqua per 2-3 giorni, mescolando di tanto in tanto, poi filtra. Diluisci il liquido 1:1 con acqua prima di innaffiare." },
]

// Una volta sola, quando la guida parte per un account nuovo e la dispensa è
// vuota: chi ha già dei concimi (o li ha tolti dopo) non se li ritrova.
async function caricaConcimiFattiInCasa(store) {
  if (Object.keys(store.concimi ?? {}).length) return
  const { data, error } = await useSupabase().from('concimi')
    .insert(CONCIMI_FATTI_IN_CASA.map(c => ({ ...c, disponibile: false }))).select()
  if (error || !data) return
  store.concimi = { ...store.concimi, ...Object.fromEntries(data.map(c => [c.id, {
    nome: c.nome, npk: c.npk, disponibile: c.disponibile, descrizione: c.descrizione,
  }])) }
}

export function usePrimiPassi() {
  const store = useDatiStore()
  const { utente } = useAuth()

  const chiave = computed(() => utente.value?.id ? PREFISSO + utente.value.id : null)
  // Un altro utente nella stessa scheda (uscita e nuovo accesso) ha il suo stato.
  watch(chiave, (c) => {
    if (c === utenteLetto) return
    utenteLetto = c
    statoSalvato.value = c ? leggi(c) : null
  }, { immediate: true })

  const pronto = computed(() => !!store.piante && !!store.zone)
  const posizioneFatta = computed(() => store.settings?.location?.lat != null && store.settings?.location?.lon != null)
  const zonaFatta = computed(() => Object.keys(store.zone ?? {}).length > 0)
  const piantaFatta = computed(() => Object.keys(store.piante ?? {}).length > 0)
  const tuttoFatto = computed(() => posizioneFatta.value && zonaFatta.value && piantaFatta.value)

  // La prima volta che i dati arrivano con un passo ancora da fare, la guida
  // parte: da lì in poi resta fino alla chiusura, anche a passi completati.
  watch([pronto, tuttoFatto], ([p, fatto]) => {
    if (!p || !chiave.value || statoSalvato.value) return
    if (!fatto) {
      statoSalvato.value = 'in-corso'
      scrivi(chiave.value, 'in-corso')
      caricaConcimiFattiInCasa(store).catch(() => { /* la dispensa resta vuota, si riempie a mano */ })
    }
  }, { immediate: true })

  const visibile = computed(() => pronto.value && !store.errore && statoSalvato.value === 'in-corso' && !rimandata.value)

  // Chiusura definitiva: solo a guida finita («Grazie, Zorba»).
  function chiudi() {
    statoSalvato.value = 'chiuso'
    if (chiave.value) scrivi(chiave.value, 'chiuso')
  }

  // «Più tardi» a guida non finita: la nasconde fino alla prossima apertura
  // dell'app (sessionStorage), non per sempre. Prima chiudeva del tutto, e chi
  // la rimandava al primo ingresso non la ritrovava più (critica del 30/10/2026).
  function rimanda() {
    rimandata.value = true
    try { sessionStorage.setItem(CHIAVE_RIMANDATA, '1') } catch { /* vale per questa pagina */ }
  }

  // Da Account («Riprendi i primi passi»): torna visibile anche se era stata
  // chiusa con il vecchio «Più tardi».
  function riapri() {
    rimandata.value = false
    try { sessionStorage.removeItem(CHIAVE_RIMANDATA) } catch { /* niente da togliere */ }
    statoSalvato.value = 'in-corso'
    if (chiave.value) scrivi(chiave.value, 'in-corso')
  }

  return { visibile, posizioneFatta, zonaFatta, piantaFatta, tuttoFatto, chiudi, rimanda, riapri }
}
