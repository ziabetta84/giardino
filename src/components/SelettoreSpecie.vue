<template>
  <div class="card" style="padding:16px;position:relative;">
    <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Specie *</label>
    <input
      v-model="specieQuery"
      @focus="dropdownAperto = true"
      @click="dropdownAperto = true"
      @blur="chiudiDropdown"
      placeholder="Cerca specie…"
      class="form-input"
      autocomplete="off"
    >
    <div v-if="dropdownAperto" class="specie-dropdown">
      <div v-for="s in specieFiltrate" :key="s.key" class="specie-opzione-riga">
        <div class="specie-opzione" @mousedown.prevent="selezionaSpecie(s)" style="display:flex;align-items:center;gap:6px;">
          <span>{{ s.nome }}</span>
          <span v-if="!s.verificata" class="badge" style="font-size:10px;padding:1px 6px;background:var(--gold-pale);color:var(--gold-dark);flex-shrink:0;">bozza</span>
        </div>
        <button type="button" class="icon-btn" @mousedown.prevent="apriModificaSpecie(s)" title="Modifica specie"><Icon name="matita" style="width:13px;height:13px;" /></button>
      </div>
      <p v-if="ricercaInCorso" style="font-size:11px;color:var(--ink-faint);padding:6px 10px;display:flex;align-items:center;gap:6px;"><Spinner style="width:12px;height:12px;" />Ricerca nel catalogo…</p>
      <p v-if="ricercaOffline" style="font-size:11px;color:var(--rose-dark);padding:6px 10px;">Ricerca nel catalogo non disponibile offline — solo le specie già caricate.</p>
      <p v-if="!specieFiltrate.length && specieQuery.trim() && !ricercaInCorso" style="font-size:12px;color:var(--ink-faint);padding:8px 10px;">Nessuna specie trovata</p>
      <p v-if="!specieQuery.trim()" style="font-size:11px;color:var(--ink-faint);padding:6px 10px 2px;">Specie verificate — digita per cercare anche nel resto del catalogo</p>
      <div class="specie-opzione specie-nuova" @mousedown.prevent="apriNuovaSpecie">
        ＋ Aggiungi nuova specie{{ specieQuery.trim() ? ` "${specieQuery.trim()}"` : '' }}
      </div>
    </div>

    <!-- Modale nuova/modifica specie -->
    <Teleport to="body">
      <div v-if="mostraNuovaSpecie" class="overlay" @click.self="chiudiNuovaSpecie">
        <div class="modal-box">
          <h3 style="font-family:var(--font-serif);font-size:16px;font-weight:600;margin-bottom:12px;">
            {{ specieModificaOriginale ? 'Modifica specie' : 'Nuova specie' }}
          </h3>

          <div style="display:flex;gap:6px;margin-bottom:16px;">
            <button type="button" class="pill" :class="{ active: tabAttiva === 'generale' }" @click="tabAttiva = 'generale'">Generale</button>
            <button type="button" class="pill" :class="{ active: tabAttiva === 'cure' }" @click="tabAttiva = 'cure'">Cure</button>
            <button type="button" class="pill" :class="{ active: tabAttiva === 'coltivazione' }" @click="tabAttiva = 'coltivazione'">Coltivazione</button>
          </div>

          <p v-if="erroreSpecie" style="font-size:11px;color:var(--rose-dark);margin:0 0 10px;">{{ erroreSpecie }}</p>

          <!-- Tab Generale -->
          <template v-if="tabAttiva === 'generale'">
            <label class="campo-label">Nome comune *</label>
            <input v-model="nuovaSpecie.nome" placeholder="es. Basilico" class="form-input" style="margin-bottom:10px;">
            <label class="campo-label">Nome scientifico</label>
            <input v-model="nuovaSpecie.nomeScientifico" placeholder="es. Passiflora caerulea" class="form-input" style="margin-bottom:10px;">

            <label class="campo-label">Descrizione</label>
            <textarea v-model="nuovaSpecie.descrizione" placeholder="Descrizione libera (opzionale)"
              rows="2" class="form-input" style="resize:vertical;font-family:inherit;margin-bottom:10px;"></textarea>

            <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Esigenze (opzionale)</label>
            <label class="campo-label">Luce</label>
            <input v-model="nuovaSpecie.luce" placeholder="es. Pieno sole" class="form-input" style="margin-bottom:8px;">
            <label class="campo-label">Acqua</label>
            <input v-model="nuovaSpecie.acqua" placeholder="es. Moderata" class="form-input" style="margin-bottom:8px;">
            <label class="campo-label">Terreno</label>
            <input v-model="nuovaSpecie.terreno" placeholder="es. Ben drenato" class="form-input" style="margin-bottom:16px;">

            <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:2px;">Avvertenze (opzionale)</label>
            <p style="font-size:11px;color:var(--ink-faint);margin:0 0 6px;">Una per riga, es. "teme ristagni", "non tollera calcare".</p>
            <textarea v-model="nuovaSpecie.alert" placeholder="Una avvertenza per riga…"
              rows="3" class="form-input" style="resize:vertical;font-family:inherit;margin-bottom:16px;"></textarea>

            <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Ciclo vitale (opzionale)</label>
            <div style="display:flex;gap:6px;flex-wrap:wrap;">
              <button type="button" class="pill" :class="{ active: nuovaSpecie.cicloVitale === 'perenne' }" @click="nuovaSpecie.cicloVitale = 'perenne'">Perenne</button>
              <button type="button" class="pill" :class="{ active: nuovaSpecie.cicloVitale === 'annuale' }" @click="nuovaSpecie.cicloVitale = 'annuale'">Annuale</button>
              <button type="button" class="pill" :class="{ active: nuovaSpecie.cicloVitale === 'biennale' }" @click="nuovaSpecie.cicloVitale = 'biennale'">Biennale</button>
            </div>
          </template>

          <!-- Tab Cure -->
          <template v-if="tabAttiva === 'cure'">
            <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:2px;">Manutenzione (opzionale)</label>
            <p style="font-size:11px;color:var(--ink-faint);margin:0 0 8px;">Ogni quanti giorni, per stagione — vuoto = non necessario. Usata dalle Attività per segnalare le cure in scadenza.</p>
            <div class="manutenzione-grid">
              <div></div>
              <div class="stagione-header">Pri</div>
              <div class="stagione-header">Est</div>
              <div class="stagione-header">Aut</div>
              <div class="stagione-header">Inv</div>

              <div class="tipo-label"><Icon name="goccia" style="width:13px;height:13px;flex-shrink:0;" />Irrigazione</div>
              <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.irrigazione.primavera" placeholder="gg">
              <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.irrigazione.estate" placeholder="gg">
              <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.irrigazione.autunno" placeholder="gg">
              <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.irrigazione.inverno" placeholder="gg">

              <div class="tipo-label"><Icon name="concimazione" style="width:13px;height:13px;flex-shrink:0;" />Concimazione</div>
              <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.primavera" placeholder="gg">
              <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.estate" placeholder="gg">
              <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.autunno" placeholder="gg">
              <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.inverno" placeholder="gg">

              <div class="tipo-label"><Icon name="provetta" style="width:13px;height:13px;flex-shrink:0;" />NPK</div>
              <input v-model="nuovaSpecie.manutenzione.npk.primavera" placeholder="N-P-K">
              <input v-model="nuovaSpecie.manutenzione.npk.estate" placeholder="N-P-K">
              <input v-model="nuovaSpecie.manutenzione.npk.autunno" placeholder="N-P-K">
              <input v-model="nuovaSpecie.manutenzione.npk.inverno" placeholder="N-P-K">

              <div class="tipo-label"><Icon name="provetta" style="width:13px;height:13px;flex-shrink:0;" />Calcio</div>
              <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.calcio.primavera" placeholder="gg">
              <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.calcio.estate" placeholder="gg">
              <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.calcio.autunno" placeholder="gg">
              <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.calcio.inverno" placeholder="gg">
            </div>
            <p style="font-size:11px;color:var(--ink-faint);margin:6px 0 0;">Calcio: da riempire solo per specie con beneficio documentato (es. marciume apicale su solanacee/cucurbitacee) — lascia vuoto per tutte le altre.</p>

            <label style="display:flex;align-items:center;gap:5px;font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;margin:12px 0 2px;">
              <Icon name="potatura" style="width:13px;height:13px;flex-shrink:0;" />Potatura (opzionale)
            </label>
            <p style="font-size:11px;color:var(--ink-faint);margin:0 0 8px;">Non è a cadenza fissa come le altre: testo libero per stagione, es. "taglio leggero", "post-fioritura", "nessuna".</p>
            <div style="display:flex;flex-direction:column;gap:6px;">
              <div>
                <label class="campo-label">Primavera</label>
                <input v-model="nuovaSpecie.manutenzione.potatura.primavera" placeholder="es. taglio leggero" class="form-input">
              </div>
              <div>
                <label class="campo-label">Estate</label>
                <input v-model="nuovaSpecie.manutenzione.potatura.estate" placeholder="es. nessuna" class="form-input">
              </div>
              <div>
                <label class="campo-label">Autunno</label>
                <input v-model="nuovaSpecie.manutenzione.potatura.autunno" placeholder="es. post-fioritura" class="form-input">
              </div>
              <div>
                <label class="campo-label">Inverno</label>
                <input v-model="nuovaSpecie.manutenzione.potatura.inverno" placeholder="es. nessuna" class="form-input">
              </div>
            </div>
          </template>

          <!-- Tab Coltivazione: la parte "in vaso" vale per ogni ciclo vitale,
               semina/trapianto/raccolta ha senso solo per annuale/biennale -->
          <template v-if="tabAttiva === 'coltivazione'">
            <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:2px;">Coltivazione in vaso (opzionale)</label>
            <p style="font-size:11px;color:var(--ink-faint);margin:0 0 8px;">Per capire se la specie regge il contenitore e come regolare cure e rinvaso.</p>

            <label class="campo-label">Adatta al vaso?</label>
            <div style="display:flex;gap:6px;margin-bottom:10px;">
              <button type="button" class="pill" :class="{ active: nuovaSpecie.vaso.adatta === true }" @click="nuovaSpecie.vaso.adatta = true">Sì</button>
              <button type="button" class="pill" :class="{ active: nuovaSpecie.vaso.adatta === false }" @click="nuovaSpecie.vaso.adatta = false">No</button>
              <button type="button" class="pill" :class="{ active: nuovaSpecie.vaso.adatta === null }" @click="nuovaSpecie.vaso.adatta = null">Non impostato</button>
            </div>

            <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:10px;">
              <div>
                <label class="campo-label">Dimensione minima (litri)</label>
                <input type="number" min="1" v-model.number="nuovaSpecie.vaso.dimensioneMinimaLitri" placeholder="es. 10" class="form-input">
              </div>
              <div>
                <label class="campo-label">Rinvaso ogni (mesi)</label>
                <input type="number" min="1" v-model.number="nuovaSpecie.vaso.rinvasoOgniMesi" placeholder="es. 12" class="form-input">
              </div>
            </div>
            <label class="campo-label">Fattore irrigazione in vaso</label>
            <p style="font-size:11px;color:var(--ink-faint);margin:0 0 6px;">Moltiplicatore rispetto alla cadenza a terra (es. 0.7 = irrigazione più ravvicinata in vaso).</p>
            <input type="number" min="0" step="0.1" v-model.number="nuovaSpecie.vaso.irrigazioneFattore" placeholder="es. 0.7" class="form-input" style="margin-bottom:16px;">

            <p v-if="nuovaSpecie.cicloVitale !== 'annuale' && nuovaSpecie.cicloVitale !== 'biennale'" style="font-size:12px;color:var(--ink-faint);padding:20px 0;text-align:center;border-top:1px solid var(--cream-dark);">
              Imposta il ciclo vitale su "Annuale" o "Biennale" nella tab Generale per compilare anche semina/trapianto/raccolta.
            </p>
            <template v-else>
              <p style="font-size:11px;color:var(--ink-faint);margin:0 0 12px;">Dati per generare in futuro un piano di semina/trapianto/raccolta — tutto facoltativo.</p>

              <label class="campo-label">Famiglia botanica</label>
              <input v-model="nuovaSpecie.coltivazione.famigliaBotanica" placeholder="es. Solanaceae" class="form-input" style="margin-bottom:10px;">

              <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:10px;">
                <div>
                  <label class="campo-label">Gg germinazione</label>
                  <input v-model="nuovaSpecie.coltivazione.giorniGerminazione" placeholder="es. 7-14" class="form-input">
                </div>
                <div>
                  <label class="campo-label">Gg al trapianto</label>
                  <input v-model="nuovaSpecie.coltivazione.giorniTrapianto" placeholder="es. 25-30" class="form-input">
                </div>
              </div>
              <label class="campo-label">Gg alla raccolta</label>
              <input v-model="nuovaSpecie.coltivazione.giorniRaccolta" placeholder="es. 60-70" class="form-input" style="margin-bottom:14px;">

              <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Finestra di semina</label>
              <div style="display:flex;gap:6px;margin-bottom:12px;">
                <button type="button" class="pill" :class="{ active: nuovaSpecie.coltivazione.finestraSemina.includes(s.val) }"
                  v-for="s in STAGIONI_PILL" :key="'sem-'+s.val" @click="toggleStagione('finestraSemina', s.val)">{{ s.label }}</button>
              </div>

              <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Finestra di trapianto</label>
              <div style="display:flex;gap:6px;margin-bottom:14px;">
                <button type="button" class="pill" :class="{ active: nuovaSpecie.coltivazione.finestraTrapianto.includes(s.val) }"
                  v-for="s in STAGIONI_PILL" :key="'trap-'+s.val" @click="toggleStagione('finestraTrapianto', s.val)">{{ s.label }}</button>
              </div>

              <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Resistenza al gelo</label>
              <div style="display:flex;gap:6px;margin-bottom:14px;flex-wrap:wrap;">
                <button type="button" class="pill" :class="{ active: nuovaSpecie.coltivazione.resistenzaGelo === r }"
                  v-for="r in ['nessuna','bassa','media','alta']" :key="r" @click="nuovaSpecie.coltivazione.resistenzaGelo = r">{{ r }}</button>
              </div>

              <label class="campo-label">Spaziatura (cm)</label>
              <input type="number" min="1" v-model.number="nuovaSpecie.coltivazione.spaziaturaCm" placeholder="es. 50" class="form-input" style="margin-bottom:14px;">

              <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:2px;">Consociazioni favorevoli</label>
              <p style="font-size:11px;color:var(--ink-faint);margin:0 0 6px;">Una per riga, es. "basilico", "carota".</p>
              <textarea v-model="nuovaSpecie.coltivazione.consociazioniFavorevoli" placeholder="Una specie per riga…"
                rows="2" class="form-input" style="resize:vertical;font-family:inherit;margin-bottom:12px;"></textarea>

              <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:2px;">Consociazioni sfavorevoli</label>
              <p style="font-size:11px;color:var(--ink-faint);margin:0 0 6px;">Una per riga.</p>
              <textarea v-model="nuovaSpecie.coltivazione.consociazioniSfavorevoli" placeholder="Una specie per riga…"
                rows="2" class="form-input" style="resize:vertical;font-family:inherit;"></textarea>
            </template>
          </template>

          <div style="display:flex;gap:10px;justify-content:flex-end;margin-top:16px;">
            <button class="btn btn-ghost" @click="chiudiNuovaSpecie" style="min-height:40px;padding:8px 16px;">Annulla</button>
            <button class="btn btn-sage" @click="salvaNuovaSpecie" :disabled="!nuovaSpecie.nome.trim() || salvandoSpecie"
              style="min-height:40px;padding:8px 16px;">
              <Spinner v-if="salvandoSpecie" /><span v-else>{{ specieModificaOriginale ? 'Salva' : 'Aggiungi' }}</span>
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
// Selettore/creatore di specie: combobox con ricerca (~100+ specie, troppe
// per una <select> nativa comoda su mobile) più un'opzione per creare o
// modificare una specie al volo. Estratto da EditPiantaView.vue perché
// riusato identico in "Zorba dice" (richiesta "revisione specie").
import { ref, computed, watch, onUnmounted } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'
import { useSupabase } from '@/composables/useSupabase'
import { mappaSpecie, COLONNE_SPECIE } from '@/stores/dati'
import { parseGiorni } from '@/composables/useCure'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const props = defineProps({
  modelValue: { type: String, default: '' },
})
const emit = defineEmits(['update:modelValue'])

