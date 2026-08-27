<template>
  <!-- Loggato: dentro il layout normale dell'app (vedi App.vue), quindi qui
       si può permettere titolo e card come le altre view. -->
  <div v-if="!caricamento && utente && !recuperoInCorso" style="max-width:420px;margin:0 auto;">
    <h1 class="title-display gradient-title" style="font-size:1.9rem;font-weight:800;margin-bottom:16px;">Account</h1>
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
  </div>

  <!-- Non loggato (login/registrazione) o con una sessione di recupero
       password temporanea (evento PASSWORD_RECOVERY in useAuth.js): stesso
       header con logo animato + titolo, App.vue toglie il resto del vestito
       dell'app e centra questo blocco da solo in pagina. -->
  <div v-else-if="!caricamento" style="width:100%;max-width:340px;">
    <div style="text-align:center;margin-bottom:20px;">
      <ZorbaLogo style="width:64px;height:64px;margin:0 auto 8px;" />
      <h1 class="title-display gradient-title" style="font-size:1.6rem;font-weight:800;">
        {{ recuperoInCorso ? 'Nuova password' : 'Account' }}
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
import Icon from '@/components/Icon.vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import { useAuth } from '@/composables/useAuth'

const { utente, caricamento, recuperoInCorso, accedi, registrati, esci, richiediResetPassword, impostaNuovaPassword } = useAuth()

const modalita  = ref('accedi')
const email     = ref('')
const password  = ref('')
const nuovaPassword = ref('')
const inviando  = ref(false)
const uscendo   = ref(false)
const errore    = ref(null)
const messaggio = ref(null)

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
