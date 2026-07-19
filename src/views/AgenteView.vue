<template>
  <div style="display:flex;flex-direction:column;min-height:calc(100dvh - 130px);">
    <h1 class="title-display gradient-title" style="font-size:1.9rem;font-weight:800;margin-bottom:4px;">Assistente</h1>
    <p style="font-size:12px;color:var(--ink-soft);margin-bottom:16px;">
      Llama 3.2 Vision · conosce il tuo giardino
      <button v-if="apiKey" @click="rimuoviKey" style="margin-left:10px;font-size:11px;color:var(--ink-faint);background:none;border:none;cursor:pointer;text-decoration:underline;">cambia chiave</button>
    </p>

    <!-- Setup chiave API -->
    <div v-if="!apiKey" class="card" style="padding:16px;margin-bottom:16px;border-color:var(--gold-light);background:var(--gold-pale);">
      <p style="font-size:13px;font-weight:600;color:var(--gold-dark);margin-bottom:4px;">🔑 Chiave API OpenRouter richiesta</p>
      <p style="font-size:12px;color:var(--ink-soft);margin-bottom:10px;">
        Ottienila gratis su <strong>openrouter.ai/keys</strong> → Create Key (nessuna carta richiesta)
      </p>
      <div style="display:flex;gap:8px;">
        <input v-model="keyInput" type="password" placeholder="sk-or-…" class="form-input"
          style="flex:1;min-height:36px;font-size:13px;" @keyup.enter="salvaKey">
        <button @click="salvaKey" :disabled="!keyInput.trim()" class="btn btn-sage"
          style="min-height:36px;padding:6px 14px;font-size:13px;">Salva</button>
      </div>
    </div>

    <!-- Chat -->
    <div v-else style="display:flex;flex-direction:column;flex:1;">

      <!-- Messaggi -->
      <div ref="chatArea" style="flex:1;display:flex;flex-direction:column;gap:12px;overflow-y:auto;padding-bottom:8px;margin-bottom:12px;">

        <!-- Empty state -->
        <div v-if="!messaggi.length" style="text-align:center;padding:40px 20px;color:var(--ink-faint);">
          <div style="font-size:40px;margin-bottom:12px;">🌿</div>
          <p style="font-size:13px;line-height:1.6;">Chiedi qualcosa sul tuo giardino.<br>Posso identificare piante, diagnosticare problemi e darti consigli di cura.</p>
        </div>

        <template v-for="msg in messaggi" :key="msg.id">
          <!-- Utente -->
          <div v-if="msg.ruolo === 'user'" style="display:flex;justify-content:flex-end;">
            <div style="max-width:80%;background:var(--sage);color:#fff;border-radius:18px 18px 4px 18px;padding:10px 14px;">
              <img v-if="msg.foto" :src="msg.foto" style="width:100%;max-width:200px;border-radius:10px;display:block;margin-bottom:8px;">
              <p style="font-size:13px;line-height:1.5;white-space:pre-wrap;">{{ msg.testo }}</p>
            </div>
          </div>

          <!-- Assistente -->
          <div v-else style="display:flex;justify-content:flex-start;">
            <div style="max-width:88%;background:var(--white);border:1px solid var(--cream-dark);border-radius:18px 18px 18px 4px;padding:10px 14px;">
              <div v-if="msg.caricamento" style="display:flex;gap:4px;align-items:center;padding:4px 0;">
                <span class="dot-pulse"></span><span class="dot-pulse" style="animation-delay:.15s"></span><span class="dot-pulse" style="animation-delay:.3s"></span>
              </div>
              <p v-else style="font-size:13px;color:var(--ink-mid);line-height:1.6;white-space:pre-wrap;">{{ msg.testo }}</p>
            </div>
          </div>
        </template>
      </div>

      <!-- Anteprima foto -->
      <div v-if="fotoPreview" style="margin-bottom:8px;position:relative;display:inline-block;">
        <img :src="fotoPreview" style="height:64px;border-radius:10px;border:1.5px solid var(--sage-light);">
        <button @click="rimuoviFoto" style="position:absolute;top:-6px;right:-6px;width:20px;height:20px;border-radius:50%;background:var(--rose);border:none;color:#fff;font-size:11px;cursor:pointer;display:flex;align-items:center;justify-content:center;line-height:1;">✕</button>
      </div>

      <!-- Input -->
      <div style="display:flex;gap:8px;align-items:flex-end;">
        <label style="cursor:pointer;width:36px;height:36px;border-radius:10px;background:var(--cream-dark);display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;border:1px solid var(--ink-faint);">
          📷
          <input type="file" accept="image/*" capture="environment" @change="selezionaFoto" style="display:none;">
        </label>
        <textarea v-model="testo" placeholder="Scrivi un messaggio…" rows="1"
          class="form-input" style="flex:1;resize:none;font-family:inherit;min-height:36px;max-height:120px;overflow-y:auto;padding-top:8px;padding-bottom:8px;"
          @input="autoResize" @keydown.enter.exact.prevent="invia"></textarea>
        <button @click="invia" :disabled="(!testo.trim() && !fotoBase64) || inviando"
          class="btn btn-sage" style="width:36px;height:36px;padding:0;border-radius:10px;font-size:16px;flex-shrink:0;">
          {{ inviando ? '⏳' : '↑' }}
        </button>
      </div>

      <!-- Reset -->
      <div v-if="messaggi.length" style="text-align:center;margin-top:10px;">
        <button @click="nuovaChat" style="font-size:11px;color:var(--ink-faint);background:none;border:none;cursor:pointer;">
          Nuova conversazione
        </button>
        <span style="color:var(--ink-faint);font-size:11px;margin:0 8px;">·</span>
        <button @click="rimuoviKey" style="font-size:11px;color:var(--ink-faint);background:none;border:none;cursor:pointer;">
          Cambia chiave API
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { useDatiStore } from '@/stores/dati'

