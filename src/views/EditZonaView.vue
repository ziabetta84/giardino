<template>
  <div>
    <RouterLink to="/zone" style="display:inline-flex;align-items:center;gap:6px;font-size:13px;color:var(--ink-soft);text-decoration:none;margin-bottom:20px;">
      ← Zone
    </RouterLink>

    <h1 class="title-display gradient-title" style="font-size:1.7rem;font-weight:800;margin-bottom:20px;">
      {{ isNuova ? 'Nuova zona' : 'Modifica zona' }}
    </h1>

    <div style="display:flex;flex-direction:column;gap:10px;">
      <div class="card" style="padding:16px;">
        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Nome *</label>
        <input v-model="form.nome" placeholder="Es. Giardino Nord, Terrazzo…" class="form-input" style="margin-bottom:12px;">

        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Tipo</label>
        <select v-model="form.tipo" class="form-input">
          <option value="esterno">Esterno</option>
          <option value="interno">Interno</option>
        </select>
      </div>

      <div class="card" style="padding:16px;">
        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Descrizione</label>
        <MiniEditor v-model="form.descrizione" placeholder="Descrizione breve della zona…" />

        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin:12px 0 6px;">Microclima</label>
        <MiniEditor v-model="form.microclima" placeholder="Caratteristiche di luce, temperatura, umidità…" />
      </div>

      <div class="card" style="padding:16px;">
        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Esposizione</label>
        <div style="display:flex;gap:8px;flex-wrap:wrap;">
          <label v-for="dir in ['nord','sud','est','ovest']" :key="dir"
            style="display:flex;align-items:center;gap:6px;font-size:13px;cursor:pointer;">
            <input type="checkbox" :value="dir" v-model="form.esposizione" style="accent-color:var(--sage);">
            {{ dir }}
          </label>
        </div>
      </div>

      <button @click="salva" :disabled="!form.nome.trim() || salvando" class="btn btn-rose"
        style="min-height:48px;font-size:15px;border-radius:16px;">
        {{ salvando ? '⏳ Salvataggio…' : (isNuova ? 'Aggiungi zona' : 'Salva modifiche') }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'
import MiniEditor from '@/components/MiniEditor.vue'

const route  = useRoute()
const router = useRouter()
const store  = useDatiStore()
const { saveJSON } = useApi()

const isNuova  = computed(() => !route.params.zona)
const salvando = ref(false)

const form = ref({
  nome: '', tipo: 'esterno', descrizione: '', microclima: '', esposizione: []
})

onMounted(async () => {
  await store.caricaTutto()
  if (!isNuova.value && store.zone?.[route.params.zona]) {
    const z = store.zone[route.params.zona]
    form.value = {
      nome:        z.nome        ?? route.params.zona,
      tipo:        z.tipo        ?? 'esterno',
      descrizione: z.descrizione ?? '',
      microclima:  z.microclima  ?? '',
      esposizione: z.esposizione ?? [],
    }
  }
})

async function salva() {
  if (!form.value.nome.trim() || salvando.value) return
  salvando.value = true
  const key = isNuova.value ? form.value.nome.trim() : route.params.zona
  try {
    const nuove = await saveJSON('zone.json', (correnti) => {
      const base = { ...(correnti ?? store.zone) }
      base[key] = {
        ...(isNuova.value ? {} : base[key]),
        nome:        form.value.nome.trim(),
        tipo:        form.value.tipo,
        descrizione: form.value.descrizione.trim() || '',
        microclima:  form.value.microclima.trim()  || '',
        esposizione: form.value.esposizione,
      }
      return base
    })
    store.zone = nuove
    router.push('/zone')
  } finally {
    salvando.value = false
  }
}
</script>
