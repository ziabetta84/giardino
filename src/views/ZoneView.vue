<template>
  <div>
    <div class="page-title__row">
      <h1 class="page-title">Zone</h1>
      <button type="button" @click="apriNuovo" class="pill">＋ Aggiungi</button>
    </div>

    <p v-if="erroreEliminazione" style="font-size:12px;color:var(--rose-ink);background:var(--rose-pale);padding:10px 14px;border-radius:12px;margin-bottom:16px;">
      {{ erroreEliminazione }}
    </p>

    <!-- Skeleton -->
    <div v-if="store.loading" class="destlist">
      <div v-for="i in 6" :key="i" class="dest">
        <div class="skeleton dest__ic" style="border-radius:50%;"></div>
        <div class="skeleton" style="height:13px;flex:1;max-width:160px;border-radius:6px;"></div>
        <div class="skeleton" style="height:11px;width:56px;border-radius:6px;"></div>
      </div>
    </div>

    <div v-else-if="!zoneList.length" class="empty">
      <Icon name="pin" />
      <p><b>Nessuna zona</b>Non hai ancora configurato nessuna zona del giardino.</p>
    </div>

    <div v-else class="destlist">
      <div v-for="z in zoneList" :key="z.key" class="dest zrow">
        <RouterLink :to="`/piante?zona=${z.key}`" class="zrow__main">
          <Icon :name="store.iconaZona(z.key)" class="dest__ic" />
          <span class="dest__n zname">{{ z.nome ?? z.key }}</span>
          <span class="dest__c">{{ contaPiante(z.key) }} piante</span>
          <Icon name="back" class="dest__chev" />
        </RouterLink>
        <p v-if="descrizioneZona(z)" class="zrow__desc">{{ descrizioneZona(z) }}</p>
        <div class="zrow__act">
          <RouterLink :to="`/zone/${z.key}/sottozone`" class="pill-mini">Sottozone</RouterLink>
          <button type="button" @click="apriModifica(z)" class="pill-mini" title="Modifica zona" aria-label="Modifica zona">
            <Icon name="matita" />
          </button>
          <button type="button" @click="daEliminare = z.key" class="pill-mini pill-mini--del" title="Elimina zona" aria-label="Elimina zona">×</button>
        </div>
      </div>
    </div>

    <!-- Foglio nuova/modifica zona -->
    <FoglioLaterale
      :model-value="mostraForm"
      @update:model-value="v => { if (!v) chiudiForm() }"
      :titolo="modificaOriginale ? 'Modifica zona' : 'Nuova zona'"
    >
      <div v-if="mostraForm" class="foglio-form">
        <input v-model="form.nome" placeholder="Nome *" class="form-input" style="margin-bottom:10px;">
        <p v-if="errore" style="font-size:11px;color:var(--rose-ink);margin:0 0 10px;">{{ errore }}</p>
        <select v-model="form.tipo" class="form-input" style="margin-bottom:12px;">
          <option value="esterno">Esterno</option>
          <option value="interno">Interno</option>
        </select>
        <label class="field-label">Descrizione</label>
        <MiniEditor v-model="form.descrizione" placeholder="Descrizione breve della zona…" />
        <label class="field-label" style="margin-top:12px">Microclima</label>
        <MiniEditor v-model="form.microclima" placeholder="Caratteristiche di luce, temperatura, umidità…" />
        <label class="field-label" style="margin-top:12px">Icona</label>
        <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(30px,1fr));gap:0;max-height:140px;overflow-y:auto;padding:6px;border:1px solid var(--cream-dark);border-radius:10px;margin-top:6px;">
          <button type="button" v-for="nome in ICONE_ZONA" :key="nome" class="pill pill-icona"
            :class="{ active: form.icona === nome }"
            @click="form.icona = form.icona === nome ? null : nome">
            <Icon :name="`zona-${nome}`" style="width:18px;height:18px;vertical-align:middle;" />
          </button>
        </div>
        <label class="field-label" style="margin-top:12px">Esposizione</label>
        <div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:4px;">
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
      titolo="Eliminare questa zona?"
      messaggio="Verranno eliminate anche tutte le sottozone collegate."
      :caricamento="eliminando"
      @conferma="eliminaZona"
      @annulla="daEliminare = null"
    />
  </div>
</template>

<style scoped>
.zrow { flex-wrap:wrap; }
.zrow__main { display:flex; align-items:center; gap:11px; flex:1 1 100%; min-width:0; text-decoration:none; }
.zrow__main .dest__chev { transform: rotate(180deg); }
.zrow__act { display:flex; gap:6px; flex-wrap:wrap; padding-bottom:4px; }
.zname { text-transform:capitalize; }
.zrow__act .pill-mini { text-decoration:none; display:inline-flex; align-items:center; gap:4px; }
.zrow__act .pill-mini:hover { border-color:var(--sage-light); color:var(--sage); }
.zrow__act .pill-mini svg { width:12px; height:12px; }
.zrow__act .pill-mini--del { color:var(--rose-ink); }
.zrow__act .pill-mini--del:hover { border-color:var(--rose); color:var(--rose-ink); }
.zrow__desc { flex: 1 1 100%; margin: 2px 0 0; font: 400 12px/1.5 var(--font-sans); color: var(--ink-soft); }
</style>

<script setup>
import { computed, ref } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'
import { ICONE_ZONA } from '@/composables/useIconeZona'
import MiniEditor from '@/components/MiniEditor.vue'
import Spinner from '@/components/Spinner.vue'
import FoglioLaterale from '@/components/FoglioLaterale.vue'
import ModalConferma from '@/components/ModalConferma.vue'
import Icon from '@/components/Icon.vue'

