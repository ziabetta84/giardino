<template>
  <div>
    <div class="page-title__row">
      <h1 class="page-title">Irrigazione automatica</h1>
    </div>
    <p class="prose" style="margin:-6px 0 20px;">
      Imposta un programma "ogni N giorni" per tutto il giardino, per una zona, per una sottozona o per una singola pianta. Le piante coperte da un programma attivo non compaiono più tra le cure da fare a mano — la pioggia prevista continua comunque a sospenderlo.
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
        <button v-if="programmaGiardino" type="button" class="pill-mini pill-mini--del" @click="chiediConferma('giardino', 'Tutto il giardino', 'giardino')" aria-label="Rimuovi programma giardino">×</button>
      </div>

      <template v-for="z in zoneList" :key="z.nome">
        <div class="dest">
          <!-- L'area che espande/comprime resta fratella dei due pill-mini,
               mai loro contenitore: un elemento interattivo annidato dentro
               un altro (qui role="button") è l'anti-pattern ARIA vietato in
               questo progetto (stesso principio di AttivitaRiga.vue). -->
          <div class="irr-zrow__main" role="button" tabindex="0"
            :aria-expanded="espanse.has(z.nome)"
            :aria-label="`${espanse.has(z.nome) ? 'Comprimi' : 'Espandi'} zona ${z.nome}`"
            @click="toggleZona(z.nome)" @keydown.enter="toggleZona(z.nome)" @keydown.space.prevent="toggleZona(z.nome)">
            <Icon :name="store.iconaZona(z.nome)" class="dest__ic" />
            <span class="dest__n">{{ z.nome }}</span>
            <span v-if="programmaZona(z.nome)" class="badge badge-ok">ogni {{ programmaZona(z.nome).ogniGiorni }} gg</span>
            <span v-else class="dest__c" style="color:var(--ink-soft);">{{ ereditaTesto(programmaGiardino) }}</span>
            <Icon name="back" class="dest__chev" :style="{ transform: espanse.has(z.nome) ? 'rotate(-90deg)' : 'rotate(90deg)' }" />
          </div>
          <div class="irr-zrow__act">
            <button type="button" class="pill-mini" @click="apriModifica({ zona: z.nome }, z.nome, programmaZona(z.nome)?.ogniGiorni)" :aria-label="`Modifica programma di ${z.nome}`">
              <Icon name="matita" />
            </button>
            <button v-if="programmaZona(z.nome)" type="button" class="pill-mini pill-mini--del" @click="chiediConferma({ zona: z.nome }, z.nome, 'zona')" :aria-label="`Rimuovi programma di ${z.nome}`">×</button>
          </div>
        </div>
        <div v-if="espanse.has(z.nome)" class="destlist" style="padding-left:30px;">
          <template v-for="sz in sottozoneDellaZona(z.nome)" :key="sz.nome">
            <div class="dest">
              <div class="irr-zrow__main" role="button" tabindex="0"
                :aria-expanded="espanse.has(chiaveSottozona(z.nome, sz.nome))"
                :aria-label="`${espanse.has(chiaveSottozona(z.nome, sz.nome)) ? 'Comprimi' : 'Espandi'} sottozona ${sz.nome}`"
                @click="toggleZona(chiaveSottozona(z.nome, sz.nome))" @keydown.enter="toggleZona(chiaveSottozona(z.nome, sz.nome))" @keydown.space.prevent="toggleZona(chiaveSottozona(z.nome, sz.nome))">
                <Icon :name="store.iconaSottozona(z.nome, sz.nome)" class="dest__ic" />
                <span class="dest__n">{{ sz.nome }}</span>
                <span v-if="programmaSottozona(z.nome, sz.nome)" class="badge badge-ok">ogni {{ programmaSottozona(z.nome, sz.nome).ogniGiorni }} gg</span>
                <span v-else class="dest__c" style="color:var(--ink-soft);">{{ ereditaTesto(programmaEffettivoZona(z.nome)) }}</span>
                <Icon name="back" class="dest__chev" :style="{ transform: espanse.has(chiaveSottozona(z.nome, sz.nome)) ? 'rotate(-90deg)' : 'rotate(90deg)' }" />
              </div>
              <div class="irr-zrow__act">
                <button type="button" class="pill-mini" @click="apriModifica({ zona: z.nome, sottozona: sz.nome }, `${z.nome} · ${sz.nome}`, programmaSottozona(z.nome, sz.nome)?.ogniGiorni)" :aria-label="`Modifica programma di ${sz.nome}`">
                  <Icon name="matita" />
                </button>
                <button v-if="programmaSottozona(z.nome, sz.nome)" type="button" class="pill-mini pill-mini--del" @click="chiediConferma({ zona: z.nome, sottozona: sz.nome }, `${z.nome} · ${sz.nome}`, 'sottozona')" :aria-label="`Rimuovi programma di ${sz.nome}`">×</button>
              </div>
            </div>
            <div v-if="espanse.has(chiaveSottozona(z.nome, sz.nome))" class="destlist" style="padding-left:30px;">
              <div v-for="p in pianteDellaZona(z.nome, sz.nome)" :key="p.id" class="dest">
                <Icon name="foglia" class="dest__ic" style="color:var(--sage);" />
                <span class="dest__n">{{ nomeSpecie(p) }}<span v-if="p.varieta"> — {{ p.varieta }}</span></span>
                <span v-if="programmaPianta(p.id)" class="badge badge-ok">ogni {{ programmaPianta(p.id).ogniGiorni }} gg</span>
                <span v-else class="dest__c" style="color:var(--ink-soft);">{{ ereditaTesto(programmaEffettivoSottozona(z.nome, sz.nome)) }}</span>
                <button type="button" class="pill-mini" @click="apriModifica({ pianta: p.id }, nomeSpecie(p), programmaPianta(p.id)?.ogniGiorni)" :aria-label="`Modifica programma di ${nomeSpecie(p)}`">
                  <Icon name="matita" />
                </button>
                <button v-if="programmaPianta(p.id)" type="button" class="pill-mini pill-mini--del" @click="chiediConferma({ pianta: p.id }, nomeSpecie(p), 'pianta')" :aria-label="`Rimuovi programma di ${nomeSpecie(p)}`">×</button>
              </div>
              <p v-if="!pianteDellaZona(z.nome, sz.nome).length" style="font-size:12px;color:var(--ink-soft);padding:10px 2px;">Nessuna pianta in questa sottozona.</p>
            </div>
          </template>

          <div v-for="p in pianteDellaZona(z.nome, null)" :key="p.id" class="dest">
            <Icon name="foglia" class="dest__ic" style="color:var(--sage);" />
            <span class="dest__n">{{ nomeSpecie(p) }}<span v-if="p.varieta"> — {{ p.varieta }}</span></span>
            <span v-if="programmaPianta(p.id)" class="badge badge-ok">ogni {{ programmaPianta(p.id).ogniGiorni }} gg</span>
            <span v-else class="dest__c" style="color:var(--ink-soft);">{{ ereditaTesto(programmaEffettivoZona(z.nome)) }}</span>
            <button type="button" class="pill-mini" @click="apriModifica({ pianta: p.id }, nomeSpecie(p), programmaPianta(p.id)?.ogniGiorni)" :aria-label="`Modifica programma di ${nomeSpecie(p)}`">
              <Icon name="matita" />
            </button>
            <button v-if="programmaPianta(p.id)" type="button" class="pill-mini pill-mini--del" @click="chiediConferma({ pianta: p.id }, nomeSpecie(p), 'pianta')" :aria-label="`Rimuovi programma di ${nomeSpecie(p)}`">×</button>
          </div>

          <p v-if="!sottozoneDellaZona(z.nome).length && !pianteDellaZona(z.nome, null).length" style="font-size:12px;color:var(--ink-soft);padding:10px 2px;">Nessuna sottozona né pianta in questa zona.</p>
        </div>
      </template>

      <p v-if="!zoneList.length" style="font-size:12px;color:var(--ink-soft);padding:10px 2px;">Nessuna zona configurata.</p>
    </div>

    <FoglioLaterale :model-value="mostraForm" @update:model-value="v => { if (!v) chiudiForm() }" :titolo="titoloForm">
      <div v-if="mostraForm" class="foglio-form">
        <div v-if="suggerimento" class="irr-suggerimento">
          <ZorbaLogo mini />
          <p v-if="suggerimento.tipo === 'numero'">
            Zorba consiglia: ogni {{ suggerimento.ogniGiorni }} giorni.
            <button v-if="giorniForm !== suggerimento.ogniGiorni" type="button" class="link-reset" @click="giorniForm = suggerimento.ogniGiorni">Usa questo</button>
          </p>
          <p v-else>
            Zorba nota una differenza: <strong>{{ suggerimento.piuEsigente }}</strong> ha bisogno di acqua ogni {{ suggerimento.minGiorni }} giorni, ma <strong>{{ suggerimento.menoEsigente }}</strong> regge fino a ogni {{ suggerimento.maxGiorni }} — troppo diverse per un programma comune. Conviene impostarle una per una.
          </p>
        </div>
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

    <ModalConferma
      :aperto="!!daEliminare"
      :titolo="titoloConferma"
      :messaggio="messaggioConferma"
      :caricamento="eliminando"
      :errore="erroreEliminazione"
      @conferma="confermaEliminazione"
      @annulla="annullaEliminazione"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useIrrigazioneApi } from '@/composables/useIrrigazioneApi'
