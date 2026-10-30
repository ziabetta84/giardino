<template>
  <!-- Eliminazione dell'account, in fondo alla pagina Account. Chiusa è una
       riga di testo, non un bottone rosa: chi apre Account per cambiare nome
       non deve trovarsi davanti un allarme. Aperta, dice con i numeri veri
       che cosa sparisce, e chiede la password: senza, un telefono lasciato
       sbloccato basterebbe a cancellare un giardino. Inline e non in una
       modale: è una decisione da leggere con calma, non un'interruzione. -->
  <div class="elimina">
    <button v-if="!aperto" ref="apriEl" type="button" class="elimina__apri" @click="apri">
      Elimina l'account
    </button>

    <section v-else class="form-card elimina__foglio" aria-labelledby="elimina-titolo" @keydown.esc="chiudi">
      <h2 id="elimina-titolo" ref="titoloEl" class="elimina__titolo" tabindex="-1">Eliminare l'account?</h2>
      <p class="elimina__testo">
        <template v-if="voci.length">Se lo elimini, esco definitivamente dal tuo giardino, dimenticando tutto ciò che lo riguarda:</template>
        <template v-else>Il tuo giardino è ancora vuoto: cancello l'account e le impostazioni.</template>
      </p>

      <ul v-if="voci.length" class="elimina__elenco">
        <li v-for="v in voci" :key="v.chiave">
          <span class="elimina__n">{{ v.n ?? '·' }}</span>
          <span>{{ v.testo }}</span>
        </li>
      </ul>

      <p class="elimina__nota">
        Non si può annullare. Se vuoi solo una pausa, esci e basta: ritrovi il giardino com'è.
      </p>

      <form novalidate class="elimina__form" @submit.prevent="onElimina">
        <div>
          <label class="field-label" for="elimina-password">Per confermare, scrivi la tua password</label>
          <CampoPassword id="elimina-password" v-model="password" autocomplete="current-password"
            aria-describedby="elimina-password-nota" :aria-invalid="!!erroreCampo" :disabled="inviando" />
          <p id="elimina-password-nota" class="elimina__campo-nota" :class="{ 'elimina__campo-nota--err': erroreCampo }">
            {{ erroreCampo || 'Non la ricordi? Esci e scegline una nuova da «Password dimenticata?».' }}
          </p>
        </div>

        <TurnstileWidget ref="turnstile" @token="onToken" @errore="onErroreCaptcha" />

        <p v-if="errore" class="elimina__esito" role="alert">{{ errore }}</p>

        <div class="elimina__azioni">
          <button type="button" class="btn btn-ghost" :disabled="inviando" @click="chiudi">Annulla</button>
          <button type="submit" class="btn elimina__conferma" :disabled="inviando || attesaCaptcha">
            {{ inviando ? 'Elimino…' : 'Elimina per sempre' }}
          </button>
        </div>
      </form>
    </section>
  </div>
</template>

<script setup>
import { ref, computed, nextTick, watch } from 'vue'
import CampoPassword from '@/components/CampoPassword.vue'
import TurnstileWidget from '@/components/TurnstileWidget.vue'
import { useAuth } from '@/composables/useAuth'
import { useSupabase } from '@/composables/useSupabase'
import { useDatiStore } from '@/stores/dati'

const store = useDatiStore()
const supabase = useSupabase()
const { eliminaAccount } = useAuth()

const aperto = ref(false)
const apriEl = ref(null)
const titoloEl = ref(null)
const password = ref('')
const inviando = ref(false)
const errore = ref(null)
const erroreCampo = ref(null)
watch(password, () => { erroreCampo.value = null })

// Foto e conversazioni non sono nello store: si contano all'apertura (RLS:
// solo le proprie). Finché non arrivano la riga c'è, senza numero.
const contaFoto = ref(null)
const contaFili = ref(null)
async function conta(tabella, destinazione) {
  const { count, error } = await supabase.from(tabella).select('id', { count: 'exact', head: true })
  // Senza numero (rete, permessi) la riga resta senza cifra, mai con uno zero che non è vero.
  if (!error && typeof count === 'number') destinazione.value = count
}

const quanti = (x) => (Array.isArray(x) ? x.length : Object.keys(x ?? {}).length)
const plurale = (n, uno, molti) => (n === 1 ? uno : molti)
const voci = computed(() => {
  const nPiante = quanti(store.piante)
  const nZone = quanti(store.zone)
  const nSottozone = Object.values(store.sottozone ?? {}).reduce((t, z) => t + quanti(z), 0)
  const nProgetti = quanti(store.progetti)
  const nConcimi = quanti(store.concimi)
  const elenco = [
    { chiave: 'piante', n: nPiante, testo: `${plurale(nPiante, 'pianta', 'piante')}, con le cure registrate` },
    { chiave: 'zone', n: nZone, testo: nSottozone
      ? `${plurale(nZone, 'zona', 'zone')} e ${nSottozone} ${plurale(nSottozone, 'sottozona', 'sottozone')}`
      : plurale(nZone, 'zona', 'zone') },
    { chiave: 'progetti', n: nProgetti, testo: `${plurale(nProgetti, 'progetto', 'progetti')} con le loro tappe` },
    { chiave: 'foto', n: contaFoto.value, testo: contaFoto.value === null ? 'le foto della galleria' : 'foto della galleria' },
    { chiave: 'fili', n: contaFili.value, testo: contaFili.value === null
      ? 'le conversazioni con Zorba' : plurale(contaFili.value, 'conversazione con Zorba', 'conversazioni con Zorba') },
    { chiave: 'concimi', n: nConcimi, testo: plurale(nConcimi, 'concime nella dispensa', 'concimi nella dispensa') },
  ]
  // Una riga a zero non dice niente; una ancora da contare (null) resta.
  return elenco.filter((v) => v.n !== 0)
})

