<template>
  <div>
    <!-- Hero -->
    <div style="text-align:center;padding:32px 0 36px;">
      <ZorbaLogo class="app-logo" />
      <h1 class="title-display gradient-title title-settle" style="font-size:2.6rem;line-height:1.05;font-weight:800;letter-spacing:-0.02em;margin-bottom:8px;">
        Il Giardino di Zorba
      </h1>
      <p class="title-serif" style="color:var(--ink-soft);font-size:15px;font-style:italic;">
        {{ oggi }} · Centinarola, Fano
      </p>
      <div class="dots">
        <span class="dot" style="background:var(--rose-light);"></span>
        <span class="dot" style="background:var(--gold-light);"></span>
        <span class="dot" style="background:var(--olive-light);"></span>
        <span class="dot" style="background:var(--sage-light);"></span>
      </div>
    </div>

    <!-- Meteo -->
    <RouterLink to="/meteo" class="card hover-card"
      style="padding:14px 18px;display:flex;align-items:center;gap:14px;margin-bottom:14px;text-decoration:none;color:inherit;">
      <div class="meteo-icon-wrap"><Icon :name="meteoOggi?.icona ?? 'meteo'" style="width:26px;height:26px;" /></div>
      <div style="flex:1;">
        <div v-if="meteoOggi" style="font-weight:600;font-size:14px;">
          {{ meteoOggi.tMax }}° / {{ meteoOggi.tMin }}° · {{ meteoOggi.descrizione }}
        </div>
        <div v-else style="font-weight:600;font-size:14px;color:var(--ink-faint);">Caricamento meteo…</div>
        <div v-if="meteoOggi" class="text-light" style="display:flex;align-items:center;gap:10px;color:var(--ink-soft);font-size:12px;margin-top:2px;">
          <span style="display:flex;align-items:center;gap:3px;"><Icon name="goccia" style="width:10px;height:10px;" />{{ meteoOggi.pioggia }} mm</span>
          <span style="display:flex;align-items:center;gap:3px;"><Icon name="vento" style="width:10px;height:10px;" />{{ meteoOggi.vento }} km/h</span>
        </div>
      </div>
      <span style="color:var(--rose);font-size:14px;font-weight:700;">→</span>
    </RouterLink>

    <!-- Zorba dice -->
    <RouterLink to="/agente" class="card hover-card"
      style="padding:14px 18px;display:flex;align-items:center;gap:14px;margin-bottom:14px;text-decoration:none;color:inherit;">
      <div class="zorba-icon-wrap"><Icon name="gatto" style="width:22px;height:22px;" /></div>
      <div style="flex:1;">
        <div style="font-weight:600;font-size:14px;">Zorba dice</div>
        <div class="text-light" style="color:var(--ink-soft);font-size:12px;margin-top:1px;">Chiedi un consiglio, identifica una specie, pianifica un progetto</div>
      </div>
      <span style="color:var(--rose);font-size:14px;font-weight:700;">→</span>
    </RouterLink>

    <!-- Card grid -->
    <div class="card-grid">
      <RouterLink v-for="card in homeCards" :key="card.id" :to="card.to"
        class="card hover-card card-item" style="text-decoration:none;color:inherit;">
        <div class="card-item-ic" :style="`background:var(--${card.tinta}-tile);`"><Icon :name="card.icona" style="width:20px;height:20px;" /></div>
        <div style="font-weight:600;font-size:12px;color:var(--ink);">{{ card.label }}</div>
        <div v-if="card.count !== null"
          :style="card.urgent ? 'color:var(--rose-dark);font-weight:700;' : 'color:var(--ink-soft);'"
          style="font-size:11px;margin-top:3px;">{{ card.count }}</div>
      </RouterLink>
    </div>

    <!-- Da fare oggi -->
    <div class="card" style="overflow:hidden;margin-top:14px;">
      <div style="display:flex;align-items:center;justify-content:space-between;padding:14px 18px;">
        <h2 class="title-serif" style="font-size:16px;font-weight:600;">Da fare oggi</h2>
        <span v-if="daFareOggi.length" class="badge badge-warn">{{ daFareOggi.length }} urgent{{ daFareOggi.length === 1 ? 'e' : 'i' }}</span>
        <span v-else class="badge" style="background:var(--sage-pale);color:var(--sage-dark);">Tutto ok ✓</span>
      </div>
      <hr class="divider">

      <!-- Skeleton -->
      <div v-if="store.loading" style="padding:14px 18px;display:flex;flex-direction:column;gap:12px;">
        <div v-for="i in 3" :key="i" style="display:flex;align-items:center;gap:12px;">
          <div class="skeleton" style="width:42px;height:42px;border-radius:12px;flex-shrink:0;"></div>
          <div style="flex:1;display:flex;flex-direction:column;gap:6px;">
            <div class="skeleton" style="height:12px;width:55%;"></div>
            <div class="skeleton" style="height:10px;width:40%;"></div>
          </div>
        </div>
      </div>

      <div v-else-if="daFareOggi.length">
        <TransitionGroup name="stagger" tag="div" style="position:relative;">
          <div v-for="(a, i) in daFareOggi.slice(0,5)" :key="a.key" :style="`transition-delay:${Math.min(i,5) * 0.07}s;`">
            <div style="display:flex;align-items:center;gap:12px;padding:12px 18px;">
              <div class="attivita-icon" :style="`background:var(--${tinta(a.tipo)}-tile);`"><Icon :name="icona(a.tipo)" style="width:18px;height:18px;" /></div>
              <div style="flex:1;min-width:0;">
                <div style="font-weight:500;font-size:13px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">{{ a.nomeSpecie }}</div>
                <div style="font-size:11px;color:var(--rose-dark);">{{ a.label }}</div>
              </div>
            </div>
            <hr v-if="i < Math.min(daFareOggi.length, 5) - 1" class="divider" style="margin-left:72px;">
          </div>
        </TransitionGroup>
        <div v-if="daFareOggi.length > 5" style="padding:10px 18px;text-align:center;">
          <RouterLink to="/attivita" style="font-size:12px;color:var(--sage-dark);text-decoration:none;font-weight:600;">
            Vedi altre {{ daFareOggi.length - 5 }} attività →
          </RouterLink>
        </div>
      </div>

      <div v-else style="padding:20px 18px;display:flex;align-items:center;justify-content:center;gap:6px;">
        <p class="text-light" style="font-size:13px;color:var(--ink-soft);margin:0;">Nessuna cura urgente oggi</p>
        <Icon name="fiore" style="width:14px;height:14px;flex-shrink:0;" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useMeteo } from '@/composables/useMeteo'
