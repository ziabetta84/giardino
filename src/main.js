import { createApp } from 'vue'
import { createPinia } from 'pinia'
import router from './router'
import App from './App.vue'
// Caratteri serviti dall'app e non da Google Fonts, che riceverebbe l'indirizzo
// IP di chi apre l'app (vedi la pagina Privacy).
import '@fontsource-variable/fraunces/opsz.css'
import '@fontsource-variable/fraunces/opsz-italic.css'
import '@fontsource-variable/dm-sans'
import '@fontsource-variable/caveat'
import './assets/main.css'

// Il token GitHub serviva solo alla galleria, che dal 28/10/2026 sta su Supabase Storage: non resta salvato nel browser.
try { localStorage.removeItem('github_token') } catch { /* storage non disponibile */ }

createApp(App).use(createPinia()).use(router).mount('#app')
