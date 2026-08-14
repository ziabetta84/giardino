<template>
  <div>
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;">
      <h1 class="title-display gradient-title title-settle" style="font-size:1.9rem;font-weight:800;">Progetti</h1>
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
        <RouterLink v-for="p in progetti" :key="p.id" :to="`/progetti/${p.id}`"
          class="card hover-card" style="padding:16px;display:block;text-decoration:none;color:inherit;">
          <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:8px;">
            <div style="flex:1;min-width:0;">
              <h3 class="title-serif" style="font-size:15px;font-weight:600;margin-bottom:4px;">{{ p.titolo }}</h3>
              <p v-if="p.descrizione" class="text-light" style="font-size:12px;color:var(--ink-soft);line-height:1.5;">{{ descrizioneBreve(p) }}</p>
            </div>
            <span class="badge" :style="badgeStato(p.stato)">{{ labelStato(p.stato) }}</span>
          </div>
          <div v-if="p.zona || scadenzaCalcolata(p)" style="display:flex;gap:10px;margin-top:10px;">
            <span v-if="p.zona" style="display:flex;align-items:center;gap:4px;font-size:11px;color:var(--ink-faint);">
              <Icon name="pin" style="width:11px;height:11px;flex-shrink:0;" />{{ p.zona }}
            </span>
            <span v-if="scadenzaCalcolata(p)" style="display:flex;align-items:center;gap:4px;font-size:11px;color:var(--ink-faint);">
              <Icon name="bandiera" style="width:11px;height:11px;flex-shrink:0;" />{{ formatData(scadenzaCalcolata(p)) }}
            </span>
          </div>
        </RouterLink>
      </div>

      <div v-else style="text-align:center;padding:60px 20px;color:var(--ink-faint);">
        <div style="width:64px;height:64px;border-radius:50%;background:var(--gold-tile);display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
          <Icon name="lampadina" style="width:28px;height:28px;" />
        </div>
        <p class="title-serif" style="font-size:15px;color:var(--ink-soft);font-weight:600;">Nessun progetto ancora</p>
        <p class="text-light" style="font-size:12px;margin-top:6px;">Pianifica interventi, trapianti o lavori in giardino</p>
      </div>
    </template>

    <!-- Form nuovo progetto -->
    <Teleport to="body">
      <div v-if="mostraForm" class="overlay" @click.self="mostraForm = false">
        <div class="modal-box">
          <h3 style="font-family:var(--font-serif);font-size:16px;font-weight:600;margin-bottom:16px;">Nuovo progetto</h3>
          <input v-model="form.titolo" placeholder="Titolo" class="form-input" style="margin-bottom:10px;">
          <MiniEditor v-model="form.descrizione" placeholder="Descrizione (opzionale)" />
          <input v-model="form.zona" placeholder="Zona (opzionale)" class="form-input" style="margin:10px 0 16px;">
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
import { scadenzaCalcolata } from '@/composables/useProgetti'
import MiniEditor from '@/components/MiniEditor.vue'
import Icon from '@/components/Icon.vue'

const store = useDatiStore()
const { saveJSON } = useApi()

const mostraForm = ref(false)
const salvando   = ref(false)
const form = ref({ titolo: '', descrizione: '', zona: '' })

const progetti = computed(() => {
  if (!store.progetti) return []
  return Object.entries(store.progetti)
    .map(([id, p]) => ({ id, ...p }))
    .sort((a, b) => (a.titolo ?? '').localeCompare(b.titolo ?? ''))
})

const STILI_STATO = {
  aperto:     'background:var(--cream-dark);color:var(--ink-soft);',
  in_corso:   'background:var(--gold-pale);color:var(--gold-dark);',
  completato: 'background:var(--sage-pale);color:var(--sage-dark);',
  fallito:    'background:var(--rose-pale);color:var(--rose-dark);',
  cancellato: 'background:var(--cream-dark);color:var(--ink-faint);',
}
const LABEL_STATO = {
  aperto: 'Aperto', in_corso: 'In corso', completato: 'Completato',
  fallito: 'Fallito', cancellato: 'Cancellato',
}
function badgeStato(stato) {
  return STILI_STATO[stato] ?? STILI_STATO.aperto
}
function labelStato(stato) {
  return LABEL_STATO[stato] ?? 'Aperto'
}

function formatData(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('it-IT', { day: 'numeric', month: 'short', year: 'numeric' })
}

// Anteprima in elenco: niente tag HTML (la formattazione ha senso solo nella
// scheda del progetto) e troncata, come già per le zone in ZoneView.vue.
function descrizioneBreve(p) {
  const pulito = (p.descrizione || '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim()
  return pulito.length > 150 ? pulito.slice(0, 150) + '…' : pulito
}

async function salvaProgetto() {
  if (!form.value.titolo.trim() || salvando.value) return
  salvando.value = true
  const id = `progetto-${Date.now()}`
  try {
    const nuovi = await saveJSON('progetti.json', (correnti) => ({
      ...(correnti ?? store.progetti),
      [id]: {
        titolo: form.value.titolo.trim(),
        descrizione: form.value.descrizione.trim() || null,
        zona: form.value.zona.trim() || null,
        stato: 'aperto',
        creato: new Date().toISOString().split('T')[0],
        tappe: [],
      }
    }))
    store.progetti = nuovi
    mostraForm.value = false
    form.value = { titolo: '', descrizione: '', zona: '' }
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