const store = useDatiStore()
const chatArea = ref(null)

const apiKey      = ref(localStorage.getItem('openrouter_api_key') || '')
const keyInput    = ref('')
const testo       = ref('')
const fotoBase64  = ref(null)
const fotoPreview = ref(null)
const inviando    = ref(false)
const messaggi    = ref([])

const stagione = () => {
  const m = new Date().getMonth() + 1
  if (m >= 3 && m <= 5) return 'primavera'
  if (m >= 6 && m <= 8) return 'estate'
  if (m >= 9 && m <= 11) return 'autunno'
  return 'inverno'
}

const systemPrompt = computed(() => {
  const zone = store.zone
    ? Object.entries(store.zone).map(([k, z]) => `${k}: ${z.nome} (${z.tipo ?? ''}, ${z.esposizione ?? ''})`).join('; ')
    : 'non disponibili'
  const specie = store.specie
    ? Object.values(store.specie).slice(0, 40).map(s => s.nome).join(', ')
    : 'non disponibili'
  return `Sei un esperto agronomo e botanico che assiste il proprietario di un giardino privato a Centinarola, Fano (Marche, Italia), zona climatica mediterranea collinare. Stagione attuale: ${stagione()}.

Zone del giardino: ${zone}.
Specie presenti (campione): ${specie}.

Rispondi in italiano, in modo pratico e conciso. Se l'utente allega una foto, analizzala attentamente per identificare la specie o diagnosticare il problema mostrato. Dai consigli specifici per il clima marchigiano.`
})

onMounted(async () => {
  await store.caricaTutto()
})

function salvaKey() {
  if (!keyInput.value.trim()) return
  localStorage.setItem('openrouter_api_key', keyInput.value.trim())
  apiKey.value = keyInput.value.trim()
  keyInput.value = ''
}

function rimuoviKey() {
  localStorage.removeItem('openrouter_api_key')
  apiKey.value = ''
}

function nuovaChat() {
  messaggi.value = []
}

function selezionaFoto(e) {
  const file = e.target.files?.[0]
  if (!file) return
  const reader = new FileReader()
  reader.onload = () => {
    fotoPreview.value = reader.result
    fotoBase64.value  = reader.result.split(',')[1]
  }
  reader.readAsDataURL(file)
  e.target.value = ''
}

function rimuoviFoto() {
  fotoPreview.value = null
  fotoBase64.value  = null
}

function autoResize(e) {
  e.target.style.height = 'auto'
  e.target.style.height = Math.min(e.target.scrollHeight, 120) + 'px'
}

async function scrollGiu() {
  await nextTick()
  if (chatArea.value) chatArea.value.scrollTop = chatArea.value.scrollHeight
}

