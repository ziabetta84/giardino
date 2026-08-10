// Wrapper attorno a virtual:pwa-register/vue: sapere con certezza quando il
// service worker ha davvero un aggiornamento pronto (needRefresh), invece di
// ricaricare la pagina alla cieca e sperare che il nuovo bundle sia già
// attivo (vedi StatusBar.vue). Un'unica istanza condivisa: la registrazione
// del service worker deve avvenire una sola volta per l'intera app.
import { useRegisterSW } from 'virtual:pwa-register/vue'

let istanza = null

export function useAppUpdate() {
  if (!istanza) {
    let registrazione = null
    const { needRefresh, updateServiceWorker } = useRegisterSW({
      onRegisteredSW(_url, r) {
        registrazione = r
      },
    })
    istanza = {
      needRefresh,
      applicaAggiornamento: () => updateServiceWorker(true),
      // Forza subito un controllo invece di aspettare la prossima
      // navigazione: usato quando sappiamo già (da useRepoStatus) che è
      // stato pubblicato un nuovo commit, per accorciare l'attesa prima che
      // needRefresh diventi vero.
      controllaAggiornamento: () => registrazione?.update(),
    }
  }
  return istanza
}
