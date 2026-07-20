<template>
  <div>
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;">
      <h1 class="title-display gradient-title" style="font-size:1.9rem;font-weight:800;">Zone</h1>
      <RouterLink to="/zone/nuova" class="btn btn-rose" style="text-decoration:none;">＋ Aggiungi</RouterLink>
    </div>

    <!-- Skeleton -->
    <div v-if="store.loading" class="zone-grid">
      <div v-for="i in 6" :key="i" class="card" style="padding:18px;min-width:0;">
        <div style="display:flex;justify-content:space-between;margin-bottom:10px;">
          <div class="skeleton" style="height:28px;width:28px;border-radius:50%;"></div>
          <div class="skeleton" style="height:20px;width:60px;border-radius:999px;"></div>
        </div>
        <div class="skeleton" style="height:15px;width:70%;margin-bottom:8px;"></div>
        <div class="skeleton" style="height:11px;width:90%;margin-bottom:4px;"></div>
        <div class="skeleton" style="height:11px;width:75%;margin-bottom:14px;"></div>
        <div class="skeleton" style="height:36px;border-radius:10px;"></div>
      </div>
    </div>

    <div v-else-if="!zoneList.length" style="text-align:center;padding:60px 0;color:var(--ink-faint);">
      <div style="font-size:40px;margin-bottom:12px;">📍</div>
      <p style="color:var(--ink-soft);">Nessuna zona ancora configurata</p>
    </div>

    <div v-else class="zone-grid">
      <div v-for="z in zoneList" :key="z.key" class="card hover-card" style="padding:18px;min-width:0;">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:10px;">
          <span style="font-size:26px;">{{ z.emoji }}</span>
          <span class="badge badge-gold">{{ contaPiante(z.key) }} piante</span>
        </div>
        <h3 class="title-display" style="font-size:16px;font-weight:600;text-transform:capitalize;margin-bottom:4px;">
          {{ z.nome }}
        </h3>
        <p style="font-size:11px;color:var(--ink-soft);line-height:1.6;margin-bottom:14px;">{{ descrizioneBreve(z) }}</p>
        <div class="zone-card-actions">
          <RouterLink :to="`/piante?zona=${z.key}`" class="btn btn-sage" style="flex:1;padding:8px;font-size:12px;border-radius:10px;text-decoration:none;min-height:38px;">
            Piante →
          </RouterLink>
          <RouterLink :to="`/zone/${z.key}/sottozone`" class="btn btn-ghost" style="padding:8px 12px;font-size:12px;border-radius:10px;text-decoration:none;min-height:38px;">
            Sottozone
          </RouterLink>
          <RouterLink :to="`/zone/${z.key}/modifica`" class="btn btn-ghost" style="padding:8px 10px;font-size:13px;border-radius:10px;text-decoration:none;min-height:38px;">
            ✏️
          </RouterLink>
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
/* 2 colonne su schermi larghi; sotto i 640px (soglia mobile già usata nel
   resto dell'app) una sola colonna: con descrizione + 3 bottoni azione,
   il contenuto della card non si restringe a sufficienza per stare in metà
   di uno schermo stretto (grid non riduce le colonne sotto il min-content
   dei figli), causando overflow orizzontale su telefono. */
.zone-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
}
.zone-card-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
@media (max-width: 640px) {
  .zone-grid {
    grid-template-columns: 1fr;
  }
}
</style>

<script setup>
import { computed, ref } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'
import ModalConferma from '@/components/ModalConferma.vue'

const store      = useDatiStore()
const { saveJSON } = useApi()
const daEliminare  = ref(null)
const eliminando   = ref(false)

const EMOJI_ZONE = {
  scivolo:'🏔️', vialetto:'🚶', est:'🌅', crinale:'🌄', orto:'🥕', casa:'🏠'
}

const zoneList = computed(() => {
  if (!store.zone) return []
  return Object.entries(store.zone)
    .map(([key, z]) => ({ key, ...z, emoji: EMOJI_ZONE[key] ?? '🌿' }))
    .sort((a, b) => (a.nome ?? a.key).localeCompare(b.nome ?? b.key))
})

function descrizioneBreve(z) {
  const testo = z.descrizione || z.microclima
  if (!testo) return '—'
  const pulito = testo.replace(/<[^>]+>/g, '')
  return pulito.length > 150 ? pulito.slice(0, 150) + '…' : pulito
}

function contaPiante(zonaKey) {
  if (!store.piante) return 0
  return Object.values(store.piante).filter(p => p.zona === zonaKey).length
}

async function eliminaZona() {
  if (!daEliminare.value) return
  eliminando.value = true
  const zonaKey = daEliminare.value
  try {
    const nuoveZone = await saveJSON('zone.json', (correnti) => {
      const base = { ...(correnti ?? store.zone) }
      delete base[zonaKey]
      return base
    })
    store.zone = nuoveZone

    // Elimina sottozone collegate
    if (store.sottozone?.[zonaKey]) {
      const nuoveSottozone = await saveJSON('sottozone.json', (correnti) => {
        const base = { ...(correnti ?? store.sottozone) }
        delete base[zonaKey]
        return base
      })
      store.sottozone = nuoveSottozone
    }
    daEliminare.value = null
  } finally {
    eliminando.value = false
  }
}
</script>
