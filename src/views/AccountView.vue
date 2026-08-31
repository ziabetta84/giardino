<template>
  <!-- Loggato: dentro il layout normale dell'app (vedi App.vue), quindi qui
       si può permettere titolo e card come le altre view. -->
  <div v-if="!caricamento && utente && !recuperoInCorso" style="max-width:420px;margin:0 auto;">
    <h1 class="title-display gradient-title title-settle" style="font-size:1.9rem;font-weight:800;margin-bottom:16px;">Account</h1>
    <div class="card" style="padding:18px;">
      <p class="section-label" style="margin-bottom:10px;">Accesso effettuato</p>
      <div style="display:flex;align-items:center;gap:10px;margin-bottom:16px;">
        <Icon name="persona" style="width:28px;height:28px;flex-shrink:0;" />
        <p style="font-size:14px;font-weight:600;word-break:break-all;">{{ utente.email }}</p>
      </div>
      <button class="btn btn-ghost" :disabled="uscendo" @click="onEsci">
        {{ uscendo ? 'Uscita in corso…' : 'Esci' }}
      </button>
      <p v-if="errore" style="font-size:12px;color:var(--rose-dark);margin-top:10px;">{{ errore }}</p>
    </div>

    <div class="card" style="padding:18px;margin-top:16px;">
      <p class="section-label" style="margin-bottom:10px;">Token GitHub</p>
      <p style="font-size:12px;color:var(--ink-soft);margin-bottom:12px;">Serve per inviare richieste a Zorba e salvare modifiche ai dati del giardino (permesso <code>contents:write</code> sul repo).</p>

      <template v-if="tokenPresente && !modificandoToken">
        <div style="display:flex;align-items:center;gap:8px;margin-bottom:14px;">
          <Icon name="chiave" style="width:16px;height:16px;flex-shrink:0;color:var(--sage-dark);" />
          <p style="font-size:13px;font-weight:600;color:var(--sage-dark);">Token configurato</p>
        </div>
        <div style="display:flex;gap:8px;">
          <button type="button" class="btn btn-ghost" style="flex:1;min-height:36px;font-size:13px;" @click="modificandoToken = true">Sostituisci</button>
          <button type="button" class="btn btn-ghost" style="flex:1;min-height:36px;font-size:13px;color:var(--rose-dark);" @click="confermaRimozione = true">Rimuovi</button>
        </div>
      </template>

      <template v-else>
        <div style="display:flex;gap:8px;">
          <input v-model="tokenInput" type="password" placeholder="ghp_…" class="form-input"
            style="flex:1;min-height:36px;font-size:13px;" @keyup.enter="onSalvaToken">
          <button type="button" @click="onSalvaToken" :disabled="!tokenInput.trim()" class="btn btn-sage"
            style="min-height:36px;padding:6px 14px;font-size:13px;">Salva</button>
        </div>
        <button v-if="tokenPresente" type="button" class="link-reset" style="margin-top:8px;" @click="modificandoToken = false; tokenInput = ''">Annulla</button>
      </template>
    </div>

    <RouterLink to="/impostazioni" class="card hover-card" style="display:flex;align-items:center;justify-content:space-between;padding:16px;margin-top:16px;text-decoration:none;color:inherit;">
      <span style="font-size:14px;font-weight:600;">Impostazioni giardino</span>
      <Icon name="pin" style="width:14px;height:14px;flex-shrink:0;color:var(--ink-faint);" />
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
    <div style="text-align:center;margin-bottom:20px;">
      <ZorbaLogo style="width:64px;height:64px;margin:0 auto 8px;" />
      <h1 class="title-display gradient-title title-settle" style="font-size:1.6rem;font-weight:800;">
        {{ recuperoInCorso ? 'Nuova password' : 'Entra nel Giardino di Zorba' }}
      </h1>
    </div>

    <form v-if="recuperoInCorso" @submit.prevent="onImpostaPassword" style="display:flex;flex-direction:column;gap:10px;">
      <div>
        <label class="field-label">Nuova password</label>
        <input v-model="nuovaPassword" type="password" minlength="6" autocomplete="new-password"
          required class="form-input" style="width:100%;">
      </div>
      <p v-if="errore" style="font-size:12px;color:var(--rose-dark);">{{ errore }}</p>
      <button type="submit" class="btn btn-sage" :disabled="inviando">
        {{ inviando ? 'Un momento…' : 'Salva password' }}
      </button>
    </form>

    <template v-else>
      <div style="display:flex;gap:6px;margin-bottom:16px;justify-content:center;">
        <button type="button" class="pill tab-icona" :class="{ active: modalita === 'accedi' }" @click="cambiaModalita('accedi')">Accedi</button>
        <button type="button" class="pill tab-icona" :class="{ active: modalita === 'registrati' }" @click="cambiaModalita('registrati')">Registrati</button>
      </div>

      <form @submit.prevent="onInvia" style="display:flex;flex-direction:column;gap:10px;">
        <div>
          <label class="field-label">Email</label>
          <input v-model.trim="email" type="email" autocomplete="email" required class="form-input" style="width:100%;">
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

        <p v-if="errore" style="font-size:12px;color:var(--rose-dark);">{{ errore }}</p>
        <p v-if="messaggio" style="font-size:12px;color:var(--sage-dark);">{{ messaggio }}</p>

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
const { utente, caricamento, recuperoInCorso, accedi, registrati, esci, richiediResetPassword, impostaNuovaPassword } = useAuth()
const { salvaToken, rimuoviToken, tokenPresente } = useApi()

const modalita  = ref('accedi')
const email     = ref('')
const password  = ref('')
const nuovaPassword = ref('')
const inviando  = ref(false)
const uscendo   = ref(false)
const errore    = ref(null)
const messaggio = ref(null)

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
}

function cambiaModalita(nuova) {
  modalita.value = nuova
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
      await registrati(email.value, password.value)
      messaggio.value = 'Account creato. Controlla la mail per confermare, poi accedi.'
    }
  } catch (e) {
    errore.value = e.message || 'Errore durante l\'operazione.'
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
    messaggio.value = 'Ti abbiamo inviato un\'email con il link per reimpostare la password.'
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
.field-label {
  font-size: 11px; font-weight: 600; color: var(--ink-soft);
  text-transform: uppercase; letter-spacing: .05em;
  display: block; margin-bottom: 6px;
}
.link-reset {
  background: none; border: none; padding: 0; text-align: left;
  font-size: 12px; color: var(--ink-soft); text-decoration: underline;
  cursor: pointer; align-self: flex-start;
}
.link-reset:hover { color: var(--ink); }
</style>
