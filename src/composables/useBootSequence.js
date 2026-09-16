import { ref } from 'vue'

// Stato di modulo (non di componente): sopravvive a ogni mount/unmount di
// BootLogo.vue e HomeView.vue nella stessa sessione di pagina, si azzera
// solo con un vero reload — non con la navigazione interna (che rimonta
// HomeView, ma non App.vue/BootLogo). Serve a non far partire la sequenza
// di SplashAiuola.vue (saluto/pillole) mentre BootLogo copre ancora lo
// schermo all'avvio: senza questo, i suoi timer scorrerebbero interamente
// nascosti dietro il logo di boot, invisibili all'utente.
export const bootCompletato = ref(false)

// Fascia del saluto e chiave "una volta al giorno per fascia": unica fonte
// di verità condivisa tra BootLogo.vue (decide se accorciare il proprio
// logo-solo perché sta per partire SplashAiuola) e HomeView.vue/
// SplashAiuola.vue (testo del saluto + gating dello splash stesso) — due
// punti che calcolavano gli stessi confini orari in modo duplicato
// rischiavano di disallinearsi silenziosamente.
export function prefissoOra() {
  const ora = new Date().getHours()
  if (ora < 12) return 'Buongiorno'
  if (ora < 18) return 'Buon pomeriggio'
  return 'Buonasera'
}
function fasciaCorrente() {
  const p = prefissoOra()
  if (p === 'Buongiorno') return 'mattina'
  if (p === 'Buon pomeriggio') return 'pomeriggio'
  return 'sera'
}
function chiaveFasciaOggi() {
  return `${new Date().toISOString().slice(0, 10)}-${fasciaCorrente()}`
}
export function fasciaGiaVista() {
  try { return localStorage.getItem('giardino_splash_fascia') === chiaveFasciaOggi() }
  catch { return true } // storage inaccessibile (es. modalità privata): non insistere
}
export function segnaFasciaVista() {
  try { localStorage.setItem('giardino_splash_fascia', chiaveFasciaOggi()) }
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