async function apri() {
  aperto.value = true
  errore.value = null
  conta('foto', contaFoto)
  conta('zorba_fili', contaFili)
  await nextTick()
  titoloEl.value?.focus()
  titoloEl.value?.scrollIntoView({ block: 'start', behavior: 'smooth' })
}

async function chiudi() {
  if (inviando.value) return
  aperto.value = false
  password.value = ''
  errore.value = null
  erroreCampo.value = null
  captchaToken.value = null
  await nextTick()
  apriEl.value?.focus()
}

// Turnstile come nel modulo di accesso: il nuovo accesso con la password lo
// richiede quando la protezione CAPTCHA di Supabase è attiva.
const turnstile = ref(null)
const captchaToken = ref(null)
const attesaCaptcha = computed(() => !!import.meta.env.VITE_TURNSTILE_SITE_KEY && !captchaToken.value)
function onToken(t) { captchaToken.value = t }
function onErroreCaptcha() {
  errore.value = 'Non riesco a caricare la verifica anti-robot: controlla la connessione e ricarica la pagina.'
}

async function onElimina() {
  if (inviando.value) return
  errore.value = null
  if (!password.value) {
    erroreCampo.value = 'Scrivi la password: senza non elimino niente.'
    document.getElementById('elimina-password')?.focus()
    return
  }
  inviando.value = true
  try {
    await eliminaAccount(password.value, captchaToken.value)
    // Riuscito: la sessione è chiusa e AccountView mostra il congedo.
  } catch (e) {
    if (e.codice === 'invalid_credentials') {
      erroreCampo.value = e.message
      document.getElementById('elimina-password')?.focus()
    } else {
      errore.value = e.message
    }
    inviando.value = false
    turnstile.value?.reset()
  }
}
</script>

<style scoped>
.elimina { margin-top: 40px; display: flex; flex-direction: column; align-items: center; }

.elimina__apri {
  background: none; border: none; padding: 0 8px; min-height: 44px;
  font: 500 13px/1 var(--font-sans); color: var(--ink-mid);
  text-decoration: underline; text-underline-offset: 4px; text-decoration-color: var(--ink-faint);
  cursor: pointer;
}
.elimina__apri:hover { color: var(--rose-ink); text-decoration-color: currentColor; }

.elimina__foglio { width: 100%; scroll-margin-top: 24px; }
.elimina__titolo {
  font: 600 19px/1.2 var(--font-display); color: var(--rose-ink);
  letter-spacing: -0.005em; outline: none;
}
.elimina__testo { margin-top: 8px; font-size: 14px; line-height: 1.55; color: var(--ink-mid); text-wrap: pretty; }

/* L'inventario come le righe di un registro: filetti sottili, il numero in
   colonna perché si legga prima della parola. */
.elimina__elenco { list-style: none; margin: 12px 0 0; padding: 0; }
.elimina__elenco li {
  display: grid; grid-template-columns: 3ch 1fr; gap: 10px; align-items: baseline;
  padding: 9px 0; border-top: 1px solid var(--cream-dark);
  font-size: 14px; line-height: 1.4; color: var(--ink);
}
.elimina__elenco li:last-child { border-bottom: 1px solid var(--cream-dark); }
.elimina__n { font-weight: 700; font-variant-numeric: tabular-nums; text-align: right; color: var(--rose-ink); }

.elimina__nota { margin-top: 14px; font-size: 13px; line-height: 1.55; color: var(--ink-mid); text-wrap: pretty; }

.elimina__form { display: flex; flex-direction: column; gap: 12px; margin-top: 20px; }
.elimina__form .field-label { color: var(--ink-mid); }
.elimina__form :deep(.form-input) { font-size: 16px; }
.elimina__form :deep(.form-input[aria-invalid="true"]) { border-color: var(--rose); }
.elimina__campo-nota { margin-top: 6px; font-size: 12px; line-height: 1.45; color: var(--ink-mid); }
.elimina__campo-nota--err { color: var(--rose-ink); }
.elimina__esito { font-size: 13px; line-height: 1.5; color: var(--rose-ink); }

.elimina__azioni { display: flex; flex-wrap: wrap-reverse; gap: 10px; margin-top: 4px; }
/* Sul telefono le due azioni vanno una sopra l'altra, la definitiva in alto:
   affiancate, «Elimina per sempre» andava a capo dentro il bottone. */
.elimina__azioni .btn { flex: 1 1 160px; min-height: 44px; white-space: nowrap; }
/* Il rosa della palette regge il testo bianco solo a 3,5:1: per l'unico
   bottone che non si può annullare, l'inchiostro rosa (7:1 in chiaro; in
   scuro è un rosa chiaro, con il testo scuro). */
.elimina__conferma { background: var(--rose-ink); color: var(--rose-pale); border: 1px solid var(--rose-ink); }
.elimina__conferma:hover:not(:disabled) { background: color-mix(in srgb, var(--rose-ink) 82%, var(--ink)); }
.elimina__conferma:disabled { opacity: .55; cursor: default; }
</style>
