<template>
  <div>
    <h1 class="title-display gradient-title title-settle" style="font-size:1.9rem;font-weight:800;margin-bottom:24px;">Meteo</h1>

    <div v-if="loading" style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px;">
      <div v-for="i in 7" :key="i" class="card" style="padding:20px;">
        <div class="skeleton" style="height:14px;width:60%;margin-bottom:12px;"></div>
        <div class="skeleton" style="height:40px;width:40px;border-radius:50%;margin-bottom:12px;"></div>
        <div class="skeleton" style="height:12px;width:80%;margin-bottom:6px;"></div>
        <div class="skeleton" style="height:12px;width:50%;"></div>
      </div>
    </div>

    <div v-else-if="errore" class="card" style="padding:24px;text-align:center;color:var(--rose-dark);">
      <div style="width:44px;height:44px;border-radius:50%;background:var(--rose-tile);display:flex;align-items:center;justify-content:center;margin:0 auto 10px;">
        <Icon name="meteo-errore" style="width:22px;height:22px;" />
      </div>
      <p>{{ errore }}</p>
    </div>

    <template v-else>
      <div v-if="adessoMeteo" class="card meteo-hero hover-card" style="padding:20px;margin-bottom:16px;display:flex;align-items:center;gap:16px;" @click="apriDettaglio(giorni[0])">
        <div class="meteo-hero-icon-wrap">
          <Icon :name="adessoMeteo.icona" style="width:42px;height:42px;" />
        </div>
        <div style="flex:1;">
          <p class="section-label" style="margin-bottom:2px;">Adesso</p>
          <div style="display:flex;align-items:baseline;gap:10px;">
            <span class="title-display" style="font-size:2.1rem;font-weight:800;line-height:1;">{{ adessoMeteo.temp }}°</span>
            <span class="text-light" style="font-size:14px;color:var(--ink-soft);">{{ adessoMeteo.descrizione }}</span>
          </div>
        </div>
      </div>

      <div v-if="avvisi.length" class="card" style="padding:14px 16px;border-color:var(--rose-light);background:var(--rose-pale);margin-bottom:16px;">
        <p style="display:flex;align-items:center;gap:6px;font-size:12px;font-weight:600;color:var(--rose-dark);margin-bottom:8px;">
          <Icon name="campanella" style="width:13px;height:13px;flex-shrink:0;" />Condizioni avverse in arrivo
        </p>
        <div style="display:flex;flex-direction:column;gap:6px;">
          <div v-for="a in avvisi" :key="a.key" style="display:flex;align-items:center;gap:6px;font-size:13px;color:var(--rose-dark);">
            <Icon :name="a.icona" style="width:15px;height:15px;flex-shrink:0;" /> <strong>{{ a.giorno }}</strong> — {{ a.testo }}
          </div>
        </div>
      </div>

      <div v-if="orarieDaAdesso.length" class="card" style="padding:16px;margin-bottom:16px;">
        <p class="section-label" style="margin-bottom:10px;">Oggi, ora per ora</p>
        <div style="display:flex;gap:10px;overflow-x:auto;padding-bottom:4px;">
          <div v-for="o in orarieDaAdesso" :key="o.ora"
            class="ora-box"
            :class="{ 'ora-corrente': oraCorrente(o) }"
            style="flex-shrink:0;text-align:center;padding:8px 10px;border-radius:12px;min-width:56px;">
            <div style="font-size:11px;color:var(--ink-soft);">{{ o.label }}</div>
            <Icon :name="o.icona" style="width:22px;height:22px;margin:4px auto;" />
            <div style="font-size:12px;font-weight:600;">{{ o.temp }}°</div>
            <div v-if="o.pioggiaProb !== null" class="text-light" style="display:flex;align-items:center;justify-content:center;gap:2px;font-size:10px;color:var(--ink-faint);margin-top:2px;">
              <Icon name="goccia" style="width:9px;height:9px;" />{{ o.pioggiaProb }}%
            </div>
          </div>
        </div>
      </div>

      <div class="meteo-giorni-grid">
        <div v-for="g in giorniSuccessivi" :key="g.data"
          class="card hover-card"
          style="padding:18px;text-align:center;"
          @click="apriDettaglio(g)">
          <div class="meteo-label">{{ g.label }}</div>
          <Icon :name="g.icona" style="width:40px;height:40px;margin:10px auto;" />
          <div class="text-light" style="font-size:12px;color:var(--ink-soft);margin-bottom:8px;">{{ g.descrizione }}</div>
          <div style="font-weight:600;font-size:15px;">{{ g.tMax }}° / {{ g.tMin }}°</div>
          <div class="text-light" style="display:flex;align-items:center;justify-content:center;gap:10px;font-size:11px;color:var(--ink-soft);margin-top:4px;">
            <span style="display:flex;align-items:center;gap:3px;"><Icon name="goccia" style="width:11px;height:11px;" />{{ g.pioggia }} mm</span>
            <span style="display:flex;align-items:center;gap:3px;"><Icon name="vento" style="width:11px;height:11px;" />{{ g.vento }} km/h</span>
          </div>
        </div>
      </div>
    </template>

    <Teleport to="body">
      <div v-if="giornoSelezionato" class="meteo-overlay" @click.self="chiudiDettaglio">
        <div class="meteo-dettaglio-box">
          <button class="meteo-dettaglio-chiudi" @click="chiudiDettaglio" aria-label="Chiudi">×</button>
          <div style="display:flex;align-items:center;gap:14px;margin-bottom:18px;">
            <div class="meteo-hero-icon-wrap">
              <Icon :name="giornoSelezionato.icona" style="width:42px;height:42px;" />
            </div>
            <div>
              <div class="meteo-label" style="font-size:15px;">{{ giornoSelezionato.label }}</div>
              <div class="text-light" style="font-size:13px;color:var(--ink-soft);">{{ giornoSelezionato.descrizione }}</div>
            </div>
          </div>
          <div class="title-display" style="font-weight:800;font-size:1.8rem;margin-bottom:18px;">
            {{ giornoSelezionato.tMax }}° / {{ giornoSelezionato.tMin }}°
          </div>
          <div class="meteo-dettaglio-stats">
            <div v-for="s in statisticheDettaglio" :key="s.label" class="meteo-dettaglio-stat">
              <Icon :name="s.icona" style="width:20px;height:20px;flex-shrink:0;" />
              <div>
                <div style="font-size:11px;color:var(--ink-soft);">{{ s.label }}</div>
                <div style="font-weight:600;font-size:14px;">{{ s.valore }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted, ref, computed } from 'vue'
