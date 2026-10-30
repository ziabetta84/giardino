<template>
  <!-- Contenitore del widget Cloudflare Turnstile: lo riempie lo script di
       Cloudflare con il suo iframe. Senza site key (sviluppo locale senza
       .env aggiornato) il componente non mostra nulla e non emette token. -->
  <div v-if="siteKey" ref="contenitore" class="turnstile" />
</template>

<script>
// Lo script si carica una volta sola per tutta l'app, anche se il widget
// compare in più punti (form di accesso, pannello "invia di nuovo").
// Render esplicito: con il render automatico Turnstile cercherebbe i div
// .cf-turnstile solo al caricamento, e qui i form compaiono e spariscono.
let scriptCaricato = null

function caricaScript() {
  if (window.turnstile) return Promise.resolve(window.turnstile)
  if (!scriptCaricato) {
    scriptCaricato = new Promise((resolve, reject) => {
      const s = document.createElement('script')
      s.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit'
      s.async = true
      s.onload = () => resolve(window.turnstile)
      s.onerror = () => {
        scriptCaricato = null
        reject(new Error('Turnstile non raggiungibile'))
      }
      document.head.appendChild(s)
    })
  }
  return scriptCaricato
}
</script>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'

// La site key è pubblica (sta nel bundle come la chiave anon di Supabase);
// la secret key vive solo nel pannello di Supabase Auth, che verifica il token.
const siteKey = import.meta.env.VITE_TURNSTILE_SITE_KEY

const emit = defineEmits(['token', 'errore'])
const contenitore = ref(null)
let widgetId = null

onMounted(async () => {
  if (!siteKey) return
  try {
    const turnstile = await caricaScript()
    // Il componente può essere smontato mentre lo script si carica.
    if (!contenitore.value) return
    widgetId = turnstile.render(contenitore.value, {
      sitekey: siteKey,
      // Stesso tema dell'app (useTema.js lo scrive su <html>), invece di un
      // riquadro sempre chiaro in mezzo a una pagina scura.
      theme: document.documentElement.dataset.theme === 'dark' ? 'dark' : 'light',
      language: 'it',
      size: 'flexible',
      // Il token dura 300 s: alla scadenza Turnstile ne chiede uno nuovo da
      // solo, intanto il form torna in attesa.
      'refresh-expired': 'auto',
      callback: (token) => emit('token', token),
      'expired-callback': () => emit('token', null),
      'error-callback': () => {
        emit('token', null)
        emit('errore')
      },
    })
  } catch {
    emit('errore')
  }
})

onBeforeUnmount(() => {
  if (widgetId !== null && window.turnstile) window.turnstile.remove(widgetId)
})

// Un token vale per una sola verifica: dopo ogni tentativo (riuscito o no)
// il form chiama reset() per riceverne uno nuovo.
function reset() {
  emit('token', null)
  // Dopo un accesso riuscito il form sta già per sparire: un widget rimosso
  // nel frattempo fa lanciare un errore a reset(), che qui non conta.
  try {
    if (widgetId !== null && window.turnstile) window.turnstile.reset(widgetId)
  } catch { /* widget già rimosso */ }
}

defineExpose({ reset })
</script>

<style scoped>
.turnstile { min-height: 65px; display: flex; justify-content: center; }
</style>
