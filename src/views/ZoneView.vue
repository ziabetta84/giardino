<template>
  <div>
    <div class="page-title__row">
      <h1 class="page-title">Zone</h1>
      <RouterLink to="/zone/nuova" class="pill">＋ Aggiungi</RouterLink>
    </div>

    <p v-if="erroreEliminazione" style="font-size:12px;color:var(--rose-dark);background:var(--rose-pale);padding:10px 14px;border-radius:12px;margin-bottom:16px;">
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
          <RouterLink :to="`/zone/${z.key}/modifica`" class="pill-mini" title="Modifica zona" aria-label="Modifica zona">
            <Icon name="matita" />
          </RouterLink>
          <button type="button" @click="daEliminare = z.key" class="pill-mini pill-mini--del" title="Elimina zona" aria-label="Elimina zona">×</button>
        </div>
      </div>
    </div>

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
a.pill { display:inline-flex; align-items:center; text-decoration:none; }
.zrow { flex-wrap:wrap; }
.zrow__main { display:flex; align-items:center; gap:11px; flex:1 1 100%; min-width:0; text-decoration:none; }
.zrow__main .dest__chev { transform: rotate(180deg); }
.zrow__act { display:flex; gap:6px; flex-wrap:wrap; padding-bottom:4px; }
.zname { text-transform:capitalize; }
.zrow__act .pill-mini { cursor:pointer; text-decoration:none; display:inline-flex; align-items:center; gap:4px; }
.zrow__act .pill-mini:hover { border-color:var(--sage-light); color:var(--sage); }
.zrow__act .pill-mini svg { width:12px; height:12px; }
.zrow__act .pill-mini--del { color:var(--rose-dark); }
.zrow__act .pill-mini--del:hover { border-color:var(--rose); color:var(--rose-dark); }
.zrow__desc { flex: 1 1 100%; margin: 2px 0 0; font: 400 12px/1.5 var(--font-sans); color: var(--ink-soft); }
</style>

<script setup>
import { computed, ref } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'
import ModalConferma from '@/components/ModalConferma.vue'
import Icon from '@/components/Icon.vue'

const store      = useDatiStore()
const supabase   = useSupabase()
const daEliminare  = ref(null)
const eliminando   = ref(false)
const erroreEliminazione = ref(null)

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
