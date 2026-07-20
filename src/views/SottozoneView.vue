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
      <button @click="apriNuovo" class="btn btn-rose" style="padding:8px 14px;">＋ Aggiungi</button>
    </div>

    <div v-if="!sottozone.length" style="text-align:center;padding:60px 20px;color:var(--ink-faint);">
      <div style="font-size:40px;margin-bottom:12px;">🗺️</div>
      <p style="color:var(--ink-soft);font-size:13px;">Nessuna sottozona configurata</p>
    </div>

    <div v-else style="display:flex;flex-direction:column;gap:10px;">
      <div v-for="sz in sottozone" :key="sz.nome" class="card" style="padding:16px;">
        <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:8px;margin-bottom:8px;">
          <h3 class="title-serif" style="font-size:15px;font-weight:600;">{{ sz.nome }}</h3>
          <div style="display:flex;gap:8px;align-items:center;">
            <span v-if="sz.tipo" class="badge" :style="sz.tipo === 'interno' ? 'background:var(--sage-pale);color:var(--sage-dark);' : 'background:var(--gold-pale);color:var(--gold-dark);'">
              {{ sz.tipo }}
            </span>
            <button type="button" class="icon-btn" @click="apriModifica(sz)" title="Modifica sottozona">✏️</button>
          </div>
        </div>
        <div v-if="sz.esposizione?.length" style="font-size:11px;color:var(--ink-faint);margin-bottom:6px;">
          ☀️ {{ sz.esposizione.join(', ') }}
        </div>
        <p v-if="sz.descrizione" style="font-size:12px;color:var(--ink-soft);line-height:1.5;">{{ descrizioneBreve(sz) }}</p>
      </div>
    </div>

    <!-- Form nuova/modifica sottozona -->
    <Teleport to="body">
      <div v-if="mostraForm" class="overlay" @click.self="chiudiForm">
        <div class="modal-box">
          <h3 style="font-family:var(--font-serif);font-size:16px;font-weight:600;margin-bottom:16px;">
            {{ modificaOriginale ? 'Modifica sottozona' : 'Nuova sottozona' }}
          </h3>
          <input v-model="form.nome" placeholder="Nome *" class="form-input" style="margin-bottom:10px;">
          <MiniEditor v-model="form.descrizione" placeholder="Descrizione (opzionale)" />
          <p v-if="errore" style="font-size:11px;color:var(--rose-dark);margin:6px 0 0;">{{ errore }}</p>
          <select v-model="form.tipo" class="form-input" style="margin:10px 0;">
            <option value="esterno">Esterno</option>
            <option value="interno">Interno</option>
          </select>
          <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Esposizione</label>
          <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:16px;">
            <label v-for="dir in ['nord','sud','est','ovest']" :key="dir"
              style="display:flex;align-items:center;gap:6px;font-size:13px;cursor:pointer;">
              <input type="checkbox" :value="dir" v-model="form.esposizione" style="accent-color:var(--sage);">
              {{ dir }}
            </label>
          </div>
          <div style="display:flex;gap:10px;justify-content:flex-end;">
            <button class="btn btn-ghost" @click="chiudiForm" style="min-height:40px;padding:8px 16px;">Annulla</button>
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
import MiniEditor from '@/components/MiniEditor.vue'

const route = useRoute()
const store = useDatiStore()
const { saveJSON } = useApi()

const mostraForm = ref(false)
const salvando   = ref(false)
const errore     = ref(null)
const form = ref({ nome: '', descrizione: '', tipo: 'esterno', esposizione: [] })
// Nome originale della sottozona in modifica (null quando si sta creando una
// nuova sottozona): serve per sapere quale chiave aggiornare/rinominare in
// sottozone.json, dato che è indicizzato per nome.
const modificaOriginale = ref(null)

const zona = computed(() => store.zone?.[route.params.zona] ?? null)
const sottozone = computed(() => {
  const sz = store.sottozone?.[route.params.zona]
  if (!sz) return []
  return Object.values(sz)
})

