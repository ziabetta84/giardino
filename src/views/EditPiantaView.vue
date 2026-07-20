<template>
  <div>
    <RouterLink :to="isNuova ? '/piante' : `/piante/${route.params.id}`"
      style="display:inline-flex;align-items:center;gap:6px;font-size:13px;color:var(--ink-soft);text-decoration:none;margin-bottom:20px;">
      ← {{ isNuova ? 'Piante' : 'Dettaglio' }}
    </RouterLink>

    <h1 class="title-display gradient-title" style="font-size:1.7rem;font-weight:800;margin-bottom:20px;">
      {{ isNuova ? 'Nuova pianta' : 'Modifica pianta' }}
    </h1>

    <div style="display:flex;flex-direction:column;gap:10px;">
      <!-- Specie -->
      <div class="card" style="padding:16px;position:relative;">
        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Specie *</label>
        <input
          v-model="specieQuery"
          @focus="dropdownAperto = true"
          @click="dropdownAperto = true"
          @blur="chiudiDropdown"
          placeholder="Cerca specie…"
          class="form-input"
          autocomplete="off"
        >
        <div v-if="dropdownAperto" class="specie-dropdown">
          <div v-for="s in specieFiltrate" :key="s.key" class="specie-opzione" @mousedown.prevent="selezionaSpecie(s)">
            {{ s.nome }}
          </div>
          <p v-if="!specieFiltrate.length" style="font-size:12px;color:var(--ink-faint);padding:8px 10px;">Nessuna specie trovata</p>
          <div class="specie-opzione specie-nuova" @mousedown.prevent="apriNuovaSpecie">
            ＋ Aggiungi nuova specie{{ specieQuery.trim() ? ` "${specieQuery.trim()}"` : '' }}
          </div>
        </div>
      </div>

      <!-- Zona -->
      <div class="card" style="padding:16px;">
        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Zona *</label>
        <select v-model="form.zona" class="form-input" style="margin-bottom:10px;">
          <option value="">Seleziona zona…</option>
          <option v-for="(z, key) in store.zone ?? {}" :key="key" :value="z.nome ?? key">{{ z.nome ?? key }}</option>
        </select>

        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Sottozona</label>
        <select v-model="form.sottozona" class="form-input">
          <option value="">Nessuna</option>
          <option v-for="s in sottozoneZona" :key="s" :value="s">{{ s }}</option>
        </select>
      </div>

      <!-- Varietà e impianto -->
      <div class="card" style="padding:16px;">
        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Varietà</label>
        <input v-model="form.varieta" placeholder="Es. Bianca, Rossa…" class="form-input" style="margin-bottom:10px;">

        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Data impianto</label>
        <input v-model="form.impianto" type="date" class="form-input">
      </div>

      <!-- Note -->
      <div class="card" style="padding:16px;">
        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Note</label>
        <textarea v-model="form.note" placeholder="Osservazioni, caratteristiche particolari…"
          rows="3" class="form-input" style="resize:vertical;font-family:inherit;"></textarea>
      </div>

      <!-- Salva -->
      <button @click="salva" :disabled="!form.specie || !form.zona || salvando" class="btn btn-rose"
        style="min-height:48px;font-size:15px;border-radius:16px;">
        {{ salvando ? '⏳ Salvataggio…' : (isNuova ? 'Aggiungi pianta' : 'Salva modifiche') }}
      </button>
    </div>

    <!-- Modale nuova specie -->
    <Teleport to="body">
      <div v-if="mostraNuovaSpecie" class="overlay" @click.self="chiudiNuovaSpecie">
        <div class="modal-box">
          <h3 style="font-family:var(--font-serif);font-size:16px;font-weight:600;margin-bottom:16px;">Nuova specie</h3>

          <input v-model="nuovaSpecie.nome" placeholder="Nome *" class="form-input" style="margin-bottom:10px;">
          <p v-if="erroreSpecie" style="font-size:11px;color:var(--rose-dark);margin:0 0 10px;">{{ erroreSpecie }}</p>

          <textarea v-model="nuovaSpecie.descrizione" placeholder="Descrizione (opzionale)"
            rows="2" class="form-input" style="resize:vertical;font-family:inherit;margin-bottom:10px;"></textarea>

          <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Esigenze (opzionale)</label>
          <input v-model="nuovaSpecie.luce" placeholder="Luce, es. Pieno sole" class="form-input" style="margin-bottom:8px;">
          <input v-model="nuovaSpecie.acqua" placeholder="Acqua, es. Moderata" class="form-input" style="margin-bottom:8px;">
          <input v-model="nuovaSpecie.terreno" placeholder="Terreno, es. Ben drenato" class="form-input" style="margin-bottom:16px;">

          <div style="display:flex;gap:10px;justify-content:flex-end;">
            <button class="btn btn-ghost" @click="chiudiNuovaSpecie" style="min-height:40px;padding:8px 16px;">Annulla</button>
            <button class="btn btn-sage" @click="salvaNuovaSpecie" :disabled="!nuovaSpecie.nome.trim() || salvandoSpecie"
              style="min-height:40px;padding:8px 16px;">
              {{ salvandoSpecie ? '⏳' : 'Aggiungi' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'

const route  = useRoute()
const router = useRouter()
const store  = useDatiStore()
const { saveJSON } = useApi()

const isNuova = computed(() => !route.params.id)
const salvando = ref(false)

const form = ref({
  specie: '', zona: '', sottozona: '', varieta: '', impianto: '', note: ''
})

// Combobox specie: testo digitato per filtrare l'elenco (~80+ specie, troppe
// per una <select> nativa comoda su mobile) più un'opzione per crearne una
// nuova al volo senza uscire dal form pianta.
const specieQuery    = ref('')
const dropdownAperto = ref(false)

const specieFiltrate = computed(() => {
  const tutte = Object.entries(store.specie ?? {})
    .map(([key, s]) => ({ key, nome: s.nome ?? key }))
    .sort((a, b) => a.nome.localeCompare(b.nome))
  const q = specieQuery.value.trim().toLowerCase()
  if (!q) return tutte
  return tutte.filter(s => s.nome.toLowerCase().includes(q))
})

function selezionaSpecie(s) {
  form.value.specie = s.key
  specieQuery.value = s.nome
  dropdownAperto.value = false
}

function chiudiDropdown() {
  dropdownAperto.value = false
  // Se l'utente ha digitato senza selezionare nulla dall'elenco, ripristina
  // il testo sul nome della specie effettivamente selezionata (o vuoto).
  specieQuery.value = store.specie?.[form.value.specie]?.nome ?? ''
}

const mostraNuovaSpecie = ref(false)
const salvandoSpecie    = ref(false)
const erroreSpecie      = ref(null)
const nuovaSpecie = ref({ nome: '', descrizione: '', luce: '', acqua: '', terreno: '' })

function slug(testo) {
  return testo
    .toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

function apriNuovaSpecie() {
  nuovaSpecie.value = { nome: specieQuery.value.trim(), descrizione: '', luce: '', acqua: '', terreno: '' }
  erroreSpecie.value = null
  dropdownAperto.value = false
  mostraNuovaSpecie.value = true
}

function chiudiNuovaSpecie() {
  mostraNuovaSpecie.value = false
  erroreSpecie.value = null
}

async function salvaNuovaSpecie() {
  const nome = nuovaSpecie.value.nome.trim()
  if (!nome || salvandoSpecie.value) return
  const chiave = slug(nome)
  if (store.specie?.[chiave]) {
    erroreSpecie.value = 'Una specie con questo nome esiste già.'
    return
  }
  erroreSpecie.value = null

  salvandoSpecie.value = true
  try {
    const nuove = await saveJSON('specie.json', (correnti) => {
      const base = { ...(correnti ?? store.specie) }
      base[chiave] = {
        nome,
        specie: nome,
        descrizione: nuovaSpecie.value.descrizione.trim() || '',
        esigenze: {
          luce:    nuovaSpecie.value.luce.trim()    || '',
          acqua:   nuovaSpecie.value.acqua.trim()   || '',
          terreno: nuovaSpecie.value.terreno.trim() || '',
        },
        alert: [],
        manutenzione: { irrigazione: {}, concimazione: {}, potatura: {} },
      }
      return base
    })
    store.specie = nuove
    selezionaSpecie({ key: chiave, nome })
    mostraNuovaSpecie.value = false
  } finally {
    salvandoSpecie.value = false
  }
}

const sottozoneZona = computed(() => {
  if (!form.value.zona || !store.sottozone) return []
  const zonaKey = Object.entries(store.zone ?? {}).find(([, z]) => (z.nome ?? '') === form.value.zona)?.[0]
  if (!zonaKey) return []
  const sz = store.sottozone[zonaKey]
  if (!sz) return []
  return Object.values(sz).map(s => s.nome ?? s).filter(Boolean)
})

onMounted(async () => {
  await store.caricaTutto()
  if (!isNuova.value && store.piante?.[route.params.id]) {
    const p = store.piante[route.params.id]
    form.value = {
      specie:    p.specie    ?? '',
      zona:      p.zona      ?? '',
      sottozona: p.sottozona ?? '',
      varieta:   p.varieta   ?? '',
      impianto:  p.impianto  ?? '',
      note:      p.note      ?? '',
    }
    specieQuery.value = store.specie?.[form.value.specie]?.nome ?? ''
  }
})

async function salva() {
  if (!form.value.specie || !form.value.zona || salvando.value) return
  salvando.value = true
  const id = isNuova.value ? `${form.value.specie}-${Date.now()}` : route.params.id
  try {
    const nuove = await saveJSON('piante.json', (correnti) => {
      const base = { ...(correnti ?? store.piante) }
      const piantaEsistente = isNuova.value ? {} : (base[id] || {})
      base[id] = {
        ...piantaEsistente,
        specie:    form.value.specie,
        zona:      form.value.zona,
        sottozona: form.value.sottozona || null,
        varieta:   form.value.varieta  || '',
        impianto:  form.value.impianto || '',
        note:      form.value.note     || '',
        ultima_cura: piantaEsistente.ultima_cura || {},
      }
      return base
    })
    store.piante = nuove
    router.push(isNuova.value ? '/piante' : `/piante/${id}`)
  } finally {
    salvando.value = false
  }
}
</script>

<style scoped>
.specie-dropdown {
  position: absolute;
  left: 16px; right: 16px;
  margin-top: 4px;
  background: var(--white);
  border: 1px solid var(--cream-dark);
  border-radius: 12px;
  box-shadow: 0 12px 32px rgba(42,34,24,0.15);
  max-height: 240px;
  overflow-y: auto;
  z-index: 50;
}
.specie-opzione {
  padding: 10px 12px;
  font-size: 13px;
  cursor: pointer;
}
.specie-opzione:hover {
  background: var(--cream);
}
.specie-nuova {
  color: var(--sage-dark);
  font-weight: 600;
  border-top: 1px solid var(--cream-dark);
}
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
