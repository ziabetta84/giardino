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
  { path: '/impostazioni',              name: 'impostazioni',   component: () => import('@/views/SettingsView.vue') },
]

const router = createRouter({
  history: createWebHashHistory('/giardino/'),
  routes,
  scrollBehavior: () => ({ top: 0 })
})

// Senza login non si naviga nell'app: unica eccezione la rotta /account
// stessa (altrimenti nessuno potrebbe mai raggiungere il form). Si aspetta
// `sessionePronta` (risolta solo a controllo sessione completato, incluso lo
// scambio del codice per un eventuale link di recupero password) per evitare
// un redirect lampo verso /account prima che la sessione risulti valida.
router.beforeEach(async (to) => {
  const { utente, sessionePronta } = useAuth()
  await sessionePronta
  if (!utente.value && to.name !== 'account') return { name: 'account' }
})

export default router
