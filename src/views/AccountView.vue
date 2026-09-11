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

    <div class="form-card" style="margin-top:16px;">
      <p class="slabel">Token GitHub</p>

      <!-- Configurato: riga discreta, i controlli stanno dietro "Gestisci".
           È un meccanismo in via di dismissione (vedi CLAUDE.md), non deve
           essere l'elemento più pesante della vista. -->
      <template v-if="tokenPresente && !modificandoToken">
        <div class="token-row">
          <Icon name="chiave" style="width:16px;height:16px;flex-shrink:0;color:var(--sage-dark);" />
          <p class="token-row__stato">Token configurato</p>
          <button type="button" class="link-reset" @click="modificandoToken = true">Gestisci</button>
        </div>
      </template>

      <!-- Assente (aggiunta senza attriti), o pannello "Gestisci" aperto -->
      <template v-else>
        <p class="token-hint">Serve per inviare richieste a Zorba e salvare modifiche ai dati del giardino (permesso <code>contents:write</code> sul repo).</p>
        <div style="display:flex;gap:8px;">
          <input v-model="tokenInput" type="password"
            :placeholder="tokenPresente ? 'ghp_… (nuovo token)' : 'ghp_…'"
            class="form-input" style="flex:1;" @keyup.enter="onSalvaToken">
          <button type="button" class="btn btn-sage" :disabled="!tokenInput.trim()" @click="onSalvaToken">Salva</button>
        </div>
        <div v-if="tokenPresente" style="display:flex;align-items:center;gap:12px;margin-top:8px;">
          <button type="button" class="link-reset" @click="modificandoToken = false; tokenInput = ''">Annulla</button>
          <button type="button" class="link-reset" style="color:var(--rose-dark);margin-left:auto;" @click="confermaRimozione = true">Rimuovi token</button>
        </div>
      </template>
    </div>

    <RouterLink to="/impostazioni" class="form-card" style="display:flex;align-items:center;justify-content:space-between;margin-top:16px;text-decoration:none;color:inherit;">
      <span style="font-size:13px;font-weight:600;">Impostazioni giardino</span>
      <Icon name="back" style="width:14px;height:14px;flex-shrink:0;color:var(--ink-faint);transform:rotate(180deg);" />
    </RouterLink>

    <ModalConferma
      :aperto="confermaRimozione"
      titolo="Rimuovere il token GitHub?"
      messaggio="Non potrai più inviare richieste a Zorba né salvare modifiche ai dati del giardino finché non ne inserisci uno nuovo."
      @conferma="onRimuoviToken"
      @annulla="confermaRimozione = false"
    />
  </div>

  <!-- Non loggato (login/registrazione) o con una sessione di recupero
       password temporanea (evento PASSWORD_RECOVERY in useAuth.js): stesso
       header con logo animato + titolo, App.vue toglie il resto del vestito
       dell'app e centra questo blocco da solo in pagina. -->
  <div v-else-if="!caricamento" style="width:100%;max-width:340px;">
    <div class="account-hero">
      <ZorbaLogo ref="zorba" style="width:64px;height:64px;margin:0 auto 8px;" />
      <h1 class="page-title">
        {{ recuperoInCorso ? 'Nuova password' : (emailConferma ? 'Controlla la posta' : 'Lascia entrare Zorba in giardino') }}
      </h1>
    </div>

    <form v-if="recuperoInCorso" @submit.prevent="onImpostaPassword" style="display:flex;flex-direction:column;gap:10px;">
      <div>
        <label class="field-label">Nuova password</label>
        <input v-model="nuovaPassword" type="password" minlength="6" autocomplete="new-password"
          required class="form-input" style="width:100%;" autofocus>
      </div>
      <p v-if="errore" role="alert" style="font-size:13px;color:var(--rose-dark);">{{ errore }}</p>
      <button type="submit" class="btn btn-sage" :disabled="inviando">
        {{ inviando ? 'Un momento…' : 'Salva password' }}
      </button>
      <button type="button" class="link-reset" style="align-self:center;" :disabled="inviando" @click="onAnnullaRecupero">
        Annulla, torna al login
      </button>
    </form>

    <!-- Conferma dopo la registrazione: pannello dedicato invece di lasciare
         il form invariato — è il momento a più alta posta emotiva del flusso
         (l'account resta inattivo finché non si clicca il link ricevuto via
         mail), quindi non riceve solo una riga di testo (vedi critica 08/09/2026).
         Da qui si può anche farsi reinviare l'email se non è arrivata. -->
    <div v-else-if="emailConferma" role="status" style="text-align:center;display:flex;flex-direction:column;gap:10px;">
      <p style="font-size:13px;color:var(--ink-mid);line-height:1.5;">
        Ti abbiamo inviato un'email di conferma a<br>
        <strong style="color:var(--ink);word-break:break-all;">{{ emailConferma }}</strong>.<br>
        Apri il link per attivare l'account, poi torna qui per accedere.
      </p>
      <p v-if="messaggio" role="status" style="font-size:12px;color:var(--sage-dark);">{{ messaggio }}</p>
      <p v-if="errore" role="alert" style="font-size:12px;color:var(--rose-dark);">{{ errore }}</p>
      <button type="button" class="btn btn-ghost" :disabled="inviando" @click="onReinviaConferma">
        {{ inviando ? 'Un momento…' : 'Non è arrivata? Invia di nuovo' }}
      </button>
      <button type="button" class="link-reset" style="align-self:center;" @click="tornaAlLogin">Torna al login</button>
    </div>

    <template v-else>
      <div style="display:flex;gap:6px;margin-bottom:16px;justify-content:center;" role="tablist" aria-label="Modalità di accesso">
        <button id="tab-accedi" type="button" class="pill" role="tab" aria-controls="pannello-accesso"
          :aria-selected="modalita === 'accedi'" :class="{ active: modalita === 'accedi' }" @click="cambiaModalita('accedi')">Accedi</button>
        <button id="tab-registrati" type="button" class="pill" role="tab" aria-controls="pannello-accesso"
          :aria-selected="modalita === 'registrati'" :class="{ active: modalita === 'registrati' }" @click="cambiaModalita('registrati')">Registrati</button>
      </div>

      <form id="pannello-accesso" role="tabpanel"
        :aria-labelledby="modalita === 'accedi' ? 'tab-accedi' : 'tab-registrati'"
        @submit.prevent="onInvia" style="display:flex;flex-direction:column;gap:10px;">
        <div v-if="modalita === 'registrati'">
          <label class="field-label">Nome</label>
          <input v-model.trim="nome" type="text" autocomplete="name" maxlength="50"
            placeholder="Come vuoi essere chiamato" required class="form-input" style="width:100%;">
        </div>
        <div>
          <label class="field-label">Email</label>
          <input v-model.trim="email" type="email" autocomplete="email" required class="form-input" style="width:100%;" autofocus>
        </div>
        <div>
          <label class="field-label">Password</label>
          <input v-model="password" type="password" minlength="6"
            :autocomplete="modalita === 'accedi' ? 'current-password' : 'new-password'"
            required class="form-input" style="width:100%;">
        </div>

        <button v-if="modalita === 'accedi'" type="button" class="link-reset" :disabled="inviando" @click="onRichiediReset">
          Password dimenticata?
        </button>

        <p v-if="errore" role="alert" style="font-size:13px;color:var(--rose-dark);">{{ errore }}</p>
        <p v-if="messaggio" role="status" style="font-size:13px;color:var(--sage-dark);">{{ messaggio }}</p>

        <button type="submit" class="btn btn-sage" :disabled="inviando" style="margin-top:4px;">
          {{ inviando ? 'Un momento…' : (modalita === 'accedi' ? 'Accedi' : 'Crea account') }}
        </button>
      </form>
    </template>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import Icon from '@/components/Icon.vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import ModalConferma from '@/components/ModalConferma.vue'
