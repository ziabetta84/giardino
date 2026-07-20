<template>
  <div>
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:16px;">
      <h1 class="title-display gradient-title" style="font-size:1.9rem;font-weight:800;">Piante</h1>
      <RouterLink to="/piante/nuova" class="btn btn-rose" style="text-decoration:none;padding:8px 16px;">＋ Aggiungi</RouterLink>
    </div>

    <!-- Search -->
    <div style="position:relative;margin-bottom:12px;">
      <span style="position:absolute;left:14px;top:50%;transform:translateY(-50%);color:var(--ink-faint);pointer-events:none;">🔍</span>
      <input class="search-input" v-model="cerca" type="search" placeholder="Cerca per nome o specie…">
    </div>

    <!-- Filtri zona -->
    <div style="display:flex;gap:8px;overflow-x:auto;padding-bottom:12px;margin-bottom:16px;" class="no-scroll">
      <button v-for="z in filtriZona" :key="z.key"
        class="pill" :class="{ active: filtroZona === z.key }"
        @click="filtroZona = z.key">
        {{ z.label }}
      </button>
    </div>

    <!-- Skeleton -->
    <div v-if="store.loading" style="display:flex;flex-direction:column;gap:8px;">
      <div v-for="i in 5" :key="i" class="card" style="display:flex;align-items:center;gap:14px;padding:12px 16px;">
        <div class="skeleton" style="width:52px;height:52px;border-radius:14px;flex-shrink:0;"></div>
        <div style="flex:1;display:flex;flex-direction:column;gap:6px;">
          <div class="skeleton" style="height:14px;width:40%;"></div>
          <div class="skeleton" style="height:11px;width:60%;"></div>
          <div class="skeleton" style="height:11px;width:30%;"></div>
        </div>
        <div class="skeleton" style="height:22px;width:50px;border-radius:999px;"></div>
      </div>
    </div>

    <template v-else>
      <!-- Urgenti in sezione separata (solo se nessun filtro attivo) -->
      <template v-if="!cerca && filtroZona === 'tutte' && pianteUrgenti.length">
        <p class="section-label">⚠ Da curare</p>
        <div style="display:flex;flex-direction:column;gap:8px;margin-bottom:20px;">
          <PiantaRiga v-for="p in pianteUrgenti" :key="'u'+p.id" :pianta="p" urgente
            @elimina="avviaElimina(p)" />
        </div>
        <p class="section-label">Tutte le piante</p>
      </template>

      <!-- Lista principale: raggruppata per sottozona (o zona) quando non si sta cercando -->
      <template v-if="pianteFiltrate.length">
        <div v-if="cerca.trim()" style="display:flex;flex-direction:column;gap:8px;">
          <PiantaRiga v-for="p in pianteFiltrate" :key="p.id" :pianta="p"
            @elimina="avviaElimina(p)" />
        </div>
        <template v-else>
          <template v-for="gruppo in gruppiPiante" :key="gruppo.chiave">
            <p class="section-label" style="margin-top:16px;">📍 {{ gruppo.sottozona ?? gruppo.zona }}</p>
            <div style="display:flex;flex-direction:column;gap:8px;margin-bottom:8px;">
              <PiantaRiga v-for="p in gruppo.items" :key="p.id" :pianta="p"
                @elimina="avviaElimina(p)" />
            </div>
          </template>
        </template>
      </template>

      <!-- Stato vuoto -->
      <div v-else style="text-align:center;padding:48px 20px;color:var(--ink-faint);">
        <div style="font-size:40px;margin-bottom:12px;">🌾</div>
        <p style="font-size:14px;color:var(--ink-soft);">Nessuna pianta trovata</p>
        <p style="font-size:12px;margin-top:4px;">Prova a cambiare il filtro o la ricerca</p>
      </div>
    </template>

    <ModalConferma
      :aperto="!!daEliminare"
      titolo="Eliminare questa pianta?"
      messaggio="Questa azione non può essere annullata."
      :caricamento="eliminando"
      @conferma="eliminaPianta"
      @annulla="daEliminare = null"
    />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'
import { cureUrgentiPianta } from '@/composables/useCure'
import ModalConferma from '@/components/ModalConferma.vue'
import PiantaRiga from '@/components/PiantaRiga.vue'

const store      = useDatiStore()
const route      = useRoute()
const { saveJSON } = useApi()

const cerca      = ref('')
const filtroZona = ref(route.query.zona ?? 'tutte')
const daEliminare = ref(null)
const eliminando  = ref(false)

const filtriZona = computed(() => {
  const zone = store.zone ? Object.entries(store.zone).map(([key, z]) => ({ key, label: z.nome ?? key })) : []
  return [{ key: 'tutte', label: 'Tutte' }, ...zone]
})

const piante = computed(() => {
  if (!store.piante) return []
  return Object.entries(store.piante).map(([id, p]) => {
    const sp = store.specie?.[p.specie] ?? null
    const urgenti = cureUrgentiPianta(p, sp)
    return { id, ...p, urgente: urgenti.length > 0 }
  })
})

const pianteFiltrate = computed(() => {
  let lista = piante.value
  if (filtroZona.value !== 'tutte')
    lista = lista.filter(p => p.zona === filtroZona.value)
  if (cerca.value.trim()) {
    const q = cerca.value.toLowerCase()
    lista = lista.filter(p =>
      p.id.includes(q) || (p.specie ?? '').toLowerCase().includes(q)
    )
    lista = [...lista].sort((a, b) => (a.urgente ? -1 : 1) - (b.urgente ? -1 : 1))
  } else if (filtroZona.value !== 'tutte') {
    lista = [...lista].sort((a, b) => (a.urgente ? -1 : 1) - (b.urgente ? -1 : 1))
  } else {
    lista = lista.filter(p => !p.urgente)
  }
  return lista
})

const pianteUrgenti = computed(() =>
  piante.value.filter(p => p.urgente && (filtroZona.value === 'tutte' || p.zona === filtroZona.value))
)

// Raggruppa la lista principale per sottozona (o per zona, se la pianta non
// ne ha una): comportamento della vecchia webapp, dove le piante erano
// sempre organizzate sotto l'intestazione della propria sottozona/zona.
const gruppiPiante = computed(() => {
  const gruppi = new Map()
  for (const p of pianteFiltrate.value) {
    const chiave = p.sottozona ? `${p.zona}|${p.sottozona}` : p.zona
    if (!gruppi.has(chiave)) gruppi.set(chiave, { chiave, zona: p.zona, sottozona: p.sottozona, items: [] })
    gruppi.get(chiave).items.push(p)
  }
  return [...gruppi.values()]
})

function avviaElimina(pianta) {
  daEliminare.value = pianta
}

async function eliminaPianta() {
  if (!daEliminare.value) return
  eliminando.value = true
  const id = daEliminare.value.id
  try {
    const nuove = await saveJSON('piante.json', (correnti) => {
      const base = { ...(correnti ?? store.piante) }
      delete base[id]
      return base
    })
    store.piante = nuove
    daEliminare.value = null
  } finally {
    eliminando.value = false
  }
}
</script>