import { valutaCura, cureUrgentiPianta } from '@/composables/useCure'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import Icon from '@/components/Icon.vue'

const store = useDatiStore()
const { giorni: meteoGiorni, carica: caricaMeteo } = useMeteo()

const oggi = new Date().toLocaleDateString('it-IT', { weekday:'long', day:'numeric', month:'long' })

const meteoOggi = computed(() => meteoGiorni.value?.[0] ?? null)

function icona(tipo) {
  return tipo === 'irrigazione' ? 'goccia' : tipo === 'concimazione' ? 'concimazione' : 'potatura'
}
function tinta(tipo) {
  return tipo === 'irrigazione' ? 'acqua' : tipo === 'concimazione' ? 'olive' : 'rose'
}

const numPiante  = computed(() => store.piante  ? Object.keys(store.piante).length  : null)
const numZone    = computed(() => store.zone    ? Object.keys(store.zone).length    : null)
const numConcimi = computed(() => store.concimi ? Object.keys(store.concimi).length : null)
const numUrgenti = computed(() => {
  if (!store.piante) return null
  let count = 0
  for (const [, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie] ?? null
    if (cureUrgentiPianta(p, sp).length > 0) count++
  }
  return count
})

const daFareOggi = computed(() => {
  if (!store.piante) return []
  const items = []
  for (const [id, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie] ?? null
    const nomeSpecie = sp?.nome ?? p.specie
    for (const tipo of ['irrigazione','concimazione','potatura']) {
      const c = valutaCura(p, sp, tipo)
      if (c.urgente) items.push({ key:`${id}-${tipo}`, tipo, nomeSpecie, label: c.label })
    }
  }
  return items
})

