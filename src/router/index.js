import { createRouter, createWebHashHistory } from 'vue-router'
import { useAuth } from '@/composables/useAuth'

const routes = [
  { path: '/',                          name: 'home',           component: () => import('@/views/HomeView.vue') },
  { path: '/meteo',                     name: 'meteo',          component: () => import('@/views/MeteoView.vue') },
  { path: '/zone',                      name: 'zone',           component: () => import('@/views/ZoneView.vue') },
  { path: '/zone/:zona/sottozone',      name: 'sottozone',      component: () => import('@/views/SottozoneView.vue') },
  { path: '/piante',                    name: 'piante',         component: () => import('@/views/PianteView.vue') },
  { path: '/piante/nuova',              name: 'pianta-nuova',   component: () => import('@/views/EditPiantaView.vue') },
  { path: '/piante/:id',                name: 'pianta',         component: () => import('@/views/PiantaView.vue') },
  { path: '/piante/:id/modifica',       name: 'pianta-modifica',component: () => import('@/views/EditPiantaView.vue') },
  { path: '/progetti',                  name: 'progetti',       component: () => import('@/views/ProgettiView.vue') },
  { path: '/progetti/:id',              name: 'progetto',       component: () => import('@/views/ProgettoView.vue') },
  { path: '/concimi',                   name: 'concimi',        component: () => import('@/views/ConcimiView.vue') },
  { path: '/attivita',                  name: 'attivita',       component: () => import('@/views/AttivitaView.vue') },
  { path: '/agente',                    name: 'agente',         component: () => import('@/views/AgenteView.vue') },
  { path: '/gallery',                   name: 'gallery',        component: () => import('@/views/GalleryView.vue') },
  { path: '/account',                   name: 'account',        component: () => import('@/views/AccountView.vue') },
  { path: '/privacy',                   name: 'privacy',        component: () => import('@/views/PrivacyView.vue') },
  { path: '/feedback',                  name: 'feedback',       component: () => import('@/views/FeedbackView.vue') },
  { path: '/impostazioni',              name: 'impostazioni',   component: () => import('@/views/SettingsView.vue') },
  { path: '/impostazioni/irrigazione',  name: 'irrigazione',    component: () => import('@/views/IrrigazioneView.vue') },
  { path: '/:pathMatch(.*)*',           name: 'not-found',      redirect: '/' },
]

const router = createRouter({
  history: createWebHashHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior: () => ({ top: 0 })
})

// Senza login non si naviga nell'app: unica eccezione la rotta /account
// stessa (altrimenti nessuno potrebbe mai raggiungere il form). Si aspetta
// `sessionePronta` (risolta solo a controllo sessione completato, incluso lo
// scambio del codice per un eventuale link di recupero password) per evitare
// un redirect lampo verso /account prima che la sessione risulti valida.
router.beforeEach(async (to) => {
  const { utente, recuperoInCorso, sessionePronta } = useAuth()
  await sessionePronta
  // Una sessione di recupero password (PASSWORD_RECOVERY) valorizza comunque
  // `utente`: senza questo controllo, un redirect di reset che non atterra
  // già su /account (es. sulla Home) mostrerebbe quella rotta invece del
  // form "Nuova password", pur restando nel layout slim di App.vue.
  // L'informativa privacy si legge anche senza account: serve prima di registrarsi.
  if ((!utente.value || recuperoInCorso.value) && !['account', 'privacy'].includes(to.name)) return { name: 'account' }
})

// Dopo una pubblicazione i file di una versione precedente non esistono più sul server: una pagina rimasta aperta
// (o un service worker che ha appena cambiato versione) chiede un pezzo che non c'è e la navigazione si ferma con
// «error loading dynamically imported module». Si ricarica una volta la pagina sulla rotta chiesta, che prende la
// versione nuova; se il pezzo manca ancora dopo il ricaricamento l'errore resta visibile, senza ricaricare all'infinito.
const CHIAVE_RICARICA = 'ricarica-versione'
function erroreDiVersione(e) {
  return /dynamically imported module|Importing a module script failed|Failed to fetch dynamically|error loading dynamically/i
    .test(String(e?.message ?? e))
}
function ricaricaUnaVolta(percorso) {
  let ultima = 0
  try { ultima = Number(sessionStorage.getItem(CHIAVE_RICARICA)) || 0 } catch { /* storage non disponibile */ }
  if (Date.now() - ultima < 30000) return false
  try { sessionStorage.setItem(CHIAVE_RICARICA, String(Date.now())) } catch { /* storage non disponibile */ }
  if (percorso) location.hash = percorso
  location.reload()
  return true
}
router.onError((e, to) => { if (erroreDiVersione(e)) ricaricaUnaVolta(to?.fullPath) })
// Lo stesso quando Vite non riesce a precaricare un pezzo collegato (CSS o JS) della pagina
window.addEventListener('vite:preloadError', (evento) => { if (ricaricaUnaVolta()) evento.preventDefault() })

export default router
