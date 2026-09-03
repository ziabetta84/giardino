<template>
  <div class="zona-edit-wide">
    <RouterLink to="/zone" style="display:inline-flex;align-items:center;gap:6px;font-size:13px;color:var(--ink-soft);text-decoration:none;margin-bottom:20px;">
      ← Zone
    </RouterLink>

    <h1 class="page-title" style="margin-bottom:20px">
      {{ isNuova ? 'Nuova zona' : 'Modifica zona' }}
    </h1>

    <p v-if="errore" style="font-size:12px;color:var(--rose-dark);background:var(--rose-pale);padding:10px 14px;border-radius:12px;margin-bottom:16px;">
      {{ errore }}
    </p>

    <div style="display:flex;flex-direction:column;gap:10px;">
      <div class="form-card">
        <label class="field-label">Nome *</label>
        <input v-model="form.nome" placeholder="Es. Giardino Nord, Terrazzo…" class="form-input" style="margin-bottom:12px;">

        <label class="field-label">Tipo</label>
        <select v-model="form.tipo" class="form-input">
          <option value="esterno">Esterno</option>
          <option value="interno">Interno</option>
        </select>

        <label class="field-label" style="margin-top:12px">Icona</label>
        <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(30px,1fr));gap:0;max-height:140px;overflow-y:auto;padding:6px;border:1px solid var(--cream-dark);border-radius:10px;">
          <button type="button" v-for="nome in ICONE_ZONA" :key="nome" class="pill pill-icona"
            :class="{ active: form.icona === nome }"
            @click="form.icona = form.icona === nome ? null : nome">
            <Icon :name="`zona-${nome}`" style="width:18px;height:18px;vertical-align:middle;" />
          </button>
        </div>
      </div>

      <div class="form-card">
        <label class="field-label">Descrizione</label>
        <MiniEditor v-model="form.descrizione" placeholder="Descrizione breve della zona…" />

        <label class="field-label" style="margin-top:12px">Microclima</label>
        <MiniEditor v-model="form.microclima" placeholder="Caratteristiche di luce, temperatura, umidità…" />
      </div>

      <div class="form-card">
        <label class="field-label">Esposizione</label>
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
        <Spinner v-if="salvando" />{{ salvando ? 'Salvataggio…' : (isNuova ? 'Aggiungi zona' : 'Salva modifiche') }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'
import { ICONE_ZONA } from '@/composables/useIconeZona'
import MiniEditor from '@/components/MiniEditor.vue'
import Spinner from '@/components/Spinner.vue'
import Icon from '@/components/Icon.vue'

const route  = useRoute()
const router = useRouter()
const store  = useDatiStore()
const supabase = useSupabase()

const isNuova  = computed(() => !route.params.zona)
const salvando = ref(false)
const errore   = ref(null)

const form = ref({
  nome: '', tipo: 'esterno', descrizione: '', microclima: '', esposizione: [], icona: null
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
      icona:       z.icona       ?? null,
    }
  }
})

async function salva() {
  if (!form.value.nome.trim() || salvando.value) return
  salvando.value = true
  errore.value = null
  const idOriginale = isNuova.value ? null : store.zone?.[route.params.zona]?.id
  const riga = {
    nome:        form.value.nome.trim(),
    tipo:        form.value.tipo,
    descrizione: form.value.descrizione.trim() || '',
    microclima:  form.value.microclima.trim()  || '',
    esposizione: form.value.esposizione,
    icona:       form.value.icona,
  }
  try {
    let salvata
    if (idOriginale) {
      const { data, error } = await supabase.from('zone').update(riga).eq('id', idOriginale).select().single()
      if (error) throw error
      salvata = data
    } else {
      const { data, error } = await supabase.from('zone').insert(riga).select().single()
      if (error) throw error
      salvata = data
    }

    const rinominata = !isNuova.value && route.params.zona !== salvata.nome
    const nuoveZone = { ...store.zone }
    if (rinominata) delete nuoveZone[route.params.zona]
    nuoveZone[salvata.nome] = {
      id: salvata.id, nome: salvata.nome, descrizione: salvata.descrizione,
      esposizione: salvata.esposizione, microclima: salvata.microclima,
      criticita: salvata.criticita, manutenzione: salvata.manutenzione, tipo: salvata.tipo,
      icona: salvata.icona,
    }
    store.zone = nuoveZone

    // Un rename lascia store.sottozone (anch'esso indicizzato per nome zona)
    // e store.piante[*].zona ancora sotto il vecchio nome: più semplice e
    // sicuro ricaricare tutto da Supabase che rincollare a mano ogni chiave
    // derivata, con il rischio di dimenticarne una.
    if (rinominata) await store.aggiorna()

    router.push('/zone')
  } catch (e) {
    errore.value = e.message || 'Errore durante il salvataggio della zona.'
  } finally {
    salvando.value = false
  }
}
</script>
