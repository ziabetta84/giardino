<template>
  <div>
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;">
      <h1 class="title-display gradient-title" style="font-size:1.9rem;font-weight:800;">Concimi</h1>
      <button @click="apriNuovo" class="btn btn-rose" style="padding:8px 16px;">＋ Aggiungi</button>
    </div>

    <!-- Skeleton -->
    <div v-if="store.loading" style="display:flex;flex-direction:column;gap:10px;">
      <div v-for="i in 3" :key="i" class="card" style="padding:16px;">
        <div class="skeleton" style="height:16px;width:50%;margin-bottom:8px;"></div>
        <div class="skeleton" style="height:11px;width:30%;"></div>
      </div>
    </div>

    <template v-else>
      <div v-if="concimi.length" style="display:flex;flex-direction:column;gap:10px;">
        <div v-for="c in concimi" :key="c.id" class="card hover-card"
          style="padding:16px;display:flex;align-items:center;justify-content:space-between;gap:12px;cursor:pointer;"
          @click="apriModifica(c)">
          <div style="flex:1;min-width:0;">
            <h3 class="title-serif" style="font-size:15px;font-weight:600;margin-bottom:4px;">{{ c.nome }}</h3>
            <span class="badge" style="background:var(--sage-pale);color:var(--sage-dark);">{{ c.npk.n }}-{{ c.npk.p }}-{{ c.npk.k }}</span>
            <p v-if="c.descrizione" class="text-light" style="font-size:12px;color:var(--ink-soft);line-height:1.5;margin-top:6px;">{{ descrizioneBreve(c) }}</p>
          </div>
          <button @click.stop="avviaElimina(c)" aria-label="Elimina concime"
            style="background:none;border:none;color:var(--ink-faint);font-size:20px;line-height:1;cursor:pointer;flex-shrink:0;padding:4px;">×</button>
        </div>
      </div>

      <div v-else style="text-align:center;padding:60px 20px;color:var(--ink-faint);">
        <div style="width:64px;height:64px;border-radius:50%;background:var(--sage-tile);display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
          <Icon name="provetta" style="width:28px;height:28px;" />
        </div>
        <p class="title-serif" style="font-size:15px;color:var(--ink-soft);font-weight:600;">Nessun concime ancora</p>
        <p class="text-light" style="font-size:12px;margin-top:6px;">Aggiungi i concimi che possiedi per ricevere suggerimenti nelle Attività</p>
      </div>
    </template>

    <!-- Modale nuovo/modifica -->
    <Teleport to="body">
      <div v-if="mostraForm" class="overlay" @click.self="chiudiForm">
        <div class="modal-box">
          <h3 style="font-family:var(--font-serif);font-size:16px;font-weight:600;margin-bottom:16px;">
            {{ modificaId ? 'Modifica concime' : 'Nuovo concime' }}
          </h3>
          <input v-model="form.nome" placeholder="Nome *" class="form-input" style="margin-bottom:10px;">
          <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">NPK</label>
          <div style="display:flex;gap:8px;margin-bottom:16px;">
            <input v-model.number="form.n" type="number" min="0" placeholder="N" class="form-input" style="text-align:center;">
            <input v-model.number="form.p" type="number" min="0" placeholder="P" class="form-input" style="text-align:center;">
            <input v-model.number="form.k" type="number" min="0" placeholder="K" class="form-input" style="text-align:center;">
          </div>
          <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Descrizione (opzionale)</label>
          <textarea v-model="form.descrizione" placeholder="Preparazione, dosi, tempo di macerazione…"
            rows="3" class="form-input" style="resize:vertical;font-family:inherit;margin-bottom:16px;"></textarea>
          <div style="display:flex;gap:10px;justify-content:flex-end;">
            <button class="btn btn-ghost" @click="chiudiForm" style="min-height:40px;padding:8px 16px;">Annulla</button>
            <button class="btn btn-sage" @click="salva" :disabled="!form.nome.trim() || salvando"
              style="min-height:40px;padding:8px 16px;">
              {{ salvando ? '⏳' : 'Salva' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>

    <ModalConferma
      :aperto="daEliminare !== null"
      titolo="Eliminare questo concime?"
      messaggio="Questa azione non può essere annullata."
      :caricamento="eliminando"
      @conferma="eliminaConcime"
      @annulla="daEliminare = null"
    />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'
import ModalConferma from '@/components/ModalConferma.vue'
import Icon from '@/components/Icon.vue'

const store = useDatiStore()
const { saveJSON } = useApi()

const mostraForm = ref(false)
const modificaId  = ref(null)
const salvando    = ref(false)
const form = ref({ nome: '', n: null, p: null, k: null, descrizione: '' })

const daEliminare = ref(null)
const eliminando  = ref(false)

const concimi = computed(() => {
  if (!store.concimi) return []
  return Object.entries(store.concimi)
    .map(([id, c]) => ({ id, ...c }))
    .sort((a, b) => (a.nome ?? '').localeCompare(b.nome ?? ''))
})

function apriNuovo() {
  modificaId.value = null
  form.value = { nome: '', n: null, p: null, k: null, descrizione: '' }
  mostraForm.value = true
}

function apriModifica(c) {
  modificaId.value = c.id
  form.value = { nome: c.nome, n: c.npk.n, p: c.npk.p, k: c.npk.k, descrizione: c.descrizione ?? '' }
  mostraForm.value = true
}

function descrizioneBreve(c) {
  const testo = c.descrizione || ''
  return testo.length > 150 ? testo.slice(0, 150) + '…' : testo
}

function chiudiForm() {
  mostraForm.value = false
}

async function salva() {
  const nome = form.value.nome.trim()
  if (!nome || salvando.value) return
  salvando.value = true
  const id = modificaId.value ?? `concime-${Date.now()}`
  try {
    const nuovi = await saveJSON('concimi.json', (correnti) => ({
      ...(correnti ?? store.concimi),
      [id]: {
        nome,
        npk: { n: form.value.n || 0, p: form.value.p || 0, k: form.value.k || 0 },
        descrizione: form.value.descrizione.trim() || '',
      }
    }))
    store.concimi = nuovi
    mostraForm.value = false
  } finally {
    salvando.value = false
  }
}

function avviaElimina(c) {
  daEliminare.value = c.id
}

async function eliminaConcime() {
  if (!daEliminare.value) return
  eliminando.value = true
  const id = daEliminare.value
  try {
    const nuovi = await saveJSON('concimi.json', (correnti) => {
      const base = { ...(correnti ?? store.concimi) }
      delete base[id]
      return base
    })
    store.concimi = nuovi
    daEliminare.value = null
  } finally {
    eliminando.value = false
  }
}
</script>

<style scoped>
.overlay {
  position: fixed; inset: 0; z-index: 200;
  background: rgba(42,34,24,0.4);
  display: flex; align-items: center; justify-content: center; padding: 16px;
}
.modal-box {
  background: var(--white); border-radius: 20px; padding: 24px;
  width: 100%; max-width: 360px;
  box-shadow: 0 20px 60px rgba(42,34,24,0.2);
}
</style>
