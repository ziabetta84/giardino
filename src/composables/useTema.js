// Fase 3 restyle "Taccuino": dark mode. Interruttore esplicito in Impostazioni,
// default chiaro, niente rilevazione automatica da sistema (decisione chiusa
// in review). Vedi docs/superpowers/specs/2026-09-04-dark-mode-design.md.
//
// Stato a livello di modulo (stesso pattern di useAuth.js): un solo ref
// condiviso, così App.vue (applicazione all'avvio + riconciliazione con
// Supabase) e SettingsView.vue (select dell'utente) vedono lo stesso tema.
//
// L'attributo data-theme viene comunque già impostato prima del bootstrap
// Vue da uno script inline in index.html (letto da localStorage), per
// evitare il lampo chiaro→scuro: applicaTema() qui sotto tiene solo lo stato
// reattivo in sincrono con quell'attributo dopo il mount.

import { ref } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useSettingsApi } from '@/composables/useSettingsApi'

const CHIAVE_STORAGE = 'giardino_theme'
const THEME_COLOR = { light: '#faf7f2', dark: '#1c1810' }

const tema = ref(leggiThemeSalvato())

function leggiThemeSalvato() {
  try {
    const salvato = localStorage.getItem(CHIAVE_STORAGE)
    return salvato === 'dark' ? 'dark' : 'light'
  } catch {
    return 'light'
  }
}

function applicaTema(t) {
  tema.value = t
  document.documentElement.setAttribute('data-theme', t)
  try { localStorage.setItem(CHIAVE_STORAGE, t) } catch { /* storage non disponibile: ok, resta solo in memoria */ }
  const meta = document.querySelector('meta[name="theme-color"]')
  if (meta) meta.setAttribute('content', THEME_COLOR[t])
}

export function useTema() {
  const store = useDatiStore()
  const settingsApi = useSettingsApi()

  // Applicazione istantanea al cambio dal select in Impostazioni + salvataggio
  // su Supabase (fonte di verità cross-device), riusando gli altri campi già
  // presenti in store.settings — stesso pattern del salva() di SettingsView.vue.
  async function impostaTema(t) {
    applicaTema(t)
    await settingsApi.salvaSettings({
      location: store.settings?.location,
      units: store.settings?.units,
      meteo: store.settings?.meteo,
      ui: { theme: t },
      zona_climatica_id: store.settings?.zona_climatica_id,
    })
  }

  // Da chiamare una volta in App.vue dopo store.caricaTutto(): se le settings
  // dell'utente su Supabase divergono dal tema applicato localmente, vince
  // Supabase e si riallinea anche localStorage. Nessuna riga settings ancora
  // creata (nuovo utente) → si tiene il default locale.
  function riconciliaConSettings() {
    const salvato = store.settings?.ui?.theme
    if ((salvato === 'light' || salvato === 'dark') && salvato !== tema.value) {
      applicaTema(salvato)
    }
  }

  return { tema, impostaTema, riconciliaConSettings }
}
