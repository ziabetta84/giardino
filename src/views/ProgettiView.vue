<template>
  <div>
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;">
      <h1 class="title-display gradient-title" style="font-size:1.9rem;font-weight:800;">Progetti</h1>
      <button @click="mostraForm = true" class="btn btn-rose" style="padding:8px 16px;">＋ Aggiungi</button>
    </div>

    <!-- Skeleton -->
    <div v-if="store.loading" style="display:flex;flex-direction:column;gap:10px;">
      <div v-for="i in 3" :key="i" class="card" style="padding:16px;">
        <div class="skeleton" style="height:16px;width:50%;margin-bottom:8px;"></div>
        <div class="skeleton" style="height:11px;width:80%;margin-bottom:6px;"></div>
        <div class="skeleton" style="height:11px;width:60%;"></div>
      </div>
    </div>

    <template v-else>
      <div v-if="progetti.length" style="display:flex;flex-direction:column;gap:10px;">
        <div v-for="p in progetti" :key="p.id" class="card hover-card" style="padding:16px;">
          <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:8px;">
            <div style="flex:1;min-width:0;">
              <h3 class="title-serif" style="font-size:15px;font-weight:600;margin-bottom:4px;">{{ p.titolo }}</h3>
              <p v-if="p.descrizione" style="font-size:12px;color:var(--ink-soft);line-height:1.5;">{{ p.descrizione }}</p>
            </div>
            <span class="badge" :style="badgeStato(p.stato)">{{ p.stato ?? 'bozza' }}</span>
          </div>
          <div v-if="p.zona || p.scadenza" style="display:flex;gap:10px;margin-top:10px;">
            <span v-if="p.zona" style="font-size:11px;color:var(--ink-faint);">📍 {{ p.zona }}</span>
            <span v-if="p.scadenza" style="font-size:11px;color:var(--ink-faint);">📅 {{ p.scadenza }}</span>
          </div>
        </div>
      </div>

      <div v-else style="text-align:center;padding:60px 20px;color:var(--ink-faint);">
        <div style="font-size:48px;margin-bottom:12px;">🌱</div>
        <p class="title-serif" style="font-size:15px;color:var(--ink-soft);font-weight:600;">Nessun progetto ancora</p>
        <p style="font-size:12px;margin-top:6px;">Pianifica interventi, trapianti o lavori in giardino</p>
      </div>
    </template>

    <!-- Form nuovo progetto -->
    <Teleport to="body">
      <div v-if="mostraForm" class="overlay" @click.self="mostraForm = false">
        <div class="modal-box">
          <h3 style="font-family:var(--font-serif);font-size:16px;font-weight:600;margin-bottom:16px;">Nuovo progetto</h3>
          <input v-model="form.titolo" placeholder="Titolo" class="form-input" style="margin-bottom:10px;">
          <textarea v-model="form.descrizione" placeholder="Descrizione (opzionale)" rows="3"
            class="form-input" style="resize:vertical;font-family:inherit;margin-bottom:10px;"></textarea>
          <input v-model="form.zona" placeholder="Zona (opzionale)" class="form-input" style="margin-bottom:10px;">
          <input v-model="form.scadenza" type="date" class="form-input" style="margin-bottom:16px;">
          <div style="display:flex;gap:10px;justify-content:flex-end;">
            <button class="btn btn-ghost" @click="mostraForm = false" style="min-height:40px;padding:8px 16px;">Annulla</button>
            <button class="btn btn-sage" @click="salvaProgetto" :disabled="!form.titolo.trim() || salvando"
              style="min-height:40px;padding:8px 16px;">
              {{ salvando ? '⏳' : 'Salva' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'

const store = useDatiStore()
const { saveJSON } = useApi()

const mostraForm = ref(false)
const salvando   = ref(false)
const form = ref({ titolo: '', descrizione: '', zona: '', scadenza: '' })

const progetti = computed(() => {
  if (!store.progetti) return []
  return Object.entries(store.progetti)
    .map(([id, p]) => ({ id, ...p }))
    .sort((a, b) => (a.titolo ?? '').localeCompare(b.titolo ?? ''))
})

function badgeStato(stato) {
  if (stato === 'completato') return 'background:var(--sage-pale);color:var(--sage-dark);'
  if (stato === 'in_corso')   return 'background:var(--gold-pale);color:var(--gold-dark);'
  return 'background:var(--cream-dark);color:var(--ink-soft);'
}

async function salvaProgetto() {
  if (!form.value.titolo.trim() || salvando.value) return
  salvando.value = true
  try {
    const id = `progetto-${Date.now()}`
    const nuovi = {
      ...store.progetti,
      [id]: {
        titolo: form.value.titolo.trim(),
        descrizione: form.value.descrizione.trim() || null,
        zona: form.value.zona.trim() || null,
        scadenza: form.value.scadenza || null,
        stato: 'bozza',
        creato: new Date().toISOString().split('T')[0],
      }
    }
    await saveJSON('progetti.json', nuovi)
    store.progetti = nuovi
    mostraForm.value = false
    form.value = { titolo: '', descrizione: '', zona: '', scadenza: '' }
  } finally {
    salvando.value = false
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