const store = useDatiStore()
const { saveJSON } = useApi()
const supabase = useSupabase()

const specieQuery    = ref('')
const dropdownAperto = ref(false)

// Con il catalogo esteso da PFAF (~8.700 voci e in crescita), non ha più
// senso caricarlo tutto in anticipo (issue #142): lo store all'avvio
// contiene solo le specie delle piante possedute e quelle verificate
// (i suggerimenti a campo vuoto, sotto). Da 2 caratteri in su la ricerca
// unisce il filtro immediato su ciò che è già in store a una ricerca live
// su Supabase (debounced, vedi avviaRicercaRemota), i cui risultati vengono
// fusi nello store così restano disponibili senza rifetch.
const specieFiltrate = computed(() => {
  const tutte = Object.entries(store.specie ?? {})

    .map(([key, s]) => ({ key, nome: s.nome ?? key, nomeScientifico: s.specie ?? '', verificata: s.stato_verifica === 'verificato' }))
  const q = specieQuery.value.trim().toLowerCase()

  const base = q
    ? tutte.filter(s => s.nome.toLowerCase().includes(q) || s.nomeScientifico.toLowerCase().includes(q))
    : tutte.filter(s => s.verificata)

  return base
    .sort((a, b) => (b.verificata - a.verificata) || a.nome.localeCompare(b.nome))
    .slice(0, 50)
})

