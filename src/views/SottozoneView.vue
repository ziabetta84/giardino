<template>
  <div>
    <RouterLink :to="`/zone`" style="display:inline-flex;align-items:center;gap:6px;font-size:13px;color:var(--ink-soft);text-decoration:none;margin-bottom:20px;">
      ← Zone
    </RouterLink>

    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;">
      <div>
        <h1 class="title-display gradient-title title-settle" style="font-size:1.7rem;font-weight:800;">
          {{ zona?.nome ?? route.params.zona }}
        </h1>
        <p style="font-size:13px;color:var(--ink-soft);margin-top:2px;">Sottozone</p>
      </div>
      <button @click="apriNuovo" class="btn btn-rose" style="padding:8px 14px;">＋ Aggiungi</button>
    </div>

    <p v-if="erroreEliminazione" style="font-size:12px;color:var(--rose-dark);background:var(--rose-pale);padding:10px 14px;border-radius:12px;margin-bottom:16px;">
      {{ erroreEliminazione }}
    </p>

    <div v-if="!sottozone.length" style="text-align:center;padding:60px 20px;color:var(--ink-faint);">
      <div style="width:56px;height:56px;border-radius:50%;background:var(--acqua-tile);display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
        <Icon name="pin" style="width:24px;height:24px;" />
      </div>
      <p style="color:var(--ink-soft);font-size:13px;">Nessuna sottozona configurata</p>
    </div>

    <div v-else style="display:flex;flex-direction:column;gap:10px;">
      <div v-for="sz in sottozone" :key="sz.nome" class="card" style="padding:16px;">
        <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:8px;margin-bottom:8px;">
          <h3 class="title-serif" style="font-size:15px;font-weight:600;display:flex;align-items:center;gap:8px;">
            <Icon :name="sz.icona ? `zona-${sz.icona}` : 'pin'" style="width:16px;height:16px;flex-shrink:0;" />{{ sz.nome }}
          </h3>
          <div style="display:flex;gap:8px;align-items:center;">
            <span v-if="sz.tipo" class="badge" :style="sz.tipo === 'interno' ? 'background:var(--sage-pale);color:var(--sage-dark);' : 'background:var(--gold-pale);color:var(--gold-dark);'">
              {{ sz.tipo }}
            </span>
            <button type="button" class="icon-btn" @click="apriModifica(sz)" title="Modifica sottozona"><Icon name="matita" style="width:13px;height:13px;" /></button>
            <button type="button" class="icon-btn" @click="avviaElimina(sz)" title="Elimina sottozona" aria-label="Elimina sottozona" style="color:var(--rose-dark);font-size:16px;line-height:1;">×</button>
          </div>
        </div>
        <div v-if="sz.esposizione?.length" style="display:flex;align-items:center;gap:4px;font-size:11px;color:var(--ink-faint);margin-bottom:6px;">
          <Icon name="sole" style="width:12px;height:12px;flex-shrink:0;" />{{ sz.esposizione.join(', ') }}
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
          <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Icona</label>
          <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(30px,1fr));gap:0;max-height:140px;overflow-y:auto;padding:6px;border:1px solid var(--cream-dark);border-radius:10px;margin-bottom:16px;">
            <button type="button" v-for="nome in ICONE_ZONA" :key="nome" class="pill pill-icona"
              :class="{ active: form.icona === nome }"
              @click="form.icona = form.icona === nome ? null : nome">
              <Icon :name="`zona-${nome}`" style="width:18px;height:18px;vertical-align:middle;" />
            </button>
          </div>
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
              <Spinner v-if="salvando" /><span v-else>Salva</span>
            </button>
          </div>
        </div>
      </div>
    </Teleport>

    <ModalConferma
      :aperto="!!daEliminare"
      titolo="Eliminare questa sottozona?"
      messaggio="Le piante che la referenziano resteranno, senza più sottozona assegnata."
      :caricamento="eliminando"
      @conferma="eliminaSottozona"
      @annulla="daEliminare = null"
    />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'
import { ICONE_ZONA } from '@/composables/useIconeZona'
import MiniEditor from '@/components/MiniEditor.vue'
import ModalConferma from '@/components/ModalConferma.vue'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const route = useRoute()
const store = useDatiStore()
const supabase = useSupabase()

