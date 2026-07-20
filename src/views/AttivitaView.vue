<template>
  <div>
    <h1 class="title-display gradient-title" style="font-size:1.9rem;font-weight:800;margin-bottom:6px;">Attività</h1>
    <p style="font-size:13px;color:var(--ink-soft);margin-bottom:20px;">{{ dataOggi }}</p>

    <!-- Skeleton -->
    <div v-if="store.loading" style="display:flex;flex-direction:column;gap:8px;">
      <div v-for="i in 4" :key="i" class="card" style="padding:14px 16px;display:flex;align-items:center;gap:12px;">
        <div class="skeleton" style="width:40px;height:40px;border-radius:12px;flex-shrink:0;"></div>
        <div style="flex:1;display:flex;flex-direction:column;gap:5px;">
          <div class="skeleton" style="height:13px;width:50%;"></div>
          <div class="skeleton" style="height:11px;width:70%;"></div>
        </div>
        <div class="skeleton" style="width:70px;height:28px;border-radius:8px;"></div>
      </div>
    </div>

    <template v-else>
      <!-- Da fare -->
      <template v-if="daFare.length">
        <p class="section-label">⚠ Da fare</p>
        <div style="margin-bottom:24px;">
          <AttivitaGruppoZona
            v-for="gruppo in gruppiDaFare"
            :key="gruppo.chiave"
            :gruppo="gruppo"
            variante="urgente"
            :salvando="salvando"
            :salvando-gruppo="salvandoGruppo"
            @registra="registra"
            @registra-gruppo="registraGruppo"
          />
        </div>
      </template>

      <!-- In scadenza -->
      <template v-if="inScadenza.length">
        <p class="section-label">🕐 In scadenza (entro 3 giorni)</p>
        <div style="margin-bottom:24px;">
          <AttivitaGruppoZona
            v-for="gruppo in gruppiInScadenza"
            :key="gruppo.chiave"
            :gruppo="gruppo"
            variante="scadenza"
            :salvando="salvando"
            :salvando-gruppo="salvandoGruppo"
            @registra="registra"
            @registra-gruppo="registraGruppo"
          />
        </div>
      </template>

      <!-- Tutto ok -->
      <div v-if="!daFare.length && !inScadenza.length" style="text-align:center;padding:60px 20px;color:var(--ink-faint);">
        <div style="font-size:48px;margin-bottom:12px;">🌸</div>
        <p class="title-serif" style="font-size:16px;color:var(--sage-dark);font-weight:600;">Tutto in ordine!</p>
        <p style="font-size:13px;margin-top:4px;">Nessuna cura urgente oggi</p>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'
import { valutaCura } from '@/composables/useCure'
import AttivitaGruppoZona from '@/components/AttivitaGruppoZona.vue'
import { raggruppaPerZona } from '@/utils/raggruppaAttivita'

const store    = useDatiStore()
const { saveJSON } = useApi()
const salvando = ref(null)
const salvandoGruppo = ref(null)

const dataOggi = new Date().toLocaleDateString('it-IT', { weekday:'long', day:'numeric', month:'long' })

const attivita = computed(() => {
  if (!store.piante) return []
  const items = []
  for (const [id, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie] ?? null
    const nomeSpecie = sp?.nome ?? p.specie
    for (const tipo of ['irrigazione', 'concimazione', 'potatura']) {
      const c = valutaCura(p, sp, tipo)
      if (c.giorni !== null) {
        items.push({ key: `${id}-${tipo}`, piantaId: id, tipo, nomeSpecie, label: c.label, giorni: c.giorni, urgente: c.urgente })
      }
    }
  }
  return items
})

const daFare = computed(() => attivita.value.filter(i => i.urgente).sort((a, b) => a.giorni - b.giorni))
const inScadenza = computed(() => attivita.value.filter(i => !i.urgente && i.giorni !== null && i.giorni <= 3).sort((a, b) => a.giorni - b.giorni))

const gruppiDaFare = computed(() => raggruppaPerZona(daFare.value, store.piante))
const gruppiInScadenza = computed(() => raggruppaPerZona(inScadenza.value, store.piante))

async function registra(item) {
  if (salvando.value || salvandoGruppo.value) return
  salvando.value = item.key
  try {
    const nuove = await saveJSON('piante.json', (correnti) => {
      const base = { ...(correnti ?? store.piante) }
      const piantaEsistente = base[item.piantaId] || {}
      base[item.piantaId] = {
        ...piantaEsistente,
        ultima_cura: {
          ...(piantaEsistente.ultima_cura || {}),
          [item.tipo]: new Date().toISOString().split('T')[0],
        }
      }
      return base
    })
    store.piante = nuove
  } finally {
    salvando.value = null
  }
}

async function registraGruppo(gruppo) {
  if (salvandoGruppo.value || salvando.value) return
  salvandoGruppo.value = gruppo.chiave
  try {
    const oggi = new Date().toISOString().split('T')[0]
    const nuove = await saveJSON('piante.json', (correnti) => {
      const base = { ...(correnti ?? store.piante) }
      for (const item of gruppo.items) {
        const piantaEsistente = base[item.piantaId] || {}
        base[item.piantaId] = {
          ...piantaEsistente,
          ultima_cura: { ...(piantaEsistente.ultima_cura || {}), [item.tipo]: oggi },
        }
      }
      return base
    })
    store.piante = nuove
  } finally {
    salvandoGruppo.value = null
  }
}
</script>
