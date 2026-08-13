<template>
  <div>
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:16px;">
      <h1 class="title-display gradient-title" style="font-size:1.9rem;font-weight:800;">Piante</h1>
      <RouterLink to="/piante/nuova" class="btn btn-rose" style="text-decoration:none;padding:8px 16px;">＋ Aggiungi</RouterLink>
    </div>

    <!-- Search -->
    <div style="position:relative;margin-bottom:12px;">
      <Icon name="cerca" style="position:absolute;left:14px;top:50%;transform:translateY(-50%);width:15px;height:15px;color:var(--ink-faint);pointer-events:none;" />
      <input class="search-input" v-model="cerca" type="search" placeholder="Cerca per nome o specie…">
    </div>

    <!-- Filtri zona -->
    <div style="display:flex;gap:8px;overflow-x:auto;padding-bottom:12px;margin-bottom:8px;" class="no-scroll">
      <button v-for="z in filtriZona" :key="z.key"
        class="pill" :class="{ active: filtroZona === z.key }"
        @click="selezionaZona(z.key)">
        {{ z.label }}
      </button>
    </div>

    <!-- Filtri sottozona (solo se la zona selezionata ne ha) -->
    <div v-if="filtriSottozona.length" style="display:flex;gap:8px;overflow-x:auto;padding-bottom:12px;margin-bottom:16px;" class="no-scroll">
      <button v-for="s in filtriSottozona" :key="s"
        class="pill" :class="{ active: filtroSottozona === s }"
        @click="filtroSottozona = s"
        style="font-size:12px;">
        {{ s === 'tutte' ? 'Tutte' : s }}
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
        <p class="section-label" style="display:flex;align-items:center;gap:6px;">
          <Icon name="campanella" style="width:12px;height:12px;flex-shrink:0;" />Da curare
        </p>
        <TransitionGroup name="stagger" tag="div" style="display:flex;flex-direction:column;gap:8px;margin-bottom:20px;">
          <PiantaRiga v-for="(p, i) in pianteUrgenti" :key="'u'+p.id" :pianta="p" urgente :thumb-url="thumbnail[p.id]"
            :style="`transition-delay:${Math.min(i,8) * 0.03}s;`"
            @elimina="avviaElimina(p)" />
        </TransitionGroup>
        <p class="section-label">Tutte le piante</p>
      </template>

      <!-- Lista principale -->
      <TransitionGroup v-if="pianteFiltrate.length" name="stagger" tag="div" style="display:flex;flex-direction:column;gap:8px;">
        <PiantaRiga v-for="(p, i) in pianteFiltrate" :key="p.id" :pianta="p" :thumb-url="thumbnail[p.id]"
          :style="`transition-delay:${Math.min(i,8) * 0.03}s;`"
          @elimina="avviaElimina(p)" />
      </TransitionGroup>

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
      messaggio="Questa azione non può essere annullata. Verranno eliminate anche eventuali foto associate."
      :caricamento="eliminando"
      @conferma="eliminaPianta"
      @annulla="daEliminare = null"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'
import { useGalleria } from '@/composables/useGalleria'
import { cureUrgentiPianta } from '@/composables/useCure'
import ModalConferma from '@/components/ModalConferma.vue'
import PiantaRiga from '@/components/PiantaRiga.vue'
import Icon from '@/components/Icon.vue'

const store      = useDatiStore()
const route      = useRoute()
const { saveJSON } = useApi()
const galleria   = useGalleria()

// Una sola chiamata per tutte le piante (vedi useGalleria.mappaThumbnail):
// se fallisce (rete assente, repo privata senza token, ecc.) l'elenco resta
// comunque utilizzabile, semplicemente senza le miniature.
const thumbnail = ref({})
onMounted(async () => {
  try {
    thumbnail.value = await galleria.mappaThumbnail()
  } catch {
    thumbnail.value = {}
  }
})

const cerca      = ref('')
const filtroZona = ref(route.query.zona ?? 'tutte')
const filtroSottozona = ref('tutte')
const daEliminare = ref(null)
const eliminando  = ref(false)

const filtriZona = computed(() => {
  const zone = store.zone ? Object.entries(store.zone).map(([key, z]) => ({ key, label: z.nome ?? key })) : []
  return [{ key: 'tutte', label: 'Tutte' }, ...zone]
})

// Sottozone effettivamente presenti tra le piante della zona selezionata
// (non tutte quelle configurate in sottozone.json: solo quelle in uso, per
// non mostrare filtri vuoti). Vuoto se la zona è "tutte" o non ha sottozone.
const filtriSottozona = computed(() => {
  if (filtroZona.value === 'tutte' || !store.piante) return []
  const nomi = new Set()
  for (const p of Object.values(store.piante)) {
    if (p.zona === filtroZona.value && p.sottozona) nomi.add(p.sottozona)
  }
  if (!nomi.size) return []
  return ['tutte', ...[...nomi].sort((a, b) => a.localeCompare(b))]
})

function selezionaZona(key) {
  filtroZona.value = key
  filtroSottozona.value = 'tutte'
}

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
  if (filtroZona.value !== 'tutte' && filtroSottozona.value !== 'tutte')
    lista = lista.filter(p => p.sottozona === filtroSottozona.value)
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

function avviaElimina(pianta) {
  daEliminare.value = pianta
}

async function eliminaPianta() {
  if (!daEliminare.value) return
  eliminando.value = true
  const id = daEliminare.value.id
  try {
    await galleria.eliminaCartella(id)
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