// Ricerca live: parte da 2 caratteri (stessa soglia del filtro locale sopra),
// con un debounce per non fare una query ad ogni tasto. Un token incrementale
// scarta le risposte arrivate fuori ordine (query più vecchia risolta dopo
// una più recente).
const ricercaInCorso = ref(false)
const ricercaOffline = ref(false)
let timerRicerca = null
let tokenRicerca = 0

function escapeIlike(testo) {
  return testo.replace(/[\\%_]/g, m => '\\' + m)
}

async function eseguiRicercaRemota(q) {
  const mioToken = ++tokenRicerca
  const pattern = `%${escapeIlike(q)}%`
  try {
    const [porNome, porScientifico] = await Promise.all([
      supabase.from('specie').select(COLONNE_SPECIE).ilike('nome', pattern).limit(50),
      supabase.from('specie').select(COLONNE_SPECIE).ilike('nome_scientifico', pattern).limit(50),
    ])
    if (porNome.error) throw porNome.error
    if (porScientifico.error) throw porScientifico.error
    if (mioToken !== tokenRicerca) return  // superata da una ricerca più recente

    store.specie = { ...(store.specie ?? {}), ...mappaSpecie([...(porNome.data ?? []), ...(porScientifico.data ?? [])]) }
    ricercaOffline.value = false
  } catch (e) {
    if (mioToken !== tokenRicerca) return
    console.error('Ricerca specie non disponibile', e)
    ricercaOffline.value = true
  } finally {
    if (mioToken === tokenRicerca) ricercaInCorso.value = false
  }
}

