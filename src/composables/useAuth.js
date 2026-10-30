// Fase 4 migrazione Supabase: sessione utente via Supabase Auth (email/password
// per ora, Google in un secondo momento). Coesiste col token GitHub in
// localStorage — login non controlla ancora nessun dato (arriva con la Fase 5),
// serve solo a far esistere un account.

import { ref, computed } from 'vue'
import { useSupabase } from '@/composables/useSupabase'

const supabase = useSupabase()

// Stato a livello di modulo: un solo ref condiviso da chiunque importi questo
// composable (stesso pattern del client singleton in useSupabase.js), così
// NavBar/StatusBar/AccountView vedono tutte la stessa sessione senza prop drilling.
const utente = ref(null)
const caricamento = ref(true)

// Nome con cui l'utente vuole essere chiamato (saluto in Home, mail di
// registrazione, contesti futuri): vive in user_metadata.nome di Supabase
// Auth — scelto al posto di una colonna `settings` perché disponibile subito
// in `utente` e interpolabile nel template email come {{ .Data.nome }}, cosa
// che una riga `settings` (inesistente al momento del signUp) non permette.
const nomeUtente = computed(() => {
  const n = utente.value?.user_metadata?.nome
  return typeof n === 'string' && n.trim() ? n.trim() : null
})

// true quando la sessione attuale viene da un link di recupero password
// (evento PASSWORD_RECOVERY): AccountView mostra il form "imposta nuova
// password" invece del solito login, anche se `utente` è già valorizzato.
// Persistito in sessionStorage (non solo nel ref) perché l'evento
// PASSWORD_RECOVERY scatta una sola volta, allo scambio del codice PKCE: un
// refresh della pagina dopo quel momento perderebbe altrimenti lo stato e
// mostrerebbe la vista Account normale invece del form, con la sessione di
// reset ancora valida ma irraggiungibile (verificato in critica 08/09/2026).
const CHIAVE_RECUPERO = 'giardino_recupero_password'

function leggiFlagRecupero() {
  try { return sessionStorage.getItem(CHIAVE_RECUPERO) === '1' }
  catch { return false }
}
function scriviFlagRecupero(attivo) {
  try {
    if (attivo) sessionStorage.setItem(CHIAVE_RECUPERO, '1')
    else sessionStorage.removeItem(CHIAVE_RECUPERO)
  } catch { /* storage non disponibile: il flag resta solo in memoria */ }
}

const recuperoInCorso = ref(leggiFlagRecupero())

