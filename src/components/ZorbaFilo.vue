<template>
  <div class="zf">
    <div v-if="filo.tipo === 'segnalazione_scheda'" class="zf__segn">
      <span class="badge" :class="CLASSI_SEGN[filo.segnalazione_stato]">{{ ETICHETTE_SEGN[filo.segnalazione_stato] }}</span>
      <p v-if="filo.segnalazione_nota" class="zf__nota">{{ filo.segnalazione_nota }}</p>
    </div>

    <div v-for="m in messaggi" :key="m.id" class="zf__m" :class="m.ruolo === 'utente' ? 'zf__m--utente' : 'zf__m--zorba'">
      <ZorbaLogo v-if="m.ruolo === 'zorba'" class="zf__logo" />
      <div class="zf__bolla">
        <img v-if="m.foto_url" :src="m.foto_url" class="zf__foto" alt="Foto allegata">
        <template v-if="m.ruolo === 'zorba' && m.id === inCorso?.id">
          <p v-for="(s, i) in inCorso.stati" v-show="!inCorso.testo" :key="i" class="zf__stato">{{ s }}</p>
          <p v-if="inCorso.testo" class="zf__testo">{{ inCorso.testo }}</p>
          <Spinner v-else-if="!inCorso.stati.length" />
        </template>
        <template v-else-if="m.ruolo === 'zorba' && (m.esito === 'errore' || scaduto(m))">
          <p class="zf__errore">Questa risposta non è riuscita.</p>
          <button v-if="!filo.importato" type="button" class="btn btn-ghost zf__riprova" @click="emit('riprova')">Riprova</button>
        </template>
        <p v-else-if="m.testo" class="zf__testo">{{ m.testo }}</p>
        <p v-else-if="m.ruolo === 'utente' && !m.foto_url" class="zf__testo zf__vuoto">(nessun testo)</p>
        <ZorbaPollici v-if="m.ruolo === 'zorba' && m.esito === 'completata' && !filo.importato" :messaggio="m"
          @vota="(v, mo, co) => emit('vota', m.id, v, mo, co)" />
      </div>
    </div>

    <RouterLink v-if="progetto" :to="`/progetti/${progetto.id}`" class="zf__progetto card">
      <Icon name="lampadina" /> <span>{{ progetto.titolo }}</span> <b>Apri il progetto →</b>
    </RouterLink>

    <div v-if="filo.stato === 'chiuso'" class="zf__chiuso">
      <p>Questo filo è concluso: per continuare apri una nuova richiesta.</p>
      <button v-if="!filo.importato" type="button" class="btn btn-sage" @click="emit('nuova', filo.tipo)">Nuova richiesta</button>
    </div>
    <div v-else-if="puoRispondere" class="reqbox zf__risposta">
      <textarea v-model="testo" rows="2" placeholder="Rispondi a Zorba…" maxlength="4000"></textarea>
      <div v-if="foto" class="agente-foto-preview">
        <img :src="foto.anteprima" alt="Anteprima"><button type="button" aria-label="Rimuovi foto" @click="foto = null">×</button>
      </div>
      <p v-if="erroreFoto" class="zf__errore">{{ erroreFoto }}</p>
      <div class="reqbar">
        <span class="ph">
          <Icon name="fotocamera" />
          <label class="agente-foto-btn">Foto<input type="file" accept="image/*" hidden @change="scegliFoto"></label>
        </span>
        <span class="zf__rimaste">Puoi rispondere ancora {{ rimasteRepliche }} {{ rimasteRepliche === 1 ? 'volta' : 'volte' }}</span>
        <button type="button" class="reqsend" :disabled="!testo.trim() && !foto" @click="invia">Invia</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import ZorbaPollici from '@/components/ZorbaPollici.vue'
import { ridimensionaFoto } from '@/utils/foto'

const props = defineProps({
  filo: { type: Object, required: true },
  messaggi: { type: Array, required: true },
  // { id, stati: string[], testo: string } mentre Zorba scrive, altrimenti null
  inCorso: { type: Object, default: null },
  progetto: { type: Object, default: null },
  bloccato: { type: Boolean, default: false },
})
const emit = defineEmits(['rispondi', 'riprova', 'vota', 'nuova'])
const ETICHETTE_SEGN = { in_attesa: 'In attesa del curatore', accolta: 'Accolta', non_accolta: 'Non accolta' }
const CLASSI_SEGN = { in_attesa: 'badge-gold', accolta: 'badge-ok', non_accolta: 'badge-warn' }

const testo = ref('')
const foto = ref(null)
const erroreFoto = ref('')

// Una risposta rimasta "in corso" da più di 3 minuti (funzione interrotta) vale come errore, come per il server
const scaduto = (m) => m.esito === 'in_corso' && m.id !== props.inCorso?.id && Date.now() - new Date(m.creato).getTime() > 180_000
const rimasteRepliche = computed(() => 4 - props.messaggi.filter(m => m.ruolo === 'utente').length)
const ultimaZorba = computed(() => props.messaggi.filter(m => m.ruolo === 'zorba').at(-1))
const puoRispondere = computed(() => !props.filo.importato && !props.bloccato && !props.inCorso && rimasteRepliche.value > 0
  && ultimaZorba.value?.esito === 'completata')

async function scegliFoto(e) {
  const f = e.target.files?.[0]
  e.target.value = ''
  erroreFoto.value = ''
  if (!f) return
  try {
    foto.value = await ridimensionaFoto(f)
  } catch {
    erroreFoto.value = 'Non riesco a leggere questa foto: prova con un\'altra.'
  }
}

function invia() {
  emit('rispondi', { testo: testo.value.trim(), foto: foto.value?.base64 ?? null })
  testo.value = ''
  foto.value = null
}
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
.zf__vuoto { color: var(--ink-soft); }
.zf__stato { font: italic 400 12.5px/1.5 var(--font-sans); color: var(--ink-soft); margin: 0; }
.zf__foto { max-width: 200px; border-radius: 10px; display: block; margin-bottom: 6px; }
.zf__errore { font: 400 12.5px/1.5 var(--font-sans); color: var(--rose-dark); margin: 0 0 6px; }
.zf__riprova { min-height: 32px; padding: 4px 12px; font-size: 12px; }
.zf__progetto { display: flex; align-items: center; gap: 8px; text-decoration: none; color: var(--ink); }
.zf__progetto svg { width: 16px; height: 16px; }
.zf__progetto b { margin-left: auto; color: var(--sage-dark); font-size: 12px; }
.zf__chiuso { font: 400 12.5px/1.5 var(--font-sans); color: var(--ink-soft); display: flex; flex-direction: column; gap: 8px; align-items: flex-start; }
.zf__rimaste { font: 400 11px/1.3 var(--font-sans); color: var(--ink-soft); }
.agente-foto-preview { display: flex; align-items: center; gap: 10px; margin-top: 8px; }
.agente-foto-preview img { width: 40px; height: 40px; object-fit: cover; border-radius: 11px; }
.agente-foto-preview button { background: none; border: none; cursor: pointer; color: var(--ink-soft); font-size: 20px; }
.agente-foto-btn { cursor: pointer; font: 600 11px/1 var(--font-sans); color: var(--sage-ink); text-decoration: underline; }
.reqsend:disabled { opacity: .5; cursor: not-allowed; }
</style>
