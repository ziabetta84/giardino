<template>
  <div class="zf">
    <div v-if="filo.tipo === 'segnalazione_scheda'" class="zf__segn">
      <span class="badge" :class="CLASSI_SEGN[filo.segnalazione_stato]">{{ ETICHETTE_SEGN[filo.segnalazione_stato] }}</span>
      <p v-if="filo.segnalazione_nota" class="zf__nota">{{ filo.segnalazione_nota }}</p>
    </div>

    <div v-for="m in messaggi" :key="m.id" class="zf__m" :class="m.ruolo === 'utente' ? 'zf__m--utente' : 'zf__m--zorba'">
      <ZorbaLogo v-if="m.ruolo === 'zorba'" class="zf__logo" :pensa="m.id === inCorso?.id && !inCorso.testo" />
      <div class="zf__bolla" :ref="(el) => { if (m.id === inCorso?.id) bollaInCorso = el }">
        <img v-if="m.foto_url" :src="m.foto_url" class="zf__foto" alt="Foto allegata">
        <template v-if="m.ruolo === 'zorba' && m.id === inCorso?.id">
          <p v-if="inCorso.testo" class="zf__testo"><template v-for="(p, i) in pezziGrassetto(inCorso.testo)" :key="i"><b v-if="p.b">{{ p.t }}</b><template v-else>{{ p.t }}</template></template><span class="zf__cursore" aria-hidden="true"></span></p>
          <ZorbaPensa v-else :stato="inCorso.stati.at(-1) ?? null" />
        </template>
        <template v-else-if="m.ruolo === 'zorba' && (m.esito === 'errore' || scaduto(m))">
          <p class="zf__errore">Questa risposta non è riuscita.</p>
          <button v-if="!filo.importato" type="button" class="btn btn-ghost zf__riprova" @click="emit('riprova')">Riprova</button>
        </template>
        <p v-else-if="m.testo && m.ruolo === 'zorba'" class="zf__testo"><template v-for="(p, i) in pezziGrassetto(m.testo)" :key="i"><b v-if="p.b">{{ p.t }}</b><template v-else>{{ p.t }}</template></template></p>
        <p v-else-if="m.testo" class="zf__testo">{{ m.testo }}</p>
        <p v-else-if="m.ruolo === 'utente' && !m.foto_url" class="zf__testo zf__vuoto">(nessun testo)</p>
        <ZorbaPollici v-if="m.ruolo === 'zorba' && m.esito === 'completata' && !filo.importato" :messaggio="m"
          :nota="m.id === ultimaZorba?.id" @vota="(v, mo, co) => emit('vota', m.id, v, mo, co)" />
      </div>
    </div>

    <RouterLink v-if="progetto" :to="`/progetti/${progetto.id}`" class="zf__progetto card">
      <Icon name="lampadina" /> <span>{{ progetto.titolo }}</span> <b>Apri il progetto →</b>
    </RouterLink>

    <div v-if="filo.stato === 'chiuso'" class="zf__chiuso">
      <p>Questa conversazione è conclusa: per continuare apri una nuova richiesta.</p>
      <button v-if="!filo.importato" type="button" class="btn btn-sage" @click="emit('nuova', filo.tipo)">Nuova richiesta</button>
    </div>
    <!-- Il riquadro non sparisce mai in silenzio: se ora non si può rispondere, al suo posto c'è il perché -->
    <ZorbaAvviso v-else-if="aperta && blocco" :motivo="blocco" :ripartenza="ripartenza" con-storico @storico="emit('storico')" />
    <div v-else-if="puoRispondere" class="zf__risposta">
      <div class="reqbox">
        <textarea v-model="testo" rows="2" placeholder="Rispondi a Zorba…" maxlength="4000" aria-label="Risposta per Zorba"
          @keydown.enter.meta.prevent="invia" @keydown.enter.ctrl.prevent="invia"></textarea>
        <p v-if="erroreFoto" class="zf__errore">{{ erroreFoto }}</p>
        <div class="reqbar zf__bar">
          <ZorbaFotoScelta v-model:foto="foto" compatta @errore="(m) => erroreFoto = m" />
          <button type="button" class="reqsend" :disabled="!testo.trim() && !foto" @click="invia">Invia</button>
        </div>
      </div>
      <p class="zf__rimaste">Puoi rispondere ancora {{ rimasteRepliche }} {{ rimasteRepliche === 1 ? 'volta' : 'volte' }} in questa conversazione.{{ consumo ? ` ${consumo}` : '' }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick } from 'vue'
import Icon from '@/components/Icon.vue'
import ZorbaPensa from '@/components/ZorbaPensa.vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import ZorbaPollici from '@/components/ZorbaPollici.vue'
import ZorbaAvviso from '@/components/ZorbaAvviso.vue'
import ZorbaFotoScelta from '@/components/ZorbaFotoScelta.vue'
import { pezziGrassetto } from '@/utils/grassetto'

