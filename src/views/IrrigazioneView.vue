<template>
  <div>
    <div class="page-title__row">
      <h1 class="page-title">Irrigazione automatica</h1>
    </div>
    <p class="prose" style="margin:-6px 0 20px;">
      Imposta un programma "ogni N giorni" per tutto il giardino, per una zona o per una singola pianta. Le piante coperte da un programma attivo non compaiono più tra le cure da fare a mano — la pioggia prevista continua comunque a sospenderlo.
    </p>

    <div v-if="store.loading" class="destlist">
      <div v-for="i in 4" :key="i" class="dest">
        <div class="skeleton dest__ic" style="border-radius:50%;"></div>
        <div class="skeleton" style="height:13px;flex:1;max-width:160px;border-radius:6px;"></div>
      </div>
    </div>

    <div v-else class="destlist">
      <div class="dest">
        <Icon name="goccia" class="dest__ic" style="color:var(--acqua);" />
        <span class="dest__n">Tutto il giardino</span>
        <span v-if="programmaGiardino" class="badge badge-ok">ogni {{ programmaGiardino.ogniGiorni }} gg</span>
        <span v-else class="dest__c" style="color:var(--ink-soft);">nessun programma</span>
        <button type="button" class="pill-mini" @click="apriModifica('giardino', 'Tutto il giardino', programmaGiardino?.ogniGiorni)" aria-label="Modifica programma giardino">
          <Icon name="matita" />
        </button>
        <button v-if="programmaGiardino" type="button" class="pill-mini pill-mini--del" @click="rimuovi('giardino')" aria-label="Rimuovi programma giardino">×</button>
      </div>

      <template v-for="z in zoneList" :key="z.nome">
        <div class="dest" style="cursor:pointer;" @click="toggleZona(z.nome)">
          <Icon :name="store.iconaZona(z.nome)" class="dest__ic" />
          <span class="dest__n">{{ z.nome }}</span>
          <span v-if="programmaZona(z.nome)" class="badge badge-ok">ogni {{ programmaZona(z.nome).ogniGiorni }} gg</span>
          <span v-else class="dest__c" style="color:var(--ink-soft);">{{ ereditaTesto(programmaGiardino) }}</span>
          <button type="button" class="pill-mini" @click.stop="apriModifica({ zona: z.nome }, z.nome, programmaZona(z.nome)?.ogniGiorni)" aria-label="Modifica programma zona">
            <Icon name="matita" />
          </button>
          <button v-if="programmaZona(z.nome)" type="button" class="pill-mini pill-mini--del" @click.stop="rimuovi({ zona: z.nome })" aria-label="Rimuovi programma zona">×</button>
          <Icon name="back" class="dest__chev" :style="{ transform: espanse.has(z.nome) ? 'rotate(-90deg)' : 'rotate(90deg)' }" />
        </div>
        <div v-if="espanse.has(z.nome)" class="destlist" style="padding-left:30px;">
          <div v-for="p in pianteDellaZona(z.nome)" :key="p.id" class="dest">
            <span class="dest__n">{{ nomeSpecie(p) }}<span v-if="p.varieta"> — {{ p.varieta }}</span></span>
            <span v-if="programmaPianta(p.id)" class="badge badge-ok">ogni {{ programmaPianta(p.id).ogniGiorni }} gg</span>
            <span v-else class="dest__c" style="color:var(--ink-soft);">{{ ereditaTesto(programmaEffettivoZona(z.nome)) }}</span>
            <button type="button" class="pill-mini" @click="apriModifica({ pianta: p.id }, nomeSpecie(p), programmaPianta(p.id)?.ogniGiorni)" aria-label="Modifica programma pianta">
              <Icon name="matita" />
            </button>
            <button v-if="programmaPianta(p.id)" type="button" class="pill-mini pill-mini--del" @click="rimuovi({ pianta: p.id })" aria-label="Rimuovi programma pianta">×</button>
          </div>
          <p v-if="!pianteDellaZona(z.nome).length" style="font-size:12px;color:var(--ink-soft);padding:10px 2px;">Nessuna pianta in questa zona.</p>
        </div>
      </template>

      <p v-if="!zoneList.length" style="font-size:12px;color:var(--ink-soft);padding:10px 2px;">Nessuna zona configurata.</p>
    </div>

    <FoglioLaterale :model-value="mostraForm" @update:model-value="v => { if (!v) chiudiForm() }" :titolo="titoloForm">
      <div v-if="mostraForm" class="foglio-form">
        <label class="field-label" for="irr-giorni">Ogni quanti giorni</label>
        <input id="irr-giorni" v-model.number="giorniForm" type="number" min="1" step="1" class="form-input" style="margin-bottom:8px;">
        <p v-if="errore" role="alert" style="font-size:11px;color:var(--rose-ink);margin:0 0 10px;">{{ errore }}</p>
        <div class="foglio-actions">
          <button type="button" class="btn btn-ghost" @click="chiudiForm" style="min-height:40px;padding:8px 16px;">Annulla</button>
          <button type="button" class="btn btn-sage" @click="salva" :disabled="!giorniForm || giorniForm < 1 || salvando" style="min-height:40px;padding:8px 16px;">
            <Spinner v-if="salvando" /><span v-else>Salva</span>
          </button>
        </div>
      </div>
    </FoglioLaterale>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useIrrigazioneApi } from '@/composables/useIrrigazioneApi'
