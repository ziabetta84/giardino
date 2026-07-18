import { createRouter, createWebHashHistory } from 'vue-router'

const routes = [
  { path: '/',                          name: 'home',           component: () => import('@/views/HomeView.vue') },
  { path: '/meteo',                     name: 'meteo',          component: () => import('@/views/MeteoView.vue') },
  { path: '/zone',                      name: 'zone',           component: () => import('@/views/ZoneView.vue') },
  { path: '/zone/nuova',                name: 'zona-nuova',     component: () => import('@/views/EditZonaView.vue') },
  { path: '/zone/:zona/modifica',       name: 'zona-modifica',  component: () => import('@/views/EditZonaView.vue') },
  { path: '/zone/:zona/sottozone',      name: 'sottozone',      component: () => import('@/views/SottozoneView.vue') },
  { path: '/piante',                    name: 'piante',         component: () => import('@/views/PianteView.vue') },
  { path: '/piante/nuova',              name: 'pianta-nuova',   component: () => import('@/views/EditPiantaView.vue') },
  { path: '/piante/:id',                name: 'pianta',         component: () => import('@/views/PiantaView.vue') },
  { path: '/piante/:id/modifica',       name: 'pianta-modifica',component: () => import('@/views/EditPiantaView.vue') },
  { path: '/progetti',                  name: 'progetti',       component: () => import('@/views/ProgettiView.vue') },
  { path: '/attivita',                  name: 'attivita',       component: () => import('@/views/AttivitaView.vue') },
  { path: '/agente',                    name: 'agente',         component: () => import('@/views/AgenteView.vue') },
  { path: '/gallery',                   name: 'gallery',        component: () => import('@/views/GalleryView.vue') },
]

export default createRouter({
  history: createWebHashHistory('/giardino/'),
  routes,
  scrollBehavior: () => ({ top: 0 })
})