const store      = useDatiStore()
const supabase   = useSupabase()
const daEliminare  = ref(null)
const eliminando   = ref(false)
const erroreEliminazione = ref(null)

const mostraForm = ref(false)
const salvando   = ref(false)
const errore     = ref(null)
// Nome originale della zona in modifica (null quando se ne crea una nuova):
// store.zone è indicizzato per nome, serve per sapere quale chiave
// aggiornare/rinominare.
const modificaOriginale = ref(null)
const form = ref({ nome: '', tipo: 'esterno', descrizione: '', microclima: '', esposizione: [], icona: null })

function formVuoto() {
  return { nome: '', tipo: 'esterno', descrizione: '', microclima: '', esposizione: [], icona: null }
}

function apriNuovo() {
  modificaOriginale.value = null
  form.value = formVuoto()
  errore.value = null
  mostraForm.value = true
}

function apriModifica(z) {
  modificaOriginale.value = z.key
  form.value = {
    nome:        z.nome ?? z.key,
    tipo:        z.tipo ?? 'esterno',
    descrizione: z.descrizione ?? '',
    microclima:  z.microclima ?? '',
    esposizione: z.esposizione ? [...z.esposizione] : [],
    icona:       z.icona ?? null,
  }
  errore.value = null
  mostraForm.value = true
}

function chiudiForm() {
  mostraForm.value = false
  modificaOriginale.value = null
  form.value = formVuoto()
  errore.value = null
}

async function salva() {
  if (!form.value.nome.trim() || salvando.value) return
  const nomeOriginale = modificaOriginale.value
  const nomeNuovo = form.value.nome.trim()

  // Non sovrascrivere silenziosamente un'altra zona già esistente con lo
  // stesso nome (perderebbe criticita/manutenzione non gestiti da questo form).
  if (store.zone?.[nomeNuovo] && nomeNuovo !== nomeOriginale) {
    errore.value = 'Una zona con questo nome esiste già.'
    return
  }
  errore.value = null

  salvando.value = true
  try {
    const idOriginale = nomeOriginale ? (store.zone?.[nomeOriginale]?.id ?? null) : null
    const riga = {
      nome:        nomeNuovo,
      tipo:        form.value.tipo,
      descrizione: form.value.descrizione.trim() || '',
      microclima:  form.value.microclima.trim()  || '',
      esposizione: form.value.esposizione,
      icona:       form.value.icona,
    }

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

    const rinominata = nomeOriginale && nomeOriginale !== salvata.nome
    const nuoveZone = { ...store.zone }
    if (rinominata) delete nuoveZone[nomeOriginale]
    nuoveZone[salvata.nome] = {
      id: salvata.id, nome: salvata.nome, descrizione: salvata.descrizione,
      esposizione: salvata.esposizione, microclima: salvata.microclima,
      criticita: salvata.criticita, manutenzione: salvata.manutenzione, tipo: salvata.tipo,
      icona: salvata.icona,
    }
    store.zone = nuoveZone

    // Un rename lascia store.sottozone (indicizzato per nome zona) e
    // store.piante[*].zona sotto il vecchio nome: ricaricare tutto da
    // Supabase è più sicuro che rincollare a mano ogni chiave derivata.
    if (rinominata) await store.aggiorna()

    chiudiForm()
  } catch (e) {
    errore.value = e.message || 'Errore durante il salvataggio della zona.'
  } finally {
    salvando.value = false
  }
}

const zoneList = computed(() => {
  if (!store.zone) return []
  return Object.entries(store.zone)
    .map(([key, z]) => ({ key, ...z }))
    .sort((a, b) => (a.nome ?? a.key).localeCompare(b.nome ?? b.key))
})

function descrizioneZona(z) {
  return (z.descrizione || z.microclima || '').replace(/<[^>]*>/g, '').trim()
}

function contaPiante(zonaKey) {
  if (!store.piante) return 0
  return Object.values(store.piante).filter(p => p.zona === zonaKey).length
}

async function eliminaZona() {
  if (!daEliminare.value) return
  eliminando.value = true
  const zonaKey = daEliminare.value
  const idZona = store.zone?.[zonaKey]?.id
  erroreEliminazione.value = null
  try {
    const { error } = await supabase.from('zone').delete().eq('id', idZona)
    if (error) {
      // Violazione della FK piante.zona_id (on delete restrict): la zona
      // contiene ancora piante. A differenza del vecchio comportamento su
      // JSON (cancellava comunque, lasciando le piante orfane), il database
      // ora blocca l'operazione esplicitamente.
      if (error.code === '23503') {
        erroreEliminazione.value = 'Non puoi eliminare una zona che contiene ancora piante: spostale o eliminale prima.'
        daEliminare.value = null
        return
      }
      throw error
    }

    const nuoveZone = { ...store.zone }
    delete nuoveZone[zonaKey]
    store.zone = nuoveZone

    // Le sottozone collegate sono cancellate dal database stesso
    // (sottozone.zona_id on delete cascade): qui aggiorniamo solo lo store.
    if (store.sottozone?.[zonaKey]) {
      const nuoveSottozone = { ...store.sottozone }
      delete nuoveSottozone[zonaKey]
      store.sottozone = nuoveSottozone
    }
    daEliminare.value = null
  } catch (e) {
    erroreEliminazione.value = e.message || 'Errore durante l\'eliminazione della zona.'
    daEliminare.value = null
  } finally {
    eliminando.value = false
  }
}
</script>
