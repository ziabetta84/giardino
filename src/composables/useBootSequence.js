import { ref } from 'vue'

// Stato di modulo (non di componente): sopravvive a ogni mount/unmount di
// BootLogo.vue e HomeView.vue nella stessa sessione di pagina, si azzera
// solo con un vero reload — non con la navigazione interna (che rimonta
// HomeView, ma non App.vue/BootLogo). Serve a non far partire la sequenza
// di SplashAiuola.vue (saluto/pillole) mentre BootLogo copre ancora lo
// schermo all'avvio: senza questo, i suoi timer scorrerebbero interamente
// nascosti dietro il logo di boot, invisibili all'utente.
export const bootCompletato = ref(false)

// Le 4 fasce del saluto, mostrato ovunque compaia (intestazione Home,
// splash) — confini decisi in critica del 20/09/2026, deliberatamente
// indipendenti dalla cadenza dello splash qui sotto: prima le due cose
// condividevano gli stessi 3 confini orari, ma la cadenza "una volta per
// fascia" (fino a 3 volte al giorno, identica ogni volta) consumava il
// momento più in fretta di quanto valesse la pena — vedi splash a schermo
// intero più sotto per la cadenza separata.
export function prefissoOra() {
  const ora = new Date().getHours()
  if (ora >= 6 && ora < 13) return 'Buongiorno'
  if (ora >= 13 && ora < 18) return 'Buon pomeriggio'
  if (ora >= 18 && ora < 22) return 'Buonasera'
  return 'Buonanotte'
}

// Cadenza dello splash a schermo intero: due finestre fisse al giorno,
// mattina e sera, non più legate alle fasce del saluto sopra. Fuori da
// entrambe (pomeriggio, notte fonda) lo splash non compare affatto quel
// giorno — un'apertura della Home in quella fascia oraria non "consuma"
// né la finestra di mattina né quella di sera.
function finestraSplashCorrente() {
  const ora = new Date().getHours()
  if (ora >= 5 && ora < 12) return 'mattina'
  if (ora >= 18 && ora < 24) return 'sera'
  return null
}
function chiaveFinestraOggi() {
  const finestra = finestraSplashCorrente()
  if (!finestra) return null
  return `${new Date().toISOString().slice(0, 10)}-${finestra}`
}
// Un'unica chiave in localStorage basta per tracciare entrambe le finestre:
// ciascuna produce una chiave diversa (stessa data, finestra diversa), quindi
// segnare "vista" la mattina non consuma quella della sera, e il giorno dopo
// la data cambia comunque entrambe.
export function fasciaGiaVista() {
  try {
    const chiave = chiaveFinestraOggi()
    if (!chiave) return true // fuori da entrambe le finestre: comportati come "già vista", niente splash
    return localStorage.getItem('giardino_splash_fascia') === chiave
  }
  catch { return true } // storage inaccessibile (es. modalità privata): non insistere
}
export function segnaFasciaVista() {
  try {
    const chiave = chiaveFinestraOggi()
    if (chiave) localStorage.setItem('giardino_splash_fascia', chiave)
  }
  catch { /* storage inaccessibile: lo splash si ripresenterà, non è grave */ }
}
export function movimentoRidotto() {
  return window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false
}
// Vero quando SplashAiuola sta per prendere il posto del logo-solo di
// BootLogo in questo avvio — entrambi lo controllano per non mostrare due
// schermate d'ingresso in sequenza (verificato live 16/09/2026: il logo-solo
// da 3s seguito subito dalla scena leggeva come due caricamenti scollegati).
export function splashInArrivo() {
  return !fasciaGiaVista() && !movimentoRidotto()
}
