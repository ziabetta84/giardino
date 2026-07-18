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
        <div style="display:flex;flex-direction:column;gap:8px;margin-bottom:24px;">
          <div v-for="item in daFare" :key="item.key" class="card"
            style="display:flex;align-items:center;gap:12px;padding:12px 16px;border-color:var(--rose-light);background:var(--rose-pale);">
            <div style="width:40px;height:40px;border-radius:12px;background:var(--rose-light);display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;">
              {{ icona(item.tipo) }}
            </div>
            <div style="flex:1;min-width:0;">
              <div class="title-serif" style="font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
                {{ item.nomeSpecie }}
              </div>
              <div style="font-size:11px;color:var(--rose-dark);margin-top:2px;">{{ item.label }}</div>
            </div>
            <button @click="registra(item)" :disabled="salvando === item.key" class="btn btn-rose"
              style="font-size:11px;padding:5px 10px;min-height:30px;flex-shrink:0;">
              {{ salvando === item.key ? '⏳' : '✓ Fatto' }}
            </button>
          </div>
        </div>
      </template>

      <!-- In scadenza -->
      <template v-if="inScadenza.length">
        <p class="section-label">🕐 In scadenza (entro 3 giorni)</p>
        <div style="display:flex;flex-direction:column;gap:8px;margin-bottom:24px;">
          <div v-for="item in inScadenza" :key="item.key" class="card"
            style="display:flex;align-items:center;gap:12px;padding:12px 16px;">
            <div style="width:40px;height:40px;border-radius:12px;background:var(--gold-pale);display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;">
              {{ icona(item.tipo) }}
            </div>
            <div style="flex:1;min-width:0;">
              <div class="title-serif" style="font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
                {{ item.nomeSpecie }}
              </div>
              <div style="font-size:11px;color:var(--ink-soft);margin-top:2px;">{{ item.label }}</div>
            </div>
            <button @click="registra(item)" :disabled="salvando === item.key" class="btn btn-ghost"
              style="font-size:11px;padding:5px 10px;min-height:30px;flex-shrink:0;">
              {{ salvando === item.key ? '⏳' : '✓ Fatto' }}
            </button>
          </div>
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

const store    = useDatiStore()
const { saveJSON } = useApi()
const salvando = ref(null)

const dataOggi = new Date().toLocaleDateString('it-IT', { weekday:'long', day:'numeric', month:'long' })

function icona(tipo) {
  return tipo === 'irrigazione' ? '💧' : tipo === 'concimazione' ? '🌱' : '✂️'
}

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

async function registra(item) {
  if (salvando.value) return
  salvando.value = item.key
  try {
    const nuove = { ...store.piante }
    nuove[item.piantaId] = {
      ...nuove[item.piantaId],
      ultima_cura: {
        ...nuove[item.piantaId].ultima_cura,
        [item.tipo]: new Date().toISOString().split('T')[0],
      }
    }
    await saveJSON('piante.json', nuove)
    store.piante = nuove
  } finally {
    salvando.value = null
  }
}
</script>
