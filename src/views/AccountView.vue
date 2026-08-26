<template>
  <div>
    <h1 class="title-display gradient-title title-settle" style="font-size:1.9rem;font-weight:800;margin-bottom:6px;">Account</h1>
    <p style="font-size:13px;color:var(--ink-soft);margin-bottom:20px;">
      Login separato dal token GitHub qui sopra: per ora non controlla ancora nessun dato del giardino, è il primo passo verso account personali.
    </p>

    <!-- Utente loggato -->
    <div v-if="!caricamento && utente" class="card" style="padding:18px;">
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

    <!-- Form login/registrazione -->
    <div v-else-if="!caricamento" class="card" style="padding:18px;max-width:420px;">
      <div style="display:flex;gap:6px;margin-bottom:16px;">
        <button type="button" class="pill tab-icona" :class="{ active: modalita === 'accedi' }" @click="cambiaModalita('accedi')">Accedi</button>
        <button type="button" class="pill tab-icona" :class="{ active: modalita === 'registrati' }" @click="cambiaModalita('registrati')">Registrati</button>
      </div>

      <form @submit.prevent="onInvia" style="display:flex;flex-direction:column;gap:10px;">
        <div>
          <label class="section-label" style="display:block;margin-bottom:4px;">Email</label>
          <input v-model.trim="email" type="email" autocomplete="email" required class="form-input" style="width:100%;">
        </div>
        <div>
          <label class="section-label" style="display:block;margin-bottom:4px;">Password</label>
          <input v-model="password" type="password" minlength="6"
            :autocomplete="modalita === 'accedi' ? 'current-password' : 'new-password'"
            required class="form-input" style="width:100%;">
        </div>

        <p v-if="errore" style="font-size:12px;color:var(--rose-dark);">{{ errore }}</p>
        <p v-if="messaggio" style="font-size:12px;color:var(--sage-dark);">{{ messaggio }}</p>

        <button type="submit" class="btn btn-sage" :disabled="inviando" style="margin-top:4px;">
          {{ inviando ? 'Un momento…' : (modalita === 'accedi' ? 'Accedi' : 'Crea account') }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import Icon from '@/components/Icon.vue'
import { useAuth } from '@/composables/useAuth'

const { utente, caricamento, accedi, registrati, esci } = useAuth()

const modalita  = ref('accedi')
const email     = ref('')
const password  = ref('')
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
