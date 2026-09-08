<template>
  <div>
    <RouterLink :to="isNuova ? '/piante' : `/piante/${route.params.id}`" class="back-link">
      <Icon name="back" /> {{ isNuova ? 'Piante' : 'Dettaglio' }}
    </RouterLink>

    <h1 class="page-title" style="margin-bottom:20px">
      {{ isNuova ? 'Nuova pianta' : 'Modifica pianta' }}
    </h1>

    <div style="display:flex;flex-direction:column;gap:10px;">
      <!-- Specie -->
      <SelettoreSpecie v-model="form.specie" />

      <!-- Zona: pillole con icona invece di <select> nativo, come ogni altra
           superficie che mostra una zona nell'app (righe pianta, filtri
           PianteView, ZoneView/SottozoneView) — vedi critica del
           08/09/2026. Il click imposta zona e sottozona insieme (invece di
           un watcher separato) per evitare di azzerare la sottozona quando
           si riclicca la stessa zona già selezionata. -->
      <div class="form-card">
        <label class="field-label">Zona *</label>
        <div v-if="Object.keys(store.zone ?? {}).length" style="display:flex;gap:6px;flex-wrap:wrap;margin-bottom:10px;">
          <button v-for="(z, key) in store.zone ?? {}" :key="key" type="button"
            class="pill pill--acqua" :class="{ active: form.zona === (z.nome ?? key) }"
            :aria-pressed="form.zona === (z.nome ?? key)"
            style="display:inline-flex;align-items:center;gap:5px;"
            @click="selezionaZona(z.nome ?? key)">
            <Icon :name="store.iconaZona(z.nome ?? key)" style="width:13px;height:13px;flex-shrink:0;" />{{ z.nome ?? key }}
          </button>
        </div>
        <p v-else class="field-hint">Nessuna zona ancora creata.</p>

        <template v-if="form.zona">
          <label class="field-label">Sottozona</label>
          <div v-if="sottozoneZona.length" style="display:flex;gap:6px;flex-wrap:wrap;margin-bottom:10px;">
            <button type="button" class="pill" :class="{ active: !form.sottozona }" :aria-pressed="!form.sottozona" @click="form.sottozona = ''">Nessuna</button>
            <button v-for="s in sottozoneZona" :key="s" type="button"
              class="pill pill--acqua" :class="{ active: form.sottozona === s }"
              :aria-pressed="form.sottozona === s"
              style="display:inline-flex;align-items:center;gap:5px;"
              @click="form.sottozona = s">
              <Icon :name="store.iconaSottozona(form.zona, s)" style="width:12px;height:12px;flex-shrink:0;" />{{ s }}
            </button>
          </div>
          <p v-else class="field-hint">Questa zona non ha sottozone.</p>
        </template>

        <label class="field-label">Coltivata in</label>
        <div style="display:flex;gap:6px;flex-wrap:wrap;">
          <button type="button" class="pill" :class="{ active: form.coltivatoIn === 'vaso' }" :aria-pressed="form.coltivatoIn === 'vaso'" style="display:inline-flex;align-items:center;gap:5px;" @click="form.coltivatoIn = 'vaso'"><Icon name="vaso" style="width:16px;height:16px;" />Vaso</button>
          <button type="button" class="pill" :class="{ active: form.coltivatoIn === 'terra' }" :aria-pressed="form.coltivatoIn === 'terra'" style="display:inline-flex;align-items:center;gap:5px;" @click="form.coltivatoIn = 'terra'"><Icon name="terra" style="width:16px;height:16px;" />Terra</button>
          <button type="button" class="pill" :class="{ active: form.coltivatoIn === 'acqua' }" :aria-pressed="form.coltivatoIn === 'acqua'" style="display:inline-flex;align-items:center;gap:5px;" @click="form.coltivatoIn = 'acqua'"><Icon name="acqua" style="width:16px;height:16px;" />Acqua</button>
        </div>
      </div>

      <!-- Varietà e impianto -->
      <div class="form-card">
        <label class="field-label">Varietà</label>
        <input v-model="form.varieta" placeholder="Es. Bianca, Rossa…" class="form-input" style="margin-bottom:10px;">

        <label class="field-label">Data impianto</label>
        <input v-model="form.impianto" type="date" class="form-input" style="margin-bottom:10px;">

        <label class="field-label">Periodo di impianto, se non conosci la data esatta</label>
        <input v-model="form.impianto_circa" placeholder="Es. &quot;circa dal 2016&quot;, &quot;primavera 2025&quot;" class="form-input">
      </div>

      <!-- Note -->
      <div class="form-card">
        <label class="field-label">Note</label>
        <textarea v-model="form.note" placeholder="Osservazioni, caratteristiche particolari…"
          rows="3" class="form-input" style="resize:vertical;font-family:inherit;"></textarea>
      </div>

      <!-- Salva -->
      <p v-if="erroreSalvataggio" class="ep-errore" role="alert">{{ erroreSalvataggio }}</p>
      <button @click="salva" :disabled="!form.specie || !form.zona || salvando" class="btn btn-sage">
        <Spinner v-if="salvando" />{{ salvando ? 'Salvataggio…' : (isNuova ? 'Aggiungi pianta' : 'Salva modifiche') }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { usePianteApi } from '@/composables/usePianteApi'
import SelettoreSpecie from '@/components/SelettoreSpecie.vue'
import Spinner from '@/components/Spinner.vue'
import Icon from '@/components/Icon.vue'

const route  = useRoute()
const router = useRouter()
const store  = useDatiStore()
const pianteApi = usePianteApi()

const isNuova = computed(() => !route.params.id)
const salvando = ref(false)
const erroreSalvataggio = ref(null)

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

// Non un watcher su form.zona: azzerare la sottozona solo quando la zona
// cambia davvero, non anche riselezionando quella già attiva (altrimenti un
// tap ridondante sulla stessa pillola cancellerebbe una scelta già fatta).
function selezionaZona(nome) {
  if (form.value.zona !== nome) form.value.sottozona = ''
  form.value.zona = nome
}

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
  erroreSalvataggio.value = null
  const id = isNuova.value ? `${form.value.specie}-${Date.now()}` : route.params.id
  try {
    await pianteApi.salvaPianta({
      id,
      isNuova: isNuova.value,
      specie: form.value.specie,
      zona: form.value.zona,
      sottozona: form.value.sottozona || null,
      coltivato_in: form.value.coltivatoIn || null,
      varieta: form.value.varieta || '',
      impianto: form.value.impianto || '',
      impianto_circa: form.value.impianto_circa || '',
      note: form.value.note || '',
    })
    router.push(isNuova.value ? '/piante' : `/piante/${id}`)
  } catch {
    erroreSalvataggio.value = 'Non sono riuscito a salvare la pianta. Riprova.'
  } finally {
    salvando.value = false
  }
}
</script>

<style scoped>
.ep-errore { font: 400 12px/1.4 var(--font-sans); color: var(--rose-ink); margin: -2px 2px 0; }
.field-hint { font: 400 12px/1.4 var(--font-sans); color: var(--ink-soft); margin: 0 2px 10px; }
</style>
