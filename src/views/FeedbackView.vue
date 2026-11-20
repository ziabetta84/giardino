<template>
  <div class="fb" style="max-width:560px;margin:0 auto;">
    <h1 class="page-title" style="margin-bottom:10px">Scrivi a chi costruisce l'app</h1>
    <p class="fb__lede">
      Dimmi che cosa non funziona, che cosa ti blocca o che cosa vorresti. Rispondo entro tre giorni lavorativi.
      Con il messaggio arrivano solo la pagina da cui scrivi e la versione dell'app.
    </p>

    <form class="fb__form" @submit.prevent="onInvia" novalidate>
      <fieldset class="fb__scelte">
        <legend class="field-label">Di che cosa si tratta?</legend>
        <div class="fb__pill-row">
          <label v-for="c in CATEGORIE" :key="c.valore" class="fb__pill">
            <input type="radio" name="categoria" :value="c.valore" v-model="categoria" :disabled="invio" />
            <span>{{ c.etichetta }}</span>
          </label>
        </div>
      </fieldset>

      <label class="field-label" for="fb-testo">Scrivi qui</label>
      <textarea id="fb-testo" v-model="testo" class="form-input fb__testo" rows="5" :maxlength="LIMITE"
        :disabled="invio" aria-describedby="fb-contatore fb-esito"
        placeholder="Per esempio: dopo aver registrato una cura la schermata non si aggiorna."></textarea>
      <div class="fb__riga">
        <span id="fb-contatore" class="fb__contatore">{{ testo.length }}/{{ LIMITE }}</span>
        <button type="submit" class="btn btn-sage" :disabled="!puoInviare">
          {{ invio ? 'Invio in corso…' : 'Invia' }}
        </button>
      </div>
      <p id="fb-esito" class="fb__esito" :class="{ 'fb__esito--errore': errore }" role="status" aria-live="polite">
        {{ errore || esito }}
      </p>
    </form>

    <section class="fb__elenco" aria-labelledby="fb-elenco-titolo">
      <h2 id="fb-elenco-titolo" class="slabel">I tuoi messaggi</h2>
      <p v-if="caricamento" class="fb__vuoto">Carico i tuoi messaggi…</p>
      <p v-else-if="erroreElenco" class="fb__esito fb__esito--errore">{{ erroreElenco }}</p>
      <p v-else-if="!messaggi.length" class="fb__vuoto">Nessun messaggio ancora. Quando ne scrivi uno, lo trovi qui con il suo stato.</p>
      <ul v-else class="fb__lista">
        <li v-for="m in messaggi" :key="m.id" class="fb__voce">
          <div class="fb__voce-hd">
            <span class="fb__categoria">{{ etichettaCategoria(m.categoria) }}</span>
            <span class="badge" :class="classeStato(m.stato)">{{ ETICHETTE_STATO[m.stato] ?? m.stato }}</span>
          </div>
          <p class="fb__voce-testo">{{ m.testo }}</p>
          <p class="fb__data">{{ dataBreve(m.creato) }}</p>
          <p v-if="m.risposta" class="fb__risposta">
            <span class="fb__risposta-etichetta">Risposta</span>
            {{ m.risposta }}
          </p>
        </li>
      </ul>
    </section>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { CATEGORIE, ETICHETTE_STATO, LIMITE_TESTO, useFeedback } from '@/composables/useFeedback'

const LIMITE = LIMITE_TESTO
const route = useRoute()
const { elenca, invia } = useFeedback()

const categoria = ref('problema')
const testo = ref('')
const invio = ref(false)
const errore = ref('')
const esito = ref('')

const messaggi = ref([])
const caricamento = ref(true)
const erroreElenco = ref('')

const puoInviare = computed(() => !invio.value && testo.value.trim().length > 0)

function etichettaCategoria(valore) {
  return CATEGORIE.find(c => c.valore === valore)?.etichetta ?? valore
}

function classeStato(stato) {
  if (stato === 'risolto') return 'badge-ok'
  if (stato === 'non_previsto') return 'badge-warn'
  return 'badge-gold'
}

