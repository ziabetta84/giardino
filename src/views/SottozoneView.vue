<template>
  <div>
    <RouterLink :to="`/zone`" style="display:inline-flex;align-items:center;gap:6px;font-size:13px;color:var(--ink-soft);text-decoration:none;margin-bottom:20px;">
      ← Zone
    </RouterLink>

    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;">
      <div>
        <h1 class="title-display gradient-title" style="font-size:1.7rem;font-weight:800;">
          {{ zona?.nome ?? route.params.zona }}
        </h1>
        <p style="font-size:13px;color:var(--ink-soft);margin-top:2px;">Sottozone</p>
      </div>
      <button @click="mostraForm = true" class="btn btn-rose" style="padding:8px 14px;">＋ Aggiungi</button>
    </div>

    <div v-if="!sottozone.length" style="text-align:center;padding:60px 20px;color:var(--ink-faint);">
      <div style="font-size:40px;margin-bottom:12px;">🗺️</div>
      <p style="color:var(--ink-soft);font-size:13px;">Nessuna sottozona configurata</p>
    </div>

    <div v-else style="display:flex;flex-direction:column;gap:10px;">
      <div v-for="sz in sottozone" :key="sz.nome" class="card" style="padding:16px;">
        <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:8px;margin-bottom:8px;">
          <h3 class="title-serif" style="font-size:15px;font-weight:600;">{{ sz.nome }}</h3>
          <div style="display:flex;gap:6px;">
            <span v-if="sz.tipo" class="badge" :style="sz.tipo === 'interno' ? 'background:var(--sage-pale);color:var(--sage-dark);' : 'background:var(--gold-pale);color:var(--gold-dark);'">
              {{ sz.tipo }}
            </span>
          </div>
        </div>
        <div v-if="sz.esposizione?.length" style="font-size:11px;color:var(--ink-faint);margin-bottom:6px;">
          ☀️ {{ sz.esposizione.join(', ') }}
        </div>
        <div v-if="sz.descrizione" style="font-size:12px;color:var(--ink-soft);line-height:1.5;" v-html="sz.descrizione?.replace(/<[^>]+>/g,'').slice(0,150)"></div>
      </div>
    </div>

    <!-- Form nuova sottozona -->
    <Teleport to="body">
      <div v-if="mostraForm" class="overlay" @click.self="mostraForm = false">
        <div class="modal-box">
          <h3 style="font-family:var(--font-serif);font-size:16px;font-weight:600;margin-bottom:16px;">Nuova sottozona</h3>
          <input v-model="form.nome" placeholder="Nome *" class="form-input" style="margin-bottom:10px;">
          <textarea v-model="form.descrizione" placeholder="Descrizione (opzionale)" rows="3"
            class="form-input" style="resize:vertical;font-family:inherit;margin-bottom:10px;"></textarea>
          <select v-model="form.tipo" class="form-input" style="margin-bottom:16px;">
            <option value="esterno">Esterno</option>
            <option value="interno">Interno</option>
          </select>
          <div style="display:flex;gap:10px;justify-content:flex-end;">
            <button class="btn btn-ghost" @click="mostraForm = false" style="min-height:40px;padding:8px 16px;">Annulla</button>
            <button class="btn btn-sage" @click="salva" :disabled="!form.nome.trim() || salvando"
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
import { useRoute } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'

const route = useRoute()
const store = useDatiStore()
const { saveJSON } = useApi()

const mostraForm = ref(false)
const salvando   = ref(false)
const form = ref({ nome: '', descrizione: '', tipo: 'esterno' })

const zona = computed(() => store.zone?.[route.params.zona] ?? null)
const sottozone = computed(() => {
  const sz = store.sottozone?.[route.params.zona]
  if (!sz) return []
  return Object.values(sz)
})

async function salva() {
  if (!form.value.nome.trim() || salvando.value) return
  salvando.value = true
  try {
    const nuove = await saveJSON('sottozone.json', (correnti) => {
      const base = { ...(correnti ?? store.sottozone) }
      base[route.params.zona] = {
        ...(base[route.params.zona] ?? {}),
        [form.value.nome]: {
          nome:        form.value.nome.trim(),
          descrizione: form.value.descrizione.trim() || '',
          tipo:        form.value.tipo,
          esposizione: [],
          microclima:  '',
          criticita:   '',
          manutenzione:'',
        }
      }
      return base
    })
    store.sottozone = nuove
    mostraForm.value = false
    form.value = { nome: '', descrizione: '', tipo: 'esterno' }
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