function descrizioneBreve(sz) {
  const pulito = (sz.descrizione || '').replace(/<[^>]+>/g, '')
  return pulito.length > 150 ? pulito.slice(0, 150) + '…' : pulito
}

function apriNuovo() {
  modificaOriginale.value = null
  form.value = { nome: '', descrizione: '', tipo: 'esterno', esposizione: [] }
  errore.value = null
  mostraForm.value = true
}

function apriModifica(sz) {
  modificaOriginale.value = sz.nome
  form.value = { nome: sz.nome, descrizione: sz.descrizione || '', tipo: sz.tipo || 'esterno', esposizione: sz.esposizione ? [...sz.esposizione] : [] }
  errore.value = null
  mostraForm.value = true
}

function chiudiForm() {
  mostraForm.value = false
  modificaOriginale.value = null
  form.value = { nome: '', descrizione: '', tipo: 'esterno', esposizione: [] }
  errore.value = null
}

async function salva() {
  if (!form.value.nome.trim() || salvando.value) return
  const nomeOriginale = modificaOriginale.value
  const nomeNuovo = form.value.nome.trim()

  // Evita di sovrascrivere silenziosamente un'altra sottozona già esistente
  // con lo stesso nome (perderebbe esposizione/microclima/criticita/
  // manutenzione non gestiti da questo form).
  const sottozoneDellaZona = store.sottozone?.[route.params.zona] ?? {}
  if (sottozoneDellaZona[nomeNuovo] && nomeNuovo !== nomeOriginale) {
    errore.value = 'Una sottozona con questo nome esiste già in questa zona.'
    return
  }
  errore.value = null

  salvando.value = true
  try {
    const nuove = await saveJSON('sottozone.json', (correnti) => {
      const base = { ...(correnti ?? store.sottozone) }
      const sottozoneZona = { ...(base[route.params.zona] ?? {}) }

      // In modifica, riparte dal record esistente (per non perdere
      // esposizione/microclima/criticita/manutenzione, non gestiti da questo
      // form) e lo rimuove dalla vecchia chiave se il nome è cambiato.
      const esistente = nomeOriginale ? (sottozoneZona[nomeOriginale] ?? {}) : {}
      if (nomeOriginale && nomeOriginale !== nomeNuovo) {
        delete sottozoneZona[nomeOriginale]
      }

      sottozoneZona[nomeNuovo] = {
        ...esistente,
        nome:        nomeNuovo,
        descrizione: form.value.descrizione.trim() || '',
        tipo:        form.value.tipo,
        esposizione: form.value.esposizione,
        microclima:  esistente.microclima  ?? '',
        criticita:   esistente.criticita   ?? '',
        manutenzione:esistente.manutenzione ?? '',
      }

      base[route.params.zona] = sottozoneZona
      return base
    })
    store.sottozone = nuove

    // Se il nome è cambiato, aggiorna anche le piante che referenziano la
    // vecchia sottozona: altrimenti resterebbero "orfane" (sottozona
    // inesistente) invece di seguire la rinomina.
    if (nomeOriginale && nomeOriginale !== nomeNuovo) {
      const nuovePiante = await saveJSON('piante.json', (correnti) => {
        const base = { ...(correnti ?? store.piante) }
        for (const id of Object.keys(base)) {
          if (base[id].zona === route.params.zona && base[id].sottozona === nomeOriginale) {
            base[id] = { ...base[id], sottozona: nomeNuovo }
          }
        }
        return base
      })
      store.piante = nuovePiante
    }

    chiudiForm()
  } finally {
    salvando.value = false
  }
}
</script>

<style scoped>
/* Pulsante icona "trasparente": accanto al badge tipo (interno/esterno) uno
   stile .btn-ghost pieno (sfondo tan) creava due "pillole" scure ravvicinate
   che si affollavano visivamente; qui lo sfondo compare solo in hover. */
.icon-btn {
  background: none; border: none; cursor: pointer;
  padding: 4px 6px; border-radius: 8px; font-size: 14px; line-height: 1;
  display: flex; align-items: center; justify-content: center;
  color: var(--ink-soft);
}
.icon-btn:hover {
  background: var(--cream-dark);
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