watch(specieQuery, (val) => {
  clearTimeout(timerRicerca)
  const q = val.trim()
  if (q.length < 2) {
    tokenRicerca++  // scarta un'eventuale ricerca ancora in volo
    ricercaInCorso.value = false
    ricercaOffline.value = false
    return
  }
  ricercaInCorso.value = true
  ricercaOffline.value = false
  timerRicerca = setTimeout(() => eseguiRicercaRemota(q), 300)
})

onUnmounted(() => clearTimeout(timerRicerca))

// Tiene il testo visualizzato allineato alla specie effettivamente selezionata
// (v-model esterno), sia al primo render sia quando cambia da fuori (es. il
// form padre la popola dopo un caricamento asincrono).
watch(() => props.modelValue, (val) => {
  if (!dropdownAperto.value) specieQuery.value = store.specie?.[val]?.nome ?? ''
}, { immediate: true })

function selezionaSpecie(s) {
  emit('update:modelValue', s.key)
  specieQuery.value = s.nome
  dropdownAperto.value = false
}

function chiudiDropdown() {
  // Ritardo breve: su alcuni browser mobile il blur dell'input scatta prima
  // che il tap sull'opzione (gestito da @mousedown.prevent) venga elaborato,
  // altrimenti il dropdown sparirebbe dal DOM prima della selezione.
  setTimeout(() => {
    dropdownAperto.value = false
    // Se l'utente ha digitato senza selezionare nulla dall'elenco, ripristina
    // il testo sul nome della specie effettivamente selezionata (o vuoto).
    specieQuery.value = store.specie?.[props.modelValue]?.nome ?? ''
  }, 150)
}