function dataBreve(iso) {
  return new Date(iso).toLocaleDateString('it-IT', { day: 'numeric', month: 'long', year: 'numeric' })
}

async function carica() {
  caricamento.value = true
  erroreElenco.value = ''
  try {
    messaggi.value = await elenca()
  } catch {
    erroreElenco.value = 'Non riesco a caricare i tuoi messaggi. Riprova tra poco.'
  } finally {
    caricamento.value = false
  }
}

async function onInvia() {
  if (!puoInviare.value) return
  invio.value = true
  errore.value = ''
  esito.value = ''
  try {
    await invia({ categoria: categoria.value, testo: testo.value, pagina: route.path })
    testo.value = ''
    esito.value = 'Ricevuto. Lo trovi qui sotto con il suo stato.'
    await carica()
  } catch (e) {
    errore.value = e.message
  } finally {
    invio.value = false
  }
}

onMounted(carica)
</script>

<style scoped>
.fb__lede { margin: 0 0 22px; font: 400 14px/1.5 var(--font-sans); color: var(--ink-mid); }

.fb__form { display: flex; flex-direction: column; gap: 10px; margin-bottom: 36px; }
.fb__scelte { border: 0; margin: 0; padding: 0; min-width: 0; }
.fb__scelte legend { padding: 0; margin-bottom: 8px; }

.fb__pill-row { display: flex; flex-wrap: wrap; gap: 8px; }
.fb__pill { position: relative; cursor: pointer; }
.fb__pill input { position: absolute; opacity: 0; width: 1px; height: 1px; pointer-events: none; }
.fb__pill span {
  display: inline-flex; align-items: center; min-height: 44px; padding: 7px 16px;
  border-radius: 999px; border: 1px solid var(--cream-dark); background: var(--white);
  font: 600 13px/1 var(--font-sans); color: var(--ink-mid);
  transition: background 0.18s var(--ease-standard), color 0.18s var(--ease-standard);
}
.fb__pill input:checked + span { background: var(--sage); border-color: var(--sage); color: var(--white); }
.fb__pill input:focus-visible + span { outline: 2px solid var(--gold); outline-offset: 2px; }
.fb__pill input:disabled + span { opacity: 0.6; cursor: default; }

.fb__testo { min-height: 120px; resize: vertical; line-height: 1.5; }
.fb__riga { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
.fb__contatore { font: 400 12px/1.4 var(--font-sans); color: var(--ink-soft); }
.fb__riga .btn { min-height: 44px; }

.fb__esito { min-height: 1.4em; margin: 0; font: 400 13px/1.4 var(--font-sans); color: var(--sage-dark); }
.fb__esito--errore { color: var(--rose-dark); }

.fb__vuoto { margin: 14px 0 0; font: 400 13px/1.5 var(--font-sans); color: var(--ink-soft); }
.fb__lista { list-style: none; margin: 14px 0 0; padding: 0; }
.fb__voce { padding: 16px 0; border-top: 1px solid var(--cream-dark); }
.fb__voce:last-child { border-bottom: 1px solid var(--cream-dark); }
.fb__voce-hd { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
.fb__categoria { font: 700 11px/1 var(--font-sans); letter-spacing: 0.13em; text-transform: uppercase; color: var(--ink-soft); }
.fb__voce-testo { margin: 8px 0 0; font: 400 14px/1.5 var(--font-sans); color: var(--ink); white-space: pre-wrap; overflow-wrap: anywhere; }
.fb__data { margin: 6px 0 0; font: 400 12px/1.4 var(--font-sans); color: var(--ink-soft); }
.fb__risposta { margin: 10px 0 0; padding: 10px 12px; border-radius: 12px; background: var(--sage-pale); font: 400 14px/1.5 var(--font-sans); color: var(--ink); white-space: pre-wrap; overflow-wrap: anywhere; }
.fb__risposta-etichetta { display: block; margin-bottom: 4px; font: 700 11px/1 var(--font-sans); letter-spacing: 0.13em; text-transform: uppercase; color: var(--sage-dark); }
</style>
