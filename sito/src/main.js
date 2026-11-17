import { ViteSSG } from 'vite-ssg'
import App from './App.vue'
import { TAPPE } from './percorso.js'
import { rivela } from './rivela.js'
import './stile.css'

const pagine = {
  giro: () => import('./pages/Giro.vue'),
  aiuole: () => import('./pages/Aiuole.vue'),
  schede: () => import('./pages/Schede.vue'),
  cure: () => import('./pages/Cure.vue'),
  zorba: () => import('./pages/Zorba.vue'),
  dati: () => import('./pages/Dati.vue'),
  domande: () => import('./pages/Domande.vue'),
}

const routes = TAPPE.map((t) => ({ path: t.percorso, name: t.nome, component: pagine[t.nome] }))

// Durata dell'uscita di una pagina (App.vue): si torna in cima solo quando la
// pagina vecchia è sparita, così lo scorrimento non si vede.
const USCITA = 220

export const createApp = ViteSSG(
  App,
  {
    routes,
    base: import.meta.env.BASE_URL,
    scrollBehavior(to, from, salvata) {
      const fermo = typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches
      const attesa = to.path === from.path || fermo ? 0 : USCITA
      return new Promise((risolvi) => {
        setTimeout(() => {
          if (salvata) risolvi(salvata)
          else if (to.hash) risolvi({ el: to.hash, top: 24, behavior: 'smooth' })
          else risolvi({ top: 0 })
        }, attesa)
      })
    },
  },
  ({ app }) => {
    app.directive('rivela', rivela)
  },
)