const mostraNuovaSpecie = ref(false)
const salvandoSpecie    = ref(false)
const erroreSpecie      = ref(null)
// Chiave della specie in modifica (null quando si sta creando una nuova
// specie): serve per sapere se salvaNuovaSpecie() deve creare o rinominare/
// aggiornare una voce esistente in specie.json.
const specieModificaOriginale = ref(null)

// Tab del modale: 'coltivazione' evita di allungare lo scroll per le ~99
// specie perenni/da appartamento a cui semina/trapianto non si applicano.
const tabAttiva = ref('generale')

const STAGIONI = ['primavera', 'estate', 'autunno', 'inverno']
const STAGIONI_PILL = [
  { val: 'primavera', label: 'Pri' },
  { val: 'estate',    label: 'Est' },
  { val: 'autunno',   label: 'Aut' },
  { val: 'inverno',   label: 'Inv' },
]

function vasoVuoto() {
  return { adatta: null, dimensioneMinimaLitri: null, rinvasoOgniMesi: null, irrigazioneFattore: null }
}

function coltivazioneVuota() {
  return {
    famigliaBotanica: '',
    giorniGerminazione: '',
    giorniTrapianto: '',
    giorniRaccolta: '',
    finestraSemina: [],
    finestraTrapianto: [],
    resistenzaGelo: '',
    spaziaturaCm: null,
    consociazioniFavorevoli: '',
    consociazioniSfavorevoli: '',
  }
}

function toggleStagione(campo, stagione) {
  const arr = nuovaSpecie.value.coltivazione[campo]
  const i = arr.indexOf(stagione)
  if (i === -1) arr.push(stagione)
  else arr.splice(i, 1)
}

function manutenzioneVuota() {
  const perStagione = () => ({ primavera: '', estate: '', autunno: '', inverno: '' })
  return { irrigazione: perStagione(), concimazione: perStagione(), potatura: perStagione(), npk: perStagione(), calcio: perStagione() }
}

// Per irrigazione/concimazione il campo del form è solo numerico ("ogni N
// giorni"), ma i dati reali delle specie esistenti spesso non sono in quel
// formato pulito (es. "ogni 7-10 giorni", "ogni 30 giorni, con concime per
// cactacee", "minima", "una volta al mese"). Il campo mostra comunque il
// primo numero trovato nel testo (per non apparire vuoto quando un valore
// in realtà c'è), ma il testo originale per intero resta la fonte di
// verità finché l'utente non cambia deliberatamente quel numero: così si
// vede cosa c'è già configurato, senza perdere un range o una nota
// (es. "solo se il terreno è asciutto") per il solo fatto di aver aperto e
// richiuso il form.
const manutenzioneOriginale = ref({
  irrigazione: { primavera: '', estate: '', autunno: '', inverno: '' },
  concimazione: { primavera: '', estate: '', autunno: '', inverno: '' },
  calcio: { primavera: '', estate: '', autunno: '', inverno: '' },
})
// Numero mostrato nel campo all'apertura del form (estratto dal testo
// originale): confrontato con il valore corrente al salvataggio per capire
// se l'utente lo ha davvero modificato (vedi generaManutenzione).
const manutenzioneNumeroIniziale = ref({
  irrigazione: { primavera: null, estate: null, autunno: null, inverno: null },
  concimazione: { primavera: null, estate: null, autunno: null, inverno: null },
  calcio: { primavera: null, estate: null, autunno: null, inverno: null },
})

// Riusa la stessa logica di useCure.js (non una regex propria): un tempo
// questo file ne teneva una copia separata che non riconosceva "settimane"
// come unità, mostrando "2" invece di "14" per un valore come "ogni 2
// settimane" — la stessa causa del bug poi trovato nel motore cure.
function estraiGiorniPuliti(testo) {
  if (typeof testo === 'number') return testo
  return parseGiorni(testo)
}

