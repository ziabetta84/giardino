<template>
  <div>
    <RouterLink :to="isNuova ? '/piante' : `/piante/${route.params.id}`"
      style="display:inline-flex;align-items:center;gap:6px;font-size:13px;color:var(--ink-soft);text-decoration:none;margin-bottom:20px;">
      ← {{ isNuova ? 'Piante' : 'Dettaglio' }}
    </RouterLink>

    <h1 class="title-display gradient-title title-settle" style="font-size:1.7rem;font-weight:800;margin-bottom:20px;">
      {{ isNuova ? 'Nuova pianta' : 'Modifica pianta' }}
    </h1>

    <div style="display:flex;flex-direction:column;gap:10px;">
      <!-- Specie -->
      <SelettoreSpecie v-model="form.specie" />

      <!-- Zona -->
      <div class="card" style="padding:16px;">
        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Zona *</label>
        <select v-model="form.zona" class="form-input" style="margin-bottom:10px;">
          <option value="">Seleziona zona…</option>
          <option v-for="(z, key) in store.zone ?? {}" :key="key" :value="z.nome ?? key">{{ z.nome ?? key }}</option>
        </select>

        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Sottozona</label>
        <select v-model="form.sottozona" class="form-input" style="margin-bottom:10px;">
          <option value="">Nessuna</option>
          <option v-for="s in sottozoneZona" :key="s" :value="s">{{ s }}</option>
        </select>

        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Coltivata in</label>
        <div style="display:flex;gap:6px;flex-wrap:wrap;">
          <button type="button" class="pill" :class="{ active: form.coltivatoIn === 'vaso' }" title="Vaso" aria-label="Vaso" style="display:inline-flex;align-items:center;justify-content:center;padding:7px 16px;" @click="form.coltivatoIn = 'vaso'"><Icon name="vaso" style="width:16px;height:16px;" /></button>
          <button type="button" class="pill" :class="{ active: form.coltivatoIn === 'terra' }" title="Terra" aria-label="Terra" style="display:inline-flex;align-items:center;justify-content:center;padding:7px 16px;" @click="form.coltivatoIn = 'terra'"><Icon name="terra" style="width:16px;height:16px;" /></button>
          <button type="button" class="pill" :class="{ active: form.coltivatoIn === 'acqua' }" title="Acqua" aria-label="Acqua" style="display:inline-flex;align-items:center;justify-content:center;padding:7px 16px;" @click="form.coltivatoIn = 'acqua'"><Icon name="acqua" style="width:16px;height:16px;" /></button>
        </div>
      </div>

      <!-- Varietà e impianto -->
      <div class="card" style="padding:16px;">
        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Varietà</label>
        <input v-model="form.varieta" placeholder="Es. Bianca, Rossa…" class="form-input" style="margin-bottom:10px;">

        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Data impianto</label>
        <input v-model="form.impianto" type="date" class="form-input" style="margin-bottom:10px;">

        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Periodo di impianto, se non conosci la data esatta</label>
        <input v-model="form.impianto_circa" placeholder="Es. &quot;circa dal 2016&quot;, &quot;primavera 2025&quot;" class="form-input">
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
        <Spinner v-if="salvando" />{{ salvando ? 'Salvataggio…' : (isNuova ? 'Aggiungi pianta' : 'Salva modifiche') }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'
import SelettoreSpecie from '@/components/SelettoreSpecie.vue'
import Spinner from '@/components/Spinner.vue'
import Icon from '@/components/Icon.vue'

const route  = useRoute()
const router = useRouter()
const store  = useDatiStore()
const { saveJSON } = useApi()

const isNuova = computed(() => !route.params.id)
const salvando = ref(false)

const form = ref({
  specie: '', zona: '', sottozona: '', coltivatoIn: '', varieta: '', impianto: '', impianto_circa: '', note: ''
})

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
      coltivatoIn: p.coltivato_in ?? '',
      varieta:   p.varieta   ?? '',
      impianto:  p.impianto  ?? '',
      impianto_circa: p.impianto_circa ?? '',
      note:      p.note      ?? '',
    }
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
        coltivato_in: form.value.coltivatoIn || null,
        varieta:   form.value.varieta  || '',
        impianto:  form.value.impianto || '',
        impianto_circa: form.value.impianto_circa || '',
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