async function invia() {
  const testoPulito = testo.value.trim()
  if ((!testoPulito && !fotoBase64.value) || inviando.value) return
  inviando.value = true

  const userMsg = {
    id: Date.now(),
    ruolo: 'user',
    testo: testoPulito,
    foto: fotoPreview.value,
    fotoBase64: fotoBase64.value,
  }
  messaggi.value.push(userMsg)

  const loadingId = Date.now() + 1
  messaggi.value.push({ id: loadingId, ruolo: 'model', testo: '', caricamento: true })

  testo.value = ''
  fotoBase64.value  = null
  fotoPreview.value = null
  await scrollGiu()

  try {
    // Costruisce la history per Gemini (esclude il messaggio di caricamento)
    const contents = messaggi.value
      .filter(m => !m.caricamento)
      .slice(0, -1) // escludi l'ultimo (quello appena aggiunto) — lo aggiungiamo strutturato
      .map(m => {
        const parts = []
        if (m.fotoBase64) parts.push({ inline_data: { mime_type: 'image/jpeg', data: m.fotoBase64 } })
        if (m.testo) parts.push({ text: m.testo })
        return { role: m.ruolo === 'user' ? 'user' : 'model', parts }
      })

    // Aggiunge il messaggio corrente
    const currentParts = []
    if (userMsg.fotoBase64) currentParts.push({ inline_data: { mime_type: 'image/jpeg', data: userMsg.fotoBase64 } })
    if (userMsg.testo) currentParts.push({ text: userMsg.testo })
    contents.push({ role: 'user', parts: currentParts })

    // Costruisce messaggi in formato OpenAI
    const messages = [{ role: 'system', content: systemPrompt.value }]
    for (const m of messaggi.value.filter(m => !m.caricamento).slice(0, -1)) {
      if (m.ruolo === 'user') {
        const content = []
        if (m.testo) content.push({ type: 'text', text: m.testo })
        if (m.fotoBase64) content.push({ type: 'image_url', image_url: { url: `data:image/jpeg;base64,${m.fotoBase64}` } })
        messages.push({ role: 'user', content: content.length === 1 && !m.fotoBase64 ? m.testo : content })
      } else {
        messages.push({ role: 'assistant', content: m.testo })
      }
    }
    // Messaggio corrente
    const currentContent = []
    if (userMsg.testo) currentContent.push({ type: 'text', text: userMsg.testo })
    if (userMsg.fotoBase64) currentContent.push({ type: 'image_url', image_url: { url: `data:image/jpeg;base64,${userMsg.fotoBase64}` } })
    messages.push({ role: 'user', content: userMsg.fotoBase64 ? currentContent : userMsg.testo })

    const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey.value}`,
        'HTTP-Referer': 'https://ziabetta84.github.io/giardino',
        'X-Title': 'Il Giardino di Zorba',
      },
      body: JSON.stringify({
        model: 'meta-llama/llama-3.2-11b-vision-instruct:free',
        messages,
        temperature: 0.7,
        max_tokens: 1024,
      }),
    })

    if (!res.ok) {
      const err = await res.json().catch(() => ({}))
      throw new Error(err?.error?.message || `Errore ${res.status}`)
    }

    const data = await res.json()
    const risposta = data.choices?.[0]?.message?.content ?? 'Nessuna risposta ricevuta.'

    const idx = messaggi.value.findIndex(m => m.id === loadingId)
    if (idx !== -1) messaggi.value[idx] = { id: loadingId, ruolo: 'model', testo: risposta, caricamento: false }

  } catch (e) {
    const idx = messaggi.value.findIndex(m => m.id === loadingId)
    if (idx !== -1) messaggi.value[idx] = { id: loadingId, ruolo: 'model', testo: `⚠ ${e.message}`, caricamento: false }
  } finally {
    inviando.value = false
    await scrollGiu()
  }
}
</script>

<style scoped>
.dot-pulse {
  width: 6px; height: 6px; border-radius: 50%;
  background: var(--ink-faint);
  display: inline-block;
  animation: pulse 1s ease-in-out infinite;
}
@keyframes pulse {
  0%, 100% { opacity: .3; transform: scale(.8); }
  50%       { opacity: 1;  transform: scale(1.1); }
}
</style>