const props = defineProps({
  filo: { type: Object, required: true },
  messaggi: { type: Array, required: true },
  // { id, stati: string[], testo: string } mentre Zorba scrive, altrimenti null
  inCorso: { type: Object, default: null },
  progetto: { type: Object, default: null },
  // Perché ora non si può scrivere a Zorba ('offline' | 'pausa' | 'prova' | 'mese'), vedi ZorbaAvviso
  blocco: { type: String, default: null },
  ripartenza: { type: String, default: '' },
  // Quanto consuma una risposta (null per il curatore): «Ogni risposta di Zorba conta: te ne restano 2 di prova.»
  consumo: { type: String, default: null },
})
const emit = defineEmits(['rispondi', 'riprova', 'vota', 'nuova', 'storico'])
const ETICHETTE_SEGN = { in_attesa: 'In attesa del curatore', accolta: 'Accolta', non_accolta: 'Non accolta' }
const CLASSI_SEGN = { in_attesa: 'badge-gold', accolta: 'badge-ok', non_accolta: 'badge-warn' }

const testo = ref('')
const foto = ref(null)
const erroreFoto = ref('')

// Una risposta rimasta "in corso" da più di 3 minuti (funzione interrotta) vale come errore, come per il server
const scaduto = (m) => m.esito === 'in_corso' && m.id !== props.inCorso?.id && Date.now() - new Date(m.creato).getTime() > 180_000
const rimasteRepliche = computed(() => 4 - props.messaggi.filter(m => m.ruolo === 'utente').length)
const ultimaZorba = computed(() => props.messaggi.filter(m => m.ruolo === 'zorba').at(-1))
// Conversazione in cui si potrebbe rispondere, a parte i limiti (offline, pausa, risposte finite)
const aperta = computed(() => !props.filo.importato && !props.inCorso && rimasteRepliche.value > 0
  && ultimaZorba.value?.esito === 'completata')
const puoRispondere = computed(() => aperta.value && !props.blocco)

// Mentre Zorba scrive la risposta resta in vista (sul telefono finirebbe sotto il bordo), finché chi legge non
// scorre per conto suo: da lì in poi la pagina resta dove l'ha messa.
let bollaInCorso = null
let seguo = false
const smetti = () => { seguo = false }
watch(() => props.inCorso?.id, (id) => {
  seguo = !!id
  for (const ev of ['wheel', 'touchmove']) window[id ? 'addEventListener' : 'removeEventListener'](ev, smetti, { passive: true })
})
watch(() => [props.inCorso?.testo, props.inCorso?.stati?.length], async () => {
  if (!seguo) return
  await nextTick()
  const r = bollaInCorso?.getBoundingClientRect()
  if (!r || r.bottom <= window.innerHeight - 16) return
  const lento = !window.matchMedia('(prefers-reduced-motion: reduce)').matches
  window.scrollBy({ top: r.bottom - window.innerHeight + 24, behavior: lento ? 'smooth' : 'auto' })
})

function invia() {
  // Il testo resta nel campo finché il genitore non conferma l'invio (svuota): se l'invio fallisce non si perde nulla
  emit('rispondi', { testo: testo.value.trim(), foto: foto.value?.base64 ?? null })
}
function svuota() {
  testo.value = ''
  foto.value = null
}
defineExpose({ svuota })
</script>

<style scoped>
.zf { display: flex; flex-direction: column; gap: 12px; margin-top: 14px; }
.zf__segn { display: flex; flex-direction: column; gap: 6px; }
.zf__nota { font: 400 12.5px/1.5 var(--font-sans); color: var(--ink-mid); }
.zf__m { display: flex; gap: 8px; align-items: flex-start; }
.zf__m--utente { justify-content: flex-end; }
.zf__logo { width: 26px; height: 26px; flex: none; }
.zf__bolla { max-width: 85%; padding: 10px 12px; border-radius: 14px; }
.zf__m--utente .zf__bolla { background: var(--sage-pale); }
.zf__m--zorba .zf__bolla { background: var(--cream); border: 1px solid var(--cream-dark); }
.zf__testo { font: 400 13.5px/1.6 var(--font-sans); color: var(--ink); white-space: pre-wrap; margin: 0; }
.zf__testo b { font-weight: 600; }
.zf__vuoto { color: var(--ink-soft); }
.zf__cursore { display: inline-block; width: 7px; height: 7px; margin-left: 4px; border-radius: 50%; background: var(--sage); vertical-align: middle; animation: zf-cursore 1.1s ease-in-out infinite; }
@keyframes zf-cursore { 0%, 100% { opacity: .25; transform: scale(.7); } 50% { opacity: 1; transform: scale(1); } }
@media (prefers-reduced-motion: reduce) { .zf__cursore { animation: none; opacity: .6; } }
.zf__foto { max-width: 200px; border-radius: 12px; display: block; margin-bottom: 6px; }
.zf__errore { font: 400 12.5px/1.5 var(--font-sans); color: var(--rose-dark); margin: 0 0 6px; }
.zf__riprova { min-height: 32px; padding: 4px 12px; font-size: 12px; }
.zf__progetto { display: flex; align-items: center; gap: 8px; text-decoration: none; color: var(--ink); }
.zf__progetto svg { width: 16px; height: 16px; }
.zf__progetto b { margin-left: auto; color: var(--sage-dark); font-size: 12px; }
.zf__chiuso { font: 400 12.5px/1.5 var(--font-sans); color: var(--ink-soft); display: flex; flex-direction: column; gap: 8px; align-items: flex-start; }
.zf__rimaste { font: 400 11.5px/1.5 var(--font-sans); color: var(--ink-soft); margin: 6px 0 0; }
.zf__bar { gap: 8px; flex-wrap: wrap; }
.reqsend:disabled { opacity: .5; cursor: not-allowed; }
</style>