import { useAuth } from '@/composables/useAuth'
import { useApi } from '@/composables/useApi'

const router = useRouter()
const { utente, nomeUtente, caricamento, recuperoInCorso, accedi, registrati, aggiornaNome, esci, reinviaConferma, richiediResetPassword, impostaNuovaPassword } = useAuth()
const { salvaToken, rimuoviToken, tokenPresente } = useApi()

const zorba = ref(null)

const modalita  = ref('accedi')
const email     = ref('')
const password  = ref('')
const nome      = ref('')
const nuovaPassword = ref('')

// Modifica del nome dalla vista loggato (pattern inline come il token GitHub)
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
// invece di lasciarlo invariato (vedi template).
const emailConferma = ref(null)

const tokenInput       = ref('')
const modificandoToken = ref(false)
const confermaRimozione = ref(false)

function onSalvaToken() {
  if (!tokenInput.value.trim()) return
  salvaToken(tokenInput.value.trim())
  tokenInput.value = ''
  modificandoToken.value = false
}

function onRimuoviToken() {
  rimuoviToken()
  confermaRimozione.value = false
  modificandoToken.value = false
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
}

function tornaAlLogin() {
  emailConferma.value = null
  modalita.value = 'accedi'
  password.value = ''
  errore.value = null
  messaggio.value = null
}