// Stesso ordine della NavBar (home e meteo escluse: home è la pagina
// stessa, meteo ha già la sua card rettangolare qui sopra) — così la
// sequenza dei colori non cambia passando da un menù all'altro.
// Zorba dice è anch'essa una card rettangolare (vedi sopra), non fa
// parte di questa griglia: 6 quadrati, non 7, per restare simmetrica
// sia a 3 che a 2 colonne.
const homeCards = computed(() => [
  { id:'zone',     to:'/zone',     icona:'pin',        tinta:'acqua', label:'Zone',       count: numZone.value !== null ? `${numZone.value} zone` : null, urgent: false },
  { id:'piante',   to:'/piante',   icona:'foglia',     tinta:'olive', label:'Piante',     count: numUrgenti.value ? `${numUrgenti.value} da curare` : (numPiante.value !== null ? `${numPiante.value} piante` : null), urgent: !!numUrgenti.value },
  { id:'progetti', to:'/progetti', icona:'lampadina',  tinta:'gold',  label:'Progetti',   count: null, urgent: false },
  { id:'concimi',  to:'/concimi',  icona:'provetta',   tinta:'sage',  label:'Concimi',    count: numConcimi.value !== null ? `${numConcimi.value} concimi` : null, urgent: false },
  { id:'attivita', to:'/attivita', icona:'campanella', tinta:'rose',  label:'Attività',   count: daFareOggi.value.length ? `${daFareOggi.value.length} urgent${daFareOggi.value.length === 1 ? 'e' : 'i'}` : 'tutto ok', urgent: daFareOggi.value.length > 0 },
  { id:'gallery',  to:'/gallery',  icona:'cornice',    tinta:'sage',  label:'Gallery',    count: null, urgent: false },
])

onMounted(async () => {
  await store.caricaTutto()
  const s = store.settings
  caricaMeteo(s?.location?.lat ?? 43.8309, s?.location?.lon ?? 12.9860)
})
</script>

<style scoped>
.app-logo {
  width: 140px; height: 140px;
  margin: 0 auto 20px;
  filter: drop-shadow(0 8px 20px rgba(42,34,24,0.18));
}
.dots { display:flex; justify-content:center; gap:8px; margin-top:14px; }
.dot  { width:8px; height:8px; border-radius:50%; display:inline-block; }
.meteo-icon-wrap {
  width:46px; height:46px; border-radius:13px;
  background:var(--gold-pale); border:1px solid var(--gold-light);
  display:flex; align-items:center; justify-content:center;
  font-size:24px; flex-shrink:0;
}
.zorba-icon-wrap {
  width:46px; height:46px; border-radius:13px;
  background:var(--ink-tile); border:1px solid var(--cream-dark);
  display:flex; align-items:center; justify-content:center;
  flex-shrink:0;
}
.card-grid {
  display: grid; grid-template-columns: repeat(3,1fr); gap: 10px;
}
.card-item { padding: 16px 10px; text-align: center; border-radius: 18px; }
.card-item-ic {
  width:36px; height:36px; border-radius:11px; margin:0 auto 7px;
  display:flex; align-items:center; justify-content:center;
}
.attivita-icon {
  width:42px; height:42px; border-radius:12px;
  display:flex; align-items:center; justify-content:center;
  flex-shrink:0;
}
@media (max-width: 400px) {
  .card-grid { grid-template-columns: repeat(2,1fr); }
}
</style>
