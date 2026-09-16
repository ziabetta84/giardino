import { ref } from 'vue'

// Stato di modulo (non di componente): sopravvive a ogni mount/unmount di
// BootLogo.vue e HomeView.vue nella stessa sessione di pagina, si azzera
// solo con un vero reload — non con la navigazione interna (che rimonta
// HomeView, ma non App.vue/BootLogo). Serve a non far partire la sequenza
// di SplashAiuola.vue (saluto/pillole) mentre BootLogo copre ancora lo
// schermo all'avvio: senza questo, i suoi timer scorrerebbero interamente
// nascosti dietro il logo di boot, invisibili all'utente.
export const bootCompletato = ref(false)
