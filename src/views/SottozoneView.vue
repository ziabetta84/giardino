<template>
  <div>
    <RouterLink :to="`/zone`" class="back-link"><Icon name="back" /> Zone</RouterLink>

    <div class="page-title__row">
      <h1 class="page-title">{{ zona?.nome ?? route.params.zona }} · Sottozone</h1>
      <button type="button" @click="apriNuovo" class="pill">＋ Aggiungi</button>
    </div>

    <!-- Skeleton -->
    <div v-if="store.loading" class="destlist">
      <div v-for="i in 4" :key="i" class="dest">
        <div class="skeleton dest__ic" style="border-radius:50%;"></div>
        <div class="skeleton" style="height:13px;flex:1;max-width:160px;border-radius:6px;"></div>
        <div class="skeleton" style="height:11px;width:56px;border-radius:6px;"></div>
      </div>
    </div>

    <div v-else-if="!sottozone.length" class="empty">
      <Icon name="pin" />
      <p><b>Nessuna sottozona</b>Questa zona non ha ancora sottozone configurate.</p>
      <button type="button" @click="apriNuovo" class="pill" style="margin-top:14px;">＋ Aggiungi una sottozona</button>
    </div>

    <div v-else class="destlist">
      <div v-for="sz in sottozone" :key="sz.nome" class="dest szrow">
        <Icon :name="store.iconaSottozona(route.params.zona, sz.nome)" class="dest__ic" />
        <span class="dest__n szname">{{ sz.nome }}</span>
        <span v-if="sz.tipo" class="dest__c szt">{{ sz.tipo }}</span>
        <span class="dest__c">{{ contaPiante(sz) }} piante</span>
        <div class="szrow__act">
          <button type="button" class="pill-mini" @click="apriModifica(sz)" title="Modifica sottozona" aria-label="Modifica sottozona">
            <Icon name="matita" />
          </button>
          <button type="button" class="pill-mini pill-mini--del" @click="avviaElimina(sz)" title="Elimina sottozona" aria-label="Elimina sottozona">×</button>
        </div>
        <div v-if="sz.esposizione?.length || descrizioneSottozona(sz)" class="szrow__desc">
          <span v-if="sz.esposizione?.length" class="szrow__espo"><Icon name="sole" />{{ sz.esposizione.join(', ') }}</span>
          <span v-if="descrizioneSottozona(sz)" class="szrow__note" v-html="descrizioneSottozona(sz)"></span>
        </div>
      </div>
    </div>

    <!-- Foglio nuova/modifica sottozona -->
    <FoglioLaterale
      :model-value="mostraForm"
      @update:model-value="v => { if (!v) chiudiForm() }"
      :titolo="modificaOriginale ? 'Modifica sottozona' : 'Nuova sottozona'"
    >
      <div v-if="mostraForm" class="foglio-form">
        <input v-model="form.nome" placeholder="Nome *" class="form-input" style="margin-bottom:10px;">
        <MiniEditor v-model="form.descrizione" placeholder="Descrizione (opzionale)" />
        <p v-if="errore" style="font-size:11px;color:var(--rose-ink);margin:6px 0 0;">{{ errore }}</p>
        <select v-model="form.tipo" class="form-input" style="margin:10px 0;">
          <option value="esterno">Esterno</option>
          <option value="interno">Interno</option>
        </select>
        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Icona</label>
        <input v-model="filtroIcona" type="text" placeholder="Cerca un'icona…" class="form-input" style="margin-bottom:8px;">
        <div class="icona-box" style="margin-bottom:16px;">
          <template v-for="gruppo in gruppiIconaFiltrati" :key="gruppo.label">
            <p class="icona-gruppo-label">{{ gruppo.label }}</p>
            <div class="icona-griglia">
              <button type="button" v-for="nome in gruppo.icone" :key="nome" class="pill pill-icona"
                :class="{ active: form.icona === nome }"
                :aria-label="nome" :aria-pressed="form.icona === nome" :title="nome"
                @click="form.icona = form.icona === nome ? null : nome">
                <Icon :name="`zona-${nome}`" style="width:18px;height:18px;vertical-align:middle;" />
              </button>
            </div>
          </template>
          <p v-if="!gruppiIconaFiltrati.length" class="icona-vuoto">Nessuna icona trovata.</p>
        </div>
        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Esposizione</label>
        <div style="display:flex;gap:8px;flex-wrap:wrap;">
          <label v-for="dir in ['nord','sud','est','ovest']" :key="dir"
            style="display:flex;align-items:center;gap:6px;font-size:13px;cursor:pointer;">
            <input type="checkbox" :value="dir" v-model="form.esposizione" style="accent-color:var(--sage);">
            {{ dir }}
          </label>
        </div>
        <div class="foglio-actions">
          <button class="btn btn-ghost" @click="chiudiForm" style="min-height:40px;padding:8px 16px;">Annulla</button>
          <button class="btn btn-sage" @click="salva" :disabled="!form.nome.trim() || salvando"
            style="min-height:40px;padding:8px 16px;">
            <Spinner v-if="salvando" /><span v-else>Salva</span>
          </button>
        </div>
      </div>
    </FoglioLaterale>

    <ModalConferma
      :aperto="!!daEliminare"
      titolo="Eliminare questa sottozona?"
      messaggio="Le piante che la referenziano resteranno, senza più sottozona assegnata."
      :caricamento="eliminando"
      :errore="erroreEliminazione"
      @conferma="eliminaSottozona"
      @annulla="daEliminare = null; erroreEliminazione = null"
    />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'