const mostraForm = ref(false)
const salvando   = ref(false)
const errore     = ref(null)
const form = ref({ nome: '', descrizione: '', tipo: 'esterno', esposizione: [], icona: null })
const daEliminare  = ref(null)
const eliminando   = ref(false)
const erroreEliminazione = ref(null)
// Nome originale della sottozona in modifica (null quando si sta creando una
// nuova sottozona): serve per sapere quale chiave aggiornare/rinominare in
// store.sottozone, dato che è indicizzato per nome.
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
  form.value = { nome: '', descrizione: '', tipo: 'esterno', esposizione: [], icona: null }
  errore.value = null
  mostraForm.value = true
}

function apriModifica(sz) {
  modificaOriginale.value = sz.nome
  form.value = { nome: sz.nome, descrizione: sz.descrizione || '', tipo: sz.tipo || 'esterno', esposizione: sz.esposizione ? [...sz.esposizione] : [], icona: sz.icona ?? null }
  errore.value = null
  mostraForm.value = true
}

function chiudiForm() {
  mostraForm.value = false
  modificaOriginale.value = null
  form.value = { nome: '', descrizione: '', tipo: 'esterno', esposizione: [], icona: null }
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
    const esistente = nomeOriginale ? (sottozoneDellaZona[nomeOriginale] ?? {}) : {}
    const riga = {
      nome:        nomeNuovo,
      descrizione: form.value.descrizione.trim() || '',
      tipo:        form.value.tipo,
      esposizione: form.value.esposizione,
      icona:       form.value.icona,
    }

    let salvata
    if (esistente.id) {
      const { data, error } = await supabase.from('sottozone').update(riga).eq('id', esistente.id).select().single()
      if (error) throw error
      salvata = data
    } else {
      const zonaId = store.zone?.[route.params.zona]?.id
      const { data, error } = await supabase.from('sottozone').insert({ ...riga, zona_id: zonaId }).select().single()
      if (error) throw error
      salvata = data
    }

    const rinominata = nomeOriginale && nomeOriginale !== nomeNuovo
    const nuove = { ...store.sottozone }
    const sottozoneZona = { ...(nuove[route.params.zona] ?? {}) }
    if (rinominata) delete sottozoneZona[nomeOriginale]
    sottozoneZona[salvata.nome] = {
      id: salvata.id, nome: salvata.nome, descrizione: salvata.descrizione,
      esposizione: salvata.esposizione, microclima: salvata.microclima,
      criticita: salvata.criticita, manutenzione: salvata.manutenzione, tipo: salvata.tipo,
      icona: salvata.icona,
    }
    nuove[route.params.zona] = sottozoneZona
    store.sottozone = nuove

    // Le piante referenziano sottozona_id (FK): rinominare una sottozona non
    // tocca nessuna pianta lato database. Ma store.piante[*].sottozona è un
    // nome denormalizzato al caricamento (mappaPiante in stores/dati.js) e
    // resterebbe sotto il vecchio nome finché non si ricarica: risolto
    // ricaricando tutto da Supabase, come per il rename di una zona.
    if (rinominata) await store.aggiorna()

    chiudiForm()
  } catch (e) {
    errore.value = e.message || 'Errore durante il salvataggio della sottozona.'
  } finally {
    salvando.value = false
  }
}

function avviaElimina(sz) {
  daEliminare.value = sz
}

async function eliminaSottozona() {
  if (!daEliminare.value) return
  eliminando.value = true
  const sz = daEliminare.value
  erroreEliminazione.value = null
  try {
    const { error } = await supabase.from('sottozone').delete().eq('id', sz.id)
    if (error) throw error

    const nuove = { ...store.sottozone }
    const sottozoneZona = { ...(nuove[route.params.zona] ?? {}) }
    delete sottozoneZona[sz.nome]
    nuove[route.params.zona] = sottozoneZona
    store.sottozone = nuove

    // Le piante in questa sottozona hanno sottozona_id impostato a null dal
    // database (on delete set null): ricarichiamo per riflettere subito il
    // cambiamento anche nel campo denormalizzato store.piante[*].sottozona,
    // stesso motivo del rename più sopra.
    await store.aggiorna()

    daEliminare.value = null
  } catch (e) {
    erroreEliminazione.value = e.message || 'Errore durante l\'eliminazione della sottozona.'
    daEliminare.value = null
  } finally {
    eliminando.value = false
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
