<template>
  <div>
    <h1 class="title-display gradient-title title-settle" style="font-size:1.9rem;font-weight:800;margin-bottom:6px;">Attività</h1>
    <p class="title-serif" style="font-size:14px;color:var(--ink-soft);font-style:italic;margin-bottom:20px;">{{ dataOggi }}</p>

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
      <!-- Tab: con 128 piante su 6 zone l'elenco unico diventava lunghissimo,
           diviso per tipo di cura invece che tutto insieme. La potatura non
           ha una tab propria: i suoi valori sono testo libero per stagione
           (es. "taglio leggero"), non un intervallo in giorni, quindi non
           genera mai una scadenza qui (vedi useCure.js/parseGiorni). -->
      <div style="display:flex;gap:6px;margin-bottom:20px;flex-wrap:wrap;">
        <button type="button" class="pill tab-icona" :class="{ active: tabAttiva === 'irrigazione' }" @click="tabAttiva = 'irrigazione'">
          <Icon name="goccia" />Irrigazione
          <span v-if="conteggioTab.irrigazione" class="badge badge-warn" style="margin-left:4px;">{{ conteggioTab.irrigazione }}</span>
        </button>
        <button type="button" class="pill tab-icona" :class="{ active: tabAttiva === 'concimi' }" @click="tabAttiva = 'concimi'">
          <Icon name="concimazione" />Concimi &amp; calcio
          <span v-if="conteggioTab.concimi" class="badge badge-warn" style="margin-left:4px;">{{ conteggioTab.concimi }}</span>
        </button>
        <button type="button" class="pill tab-icona" :class="{ active: tabAttiva === 'progetti' }" @click="tabAttiva = 'progetti'">
          <Icon name="lampadina" />Progetti
          <span v-if="conteggioTab.progetti" class="badge badge-warn" style="margin-left:4px;">{{ conteggioTab.progetti }}</span>
        </button>
      </div>

      <Transition name="fade" mode="out-in">
      <div :key="tabAttiva">
      <template v-if="tabAttiva !== 'progetti'">
        <!-- Da fare -->
        <template v-if="daFareTab.length">
          <p class="section-label" style="display:flex;align-items:center;gap:6px;">
            <Icon name="campanella" style="width:12px;height:12px;flex-shrink:0;" />Da fare
          </p>
          <div style="margin-bottom:24px;">
            <AttivitaGruppoZona
              v-for="gruppo in gruppiDaFareTab"
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
        <template v-if="inScadenzaTab.length">
          <p class="section-label" style="display:flex;align-items:center;gap:5px;">
            <Icon name="orologio" style="width:13px;height:13px;flex-shrink:0;" />In scadenza (entro 3 giorni)
          </p>
          <div style="margin-bottom:24px;">
            <AttivitaGruppoZona
              v-for="gruppo in gruppiInScadenzaTab"
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
      </template>

      <!-- Tappe progetto -->
      <template v-else-if="tappeProgetto.length">
        <div style="display:flex;flex-direction:column;gap:8px;margin-bottom:24px;">
          <div v-for="t in tappeProgetto" :key="`${t.progettoId}-${t.indice}`" class="card"
            :style="t.urgente ? 'display:flex;align-items:center;gap:12px;padding:12px 16px;border-color:var(--rose-light);background:var(--rose-pale);' : 'display:flex;align-items:center;gap:12px;padding:12px 16px;'">
            <div :style="`width:40px;height:40px;border-radius:12px;display:flex;align-items:center;justify-content:center;flex-shrink:0;background:${t.urgente ? 'var(--rose-tile)' : 'var(--gold-tile)'};`"><Icon name="lampadina" style="width:18px;height:18px;" /></div>
            <div style="flex:1;min-width:0;">
              <RouterLink :to="`/progetti/${t.progettoId}`" class="title-serif"
                style="font-size:13px;font-weight:600;text-decoration:none;color:inherit;display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
                {{ t.progettoTitolo }}
              </RouterLink>
              <div :style="`font-size:11px;margin-top:2px;color:${t.urgente ? 'var(--rose-dark)' : 'var(--ink-soft)'};`">
                {{ t.tappa.descrizione }} — {{ t.urgente ? `scaduta ${Math.abs(t.giorni)} gg fa` : `tra ${t.giorni} gg` }}
              </div>
            </div>
            <button @click="registraTappa(t)" :disabled="salvandoTappa === `${t.progettoId}-${t.indice}`"
              :class="['btn', t.urgente ? 'btn-rose' : 'btn-ghost']" style="font-size:11px;padding:5px 10px;min-height:30px;flex-shrink:0;">
              <Spinner v-if="salvandoTappa === `${t.progettoId}-${t.indice}`" /><span v-else>✓ Fatto</span>
            </button>
          </div>
        </div>
      </template>

      <!-- Tutto ok (per la tab attiva) -->
      <div v-if="vuotaTab" style="text-align:center;padding:60px 20px;color:var(--ink-faint);">
        <div style="width:56px;height:56px;border-radius:50%;background:var(--olive-tile);display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
          <Icon name="foglia" style="width:24px;height:24px;" />
        </div>
        <p class="title-serif" style="font-size:16px;color:var(--sage-dark);font-weight:600;">Tutto in ordine!</p>
        <p class="text-light" style="font-size:13px;margin-top:4px;">Nessuna cura urgente qui</p>
      </div>
      </div>
      </Transition>
    </template>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'
