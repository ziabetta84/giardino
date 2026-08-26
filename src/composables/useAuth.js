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

supabase.auth.getSession().then(({ data }) => {
  utente.value = data.session?.user ?? null
  caricamento.value = false
})

supabase.auth.onAuthStateChange((_evento, sessione) => {
  utente.value = sessione?.user ?? null
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

  return { utente, caricamento, registrati, accedi, esci }
}