// Ritorno dal link di una mail di Supabase (conferma della registrazione o
// recupero password). Supabase rimanda con `?code=…` (PKCE) oppure con
// `error_code`/`error_description` se il link è scaduto o già usato. I
// parametri si leggono qui, all'avvio, prima che Supabase li tolga
// dall'indirizzo. `esitoLink` dice ad AccountView e a Home cosa raccontare:
// - 'confermato': codice scambiato, sessione aperta (la mail è confermata);
// - 'altro-browser': la mail è confermata lato Supabase, ma il link si è
//   aperto in un browser diverso da quello della registrazione (spesso il
//   browser interno dell'app di posta), dove manca la chiave PKCE: niente
//   sessione, si accede a mano;
// - 'scaduto': link scaduto o già usato.
function leggiParametriLink() {
  if (typeof window === 'undefined') return { codice: null, errore: null }
  const cerca = new URLSearchParams(window.location.search)
  // Gli errori possono arrivare anche nel frammento (#error=…), che con
  // createWebHashHistory è anche dove vive la rotta: si leggono solo se il
  // frammento ha la forma di parametri e non di una rotta.
  const frammento = window.location.hash.replace(/^#\/?/, '')
  const nelFrammento = /^(error|error_code|error_description)=/.test(frammento) ? new URLSearchParams(frammento) : null
  const errore = cerca.get('error_code') || cerca.get('error') || nelFrammento?.get('error_code') || nelFrammento?.get('error') || null
  return { codice: cerca.get('code'), errore }
}
const parametriLink = leggiParametriLink()
const esitoLink = ref(parametriLink.errore ? 'scaduto' : null)

function pulisciIndirizzo() {
  try {
    const url = new URL(window.location.href)
    let cambiato = false
    for (const k of ['code', 'error', 'error_code', 'error_description']) {
      if (url.searchParams.has(k)) { url.searchParams.delete(k); cambiato = true }
    }
    if (/^#\/?(error|error_code|error_description)=/.test(url.hash)) { url.hash = '#/account'; cambiato = true }
    if (cambiato) window.history.replaceState(window.history.state, '', url.toString())
  } catch { /* indirizzo non modificabile: resta com'è */ }
}

// Promise esposta (vedi sotto) così la guardia di navigazione del router può
// aspettare la sessione senza reimplementare un polling su `caricamento`.
const sessionePronta = supabase.auth.getSession().then(({ data }) => {
  utente.value = data.session?.user ?? null
  caricamento.value = false
  // Un codice rimasto nell'indirizzo senza sessione: Supabase non l'ha
  // scambiato perché in questo browser manca la chiave PKCE.
  if (parametriLink.codice && !utente.value && !recuperoInCorso.value) esitoLink.value = 'altro-browser'
  if (parametriLink.codice || parametriLink.errore) pulisciIndirizzo()
})

supabase.auth.onAuthStateChange((evento, sessione) => {
  utente.value = sessione?.user ?? null
  if (evento === 'SIGNED_IN' && parametriLink.codice && !recuperoInCorso.value && !esitoLink.value) {
    esitoLink.value = 'confermato'
  }
  if (evento === 'PASSWORD_RECOVERY') {
    if (esitoLink.value === 'confermato') esitoLink.value = null
    recuperoInCorso.value = true
    scriviFlagRecupero(true)
  }
  // La cache del service worker per le risposte Supabase (vite.config.js) è
  // per-URL, non per-utente: su un device condiviso, senza questa pulizia,
  // un secondo utente offline potrebbe vedere temporaneamente i dati
  // dell'utente precedente. `caches` non esiste in ambienti senza service
  // worker (es. alcuni contesti di test): controllo difensivo.
  if (evento === 'SIGNED_OUT') {
    recuperoInCorso.value = false
    scriviFlagRecupero(false)
    if (typeof caches !== 'undefined') caches.delete('giardino-dati-supabase')
  }
})

// Supabase Auth risponde in inglese: traduciamo per codice (`error.code`,
// stabile tra le versioni di Supabase), con il testo esatto come ripiego per
// le risposte senza codice (rete assente, versioni vecchie). Quello che non
// riconosciamo diventa un messaggio italiano generico: il testo inglese di
// Supabase non arriva mai all'utente (critica del 30/10/2026).
const MESSAGGI_PER_CODICE = {
  email_not_confirmed: 'Questo indirizzo non è ancora confermato: apri il link che ti ho mandato per email.',
  invalid_credentials: 'Email o password non corretti.',
  user_already_exists: 'Esiste già un account con questa email.',
  email_exists: 'Esiste già un account con questa email.',
  weak_password: 'Password troppo debole: scegline una più lunga, mescolando lettere, numeri e simboli.',
  same_password: 'La nuova password è uguale a quella di prima: scegline una diversa.',
  email_address_invalid: 'Questo indirizzo email non è valido: controlla di averlo scritto bene.',
  email_address_not_authorized: 'Non riesco a mandare email a questo indirizzo: provane un altro.',
  validation_failed: 'Controlla i dati inseriti: qualcosa non è nel formato giusto.',
  signup_disabled: 'Le nuove registrazioni sono chiuse per il momento.',
  otp_expired: 'Il link non è più valido: richiedine uno nuovo.',
  flow_state_expired: 'Il link non è più valido: richiedine uno nuovo.',
  flow_state_not_found: 'Il link non è più valido: richiedine uno nuovo.',
  over_email_send_rate_limit: 'Ho già mandato troppe email a questo indirizzo: aspetta qualche minuto e riprova.',
  over_request_rate_limit: 'Troppi tentativi ravvicinati: aspetta un minuto e riprova.',
  captcha_failed: 'Verifica anti-robot non riuscita: attendi che si completi e riprova.',
}
const MESSAGGI_PER_TESTO = {
  'Email not confirmed': MESSAGGI_PER_CODICE.email_not_confirmed,
  'Invalid login credentials': MESSAGGI_PER_CODICE.invalid_credentials,
  'User already registered': MESSAGGI_PER_CODICE.user_already_exists,
  'Password should be at least 6 characters': 'La password deve avere almeno 6 caratteri.',
  'Email link is invalid or has expired': MESSAGGI_PER_CODICE.otp_expired,
  'Token has expired or is invalid': MESSAGGI_PER_CODICE.otp_expired,
  'Failed to fetch': 'Connessione assente: controlla la rete e riprova.',
  'Load failed': 'Connessione assente: controlla la rete e riprova.',
}

// Restituisce un Error con il messaggio in italiano e `codice` (il codice di
// Supabase, o 'email_not_confirmed' riconosciuto dal testo), così la vista
// può reagire al caso e non solo mostrarlo.
function traduci(error) {
  const grezzo = error?.message ?? ''
  let codice = error?.code ?? null
  if (!codice && grezzo === 'Email not confirmed') codice = 'email_not_confirmed'
  let messaggio = (codice && MESSAGGI_PER_CODICE[codice]) || MESSAGGI_PER_TESTO[grezzo]
  if (!messaggio && /only request this after|rate limit/i.test(grezzo)) messaggio = MESSAGGI_PER_CODICE.over_request_rate_limit
  // Token Turnstile mancante, scaduto o già usato (Supabase lo verifica con
  // la secret key impostata in Attack Protection).
  if (!messaggio && /captcha/i.test(grezzo)) messaggio = MESSAGGI_PER_CODICE.captcha_failed
  if (!messaggio && /password/i.test(grezzo)) messaggio = MESSAGGI_PER_CODICE.weak_password
  if (!messaggio && /fetch|network/i.test(grezzo)) messaggio = MESSAGGI_PER_TESTO['Failed to fetch']
  const tradotto = new Error(messaggio || 'Qualcosa non ha funzionato: riprova tra poco.')
  tradotto.codice = codice
  return tradotto
}

// captchaToken è il token di Cloudflare Turnstile (TurnstileWidget.vue):
// quando la protezione CAPTCHA di Supabase Auth è attiva, accesso,
// registrazione, reinvio della conferma e recupero password lo richiedono.
// Senza site key configurata arriva undefined e Supabase non lo cerca.
export function useAuth() {
  async function registrati(email, password, nome, captchaToken) {
    const { data, error } = await supabase.auth.signUp({
      email, password, options: { data: { nome }, captchaToken },
    })
    if (error) throw traduci(error)
    return data
  }

  // updateUser emette USER_UPDATED: onAuthStateChange qui sopra riaggiorna
  // `utente` (e quindi `nomeUtente`) senza bisogno di un refresh manuale.
  async function aggiornaNome(nome) {
    const { error } = await supabase.auth.updateUser({ data: { nome } })
    if (error) throw traduci(error)
  }

  async function accedi(email, password, captchaToken) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email, password, options: { captchaToken },
    })
    if (error) throw traduci(error)
    return data
  }

  // Rimanda l'email di conferma quando la prima non arriva: senza questo, chi
  // chiude la scheda dopo la registrazione resta bloccato ("Email non
  // confermata" al login, nessun modo di farsela reinviare dall'app).
  async function reinviaConferma(email, captchaToken) {
    const { error } = await supabase.auth.resend({ type: 'signup', email, options: { captchaToken } })
    if (error) throw traduci(error)
  }

  async function esci() {
    const { error } = await supabase.auth.signOut()
    if (error) throw traduci(error)
  }

  async function richiediResetPassword(email, captchaToken) {
    const redirectTo = window.location.origin + import.meta.env.BASE_URL
    const { error } = await supabase.auth.resetPasswordForEmail(email, { redirectTo, captchaToken })
    if (error) throw traduci(error)
  }

  async function impostaNuovaPassword(password) {
    const { error } = await supabase.auth.updateUser({ password })
    if (error) throw traduci(error)
    recuperoInCorso.value = false
    scriviFlagRecupero(false)
  }

  return {
    utente, nomeUtente, caricamento, recuperoInCorso, sessionePronta, esitoLink,
    registrati, aggiornaNome, accedi, esci, reinviaConferma,
    richiediResetPassword, impostaNuovaPassword,
  }
}