import { usePianteApi } from '@/composables/usePianteApi'
import { valutaCura, stagione } from '@/composables/useCure'
import { concimeConsigliato } from '@/composables/useConcimi'
import { tappeAttese } from '@/composables/useProgetti'
import AttivitaGruppoZona from '@/components/AttivitaGruppoZona.vue'
import { raggruppaPerZona } from '@/utils/raggruppaAttivita'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const store    = useDatiStore()
const { saveJSON } = useApi()
const pianteApi = usePianteApi()
const salvando = ref(null)
const salvandoGruppo = ref(null)
const salvandoTappa = ref(null)

const dataOggi = new Date().toLocaleDateString('it-IT', { weekday:'long', day:'numeric', month:'long' })

const attivita = computed(() => {
  if (!store.piante) return []
  const stagioneCorrente = stagione()
  const items = []
  const contestoMeteo = { meteo: store.meteo }
  for (const [id, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie] ?? null
    const nomeSpecie = sp?.nome ?? p.specie
    const contesto = { ...contestoMeteo, esterno: store.zone?.[p.zona]?.tipo === 'esterno' }
    for (const tipo of ['irrigazione', 'concimazione', 'potatura', 'calcio']) {
      const c = valutaCura(p, sp, tipo, contesto)
      if (c.giorni !== null) {
        const suggerimento = tipo === 'concimazione'
          ? concimeConsigliato(sp?.manutenzione?.npk?.[stagioneCorrente], store.concimi)
          : null
        items.push({ key: `${id}-${tipo}`, piantaId: id, tipo, nomeSpecie, label: c.label, giorni: c.giorni, urgente: c.urgente, suggerimento })
      }
    }
  }
  return items
})

const daFare = computed(() => attivita.value.filter(i => i.urgente).sort((a, b) => a.giorni - b.giorni))
const inScadenza = computed(() => attivita.value.filter(i => !i.urgente && i.giorni !== null && i.giorni <= 3).sort((a, b) => a.giorni - b.giorni))

// Solo le tappe scadute o in arrivo entro 14 giorni: un progetto come una
// germinazione da seme può avere tappe previste anche a distanza di anni,
// che qui affollerebbero la lista senza essere ancora attuabili.
const tappeProgetto = computed(() =>
  tappeAttese(store.progetti).filter(t => t.giorni <= 14).sort((a, b) => a.giorni - b.giorni)
)

// Tab: divide l'elenco per tipo di cura invece di mostrarlo tutto insieme
// (con molte piante diventa uno scroll lunghissimo). Niente tab per la
// potatura: essendo testo libero non genera mai voci in daFare/inScadenza.
const tabAttiva = ref('irrigazione')
const TIPI_TAB = { irrigazione: ['irrigazione'], concimi: ['concimazione', 'calcio'] }

const daFareTab = computed(() =>
  tabAttiva.value === 'progetti' ? [] : daFare.value.filter(i => TIPI_TAB[tabAttiva.value].includes(i.tipo))
)
const inScadenzaTab = computed(() =>
  tabAttiva.value === 'progetti' ? [] : inScadenza.value.filter(i => TIPI_TAB[tabAttiva.value].includes(i.tipo))
)
const gruppiDaFareTab = computed(() => raggruppaPerZona(daFareTab.value, store.piante))
const gruppiInScadenzaTab = computed(() => raggruppaPerZona(inScadenzaTab.value, store.piante))

const conteggioTab = computed(() => ({
  irrigazione: daFare.value.filter(i => i.tipo === 'irrigazione').length,
  concimi: daFare.value.filter(i => i.tipo === 'concimazione' || i.tipo === 'calcio').length,
  progetti: tappeProgetto.value.filter(t => t.urgente).length,
}))

const vuotaTab = computed(() =>
  tabAttiva.value === 'progetti' ? !tappeProgetto.value.length : !daFareTab.value.length && !inScadenzaTab.value.length
)

async function registra(item) {
  if (salvando.value || salvandoGruppo.value) return
  salvando.value = item.key
  try {
    await pianteApi.registraCura(item.piantaId, item.tipo)
  } finally {
    salvando.value = null
  }
}

async function registraGruppo(gruppo) {
  if (salvandoGruppo.value || salvando.value) return
  salvandoGruppo.value = gruppo.chiave
  try {
    await pianteApi.registraCuraMultipla(gruppo.items)
  } finally {
    salvandoGruppo.value = null
  }
}

async function registraTappa(t) {
  const chiave = `${t.progettoId}-${t.indice}`
  if (salvandoTappa.value) return
  salvandoTappa.value = chiave
  try {
    const nuovi = await saveJSON('progetti.json', (correnti) => {
      const base = { ...(correnti ?? store.progetti) }
      const progetto = base[t.progettoId]
      if (!progetto?.tappe?.[t.indice]) return base
      const tappe = [...progetto.tappe]
      tappe[t.indice] = { ...tappe[t.indice], esito: 'riuscito' }
      base[t.progettoId] = { ...progetto, tappe }
      return base
    })
    store.progetti = nuovi
  } finally {
    salvandoTappa.value = null
  }
}
</script>

<style scoped>
.tab-icona { display: inline-flex; align-items: center; gap: 5px; }
.tab-icona :deep(svg) { width: 14px; height: 14px; flex-shrink: 0; }
</style>
