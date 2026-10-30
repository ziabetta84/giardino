<template>
  <!-- Loggato: dentro il layout normale dell'app (vedi App.vue), quindi qui
       si può permettere titolo e card come le altre view. -->
  <div v-if="!caricamento && utente && !recuperoInCorso" style="max-width:420px;margin:0 auto;">
    <h1 class="page-title" style="margin-bottom:24px">Account</h1>

    <!-- Blocco identità: stesso Zorba che ti ha accolto all'ingresso, ora più
         piccolo, e il nome scelto in Fraunces (Regola del Nome in Fraunces).
         DESIGN.md indica questa vista come la più critica per la fiducia:
         l'accesso effettuato non deve atterrare sullo schermo più anonimo
         dell'app (critica 10/09/2026). -->
    <div class="form-card account-id">
      <div class="account-id__hd">
        <ZorbaLogo mini />
        <div style="min-width:0;flex:1;">
          <div class="account-id__greet">
            <p class="account-id__nome">{{ nomeUtente ? `Ciao, ${nomeUtente}` : 'Ciao' }}</p>
            <button v-if="!modificandoNome" type="button" class="link-reset" @click="iniziaModificaNome">
              {{ nomeUtente ? 'Modifica nome' : 'Aggiungi il tuo nome' }}
            </button>
          </div>
          <p class="account-id__email">{{ utente.email }}</p>
        </div>
      </div>

      <div v-if="modificandoNome" class="account-id__nome-edit">
        <label class="field-label" for="account-nome">Come vuoi essere chiamato</label>
        <div style="display:flex;gap:8px;">
          <input id="account-nome" v-model.trim="nomeInput" type="text" maxlength="50" autocomplete="name"
            placeholder="Il tuo nome" class="form-input" style="flex:1;" @keyup.enter="onSalvaNome">
          <button type="button" class="btn btn-sage"
            :disabled="!nomeInput.trim() || salvandoNome" @click="onSalvaNome">
            {{ salvandoNome ? '…' : 'Salva' }}
          </button>
        </div>
        <button type="button" class="link-reset" style="margin-top:8px;" @click="modificandoNome = false">Annulla</button>
        <p v-if="erroreNome" role="alert" class="account-err">{{ erroreNome }}</p>
      </div>

      <button class="btn btn-ghost" style="width:100%;" :disabled="uscendo" @click="onEsci">
        {{ uscendo ? 'Uscita in corso…' : 'Esci' }}
      </button>
      <p v-if="errore" role="alert" class="account-err">{{ errore }}</p>
    </div>

    <RouterLink to="/impostazioni" class="form-card" style="display:flex;align-items:center;justify-content:space-between;margin-top:16px;text-decoration:none;color:inherit;">
      <span style="font-size:13px;font-weight:600;">Impostazioni giardino</span>
      <Icon name="back" style="width:14px;height:14px;flex-shrink:0;color:var(--ink-faint);transform:rotate(180deg);" />
    </RouterLink>

    <!-- Contributo volontario durante la beta: link esterno alla piattaforma
         di donazione (VITE_LINK_CONTRIBUTO in .env), nessun pagamento passa
         dall'app. Vuoto = la card non compare. -->
    <ContributoCard v-if="linkContributo" class="form-card" style="margin-top:16px;" />

    <!-- Rivede lo splash d'ingresso di Home fuori dalla sua cadenza normale
         (due finestre al giorno, una volta a testa) — vedi richiediSplash()
         in useBootSequence.js. -->
    <button type="button" class="form-card" style="display:flex;align-items:center;justify-content:space-between;margin-top:16px;width:100%;text-align:left;font-family:inherit;cursor:pointer;" @click="onRivediSplash">
      <span style="font-size:13px;font-weight:600;">Rivedi il benvenuto</span>
      <Icon name="back" style="width:14px;height:14px;flex-shrink:0;color:var(--ink-faint);transform:rotate(180deg);" />
    </button>

  </div>

  <!-- Non loggato (login/registrazione) o con una sessione di recupero
       password temporanea (evento PASSWORD_RECOVERY in useAuth.js): stesso
       header con logo animato + titolo, App.vue toglie il resto del vestito
       dell'app e centra questo blocco da solo in pagina. -->
  <div v-else-if="!caricamento" class="auth">
    <div class="account-hero">
      <ZorbaLogo ref="zorba" style="width:64px;height:64px;margin:0 auto 8px;" />
      <!-- A ogni cambio di passo il focus va sul titolo: chi usa un lettore
           di schermo sente dove è arrivato invece di restare su un pulsante
           che non c'è più. -->
      <h1 ref="titoloEl" class="page-title auth__titolo" tabindex="-1">{{ titolo }}</h1>
      <p v-if="passo === 'modulo'" class="auth__sottotitolo">
        Il quaderno del tuo giardino: le piante, le cure di stagione e Zorba che ti consiglia.
      </p>
    </div>

    <form v-if="passo === 'recupero'" novalidate @submit.prevent="onImpostaPassword" class="auth__form">
      <div>
        <label class="field-label" for="auth-nuova-password">Nuova password</label>
        <CampoPassword id="auth-nuova-password" v-model="nuovaPassword" autocomplete="new-password"
          aria-describedby="auth-nuova-password-nota" :aria-invalid="!!erroriCampo.nuovaPassword" autofocus />
        <p id="auth-nuova-password-nota" class="auth__nota" :class="{ 'auth__nota--err': erroriCampo.nuovaPassword }">
          {{ erroriCampo.nuovaPassword || 'Almeno 6 caratteri.' }}
        </p>
      </div>
      <p v-if="errore" class="auth__esito auth__esito--err" role="alert">{{ errore }}</p>
      <button type="submit" class="btn btn-sage" :disabled="inviando">
        {{ inviando ? 'Salvo…' : 'Salva password' }}
      </button>
      <button type="button" class="link-reset" style="align-self:center;" :disabled="inviando" @click="onAnnullaRecupero">
        Annulla e torna ad accedere
      </button>
    </form>

    <!-- Subito dopo la registrazione, prima di «Controlla la posta»: invito
         al contributo volontario (posizione decisa dall'utente il 29/10/2026).
         Prima dell'invito, una riga dice che la mail è già partita: chi si è
         appena registrato sa che l'account esiste prima che gli si chieda
         qualcosa (critica del 30/10/2026). Qualunque scelta porta alla
         schermata della mail di conferma. -->
    <div v-else-if="passo === 'contributo'" class="auth__colonna">
      <p class="auth__testo" role="status">
        Ti ho mandato una mail a <strong class="auth__email">{{ emailConferma }}</strong>
        per confermare l'indirizzo. Prima di aprirla, una cosa:
      </p>
      <ContributoCard invito testo-no="Magari più avanti"
        class="form-card" style="text-align:left;" @scelta="passoContributo = false" />
    </div>

    <!-- Indirizzo già registrato: con la conferma email attiva Supabase non
         dà errore (per non rivelare chi è iscritto) e restituisce un utente
         senza identità, senza mandare nessuna mail. Senza questo passo chi
         si iscrive due volte aspetterebbe una mail che non arriva mai. -->
    <div v-else-if="passo === 'gia-registrato'" class="auth__colonna">
      <p class="auth__testo">
        Con <strong class="auth__email">{{ email }}</strong> c'è già un account.
        Se l'hai creato tu, entra da qui; se non ricordi la password, te ne faccio scegliere una nuova.
      </p>
      <p v-if="messaggio" class="auth__esito auth__esito--ok" role="status">{{ messaggio }}</p>
      <p v-if="errore" class="auth__esito auth__esito--err" role="alert">{{ errore }}</p>
      <button type="button" class="btn btn-sage" @click="vaiAdAccedere(true)">Accedi con questo indirizzo</button>
      <TurnstileWidget ref="turnstile" @token="onToken" @errore="onErroreCaptcha" />
      <button type="button" class="btn btn-ghost" :disabled="inviando || attesaCaptcha" @click="onRichiediReset">
        {{ inviando ? 'Invio…' : 'Ho dimenticato la password' }}
      </button>
      <button type="button" class="link-reset" style="align-self:center;" @click="correggiIndirizzo">Usa un altro indirizzo</button>
    </div>

    <!-- In attesa della conferma: dopo la registrazione, oppure dopo un
         accesso con un indirizzo non ancora confermato. Resta anche
         ricaricando la pagina (sessionStorage). -->
    <div v-else-if="passo === 'posta'" class="auth__colonna" style="text-align:center;">
      <p class="auth__testo">
        <template v-if="origineConferma === 'accesso'">
          Questo indirizzo non è ancora confermato. Ti avevo mandato una mail a
        </template>
        <template v-else>Ti ho mandato una mail a</template>
        <strong class="auth__email">{{ emailConferma }}</strong>:
        apri il link che contiene e il cancello si apre. Se non la trovi, guarda anche nello spam.
      </p>
      <p v-if="messaggio" class="auth__esito auth__esito--ok" role="status">{{ messaggio }}</p>
      <p v-if="errore" class="auth__esito auth__esito--err" role="alert">{{ errore }}</p>
      <TurnstileWidget ref="turnstile" @token="onToken" @errore="onErroreCaptcha" />
      <button type="button" class="btn btn-ghost" :disabled="inviando || attesaCaptcha" @click="onReinviaConferma">
        {{ inviando ? 'Invio…' : 'Non è arrivata? Mandamela di nuovo' }}
      </button>
      <div class="auth__link-riga">
        <button type="button" class="link-reset" @click="correggiIndirizzo">Indirizzo sbagliato? Correggilo</button>
        <button type="button" class="link-reset" @click="vaiAdAccedere(false)">Torna ad accedere</button>
      </div>
    </div>

    <template v-else>
      <!-- Ritorno dal link di una mail (vedi esitoLink in useAuth.js). -->
      <p v-if="esitoLink === 'altro-browser'" class="auth__avviso" role="status">
        Il tuo indirizzo è confermato. Il link si è aperto in un browser diverso da quello
        usato per la registrazione, quindi qui si entra con email e password.
        Se invece stavi cambiando la password, chiedila di nuovo da «Password dimenticata?».
      </p>
      <p v-else-if="esitoLink === 'scaduto'" class="auth__avviso" role="status">
        Il link della mail non è più valido: si usa una volta sola e dura poco.
        Accedi con email e password: se l'indirizzo non è ancora confermato ti propongo di mandarti
        un'altra mail. Se stavi cambiando la password, chiedila di nuovo da «Password dimenticata?».
      </p>

      <div class="auth__schede" role="tablist" aria-label="Accedi o registrati">
        <button id="tab-accedi" type="button" class="pill" role="tab" aria-controls="pannello-accesso"
          :aria-selected="modalita === 'accedi'" :class="{ active: modalita === 'accedi' }" @click="cambiaModalita('accedi')">Accedi</button>
        <button id="tab-registrati" type="button" class="pill" role="tab" aria-controls="pannello-accesso"
          :aria-selected="modalita === 'registrati'" :class="{ active: modalita === 'registrati' }" @click="cambiaModalita('registrati')">Registrati</button>
      </div>

      <!-- novalidate: i messaggi sono quelli dell'app, sotto ogni campo, non
           i fumetti del browser (che non seguono né la lingua né lo stile). -->
      <form id="pannello-accesso" role="tabpanel" novalidate class="auth__form"
        :aria-labelledby="modalita === 'accedi' ? 'tab-accedi' : 'tab-registrati'"
        @submit.prevent="onInvia">
        <div v-if="modalita === 'registrati'">
          <label class="field-label" for="auth-nome">Nome</label>
          <input id="auth-nome" ref="campoNome" v-model.trim="nome" type="text" autocomplete="name" maxlength="50"
            class="form-input" aria-describedby="auth-nome-nota" :aria-invalid="!!erroriCampo.nome">
          <p id="auth-nome-nota" class="auth__nota" :class="{ 'auth__nota--err': erroriCampo.nome }">
            {{ erroriCampo.nome || 'Come ti chiamerà Zorba.' }}
          </p>
        </div>
        <div>
          <label class="field-label" for="auth-email">Email</label>
          <input id="auth-email" ref="campoEmail" v-model.trim="email" type="email" inputmode="email"
            autocomplete="email" autocapitalize="off" spellcheck="false" class="form-input"
            :aria-describedby="erroriCampo.email || suggerimentoEmail ? 'auth-email-nota' : undefined"
            :aria-invalid="!!erroriCampo.email" autofocus @blur="emailToccata = true">
          <p v-if="erroriCampo.email" id="auth-email-nota" class="auth__nota auth__nota--err">{{ erroriCampo.email }}</p>
          <p v-else-if="suggerimentoEmail" id="auth-email-nota" class="auth__nota">
            Intendevi
            <button type="button" class="auth__suggerimento" @click="usaSuggerimento">{{ suggerimentoEmail }}</button>?
          </p>
        </div>
        <div>
          <label class="field-label" for="auth-password">Password</label>
          <CampoPassword id="auth-password" v-model="password"
            :autocomplete="modalita === 'accedi' ? 'current-password' : 'new-password'"
            :aria-describedby="modalita === 'registrati' || erroriCampo.password ? 'auth-password-nota' : undefined"
            :aria-invalid="!!erroriCampo.password" />
          <p v-if="modalita === 'registrati' || erroriCampo.password" id="auth-password-nota"
            class="auth__nota" :class="{ 'auth__nota--err': erroriCampo.password }">
            {{ erroriCampo.password || 'Almeno 6 caratteri.' }}
          </p>
        </div>

        <button v-if="modalita === 'accedi'" type="button" class="link-reset" :disabled="inviando || attesaCaptcha" @click="onRichiediReset">
          Password dimenticata?
        </button>

        <!-- Verifica anti-robot di Cloudflare: di solito si completa da sola
             in un attimo; il suo token accompagna accesso, registrazione e
             recupero password. -->
        <TurnstileWidget ref="turnstile" @token="onToken" @errore="onErroreCaptcha" />

        <p v-if="errore" class="auth__esito auth__esito--err" role="alert">{{ errore }}</p>
        <p v-if="messaggio" class="auth__esito auth__esito--ok" role="status">{{ messaggio }}</p>

        <button type="submit" class="btn btn-sage" :disabled="inviando || attesaCaptcha" style="margin-top:4px;">
          {{ etichettaInvio }}
        </button>
      </form>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import Icon from '@/components/Icon.vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import TurnstileWidget from '@/components/TurnstileWidget.vue'
import ContributoCard from '@/components/ContributoCard.vue'
import CampoPassword from '@/components/CampoPassword.vue'
import { emailValida, suggerisciEmail } from '@/utils/email'
import { linkContributo } from '@/composables/useContributo'
import { useAuth } from '@/composables/useAuth'
import { richiediSplash } from '@/composables/useBootSequence'

const router = useRouter()
const { utente, nomeUtente, caricamento, recuperoInCorso, esitoLink, accedi, registrati, aggiornaNome, esci, reinviaConferma, richiediResetPassword, impostaNuovaPassword } = useAuth()

const zorba = ref(null)

const modalita  = ref('accedi')
const email     = ref('')
const password  = ref('')
const nome      = ref('')
const nuovaPassword = ref('')

// Modifica del nome dalla vista loggato (modifica inline)
const nomeInput       = ref('')
const modificandoNome = ref(false)
const salvandoNome    = ref(false)
const erroreNome      = ref(null)
const inviando  = ref(false)
const uscendo   = ref(false)
const errore    = ref(null)
const messaggio = ref(null)
// Email a cui è stata inviata la conferma di registrazione, o null quando non
// c'è una conferma in attesa: sostituisce il form con un pannello dedicato
// invece di lasciarlo invariato (vedi template). In sessionStorage, insieme a
// da dove si è arrivati (registrazione o accesso non confermato): ricaricando
// la pagina il pannello resta, con il pulsante per farsi rimandare la mail.
const CHIAVE_CONFERMA = 'giardino_conferma_in_attesa'
function leggiConferma() {
  try { return JSON.parse(sessionStorage.getItem(CHIAVE_CONFERMA)) ?? null } catch { return null }
}
function scriviConferma(valore) {
  try {
    if (valore) sessionStorage.setItem(CHIAVE_CONFERMA, JSON.stringify(valore))
    else sessionStorage.removeItem(CHIAVE_CONFERMA)
  } catch { /* storage non disponibile: il pannello vale finché la pagina resta aperta */ }
}
const confermaSalvata = leggiConferma()
const emailConferma = ref(confermaSalvata?.email ?? null)
const origineConferma = ref(confermaSalvata?.origine ?? 'registrazione')
watch([emailConferma, origineConferma], ([e, o]) => scriviConferma(e ? { email: e, origine: o } : null))
const passoContributo = ref(false)
const giaRegistrato = ref(false)
// Entrati (anche dal link della mail, nella stessa scheda): nessun pannello
// di attesa deve ricomparire a un'uscita successiva.
watch(utente, (u) => {
  if (!u) return
  emailConferma.value = null
  giaRegistrato.value = false
}, { immediate: true })

// Un solo stato del blocco non loggato, da cui dipendono titolo e contenuto.
const passo = computed(() => {
  if (recuperoInCorso.value) return 'recupero'
  if (passoContributo.value) return 'contributo'
  if (giaRegistrato.value) return 'gia-registrato'
  if (emailConferma.value) return 'posta'
  return 'modulo'
})
const titolo = computed(() => ({
  recupero: 'Nuova password',
  contributo: 'Il cancello è quasi aperto',
  'gia-registrato': 'Ci conosciamo già',
  posta: 'Controlla la posta',
  modulo: 'Lascia entrare Zorba in giardino',
})[passo.value])

const titoloEl = ref(null)
const campoNome = ref(null)
const campoEmail = ref(null)
watch(passo, async (nuovo, vecchio) => {
  if (nuovo === vecchio) return
  await nextTick()
  titoloEl.value?.focus()
})

// Errori dei singoli campi, scritti sotto il campo (il modulo è novalidate).
const erroriCampo = ref({})
const emailToccata = ref(false)
const suggerimentoEmail = computed(() => (emailToccata.value ? suggerisciEmail(email.value) : null))
function usaSuggerimento() {
  email.value = suggerimentoEmail.value
  erroriCampo.value = { ...erroriCampo.value, email: null }
}
function validaModulo() {
  const e = {}
  if (modalita.value === 'registrati' && !nome.value) e.nome = 'Scrivi il tuo nome: è come ti chiamerà Zorba.'
  if (!email.value) e.email = 'Scrivi il tuo indirizzo email.'
  else if (!emailValida(email.value)) e.email = 'Questo indirizzo non sembra completo: controlla la @ e il punto.'
  if (!password.value) e.password = 'Scrivi la password.'
  else if (modalita.value === 'registrati' && password.value.length < 6) e.password = 'La password deve avere almeno 6 caratteri.'
  erroriCampo.value = e
  if (e.nome) campoNome.value?.focus()
  else if (e.email) campoEmail.value?.focus()
  else if (e.password) document.getElementById('auth-password')?.focus()
  return !Object.keys(e).length
}

const etichettaInvio = computed(() => {
  if (inviando.value) return modalita.value === 'accedi' ? 'Accesso…' : 'Creo l\'account…'
  if (attesaCaptcha.value && !captchaFallito.value) return 'Verifica in corso…'
  return modalita.value === 'accedi' ? 'Accedi' : 'Crea account'
})

// Token Turnstile: obbligatorio solo se la site key è configurata (vedi
// TurnstileWidget.vue). Un token vale una volta: dopo ogni chiamata ad Auth
// il widget viene azzerato e ne produce uno nuovo.
const turnstile    = ref(null)
const captchaToken = ref(null)
const attesaCaptcha = computed(() => !!import.meta.env.VITE_TURNSTILE_SITE_KEY && !captchaToken.value)
// Widget non caricato (rete, blocco dei contenuti): il pulsante resta
// disabilitato ma non dice più "Verifica in corso…", c'è il messaggio d'errore.
const captchaFallito = ref(false)

function onToken(t) {
  captchaToken.value = t
  if (t) captchaFallito.value = false
}

function onErroreCaptcha() {
  captchaFallito.value = true
  errore.value = 'Non riesco a caricare la verifica anti-robot: controlla la connessione e ricarica la pagina.'
}

function nuovoCaptcha() {
  turnstile.value?.reset()
}

function iniziaModificaNome() {
  nomeInput.value = nomeUtente.value || ''
  erroreNome.value = null
  modificandoNome.value = true
}

async function onSalvaNome() {
  if (salvandoNome.value || !nomeInput.value.trim()) return
  salvandoNome.value = true
  erroreNome.value = null
  try {
    await aggiornaNome(nomeInput.value.trim())
    modificandoNome.value = false
  } catch (e) {
    erroreNome.value = e.message || 'Errore durante il salvataggio.'
  } finally {
    salvandoNome.value = false
  }
}

function cambiaModalita(nuova) {
  modalita.value = nuova
  errore.value = null
  messaggio.value = null
  erroriCampo.value = {}
}

function chiudiPannelli() {
  emailConferma.value = null
  passoContributo.value = false
  giaRegistrato.value = false
  password.value = ''
  errore.value = null
  messaggio.value = null
  erroriCampo.value = {}
}

// Torna al modulo di accesso; con `tieniEmail` l'indirizzo resta scritto
// (account già esistente: si entra con quello).
async function vaiAdAccedere(tieniEmail) {
  const indirizzo = emailConferma.value || email.value
  chiudiPannelli()
  modalita.value = 'accedi'
  email.value = tieniEmail ? indirizzo : email.value
  await nextTick()
  if (tieniEmail) document.getElementById('auth-password')?.focus()
}

// Indirizzo sbagliato: si torna al modulo da cui si era partiti, con i campi
// già compilati e il cursore sull'email.
async function correggiIndirizzo() {
  const indirizzo = emailConferma.value || email.value
  const daAccesso = emailConferma.value && origineConferma.value === 'accesso'
  chiudiPannelli()
  modalita.value = daAccesso ? 'accedi' : 'registrati'
  email.value = indirizzo
  await nextTick()
  campoEmail.value?.focus()
  campoEmail.value?.select()
}

async function onInvia() {
  if (inviando.value) return
  errore.value = null
  messaggio.value = null
  if (!validaModulo()) return
  esitoLink.value = null
  inviando.value = true
  try {
    if (modalita.value === 'accedi') {
      await accedi(email.value, password.value, captchaToken.value)
      router.push('/')
    } else {
      const dati = await registrati(email.value, password.value, nome.value, captchaToken.value)
      // Indirizzo già confermato da un altro account: Supabase risponde
      // senza errore ma con `identities` vuoto e non manda nessuna mail.
      if (Array.isArray(dati?.user?.identities) && dati.user.identities.length === 0) {
        password.value = ''
        giaRegistrato.value = true
        return
      }
      origineConferma.value = 'registrazione'
      emailConferma.value = email.value
      passoContributo.value = !!linkContributo
      // Battito lento: evento raro (una tantum per account), non la conferma
      // quotidiana di confermaCura() — vedi "Regola dei Due Battiti" in ZorbaLogo.vue.
      zorba.value?.reagisci()
    }
  } catch (e) {
    // Accesso con un indirizzo non confermato: invece di una riga rossa senza
    // via d'uscita, il pannello della posta con il pulsante per rimandarla
    // (la mail di conferma lo promette: «chiedine un altro dalla pagina di
    // accesso»).
    if (e.codice === 'email_not_confirmed') {
      origineConferma.value = 'accesso'
      emailConferma.value = email.value
      password.value = ''
      return
    }
    errore.value = e.message || 'Qualcosa non ha funzionato: riprova tra poco.'
  } finally {
    inviando.value = false
    nuovoCaptcha()
  }
}

async function onReinviaConferma() {
  if (inviando.value) return
  errore.value = null
  messaggio.value = null
  inviando.value = true
  try {
    await reinviaConferma(emailConferma.value, captchaToken.value)
    messaggio.value = 'Fatto: ti ho mandato una mail nuova. Usa il link dell\'ultima che ricevi.'
  } catch (e) {
    errore.value = e.message || 'Non sono riuscito a mandare la mail: riprova tra poco.'
  } finally {
    inviando.value = false
    nuovoCaptcha()
  }
}

async function onRichiediReset() {
  if (inviando.value) return
  errore.value = null
  messaggio.value = null
  if (!email.value || !emailValida(email.value)) {
    erroriCampo.value = { email: 'Scrivi qui il tuo indirizzo email: ti mando il link per scegliere una nuova password.' }
    campoEmail.value?.focus()
    return
  }
  inviando.value = true
  try {
    await richiediResetPassword(email.value, captchaToken.value)
    messaggio.value = `Ti ho mandato una mail a ${email.value} con il link per scegliere una nuova password.`
    zorba.value?.reagisci()
  } catch (e) {
    errore.value = e.message || 'Non sono riuscito a mandare la mail: riprova tra poco.'
  } finally {
    inviando.value = false
    nuovoCaptcha()
  }
}

async function onImpostaPassword() {
  if (inviando.value) return
  errore.value = null
  erroriCampo.value = nuovaPassword.value.length < 6
    ? { nuovaPassword: 'La password deve avere almeno 6 caratteri.' } : {}
  if (erroriCampo.value.nuovaPassword) {
    document.getElementById('auth-nuova-password')?.focus()
    return
  }
  inviando.value = true
  try {
    await impostaNuovaPassword(nuovaPassword.value)
  } catch (e) {
    errore.value = e.message || 'Errore durante il salvataggio.'
  } finally {
    inviando.value = false
  }
}

async function onAnnullaRecupero() {
  if (inviando.value) return
  errore.value = null
  inviando.value = true
  try {
    await esci()
  } catch (e) {
    errore.value = e.message || 'Errore durante l\'uscita.'
  } finally {
    inviando.value = false
  }
}

function onRivediSplash() {
  richiediSplash()
  router.push('/')
}

async function onEsci() {
  if (uscendo.value) return
  errore.value = null
  uscendo.value = true
  try {
    await esci()
  } catch (e) {
    errore.value = e.message || 'Errore durante l\'uscita.'
  } finally {
    uscendo.value = false
  }
}
</script>

<style scoped>
.form-card > .slabel:first-child { margin-top: 0; }
.link-reset {
  background: none; border: none; padding: 0; text-align: left;
  font-size: 13px; color: var(--ink-mid); text-decoration: underline;
  text-underline-offset: 3px; text-decoration-color: var(--ink-faint);
  cursor: pointer; align-self: flex-start;
  min-height: 44px; display: inline-flex; align-items: center;
}
.link-reset:hover { color: var(--ink); text-decoration-color: currentColor; }
.link-reset:disabled { opacity: .5; cursor: default; }

/* Blocco identità della vista loggata: Zorba mini + saluto in Fraunces, con
   un alone ad acquerello proprio — la stessa cura data allo stato slogato
   (.account-hero), estesa alla metà loggata (critica 10/09/2026). */
.form-card.account-id { position: relative; overflow: hidden; }
.account-id::before {
  content: '';
  position: absolute; right: -44px; top: -54px;
  width: 176px; height: 176px;
  background: radial-gradient(circle, rgba(224,184,74,0.16) 0%, rgba(122,158,130,0.10) 55%, transparent 78%);
  pointer-events: none;
}
.account-id > * { position: relative; }
.account-id__hd { display: flex; align-items: flex-start; gap: 12px; margin-bottom: 18px; }
.account-id :deep(.zorba-mini) { width: 30px; height: 30px; flex: none; margin-top: 2px; }
.account-id__greet { display: flex; flex-wrap: wrap; align-items: baseline; gap: 2px 12px; }
.account-id__nome { font: 600 18px/1.25 var(--font-display); color: var(--ink); }
.account-id__email { font-size: 13px; color: var(--ink-mid); word-break: break-all; margin-top: 4px; }
.account-id__nome-edit { margin: -4px 0 16px; }
.account-err { font-size: 12px; color: var(--rose-dark); margin-top: 10px; }

.account-hero { text-align: center; margin-bottom: 20px; }

/* ===== Blocco non loggato (accesso, registrazione, attesa della mail) =====
   Contrasti e misure riviste nella critica del 30/10/2026: etichette in
   inchiostro medio (il grigio carta era a 3:1), testo dei campi a 16px
   (sotto quella misura iOS ingrandisce la pagina al tocco), schede e link
   da almeno 44px, verde del bottone principale più scuro per reggere il
   testo bianco (4,6:1 invece di 3:1). */
.auth { width: 100%; max-width: 360px; }
.auth__titolo { text-wrap: balance; outline: none; }
.auth__sottotitolo {
  margin: 8px auto 0; max-width: 30ch;
  font-size: 13px; line-height: 1.5; color: var(--ink-mid); text-wrap: pretty;
}
.auth__form, .auth__colonna { display: flex; flex-direction: column; gap: 10px; }
.auth__testo { font-size: 14px; line-height: 1.55; color: var(--ink-mid); text-wrap: pretty; }
.auth__email { color: var(--ink); font-weight: 600; word-break: break-all; }
.auth__link-riga { display: flex; flex-wrap: wrap; justify-content: center; column-gap: 20px; }
.auth__avviso {
  margin-bottom: 16px; padding: 12px 14px; border-radius: 14px;
  background: var(--gold-bg); color: var(--gold-ink);
  font-size: 13px; line-height: 1.5; text-wrap: pretty;
}
.auth__schede { display: flex; gap: 6px; margin-bottom: 16px; justify-content: center; }
.auth__schede .pill { min-height: 44px; padding: 0 20px; font-size: 13px; color: var(--ink-mid); }
.auth__schede .pill.active,
.auth .btn-sage { background: var(--sage-dark); border-color: var(--sage-dark); color: var(--white); }
.auth .btn-sage:hover { background: var(--sage-ink); }
.auth .field-label { color: var(--ink-mid); }
.auth :deep(.form-input) { font-size: 16px; }
.auth :deep(.form-input[aria-invalid="true"]) { border-color: var(--rose); }
.auth__nota { margin-top: 6px; font-size: 12px; line-height: 1.45; color: var(--ink-mid); }
.auth__nota--err { color: var(--rose-ink); }
.auth__suggerimento {
  background: none; border: none; padding: 0; font: inherit; font-weight: 600;
  color: var(--sage-ink); text-decoration: underline; text-underline-offset: 3px; cursor: pointer;
}
.auth__esito { font-size: 13px; line-height: 1.5; }
.auth__esito--err { color: var(--rose-ink); }
.auth__esito--ok { color: var(--sage-ink); }
/* Tema scuro: lì --sage-dark è un verde chiaro, che regge il testo scuro
   e non il bianco. */
:global(:root[data-theme="dark"]) .auth__schede .pill.active,
:global(:root[data-theme="dark"]) .auth .btn-sage { color: var(--sage-pale); }

</style>
