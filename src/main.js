import { createApp } from 'vue'
import { createPinia } from 'pinia'
import router from './router'
import App from './App.vue'
import './assets/main.css'

// Il token GitHub serviva solo alla galleria, che dal 28/10/2026 sta su Supabase Storage: non resta salvato nel browser.
try { localStorage.removeItem('github_token') } catch { /* storage non disponibile */ }

createApp(App).use(createPinia()).use(router).mount('#app')