async function onInvia() {
  if (inviando.value) return
  errore.value = null
  messaggio.value = null
  inviando.value = true
  try {
    if (modalita.value === 'accedi') {
      await accedi(email.value, password.value)
      router.push('/')
    } else {
      await registrati(email.value, password.value, nome.value)
      emailConferma.value = email.value
      // Battito lento: evento raro (una tantum per account), non la conferma
      // quotidiana di confermaCura() — vedi "Regola dei Due Battiti" in ZorbaLogo.vue.
      zorba.value?.reagisci()
    }
  } catch (e) {
    errore.value = e.message || 'Errore durante l\'operazione.'
  } finally {
    inviando.value = false
  }
}

async function onReinviaConferma() {
  if (inviando.value) return
  errore.value = null
  messaggio.value = null
  inviando.value = true
  try {
    await reinviaConferma(emailConferma.value)
    messaggio.value = 'Email di conferma inviata di nuovo.'
  } catch (e) {
    errore.value = e.message || 'Errore durante l\'invio.'
  } finally {
    inviando.value = false
  }
}

async function onRichiediReset() {
  if (inviando.value) return
  errore.value = null
  messaggio.value = null
  if (!email.value) {
    errore.value = 'Inserisci la tua email qui sopra, poi riprova.'
    return
  }
  inviando.value = true
  try {
    await richiediResetPassword(email.value)
    messaggio.value = `Ti abbiamo inviato un'email a ${email.value} con il link per reimpostare la password.`
    zorba.value?.reagisci()
  } catch (e) {
    errore.value = e.message || 'Errore durante la richiesta.'
  } finally {
    inviando.value = false
  }
}

async function onImpostaPassword() {
  if (inviando.value) return
  errore.value = null
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
  font-size: 13px; color: var(--ink-soft); text-decoration: underline;
  cursor: pointer; align-self: flex-start;
}
.link-reset:hover { color: var(--ink); }
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

/* Token GitHub — stato compatto di default */
.token-row { display: flex; align-items: center; gap: 8px; }
.token-row__stato { flex: 1; font-size: 13px; font-weight: 600; color: var(--sage-dark); }
.token-hint { font-size: 13px; color: var(--ink-soft); margin-bottom: 12px; line-height: 1.5; }

/* Alone ad acquerello dietro Zorba sulla superficie di primo contatto — un
   piccolo elemento illustrativo dedicato, distinto dal lavaggio globale su
   `body::before`, perché questa è la vista che DESIGN.md indica come più
   critica per fiducia e non aveva finora nulla di proprio (critica 08/09/2026). */
.account-hero { position: relative; text-align: center; margin-bottom: 20px; }
.account-hero::before {
  content: '';
  position: absolute; left: 50%; top: -12px;
  width: 132px; height: 132px; transform: translateX(-50%);
  background: radial-gradient(circle, rgba(224,184,74,0.18) 0%, rgba(122,158,130,0.12) 55%, transparent 75%);
  border-radius: 50%;
  pointer-events: none;
}
.account-hero > * { position: relative; }
</style>