import { ICONE_ZONA_GRUPPI } from '@/composables/useIconeZona'
import MiniEditor from '@/components/MiniEditor.vue'
import ModalConferma from '@/components/ModalConferma.vue'
import FoglioLaterale from '@/components/FoglioLaterale.vue'
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
const filtroIcona = ref('')

const gruppiIconaFiltrati = computed(() => {
  const q = filtroIcona.value.trim().toLowerCase()
  if (!q) return ICONE_ZONA_GRUPPI
  return ICONE_ZONA_GRUPPI
    .map(g => ({ label: g.label, icone: g.icone.filter(nome => nome.includes(q)) }))
    .filter(g => g.icone.length)
})

const zona = computed(() => store.zone?.[route.params.zona] ?? null)
const sottozone = computed(() => {
  const sz = store.sottozone?.[route.params.zona]
  if (!sz) return []
  return Object.values(sz)
})

function contaPiante(sz) {
  if (!store.piante) return 0
  return Object.values(store.piante)
    .filter(p => p.zona === route.params.zona && p.sottozona === sz.nome).length
}

// Non viene ripulito dal markup: MiniEditor ammette solo p/br/b/strong/i/em
// senza attributi e passa sempre da sanitizza() prima del salvataggio, quindi
// è sicuro mostrarlo qui con v-html (vedi commento in MiniEditor.vue) — così
// grassetto/corsivo scritti dall'utente restano visibili anche in lista,
// invece di sparire dietro la sola vista di modifica.
function descrizioneSottozona(sz) {
  return (sz.descrizione || '').trim()
}

function apriNuovo() {
  modificaOriginale.value = null
  form.value = { nome: '', descrizione: '', tipo: 'esterno', esposizione: [], icona: null }
  filtroIcona.value = ''
  errore.value = null
  mostraForm.value = true
}

function apriModifica(sz) {
  modificaOriginale.value = sz.nome
  form.value = { nome: sz.nome, descrizione: sz.descrizione || '', tipo: sz.tipo || 'esterno', esposizione: sz.esposizione ? [...sz.esposizione] : [], icona: sz.icona ?? null }
  filtroIcona.value = ''
  errore.value = null
  mostraForm.value = true
}

function chiudiForm() {
  mostraForm.value = false
  filtroIcona.value = ''
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
  } finally {
    eliminando.value = false
  }
}
</script>

<style scoped>
.szrow { flex-wrap:wrap; }
.szrow__act { display:flex; gap:6px; flex-wrap:wrap; }
.dest .pill-mini:hover { border-color:var(--sage-light); color:var(--sage); }
.dest .pill-mini svg { width:12px; height:12px; }
.dest .pill-mini--del { color:var(--rose-ink); }
.dest .pill-mini--del:hover { border-color:var(--rose); color:var(--rose-ink); }
.szname { font-family: var(--font-display); min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.szt { text-transform:capitalize; }
.szrow__desc { flex: 1 1 100%; margin: 2px 0 0; display: flex; flex-wrap: wrap; align-items: center; gap: 4px 10px; font: 400 12px/1.5 var(--font-sans); color: var(--ink-soft); }
.szrow__espo { display: inline-flex; align-items: center; gap: 4px; }
.szrow__espo svg { width: 12px; height: 12px; flex: none; }
.szrow__note :deep(p) { display: inline; margin: 0; }
.szrow__note :deep(br) { display: none; }
.icona-box { max-height:220px; overflow-y:auto; padding:8px; border:1px solid var(--cream-dark); border-radius:12px; }
.icona-gruppo-label { font:700 9.5px/1 var(--font-sans); letter-spacing:0.1em; text-transform:uppercase; color:var(--ink-soft); margin:10px 0 6px; }
.icona-gruppo-label:first-child { margin-top:0; }
.icona-griglia { display:grid; grid-template-columns:repeat(auto-fill,minmax(44px,1fr)); gap:4px; }
.icona-vuoto { font:400 12px/1.4 var(--font-sans); color:var(--ink-soft); text-align:center; margin:4px 0; }

</style>
