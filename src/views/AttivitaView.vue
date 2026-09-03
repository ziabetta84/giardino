<template>
  <div>
    <h1 class="page-title">Attività</h1>
    <p class="attivita-data">{{ dataOggi }}</p>

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
          <div class="slabel"><Icon name="campanella" style="width:12px;height:12px;flex-shrink:0;" />Da fare</div>
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
              @apri-dossier="apriDossier"
            />
          </div>
        </template>

        <!-- In scadenza -->
        <template v-if="inScadenzaTab.length">
          <div class="slabel"><Icon name="orologio" style="width:13px;height:13px;flex-shrink:0;" />In scadenza (entro 3 giorni)</div>
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
              @apri-dossier="apriDossier"
            />
          </div>
        </template>
      </template>

      <!-- Tappe progetto -->
      <template v-else-if="tappeProgetto.length">
        <div class="tappa-lista">
          <div v-for="t in tappeProgetto" :key="`${t.progettoId}-${t.indice}`"
            class="tappa-riga" :class="{ 'tappa-riga--urgente': t.urgente }">
            <span class="tappa-riga__ic" :class="{ 'tappa-riga__ic--urgente': t.urgente }"><Icon name="lampadina" /></span>
            <div class="tappa-riga__m">
              <RouterLink :to="`/progetti/${t.progettoId}`" class="tappa-riga__t">{{ t.progettoTitolo }}</RouterLink>
              <div class="tappa-riga__d" :class="{ 'tappa-riga__d--urgente': t.urgente }">
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
      <div v-if="vuotaTab" class="empty">
        <Icon name="foglia" />
        <p><b>Tutto in ordine!</b>Nessuna cura urgente qui</p>
      </div>
      </div>
      </Transition>
    </template>

    <FoglioLaterale
      :model-value="!!dossierItem"
      @update:model-value="v => { if (!v) dossierItem = null }"
      :titolo="dossierItem?.nomeSpecie ?? ''"
    >
      <DossierPianta v-if="dossierItem" :pianta-id="dossierItem.piantaId" />
    </FoglioLaterale>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { usePianteApi } from '@/composables/usePianteApi'
import { useProgettiApi } from '@/composables/useProgettiApi'
import { valutaCura, stagione } from '@/composables/useCure'
import { concimeConsigliato } from '@/composables/useConcimi'
import { tappeAttese } from '@/composables/useProgetti'
import AttivitaGruppoZona from '@/components/AttivitaGruppoZona.vue'
import FoglioLaterale from '@/components/FoglioLaterale.vue'
import DossierPianta from '@/components/DossierPianta.vue'
import { raggruppaPerZona } from '@/utils/raggruppaAttivita'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const store    = useDatiStore()
const pianteApi = usePianteApi()
const progettiApi = useProgettiApi()
const salvando = ref(null)
const salvandoGruppo = ref(null)
const salvandoTappa = ref(null)
const dossierItem = ref(null)

function apriDossier(item) { dossierItem.value = item }

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
    // La potatura non ha cadenza temporale: è un'etichetta testuale,
    // registrabile per pianta ma mai valutata per urgenza né mostrata nei
    // feed "attività". I tipi con cadenza sono irrigazione, concimazione e
    // (per le specie con beneficio documentato) calcio.
    const tipiCura = ['irrigazione', 'concimazione']
    if (sp?.manutenzione?.calcio) tipiCura.push('calcio')
    for (const tipo of tipiCura) {
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
    await progettiApi.registraTappa(t.tappa.id, 'riuscito')
  } finally {
    salvandoTappa.value = null
  }
}
</script>

<style scoped>
.attivita-data { font-family: var(--font-display); font-style: italic; font-size: 14px; color: var(--ink-soft); margin: 4px 2px 20px; }
.tab-icona { display: inline-flex; align-items: center; gap: 5px; }
.tab-icona :deep(svg) { width: 14px; height: 14px; flex-shrink: 0; }

.tappa-lista { display:flex; flex-direction:column; margin-bottom:24px; }
.tappa-riga { display:flex; align-items:center; gap:12px; padding:12px 2px; }
.tappa-riga + .tappa-riga { border-top:1px solid var(--cream-dark); }
.tappa-riga--urgente { padding:12px; background:var(--rose-pale); border-radius:10px; }
.tappa-riga__ic { flex:none; width:40px; height:40px; border-radius:12px; display:flex; align-items:center; justify-content:center;
  background:var(--gold-bg); color:var(--gold-ink); }
.tappa-riga__ic--urgente { background:var(--rose-bg); color:var(--rose-ink); }
.tappa-riga__ic svg { width:18px; height:18px; }
.tappa-riga__m { flex:1; min-width:0; }
.tappa-riga__t { display:block; font:600 13px/1.25 var(--font-display); color:var(--ink); text-decoration:none;
  white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.tappa-riga__d { font:400 11px/1.4 var(--font-sans); color:var(--ink-soft); margin-top:2px; }
.tappa-riga__d--urgente { color:var(--rose-dark); }
</style>