import FoglioLaterale from '@/components/FoglioLaterale.vue'
import Spinner from '@/components/Spinner.vue'
import Icon from '@/components/Icon.vue'

const store = useDatiStore()
const irrigazioneApi = useIrrigazioneApi()

onMounted(() => store.caricaTutto())

const zoneList = computed(() => Object.values(store.zone ?? {}))
const piante = computed(() => Object.entries(store.piante ?? {}).map(([id, p]) => ({ id, ...p })))

function pianteDellaZona(nomeZona) {
  return piante.value.filter(p => p.zona === nomeZona)
}
function nomeSpecie(p) {
  return store.specie?.[p.specie]?.nome ?? p.specie
}

const programmaGiardino = computed(() => store.programmiIrrigazione?.giardino ?? null)
function programmaZona(nome) { return store.programmiIrrigazione?.zone?.[nome] ?? null }
function programmaPianta(id) { return store.programmiIrrigazione?.piante?.[id] ?? null }

// Cosa vince davvero per una zona/pianta senza programma proprio, secondo
// la stessa cascata di useIrrigazioneAuto.js — qui espansa a mano perché la
// vista deve mostrare l'eredità anche quando manca il livello intermedio.
function programmaEffettivoZona(nome) {
  return programmaZona(nome) ?? programmaGiardino.value
}
function ereditaTesto(effettivo) {
  return effettivo ? `eredita: ogni ${effettivo.ogniGiorni} gg` : 'nessun programma'
}

const espanse = ref(new Set())
function toggleZona(nome) {
  const copia = new Set(espanse.value)
  copia.has(nome) ? copia.delete(nome) : copia.add(nome)
  espanse.value = copia
}

const mostraForm = ref(false)
const targetForm = ref(null)
const titoloForm = ref('')
const giorniForm = ref(null)
const salvando = ref(false)
const errore = ref(null)

function apriModifica(target, titolo, valoreAttuale) {
  targetForm.value = target
  titoloForm.value = titolo
  giorniForm.value = valoreAttuale ?? null
  errore.value = null
  mostraForm.value = true
}
function chiudiForm() {
  mostraForm.value = false
  targetForm.value = null
}
async function salva() {
  if (!giorniForm.value || giorniForm.value < 1 || !targetForm.value) return
  salvando.value = true
  errore.value = null
  try {
    await irrigazioneApi.salvaProgramma(targetForm.value, giorniForm.value)
    chiudiForm()
  } catch (e) {
    errore.value = 'Salvataggio non riuscito. Riprova.'
  } finally {
    salvando.value = false
  }
}
async function rimuovi(target) {
  await irrigazioneApi.rimuoviProgramma(target)
}
</script>