import FoglioLaterale from '@/components/FoglioLaterale.vue'
import ModalConferma from '@/components/ModalConferma.vue'
import Spinner from '@/components/Spinner.vue'
import Icon from '@/components/Icon.vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import { suggerimentoIrrigazione } from '@/composables/useSuggerimentoIrrigazione'

const store = useDatiStore()
const irrigazioneApi = useIrrigazioneApi()

onMounted(() => store.caricaTutto())

const zoneList = computed(() => Object.values(store.zone ?? {}))
const piante = computed(() => Object.entries(store.piante ?? {}).map(([id, p]) => ({ id, ...p })))

// nomeSottozona: null per le piante senza sottozona (mostrate direttamente
// sotto la zona), altrimenti filtra sulla sottozona specifica.
function pianteDellaZona(nomeZona, nomeSottozona) {
  return piante.value.filter(p => p.zona === nomeZona && (p.sottozona ?? null) === nomeSottozona)
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

// Chiave composta "<zona>|<sottozona>", stesso separatore di
// raggruppaAttivita.js — usata sia per leggere store.programmiIrrigazione.sottozone
// sia come chiave del Set `espanse` (nessuna collisione: i nomi di zona non
// contengono mai "|").
function chiaveSottozona(zona, sottozona) {
  return `${zona}|${sottozona}`
}
function sottozoneDellaZona(nomeZona) {
  return Object.values(store.sottozone?.[nomeZona] ?? {})
}
function programmaSottozona(zona, sottozona) {
  return store.programmiIrrigazione?.sottozone?.[chiaveSottozona(zona, sottozona)] ?? null
}
function programmaEffettivoSottozona(zona, sottozona) {
  return programmaSottozona(zona, sottozona) ?? programmaEffettivoZona(zona)
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
const suggerimento = ref(null)

// Le piante fisicamente coperte da questo livello, a prescindere da un
// eventuale override più specifico già impostato su una di loro — il
// consiglio descrive cosa c'è in quel punto del giardino, non ricalcola
// la cascata reale (quella resta compito di useIrrigazioneAuto.js).
function pianteCoperte(target) {
  if (target.pianta) {
    const p = piante.value.find(pp => pp.id === target.pianta)
    return p ? [p] : []
  }
  if (target.sottozona) return pianteDellaZona(target.zona, target.sottozona)
  return piante.value.filter(p => p.zona === target.zona)
}

function apriModifica(target, titolo, valoreAttuale) {
  targetForm.value = target
  titoloForm.value = titolo
  giorniForm.value = valoreAttuale ?? null
  errore.value = null
  suggerimento.value = target === 'giardino' ? null : suggerimentoIrrigazione(pianteCoperte(target), store.specie)
  mostraForm.value = true
}
function chiudiForm() {
  mostraForm.value = false
  targetForm.value = null
  suggerimento.value = null
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
// Conferma prima di rimuovere un programma: a livello giardino è l'azione
// dal raggio d'azione più ampio della pagina (ogni pianta senza un livello
// più specifico torna a mostrare le cure da fare a mano), quindi merita
// la stessa protezione che ZoneView/SottozoneView danno già all'eliminazione
// di una zona/sottozona — non solo un click su una ×.
const daEliminare = ref(null) // { target, titolo, livello }
const eliminando = ref(false)
const erroreEliminazione = ref(null)

function chiediConferma(target, titolo, livello) {
  daEliminare.value = { target, titolo, livello }
  erroreEliminazione.value = null
}
function annullaEliminazione() {
  daEliminare.value = null
  erroreEliminazione.value = null
}
const titoloConferma = computed(() => `Rimuovere il programma di ${daEliminare.value?.titolo}?`)
const messaggioConferma = computed(() => daEliminare.value?.livello === 'giardino'
  ? 'Ogni pianta senza un programma più specifico tornerà a mostrare le cure da fare a mano.'
  : 'Le piante coperte solo da questo programma torneranno a ereditare dal livello superiore.')

async function confermaEliminazione() {
  if (!daEliminare.value) return
  eliminando.value = true
  erroreEliminazione.value = null
  try {
    await irrigazioneApi.rimuoviProgramma(daEliminare.value.target)
    daEliminare.value = null
  } catch (e) {
    erroreEliminazione.value = 'Rimozione non riuscita. Riprova.'
  } finally {
    eliminando.value = false
  }
}
</script>

<style scoped>
/* Regola del Nome in Fraunces (DESIGN.md): ogni nome — qui giardino, zona,
   sottozona, pianta — usa il font display, come già fanno .zname/.szname
   in ZoneView.vue/SottozoneView.vue. */
.dest__n { font-family: var(--font-display); }
/* Area cliccabile che espande/comprime una zona: fratella, non contenitore,
   dei due pill-mini (vedi commento nel template). */
.irr-zrow__main { display:flex; align-items:center; gap:11px; flex:1; min-width:0; cursor:pointer; }
.irr-zrow__main:focus-visible { outline:none; box-shadow: inset 0 0 0 3px var(--gold); }
.irr-zrow__act { display:flex; gap:6px; flex-wrap:wrap; }
.dest .pill-mini:hover { border-color:var(--sage-light); color:var(--sage); }
.dest .pill-mini svg { width:12px; height:12px; }
.dest .pill-mini--del { color:var(--rose-ink); }
.dest .pill-mini--del:hover { border-color:var(--rose); color:var(--rose-ink); }

.irr-suggerimento { display:flex; align-items:flex-start; gap:8px; margin-bottom:12px; }
.irr-suggerimento p { margin:0; font-size:12.5px; line-height:1.5; color:var(--ink-mid); }
.irr-suggerimento .link-reset {
  background: none; border: none; padding: 0; margin-left: 4px;
  font-size: 12.5px; color: var(--sage-dark); text-decoration: underline;
  cursor: pointer;
}
.irr-suggerimento .link-reset:hover { color: var(--sage); }
</style>