const nuovaSpecie = ref({ nome: '', nomeScientifico: '', descrizione: '', luce: '', acqua: '', terreno: '', alert: '', manutenzione: manutenzioneVuota(), cicloVitale: '', coltivazione: coltivazioneVuota(), vaso: vasoVuoto() })

// Converte i giorni inseriti nella tabella manutenzione nel formato testuale
// già usato da tutte le specie esistenti e atteso da useCure.js (parseGiorni
// estrae il primo numero da stringhe come "ogni 7 giorni"): così le nuove
// specie restano compatibili senza dover cambiare la logica di valutazione
// cure o migrare i dati esistenti. Campo vuoto → stringa vuota, trattata da
// valutaCura come "non necessario" (nessuna cura mai segnalata come urgente).
//
// La potatura fa eccezione: nei dati reali delle ~100 specie esistenti non è
// quasi mai a cadenza numerica ("ogni N giorni"), ma descrittiva/stagionale
// ("taglio leggero", "post-fioritura", "nessuna") — per questo resta testo
// libero invece di essere convertita da un numero di giorni.
function generaManutenzione(struttura, originale, numeroIniziale) {
  const risultato = {}
  for (const tipo of ['irrigazione', 'concimazione', 'calcio']) {
    risultato[tipo] = {}
    for (const stagione of STAGIONI) {
      const giorni = struttura?.[tipo]?.[stagione]
      const iniziale = numeroIniziale?.[tipo]?.[stagione] ?? null
      const modificato = typeof giorni === 'number' && giorni > 0 && giorni !== iniziale
      risultato[tipo][stagione] = modificato
        ? `ogni ${giorni} giorni`
        : (originale?.[tipo]?.[stagione] || (typeof giorni === 'number' && giorni > 0 ? `ogni ${giorni} giorni` : ''))
    }
  }
  risultato.potatura = {}
  for (const stagione of STAGIONI) {
    risultato.potatura[stagione] = (struttura?.potatura?.[stagione] || '').trim()
  }
  risultato.npk = {}
  for (const stagione of STAGIONI) {
    const valore = (struttura?.npk?.[stagione] || '').trim()
    risultato.npk[stagione] = valore || null
  }
  return risultato
}