import { useMeteo } from '@/composables/useMeteo'
import { useDatiStore } from '@/stores/dati'
import Icon from '@/components/Icon.vue'

const { giorni, orarieOggi, avvisi, loading, errore, carica } = useMeteo()
const store = useDatiStore()

const giorniSuccessivi = computed(() => giorni.value.slice(1))

const adesso = ref(new Date())
let timer = null
onMounted(() => {
  timer = setInterval(() => { adesso.value = new Date() }, 60000)
})
onUnmounted(() => {
  if (timer) clearInterval(timer)
})

function chiaveOra(d) {
  const oggiStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
  const oraStr = String(d.getHours()).padStart(2, '0')
  return `${oggiStr}T${oraStr}:00`
}

const orarieDaAdesso = computed(() => {
  const chiave = chiaveOra(adesso.value)
  return orarieOggi.value.filter(o => o.ora >= chiave)
})

const adessoMeteo = computed(() => orarieDaAdesso.value[0] ?? null)

function oraCorrente(o) {
  return o.ora === chiaveOra(adesso.value)
}

const giornoSelezionato = ref(null)
function apriDettaglio(g) { giornoSelezionato.value = g }
function chiudiDettaglio() { giornoSelezionato.value = null }

const statisticheDettaglio = computed(() => {
  const g = giornoSelezionato.value
  if (!g) return []
  const stats = [
    { icona:'goccia', label:'Pioggia', valore:`${g.pioggia} mm` },
    { icona:'vento', label:'Vento', valore:`${g.vento} km/h` },
  ]
  if (g.umidita != null) stats.push({ icona:'umidita', label:'Umidità aria', valore:`${g.umidita}%` })
  if (g.umiditaSuolo != null) stats.push({ icona:'umidita-suolo', label:'Umidità suolo', valore:`${g.umiditaSuolo}%` })
  if (g.evapotraspirazione != null) stats.push({ icona:'evapotraspirazione', label:'Evapotraspirazione', valore:`${g.evapotraspirazione} mm` })
  return stats
})

onMounted(async () => {
  await store.caricaTutto()
  const s = store.settings
  carica(s?.location?.lat ?? 43.8309, s?.location?.lon ?? 12.9860)
})
</script>

<style scoped>
.meteo-hero-icon-wrap {
  width: 64px; height: 64px; border-radius: 16px;
  background: var(--gold-pale); border: 1px solid var(--gold-light);
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.meteo-label {
  font-family: var(--font-serif); font-size: 13px;
  font-weight: 600; color: var(--ink-mid); text-transform: capitalize;
}
.ora-box { background: var(--cream); }
.ora-corrente { background: var(--gold-pale); border: 1px solid var(--gold-light); }
.meteo-giorni-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 12px;
}
@media (min-width: 641px) {
  .meteo-giorni-grid { grid-template-columns: repeat(3, 1fr); }
}
.meteo-overlay {
  position: fixed; inset: 0; z-index: 400;
  background: rgba(42,34,24,0.4);
  display: flex; align-items: center; justify-content: center;
  padding: 16px;
}
.meteo-dettaglio-box {
  background: var(--white);
  border-radius: 20px;
  padding: 24px;
  width: 100%; max-width: 380px;
  box-shadow: 0 20px 60px rgba(42,34,24,0.2);
  position: relative;
}
.meteo-dettaglio-chiudi {
  position: absolute; top: 14px; right: 14px;
  background: none; border: none; cursor: pointer;
  font-size: 20px; line-height: 1; color: var(--ink-soft);
  width: 32px; height: 32px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
}
.meteo-dettaglio-chiudi:hover { background: var(--cream-dark); }
.meteo-dettaglio-stats {
  display: grid; grid-template-columns: 1fr 1fr; gap: 14px;
}
.meteo-dettaglio-stat {
  display: flex; align-items: center; gap: 10px;
}
</style>
