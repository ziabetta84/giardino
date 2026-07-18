<template>
  <div>
    <h1 class="title-display gradient-title" style="font-size:1.9rem;font-weight:800;margin-bottom:24px;">Meteo</h1>

    <div v-if="loading" style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px;">
      <div v-for="i in 7" :key="i" class="card" style="padding:20px;">
        <div class="skeleton" style="height:14px;width:60%;margin-bottom:12px;"></div>
        <div class="skeleton" style="height:40px;width:40px;border-radius:50%;margin-bottom:12px;"></div>
        <div class="skeleton" style="height:12px;width:80%;margin-bottom:6px;"></div>
        <div class="skeleton" style="height:12px;width:50%;"></div>
      </div>
    </div>

    <div v-else-if="errore" class="card" style="padding:24px;text-align:center;color:var(--rose-dark);">
      <div style="font-size:32px;margin-bottom:8px;">⚠️</div>
      <p>{{ errore }}</p>
    </div>

    <div v-else style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px;">
      <div v-for="(g, i) in giorni" :key="g.data"
        class="card"
        :class="{ 'card-oggi': i === 0 }"
        style="padding:18px;text-align:center;">
        <div class="meteo-label">{{ i === 0 ? 'Oggi' : g.label }}</div>
        <div style="font-size:40px;margin:10px 0;">{{ g.icona }}</div>
        <div style="font-size:12px;color:var(--ink-soft);margin-bottom:8px;">{{ g.descrizione }}</div>
        <div style="font-weight:600;font-size:15px;">{{ g.tMax }}° / {{ g.tMin }}°</div>
        <div style="font-size:11px;color:var(--ink-soft);margin-top:4px;">
          💧 {{ g.pioggia }} mm · 💨 {{ g.vento }} km/h
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useMeteo } from '@/composables/useMeteo'
import { useDatiStore } from '@/stores/dati'

const { giorni, loading, errore, carica } = useMeteo()
const store = useDatiStore()

onMounted(async () => {
  await store.caricaTutto()
  const s = store.settings
  carica(s?.lat ?? 43.8309, s?.lon ?? 12.9860)
})
</script>

<style scoped>
.card-oggi { border-color: var(--gold-light); background: var(--gold-pale); }
.meteo-label {
  font-family: var(--font-serif); font-size: 13px;
  font-weight: 600; color: var(--ink-mid); text-transform: capitalize;
}
</style>
