// Fase 4 migrazione Supabase: sessione utente via Supabase Auth (email/password
// per ora, Google in un secondo momento). Coesiste col token GitHub in
// localStorage — login non controlla ancora nessun dato (arriva con la Fase 5),
// serve solo a far esistere un account.

import { ref } from 'vue'
import { useSupabase } from '@/composables/useSupabase'

const supabase = useSupabase()

// Stato a livello di modulo: un solo ref condiviso da chiunque importi questo
// composable (stesso pattern del client singleton in useSupabase.js), così
// NavBar/StatusBar/AccountView vedono tutte la stessa sessione senza prop drilling.
const utente = ref(null)
const caricamento = ref(true)
// true quando la sessione attuale viene da un link di recupero password
// (evento PASSWORD_RECOVERY): AccountView mostra il form "imposta nuova
// password" invece del solito login, anche se `utente` è già valorizzato.
const recuperoInCorso = ref(false)

// Promise esposta (vedi sotto) così la guardia di navigazione del router può
// aspettare la sessione senza reimplementare un polling su `caricamento`.
const sessionePronta = supabase.auth.getSession().then(({ data }) => {
  utente.value = data.session?.user ?? null
  caricamento.value = false
})

supabase.auth.onAuthStateChange((evento, sessione) => {
  utente.value = sessione?.user ?? null
  if (evento === 'PASSWORD_RECOVERY') recuperoInCorso.value = true
  // La cache del service worker per le risposte Supabase (vite.config.js) è
  // per-URL, non per-utente: su un device condiviso, senza questa pulizia,
  // un secondo utente offline potrebbe vedere temporaneamente i dati
  // dell'utente precedente. `caches` non esiste in ambienti senza service
  // worker (es. alcuni contesti di test): controllo difensivo.
  if (evento === 'SIGNED_OUT' && typeof caches !== 'undefined') {
    caches.delete('giardino-dati-supabase')
  }
})

// Supabase Auth risponde in inglese: traduciamo solo i casi che un utente
// incontra davvero nel flusso normale (email da confermare, credenziali
// sbagliate, account duplicato) — il resto passa così com'è piuttosto che
// inventare una traduzione per errori che non abbiamo mai visto succedere.
const MESSAGGI_ERRORE = {
  'Email not confirmed': 'Email non confermata: controlla la posta e clicca il link di conferma prima di accedere.',
  'Invalid login credentials': 'Email o password non corretti.',
  'User already registered': 'Esiste già un account con questa email.',
  'Password should be at least 6 characters': 'La password deve avere almeno 6 caratteri.',
}

function traduci(error) {
  const messaggio = MESSAGGI_ERRORE[error.message] ?? error.message
  return new Error(messaggio)
}

export function useAuth() {
  async function registrati(email, password) {
    const { data, error } = await supabase.auth.signUp({ email, password })
    if (error) throw traduci(error)
    return data
  }

  async function accedi(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw traduci(error)
    return data
  }

  async function esci() {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
  }

  async function richiediResetPassword(email) {
    const redirectTo = window.location.origin + import.meta.env.BASE_URL
    const { error } = await supabase.auth.resetPasswordForEmail(email, { redirectTo })
    if (error) throw traduci(error)
  }

  async function impostaNuovaPassword(password) {
    const { error } = await supabase.auth.updateUser({ password })
    if (error) throw traduci(error)
    recuperoInCorso.value = false
  }

  return {
    utente, caricamento, recuperoInCorso, sessionePronta,
    registrati, accedi, esci, richiediResetPassword, impostaNuovaPassword,
  }
}