function slug(testo) {
  return testo
    .toLowerCase()
    .normalize('NFD').replace(/\p{Diacritic}/gu, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

function apriNuovaSpecie() {
  nuovaSpecie.value = { nome: specieQuery.value.trim(), nomeScientifico: '', descrizione: '', luce: '', acqua: '', terreno: '', alert: '', manutenzione: manutenzioneVuota(), cicloVitale: '', coltivazione: coltivazioneVuota(), vaso: vasoVuoto() }
  tabAttiva.value = 'generale'
  manutenzioneOriginale.value = {
    irrigazione: { primavera: '', estate: '', autunno: '', inverno: '' },
    concimazione: { primavera: '', estate: '', autunno: '', inverno: '' },
    calcio: { primavera: '', estate: '', autunno: '', inverno: '' },
  }
  manutenzioneNumeroIniziale.value = {
    irrigazione: { primavera: null, estate: null, autunno: null, inverno: null },
    concimazione: { primavera: null, estate: null, autunno: null, inverno: null },
    calcio: { primavera: null, estate: null, autunno: null, inverno: null },
  }
  specieModificaOriginale.value = null
  erroreSpecie.value = null
  dropdownAperto.value = false
  mostraNuovaSpecie.value = true
}

function apriModificaSpecie(s) {
  const record = store.specie?.[s.key]
  if (!record) return

  const manutenzione = manutenzioneVuota()
  const originale = {
    irrigazione: { primavera: '', estate: '', autunno: '', inverno: '' },
    concimazione: { primavera: '', estate: '', autunno: '', inverno: '' },
    calcio: { primavera: '', estate: '', autunno: '', inverno: '' },
  }
  const numeroIniziale = {
    irrigazione: { primavera: null, estate: null, autunno: null, inverno: null },
    concimazione: { primavera: null, estate: null, autunno: null, inverno: null },
    calcio: { primavera: null, estate: null, autunno: null, inverno: null },
  }
  for (const tipo of ['irrigazione', 'concimazione', 'calcio']) {
    for (const stagione of STAGIONI) {
      const testo = record.manutenzione?.[tipo]?.[stagione] || ''
      const numero = estraiGiorniPuliti(testo)
      manutenzione[tipo][stagione] = numero ?? ''
      originale[tipo][stagione] = testo
      numeroIniziale[tipo][stagione] = numero
    }
  }
  for (const stagione of STAGIONI) {
    manutenzione.potatura[stagione] = record.manutenzione?.potatura?.[stagione] || ''
    manutenzione.npk[stagione] = record.manutenzione?.npk?.[stagione] || ''
  }

  const col = record.coltivazione ?? {}
  const vaso = record.vaso ?? {}
  nuovaSpecie.value = {
    nome: record.nome ?? s.nome,
    nomeScientifico: record.specie ?? '',
    descrizione: record.descrizione ?? '',
    luce: record.esigenze?.luce ?? '',
    acqua: record.esigenze?.acqua ?? '',
    terreno: record.esigenze?.terreno ?? '',
    alert: Array.isArray(record.alert) ? record.alert.join('\n') : (record.alert ?? ''),
    manutenzione,
    cicloVitale: record.ciclo_vitale ?? '',
    coltivazione: {
      famigliaBotanica: col.famiglia_botanica ?? '',
      giorniGerminazione: col.giorni_germinazione ?? '',
      giorniTrapianto: col.giorni_trapianto ?? '',
      giorniRaccolta: col.giorni_raccolta ?? '',
      finestraSemina: Array.isArray(col.finestra_semina) ? [...col.finestra_semina] : [],
      finestraTrapianto: Array.isArray(col.finestra_trapianto) ? [...col.finestra_trapianto] : [],
      resistenzaGelo: col.resistenza_gelo ?? '',
      spaziaturaCm: col.spaziatura_cm ?? null,
      consociazioniFavorevoli: Array.isArray(col.consociazioni_favorevoli) ? col.consociazioni_favorevoli.join('\n') : '',
      consociazioniSfavorevoli: Array.isArray(col.consociazioni_sfavorevoli) ? col.consociazioni_sfavorevoli.join('\n') : '',
    },
    vaso: {
      adatta: typeof vaso.adatta === 'boolean' ? vaso.adatta : null,
      dimensioneMinimaLitri: vaso.dimensione_minima_litri ?? null,
      rinvasoOgniMesi: vaso.rinvaso_ogni_mesi ?? null,
      irrigazioneFattore: vaso.irrigazione_fattore ?? null,
    },
  }
  manutenzioneOriginale.value = originale
  manutenzioneNumeroIniziale.value = numeroIniziale
  specieModificaOriginale.value = s.key
  erroreSpecie.value = null
  dropdownAperto.value = false
  tabAttiva.value = 'generale'
  mostraNuovaSpecie.value = true
}

function chiudiNuovaSpecie() {
  mostraNuovaSpecie.value = false
  erroreSpecie.value = null
}

async function salvaNuovaSpecie() {
  const nome = nuovaSpecie.value.nome.trim()
  if (!nome || salvandoSpecie.value) return
  const chiaveOriginale = specieModificaOriginale.value
  const chiave = slug(nome)
  if (!chiave) {
    erroreSpecie.value = 'Il nome della specie deve contenere almeno una lettera o un numero.'
    return
  }
  if (store.specie?.[chiave] && chiave !== chiaveOriginale) {
    erroreSpecie.value = 'Una specie con questo nome esiste già.'
    return
  }
  erroreSpecie.value = null

  salvandoSpecie.value = true
  try {
    // Se la specie viene rinominata, aggiorna prima le piante che la
    // referenziano (restano su GitHub, non ancora migrate) e solo dopo la
    // specie stessa su Supabase: se questo primo passaggio fallisce, la riga
    // specie non è ancora stata toccata e l'utente può semplicemente
    // riprovare. Nell'ordine opposto, un fallimento del salvataggio delle
    // piante dopo un rename già scritto lascerebbe sia piante orfane
    // (puntano a uno slug specie non più esistente) sia un nuovo tentativo
    // bloccato dal controllo duplicati (lo slug nuovo risulterebbe già
    // presente in store.specie).
    if (chiaveOriginale && chiaveOriginale !== chiave) {
      const nuovePiante = await saveJSON('piante.json', (correnti) => {
        const base = { ...(correnti ?? store.piante) }
        for (const id of Object.keys(base)) {
          if (base[id].specie === chiaveOriginale) {
            base[id] = { ...base[id], specie: chiave }
          }
        }
        return base
      })
      store.piante = nuovePiante
      if (props.modelValue === chiaveOriginale) emit('update:modelValue', chiave)
    }

    const riga = {
      slug: chiave,
      nome,
      nome_scientifico: nuovaSpecie.value.nomeScientifico.trim() || nome,
      descrizione: nuovaSpecie.value.descrizione.trim() || '',
      esigenze: {
        luce:    nuovaSpecie.value.luce.trim()    || '',
        acqua:   nuovaSpecie.value.acqua.trim()   || '',
        terreno: nuovaSpecie.value.terreno.trim() || '',
      },
      alert: nuovaSpecie.value.alert.split('\n').map(a => a.trim()).filter(Boolean),
      manutenzione: generaManutenzione(nuovaSpecie.value.manutenzione, manutenzioneOriginale.value, manutenzioneNumeroIniziale.value),
      ciclo_vitale: nuovaSpecie.value.cicloVitale || null,
      ciclo_colturale: null,
      vaso: null,
    }
    const v = nuovaSpecie.value.vaso
    if (v.adatta !== null || v.dimensioneMinimaLitri || v.rinvasoOgniMesi || v.irrigazioneFattore) {
      riga.vaso = {
        adatta: v.adatta,
        dimensione_minima_litri: v.dimensioneMinimaLitri || null,
        rinvaso_ogni_mesi: v.rinvasoOgniMesi || null,
        irrigazione_fattore: v.irrigazioneFattore || null,
      }
    }
    if (nuovaSpecie.value.cicloVitale === 'annuale' || nuovaSpecie.value.cicloVitale === 'biennale') {
      const col = nuovaSpecie.value.coltivazione
      riga.ciclo_colturale = {
        famiglia_botanica: col.famigliaBotanica.trim(),
        giorni_germinazione: col.giorniGerminazione.trim() || null,
        giorni_trapianto: col.giorniTrapianto.trim() || null,
        giorni_raccolta: col.giorniRaccolta.trim() || null,
        finestra_semina: [...col.finestraSemina],
        finestra_trapianto: [...col.finestraTrapianto],
        resistenza_gelo: col.resistenzaGelo || null,
        spaziatura_cm: col.spaziaturaCm || null,
        consociazioni_favorevoli: col.consociazioniFavorevoli.split('\n').map(v => v.trim()).filter(Boolean),
        consociazioni_sfavorevoli: col.consociazioniSfavorevoli.split('\n').map(v => v.trim()).filter(Boolean),
      }
    }

    const idOriginale = chiaveOriginale ? store.specie?.[chiaveOriginale]?.id : null
    let salvata
    if (idOriginale != null) {
      // Modifica di una specie esistente (anche con rename dello slug):
      // update per id, mai per slug, così il rename non rischia di colpire
      // zero righe se lo slug fosse già cambiato da un salvataggio precedente.
      const { data, error } = await supabase.from('specie').update(riga).eq('id', idOriginale).select(COLONNE_SPECIE)
      if (error) throw error
      salvata = data?.[0]
    } else {
      // Nuova specie, o modifica di una riga arrivata dal fallback statico
      // (senza id perché letta da specie.json, non da Supabase): in
      // quest'ultimo caso un insert è l'unica opzione sensata, non avendo una
      // riga Supabase da aggiornare.
      riga.stato_verifica = 'bozza'
      const { data, error } = await supabase.from('specie').insert(riga).select(COLONNE_SPECIE)
      if (error) throw error
      salvata = data?.[0]
    }

    const nuova = mappaSpecie(salvata ? [salvata] : [])
    const specieAggiornate = { ...(store.specie ?? {}) }
    if (chiaveOriginale && chiaveOriginale !== chiave) delete specieAggiornate[chiaveOriginale]
    Object.assign(specieAggiornate, nuova)
    store.specie = specieAggiornate

    selezionaSpecie({ key: chiave, nome })
    mostraNuovaSpecie.value = false
  } catch (e) {
    erroreSpecie.value = e.message || 'Errore durante il salvataggio della specie.'
  } finally {
    salvandoSpecie.value = false
  }
}
</script>

<style scoped>
.specie-dropdown {
  position: absolute;
  left: 16px; right: 16px;
  margin-top: 4px;
  background: var(--white);
  border: 1px solid var(--cream-dark);
  border-radius: 12px;
  box-shadow: 0 12px 32px rgba(42,34,24,0.15);
  max-height: 240px;
  overflow-y: auto;
  z-index: 50;
}
.specie-opzione {
  padding: 10px 12px;
  font-size: 13px;
  cursor: pointer;
}
.specie-opzione:hover {
  background: var(--cream);
}
.specie-nuova {
  color: var(--sage-dark);
  font-weight: 600;
  border-top: 1px solid var(--cream-dark);
}
.specie-opzione-riga {
  display: flex;
  align-items: center;
  gap: 4px;
  padding-right: 6px;
}
.specie-opzione-riga:hover {
  background: var(--cream);
}
.specie-opzione-riga .specie-opzione {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.specie-opzione-riga .icon-btn {
  background: none; border: none; cursor: pointer;
  padding: 4px 6px; border-radius: 8px; font-size: 13px; line-height: 1;
  color: var(--ink-soft); flex-shrink: 0;
}
.campo-label {
  display: block;
  font-size: 10px;
  color: var(--ink-faint);
  margin-bottom: 3px;
}
.manutenzione-grid {
  display: grid;
  grid-template-columns: minmax(0,1fr) 44px 44px 44px 44px;
  gap: 6px;
  align-items: center;
}
.stagione-header {
  font-size: 10px;
  color: var(--ink-faint);
  text-align: center;
}
.tipo-label {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 12px;
  color: var(--ink-mid);
}
.manutenzione-grid input {
  width: 100%;
  padding: 6px 4px;
  font-size: 12px;
  text-align: center;
  border: 1px solid var(--cream-dark);
  border-radius: 8px;
  font-family: inherit;
}
.overlay {
  position: fixed; inset: 0; z-index: 200;
  background: rgba(42,34,24,0.4);
  display: flex; align-items: center; justify-content: center; padding: 16px;
}
.modal-box {
  background: var(--white); border-radius: 20px; padding: 24px;
  width: 100%; max-width: 360px;
  max-height: 90vh; overflow-y: auto;
  box-shadow: 0 20px 60px rgba(42,34,24,0.2);
}
</style>
