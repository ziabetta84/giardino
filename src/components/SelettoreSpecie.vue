<template>
  <div class="form-card" style="position:relative;">
    <label class="field-label">Specie *</label>
    <input
      ref="inputRef"
      v-model="specieQuery"
      @focus="dropdownAperto = true"
      @click="dropdownAperto = true"
      @blur="chiudiDropdown"
      placeholder="Cerca specie…"
      class="form-input"
      autocomplete="off"
    >
    <div v-if="dropdownAperto" class="specie-dropdown">
      <template v-if="mostraGruppi">
        <div class="dd-group"><div class="slabel">Nel tuo giardino</div></div>
        <div v-for="s in speciePossedute" :key="s.key" class="dd-row" @mousedown.prevent="selezionaSpecie(s)">
          <span class="dd-thumb" :class="{ leaf: !s.immagine?.url }"
            :style="s.immagine?.url ? { backgroundImage: `url(${urlMiniatura(s.immagine.url, 96)})` } : null">
            <Icon v-if="!s.immagine?.url" name="foglia" />
          </span>
          <span class="dd-m">
            <span class="dd-name">
              {{ s.nome }}
              <span v-if="s.cultivarDi" class="badge-mini cv">cultivar</span>
              <span v-else-if="!s.verificata" class="badge-mini bz">bozza</span>
            </span>
            <span v-if="s.nomeScientifico" class="dd-sci">{{ s.nomeScientifico }}</span>
          </span>
        </div>
        <div class="dd-group"><div class="slabel">Nel catalogo</div></div>
        <div v-for="s in specieCatalogo" :key="s.key" class="dd-row" @mousedown.prevent="selezionaSpecie(s)">
          <span class="dd-thumb" :class="{ leaf: !s.immagine?.url }"
            :style="s.immagine?.url ? { backgroundImage: `url(${urlMiniatura(s.immagine.url, 96)})` } : null">
            <Icon v-if="!s.immagine?.url" name="foglia" />
          </span>
          <span class="dd-m">
            <span class="dd-name">
              {{ s.nome }}
              <span v-if="s.cultivarDi" class="badge-mini cv">cultivar</span>
              <span v-else-if="!s.verificata" class="badge-mini bz">bozza</span>
            </span>
            <span v-if="s.nomeScientifico" class="dd-sci">{{ s.nomeScientifico }}</span>
          </span>
        </div>
      </template>
      <template v-else>
        <div v-for="s in specieFiltrate" :key="s.key" class="dd-row" @mousedown.prevent="selezionaSpecie(s)">
          <span class="dd-thumb" :class="{ leaf: !s.immagine?.url }"
            :style="s.immagine?.url ? { backgroundImage: `url(${urlMiniatura(s.immagine.url, 96)})` } : null">
            <Icon v-if="!s.immagine?.url" name="foglia" />
          </span>
          <span class="dd-m">
            <span class="dd-name">
              {{ s.nome }}
              <span v-if="s.cultivarDi" class="badge-mini cv">cultivar</span>
              <span v-else-if="!s.verificata" class="badge-mini bz">bozza</span>
            </span>
            <span v-if="s.nomeScientifico" class="dd-sci">{{ s.nomeScientifico }}</span>
          </span>
        </div>
      </template>

      <p v-if="ricercaInCorso" class="dd-nota"><Spinner style="width:12px;height:12px;" />Ricerca nel catalogo…</p>
      <p v-if="ricercaOffline" class="dd-nota">Ricerca nel catalogo non disponibile offline — solo le specie già caricate.</p>
      <p v-if="!specieFiltrate.length && specieQuery.trim() && !ricercaInCorso" class="dd-nota">Nessuna specie trovata</p>
      <p v-if="!specieQuery.trim()" class="dd-nota">Specie del tuo giardino — digita per cercare in tutto il catalogo, cultivar inclusi</p>

      <RouterLink to="/agente" class="dd-foot" @mousedown.prevent>
        <span>Non la trovi?</span><span class="dd-foot-cta">Chiedi a Zorba di aggiungerla →</span>
      </RouterLink>
    </div>

    <!-- Card compatta della specie scelta: la scheda completa vive nel foglio. -->
    <div v-if="specieSelezionata && !dropdownAperto" class="scheda-chosen">
      <span class="sc-th" :style="hero ? { backgroundImage: `url(${hero.thumbUrl})` } : null"></span>
      <span class="sc-m">
        <span class="sc-nm">{{ specieSelezionata.nome }}</span>
        <span v-if="specieSelezionata.specie" class="sc-sci">{{ specieSelezionata.specie }}</span>
        <span class="sc-acts">
          <button type="button" @click="dossierAperto = true">Vedi scheda completa</button>
          <button type="button" class="alt" @click="apriRicerca">Cambia</button>
        </span>
      </span>
    </div>

    <FoglioLaterale v-if="specieSelezionata" v-model="dossierAperto">
      <template #intestazione><span></span></template>
      <div class="dossier">
        <div class="specie-ghost" aria-hidden="true"><svg viewBox="0 0 512 512" aria-hidden="true"><g transform="translate(0 512) scale(0.1 -0.1)"><path class="sg" d="M3759 4349 c-27 -27 -22 -60 25 -164 55 -122 49 -157 -45 -277 -45 -57 -74 -132 -84 -213 -10 -75 -29 -130 -59 -169 -13 -17 -26 -41 -30 -54 -17 -52 50 -169 115 -202 25 -13 70 -23 120 -27 96 -7 129 -27 129 -76 0 -45 -34 -95 -78 -115 -32 -15 -72 -17 -282 -16 -135 0 -297 6 -360 12 -213 22 -501 26 -660 8 -148 -16 -171 -21 -345 -74 -119 -36 -187 -64 -405 -169 -160 -77 -376 -157 -452 -168 l-38 -6 0 -196 0 -196 68 6 c38 4 114 16 171 28 56 11 104 19 106 17 3 -2 9 -84 15 -182 6 -99 13 -183 16 -187 2 -5 5 -41 6 -82 0 -63 -4 -81 -31 -135 -17 -34 -35 -62 -39 -62 -9 0 -131 -99 -177 -143 -20 -19 -40 -50 -45 -68 -5 -18 -14 -114 -20 -213 -6 -100 -18 -241 -27 -314 -18 -150 -12 -190 34 -237 51 -51 79 -59 211 -63 129 -4 167 3 210 41 16 15 22 31 22 64 0 54 -29 87 -91 103 -24 6 -50 13 -56 15 -21 7 -15 65 17 155 16 47 30 94 30 105 1 11 9 35 18 54 14 29 26 37 67 48 65 16 330 60 419 68 38 4 75 9 83 12 22 8 15 -14 -22 -72 -20 -30 -38 -68 -41 -84 -14 -70 74 -165 281 -302 182 -120 202 -132 275 -162 90 -37 140 -46 251 -47 82 0 102 3 145 25 80 40 95 96 41 150 -36 36 -89 55 -151 55 -38 0 -126 34 -126 49 0 4 -40 42 -90 84 -49 43 -90 83 -90 90 0 18 204 143 315 193 142 64 572 204 649 211 76 7 72 11 122 -142 18 -55 56 -163 84 -240 29 -77 65 -178 81 -225 39 -112 77 -180 116 -206 52 -35 137 -47 300 -42 201 6 263 33 263 115 0 16 -7 39 -16 52 -20 28 -88 60 -126 61 -26 0 -28 3 -28 38 0 21 4 73 9 117 6 44 13 116 16 160 3 44 10 100 15 125 6 25 21 117 35 205 28 171 62 307 126 500 112 334 130 413 155 668 17 183 12 251 -38 502 -91 465 -355 899 -680 1117 -53 36 -104 45 -137 26 -23 -13 -26 -20 -24 -61 2 -26 -1 -47 -6 -47 -5 0 -28 21 -51 47 -64 73 -139 133 -166 133 -13 0 -33 -9 -45 -21z m661 -3244 c0 -17 9 -29 31 -41 31 -16 32 -17 26 -74 -9 -84 -37 -154 -64 -158 -17 -3 -24 3 -29 24 -8 30 2 231 12 257 9 25 24 20 24 -8z"/><path class="sg" d="M124 3636 c-52 -23 -68 -73 -60 -187 26 -406 211 -760 516 -990 108 -82 230 -139 390 -184 66 -19 315 -31 424 -20 l77 7 -3 198 c-2 109 -6 201 -9 204 -3 4 -17 2 -31 -3 -14 -5 -77 -15 -140 -22 -99 -11 -132 -10 -224 2 -60 9 -127 24 -149 34 -161 74 -273 169 -363 308 -86 132 -116 202 -162 377 -48 180 -68 227 -112 260 -38 28 -110 36 -154 16z"/></g></svg></div>

        <div v-if="hero" class="dh" :style="{ backgroundImage: `url(${hero.thumbUrl})` }">
          <div class="dh-scrim"></div>
          <span class="dh-chip">{{ statoBadge }}</span>
          <div class="dh-cap">
            <p class="dh-name">{{ specieSelezionata.nome }}</p>
            <p v-if="specieSelezionata.specie" class="dh-sci">{{ specieSelezionata.specie }}</p>
          </div>
          <a v-if="hero.attribuzione" :href="hero.fontePagina" target="_blank" rel="noopener"
            class="dh-credit" @click.stop>Foto: {{ hero.attribuzione }} / Wikimedia Commons</a>
        </div>
        <div v-else class="dh-np">
          <div class="np-name">{{ specieSelezionata.nome }}</div>
          <div v-if="specieSelezionata.specie" class="np-sci">{{ specieSelezionata.specie }}</div>
          <span class="np-badge">{{ statoBadge }}</span>
        </div>

        <div class="dossier-body">
          <div class="slabel">La specie</div>
          <p v-if="specieSelezionata.descrizione" class="prose">{{ specieSelezionata.descrizione }}</p>
          <p v-else class="prose dossier-vuoto">Nessuna descrizione per questa specie.</p>

          <template v-if="esigenzeVoci.length">
            <div class="slabel">Esigenze</div>
            <div class="kv">
              <div v-for="e in esigenzeVoci" :key="e.chiave">
                <span class="k"><Icon :name="e.icona" />{{ capitalizza(e.chiave) }}</span><span class="v">{{ e.valore }}</span>
              </div>
            </div>
          </template>

          <template v-if="cureRighe.length">
            <div class="slabel">Calendario cure</div>
            <div class="dossier-stagioni">
              <button v-for="s in STAGIONI_CAL" :key="s.val" type="button" class="pill"
                :class="{ active: stagioneCal === s.val }" @click="stagioneCal = s.val">{{ s.label }}</button>
            </div>
            <div class="care">
              <div v-for="r in cureRighe" :key="r.tipo" class="care__row">
                <span class="care__ic" :class="`care__ic--${r.tipo}`"><Icon :name="r.icona" /></span>
                <span class="care__m">
                  <span class="care__n">{{ r.label }}</span>
                  <span class="care__d" :class="{ 'care__d--none': !r.valore }">{{ r.valore || 'Non prevista in questa stagione' }}</span>
                </span>
              </div>
            </div>
          </template>

          <template v-if="coltivazioneVoci.length">
            <div class="slabel">Coltivazione</div>
            <div class="kv"><div v-for="c in coltivazioneVoci" :key="c.k"><span class="k">{{ c.k }}</span><span class="v">{{ c.v }}</span></div></div>
          </template>

          <template v-if="alertList.length">
            <div class="slabel">Note tecniche</div>
            <ul class="notelist"><li v-for="a in alertVisibili" :key="a">{{ a }}</li></ul>
            <button v-if="alertExtra > 0" type="button" class="dossier-more" @click="alertTuttiAperti = !alertTuttiAperti">
              {{ alertTuttiAperti ? 'Mostra meno' : `+ ${alertExtra} altre` }}
            </button>
          </template>
        </div>
      </div>
    </FoglioLaterale>
  </div>
</template>

<script setup>
// Selettore di specie: combobox con ricerca (catalogo di ~9.000+ voci, troppe
// per una <select> nativa). Sola lettura — il catalogo `specie` è dato
// condiviso in multiutenza: nuove specie si chiedono a Zorba (/agente).
// Estratto da EditPiantaView.vue perché riusato identico in "Zorba dice"
// (richiesta "revisione specie").
import { ref, computed, watch, onUnmounted, nextTick } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'
import { mappaSpecie, COLONNE_SPECIE, fondiEredita } from '@/stores/dati'
import { parseGiorni, stagione } from '@/composables/useCure'
import { urlMiniatura } from '@/composables/useWikimedia'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'
import FoglioLaterale from '@/components/FoglioLaterale.vue'

const props = defineProps({
  modelValue: { type: String, default: '' },
})
const emit = defineEmits(['update:modelValue'])

const store = useDatiStore()
const supabase = useSupabase()

const inputRef       = ref(null)
const specieQuery    = ref('')
const dropdownAperto = ref(false)
const dossierAperto  = ref(false)

// Con il catalogo esteso da PFAF (~8.700 voci e in crescita), non ha più
// senso caricarlo tutto in anticipo (issue #142): lo store all'avvio
// contiene solo le specie delle piante possedute e quelle verificate
// (i suggerimenti a campo vuoto, sotto). Da 2 caratteri in su la ricerca
// unisce il filtro immediato su ciò che è già in store a una ricerca live
// su Supabase (debounced, vedi avviaRicercaRemota), i cui risultati vengono
// fusi nello store così restano disponibili senza rifetch.
const specieFiltrate = computed(() => {
  const tuttiValori = Object.values(store.specie ?? {})
  const nomePerId = Object.fromEntries(tuttiValori.filter(s => s.id).map(s => [s.id, s.nome]))

  const tutte = Object.entries(store.specie ?? {})
    .map(([key, s]) => ({
      key,
      nome: s.nome ?? key,
      nomeScientifico: s.specie ?? '',
      verificata: s.stato_verifica === 'verificato',
      immagine: s.immagine ?? null,
      // un cultivar è una ricerca esplicita (digitando il nome del cultivar
      // stesso), mai un suggerimento a campo vuoto — vedi filtro sotto
      cultivarDi: s.specie_padre_id ? (nomePerId[s.specie_padre_id] ?? '') : null,
    }))
  const q = specieQuery.value.trim().toLowerCase()

  const base = q
    ? tutte.filter(s => s.nome.toLowerCase().includes(q) || s.nomeScientifico.toLowerCase().includes(q))
    : tutte.filter(s => s.verificata && !s.cultivarDi)

  return base
    // specie "vere" prima dei cultivar (es. "Rosa" ha 9.500+ cultivar: non
    // devono seppellire la specie stessa in una ricerca larga), poi
    // verificate, poi alfabetico
    .sort((a, b) => (!!a.cultivarDi - !!b.cultivarDi) || (b.verificata - a.verificata) || a.nome.localeCompare(b.nome))
    .slice(0, 50)
})

// Tendina raggruppata: "Nel tuo giardino" (specie verificate) vs "Nel
// catalogo" (il resto). Le due intestazioni compaiono solo quando entrambi
// i gruppi hanno voci; altrimenti la lista è piatta (es. campo vuoto → solo
// verificate).
const speciePossedute = computed(() => specieFiltrate.value.filter(s => s.verificata))
const specieCatalogo  = computed(() => specieFiltrate.value.filter(s => !s.verificata))
const mostraGruppi    = computed(() => speciePossedute.value.length > 0 && specieCatalogo.value.length > 0)

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
    // Niente filtro su specie_padre_id: la ricerca copre anche i cultivar
    // (un collezionista può cercare direttamente "Aureomarginatum" senza
    // passare dalla specie madre, vedi discussione issue #153, 2026-08-30).
    const [porNome, porScientifico] = await Promise.all([
      supabase.from('specie').select(COLONNE_SPECIE).ilike('nome', pattern).limit(50),
      supabase.from('specie').select(COLONNE_SPECIE).ilike('nome_scientifico', pattern).limit(50),
    ])
    if (porNome.error) throw porNome.error
    if (porScientifico.error) throw porScientifico.error
    if (mioToken !== tokenRicerca) return  // superata da una ricerca più recente

    const righe = [...(porNome.data ?? []), ...(porScientifico.data ?? [])]
    await risolviEMergeCultivar(righe)
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

// Risolve l'eredità dei cultivar presenti tra le righe appena arrivate da
// Supabase (ricerca o lookup diretto) prima di fonderle nello store: un
// cultivar senza dato proprio (quasi tutti, vedi issue #153) deve mostrare
// i campi di cura della specie madre a tutti i ~9 punti dell'app che
// leggono store.specie[…], non solo a questo componente. La madre di un
// cultivar già scelto altrove potrebbe non essere ancora tra le righe
// caricate: in quel caso va recuperata a parte (una query in più, rara:
// capita solo aprendo una pianta la cui specie è già un cultivar).
async function risolviEMergeCultivar(righe) {
  const mappate = mappaSpecie(righe)
  const perIdBatch = Object.fromEntries(Object.values(mappate).filter(s => s.id).map(s => [s.id, s]))
  const idMadriMancanti = [...new Set(
    Object.values(mappate)
      .filter(s => s.specie_padre_id && !perIdBatch[s.specie_padre_id] && !Object.values(store.specie ?? {}).some(m => m.id === s.specie_padre_id))
      .map(s => s.specie_padre_id)
  )]
  let perIdStore = {}
  if (idMadriMancanti.length) {
    const { data } = await supabase.from('specie').select(COLONNE_SPECIE).in('id', idMadriMancanti)
    if (data) {
      const madriMappate = mappaSpecie(data)
      store.specie = { ...(store.specie ?? {}), ...madriMappate }
      perIdStore = Object.fromEntries(Object.values(madriMappate).map(s => [s.id, s]))
    }
  }
  for (const slug of Object.keys(mappate)) {
    const s = mappate[slug]
    if (!s.specie_padre_id) continue
    const madre = perIdBatch[s.specie_padre_id] ?? perIdStore[s.specie_padre_id]
      ?? Object.values(store.specie ?? {}).find(m => m.id === s.specie_padre_id)
    mappate[slug] = fondiEredita(s, madre)
  }
  store.specie = { ...(store.specie ?? {}), ...mappate }
}

// Tiene il testo visualizzato allineato alla specie effettivamente selezionata
// (v-model esterno), sia al primo render sia quando cambia da fuori (es. il
// form padre la popola dopo un caricamento asincrono). Se il valore arriva
// da fuori e non è ancora nello store (non era né tra le verificate né tra
// le referenziate al bootstrap — capita editando una pianta la cui specie è
// un cultivar), va recuperato per risolvere l'eredità prima di mostrarlo.
watch(() => props.modelValue, async (val) => {
  if (val && !store.specie?.[val]) {
    const { data } = await supabase.from('specie').select(COLONNE_SPECIE).eq('slug', val).maybeSingle()
    if (data) await risolviEMergeCultivar([data])
  }
  if (!dropdownAperto.value) specieQuery.value = store.specie?.[val]?.nome ?? ''
}, { immediate: true })

function selezionaSpecie(s) {
  emit('update:modelValue', s.key)
  specieQuery.value = s.nome
  dropdownAperto.value = false
  // Apertura automatica della scheda alla prima scelta (richiesta di Rob).
  dossierAperto.value = true
}

function apriRicerca() {
  dropdownAperto.value = true
  nextTick(() => inputRef.value?.focus())
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

// --- Dossier in sola lettura della specie selezionata ---
// Il record nello store ha già descrizione/esigenze/alert/manutenzione/
// coltivazione/vaso: sia la ricerca live sia il watch su modelValue caricano
// con COLONNE_SPECIE.
const ICONA_ESIGENZA = {
  sole: 'sole', luce: 'sole', esposizione: 'sole',
  acqua: 'goccia', irrigazione: 'goccia', umidita: 'goccia', 'umidità': 'goccia',
  terreno: 'foglia', suolo: 'foglia', substrato: 'foglia', ph: 'foglia',
  temperatura: 'caldo', clima: 'caldo', gelo: 'gelo',
  spazio: 'pin', distanza: 'pin', potatura: 'potatura', concimazione: 'concimazione',
}
const ALERT_PREVIEW = 3
const alertTuttiAperti = ref(false)

function capitalizza(s) { s = String(s); return s.charAt(0).toUpperCase() + s.slice(1) }

const specieSelezionata = computed(() =>
  props.modelValue ? (store.specie?.[props.modelValue] ?? null) : null
)

const statoBadge = computed(() => {
  const s = specieSelezionata.value
  if (!s) return ''
  if (s.specie_padre_id) return 'cultivar'
  return s.stato_verifica === 'verificato' ? 'verificata' : 'bozza'
})

// Immagine hero della specie (Wikimedia): propria o, per i cultivar, ereditata
// dalla madre via fondiEredita nello store. urlMiniatura ridimensiona alla
// larghezza della scheda.
const hero = computed(() => {
  const img = specieSelezionata.value?.immagine
  return img?.url
    ? { thumbUrl: urlMiniatura(img.url, 480), attribuzione: img.attribuzione, fontePagina: img.fonte_pagina }
    : null
})

const esigenzeVoci = computed(() => {
  const e = specieSelezionata.value?.esigenze
  if (!e || typeof e !== 'object') return []
  return Object.entries(e)
    .filter(([, v]) => v != null && String(v).trim())
    .map(([chiave, valore]) => ({ chiave, valore, icona: ICONA_ESIGENZA[String(chiave).toLowerCase()] ?? 'foglia' }))
})

// Calendario cure: stesse tessere di "Stato cure" in Scheda Pianta, ma con le
// pill delle stagioni sopra — il valore mostrato è quello della stagione
// scelta. Solo i tipi con almeno una stagione compilata compaiono.
const STAGIONI_CAL = [
  { val: 'primavera', label: 'Primavera' },
  { val: 'estate',    label: 'Estate' },
  { val: 'autunno',   label: 'Autunno' },
  { val: 'inverno',   label: 'Inverno' },
]
const stagioneCal = ref(stagione())

const TIPI_CURA_DOSSIER = [
  { tipo: 'irrigazione',  label: 'Irrigazione',   icona: 'goccia' },
  { tipo: 'concimazione', label: 'Concimazione',  icona: 'concimazione' },
  { tipo: 'calcio',       label: 'Calcio',         icona: 'uovo' },
  { tipo: 'potatura',     label: 'Potatura',       icona: 'potatura' },
  { tipo: 'npk',          label: 'Fabbisogno NPK', icona: 'provetta' },
]

const cureRighe = computed(() => {
  const m = specieSelezionata.value?.manutenzione
  if (!m || typeof m !== 'object') return []
  const haStagioni = (blocco) =>
    blocco && typeof blocco === 'object' && Object.values(blocco).some(v => v != null && String(v).trim())
  return TIPI_CURA_DOSSIER
    .filter(t => haStagioni(m[t.tipo]))
    .map(t => {
      const grezzo = m[t.tipo]?.[stagioneCal.value]
      const testo = grezzo != null ? String(grezzo).trim() : ''
      let valore = ''
      if (testo) {
        if (t.tipo === 'irrigazione' || t.tipo === 'concimazione' || t.tipo === 'calcio') {
          const n = parseGiorni(testo)
          valore = typeof n === 'number' && n > 0
            ? (n === 1 ? 'Ogni giorno' : `Ogni ${n} giorni`)
            : testo
        } else {
          // potatura / npk: testo grezzo (descrittivo o "n-p-k")
          valore = testo
        }
      }
      return { tipo: t.tipo, label: t.label, icona: t.icona, valore }
    })
})

const coltivazioneVoci = computed(() => {
  const c = specieSelezionata.value?.coltivazione
  const v = []
  if (c && typeof c === 'object') {
    if (c.famiglia_botanica) v.push({ k: 'Famiglia', v: c.famiglia_botanica })
    if (c.giorni_germinazione) v.push({ k: 'Germinazione', v: `${c.giorni_germinazione} gg` })
    if (c.giorni_trapianto) v.push({ k: 'Al trapianto', v: `${c.giorni_trapianto} gg dalla semina` })
    if (c.giorni_raccolta) v.push({ k: 'Prima raccolta', v: `${c.giorni_raccolta} gg dal trapianto` })
    if (c.finestra_semina?.length) v.push({ k: 'Finestra semina', v: c.finestra_semina.join(', ') })
    if (c.finestra_trapianto?.length) v.push({ k: 'Finestra trapianto', v: c.finestra_trapianto.join(', ') })
    if (c.resistenza_gelo) v.push({ k: 'Resistenza al gelo', v: c.resistenza_gelo })
    if (c.spaziatura_cm) v.push({ k: 'Spaziatura', v: `${c.spaziatura_cm} cm` })
    if (c.consociazioni_favorevoli?.length) v.push({ k: 'Si abbina a', v: c.consociazioni_favorevoli.join(', ') })
    if (c.consociazioni_sfavorevoli?.length) v.push({ k: 'Evitare vicino a', v: c.consociazioni_sfavorevoli.join(', ') })
  }
  const vs = specieSelezionata.value?.vaso
  if (vs && typeof vs === 'object') {
    if (typeof vs.adatta === 'boolean') v.push({ k: 'Adatta al vaso', v: vs.adatta ? 'Sì' : 'No' })
    if (vs.dimensione_minima_litri) v.push({ k: 'Dim. minima vaso (L)', v: String(vs.dimensione_minima_litri) })
    if (vs.rinvaso_ogni_mesi) v.push({ k: 'Rinvaso (mesi)', v: String(vs.rinvaso_ogni_mesi) })
  }
  return v
})

const alertList = computed(() => {
  const a = specieSelezionata.value?.alert
  return Array.isArray(a) ? a.filter(x => x && String(x).trim()) : []
})
const alertVisibili = computed(() =>
  alertTuttiAperti.value ? alertList.value : alertList.value.slice(0, ALERT_PREVIEW)
)
const alertExtra = computed(() => Math.max(0, alertList.value.length - ALERT_PREVIEW))

// Ripiega l'elenco avvertenze e riallinea la stagione quando si cambia specie.
watch(() => props.modelValue, () => {
  alertTuttiAperti.value = false
  stagioneCal.value = stagione()
})
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
  max-height: 280px;
  overflow-y: auto;
  z-index: 50;
}
.dd-group {
  padding: 11px 13px 4px;
}
.dd-group .slabel {
  margin: 0;
}
.dd-row {
  display: flex;
  align-items: center;
  gap: 11px;
  padding: 9px 13px;
  cursor: pointer;
}
.dd-row:hover {
  background: var(--sage-pale);
}
.dd-row + .dd-row {
  border-top: 1px solid var(--cream-dark);
}
.dd-thumb {
  width: 34px; height: 34px;
  border-radius: 9px;
  flex: none;
  background-size: cover;
  background-position: center;
  background-color: var(--sage-bg);
  display: flex;
  align-items: center;
  justify-content: center;
}
.dd-thumb.leaf {
  background-color: var(--sage-light);
}
.dd-thumb :deep(svg) {
  width: 16px; height: 16px;
  color: var(--white);
}
.dd-m {
  flex: 1;
  min-width: 0;
}
.dd-name {
  font: 600 13.5px/1.25 var(--font-display);
  color: var(--ink);
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
  word-break: break-word;
}
.dd-sci {
  display: block;
  font: 400 11.5px/1.3 var(--font-display);
  font-style: italic;
  color: var(--ink-faint);
  margin-top: 1px;
}
.badge-mini {
  font: 700 8.5px/1 var(--font-sans);
  letter-spacing: .06em;
  text-transform: uppercase;
  padding: 2px 6px;
  border-radius: 999px;
  flex-shrink: 0;
}
.badge-mini.cv { background: var(--sage-pale); color: var(--sage-dark); }
.badge-mini.bz { background: var(--gold-pale); color: var(--gold-dark); }
.dd-nota {
  margin: 0;
  font: 400 11px/1.5 var(--font-sans);
  color: var(--ink-faint);
  padding: 6px 13px;
  display: flex;
  align-items: center;
  gap: 6px;
}
.dd-foot {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 14px;
  font: 500 12px/1.4 var(--font-sans);
  color: var(--ink-soft);
  background: var(--cream);
  border-top: 1px solid var(--cream-dark);
  text-decoration: none;
}
.dd-foot-cta {
  color: var(--sage-dark);
  font-weight: 600;
}

/* Card compatta dopo la scelta */
.scheda-chosen {
  margin-top: 12px;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: var(--cream);
  border: 1px solid var(--cream-dark);
  border-radius: 14px;
}
.sc-th {
  width: 44px; height: 44px;
  border-radius: 10px;
  flex: none;
  background: linear-gradient(140deg, #95b592, #5c7d60);
  background-size: cover;
  background-position: center;
}
.sc-m {
  flex: 1;
  min-width: 0;
  display: block;
}
.sc-nm {
  display: block;
  font: 600 14px/1.2 var(--font-display);
  color: var(--ink);
}
.sc-sci {
  display: block;
  font: 400 11.5px/1.3 var(--font-display);
  font-style: italic;
  color: var(--ink-faint);
  margin-top: 1px;
}
.sc-acts {
  display: flex;
  gap: 14px;
  margin-top: 5px;
}
.sc-acts button {
  background: none;
  border: 0;
  padding: 0;
  font: 600 11px/1 var(--font-sans);
  color: var(--sage-dark);
  cursor: pointer;
}
.sc-acts button.alt {
  color: var(--ink-soft);
}

/* Dossier nel foglio */
.dossier {
  position: relative;
  overflow: hidden;
  isolation: isolate;
}
.dossier :deep(.specie-ghost svg) {
  display: block;
  width: 100%;
  height: 100%;
}
.dh {
  position: relative;
  height: 190px;
  background: var(--sage-bg);
  background-size: cover;
  background-position: center;
}
.dh-scrim {
  position: absolute;
  inset: 0;
  background: linear-gradient(180deg, rgba(22,16,8,.26) 0%, rgba(22,16,8,0) 32%, rgba(22,16,8,0) 44%, rgba(22,16,8,.72) 100%);
}
.dh-chip {
  position: absolute;
  top: 13px; left: 14px;
  z-index: 3;
  font: 700 8.5px/1 var(--font-sans);
  letter-spacing: .06em;
  text-transform: uppercase;
  background: rgba(253,248,238,.24);
  color: #fdf8ee;
  padding: 4px 9px;
  border-radius: 999px;
}
.dh-cap {
  position: absolute;
  left: 16px; right: 16px; bottom: 16px;
  z-index: 3;
  color: #fdf8ee;
}
.dh-name {
  font: 700 22px/1.12 var(--font-display);
  margin: 0;
  letter-spacing: -.01em;
  text-shadow: 0 2px 14px rgba(0,0,0,.35);
}
.dh-sci {
  font: 400 12.5px/1.4 var(--font-display);
  font-style: italic;
  color: rgba(253,248,238,.9);
  margin: 2px 0 0;
}
.dh-credit {
  position: absolute;
  right: 8px; bottom: 8px;
  z-index: 3;
  font-size: 9.5px;
  color: rgba(253,248,238,.75);
  text-decoration: none;
  background: rgba(0,0,0,0.28);
  padding: 2px 8px;
  border-radius: 999px;
}
.dh-credit:hover { color: #fdf8ee; }
.dh-np {
  padding: 18px 16px 4px;
}
.dh-np .np-name {
  font: 600 19px/1.15 var(--font-display);
  color: var(--ink);
}
.dh-np .np-sci {
  font: 400 12.5px/1.35 var(--font-display);
  font-style: italic;
  color: var(--ink-faint);
  margin-top: 2px;
}
.dh-np .np-badge {
  display: inline-block;
  margin-top: 8px;
  font: 700 8.5px/1 var(--font-sans);
  letter-spacing: .06em;
  text-transform: uppercase;
  background: var(--gold-pale);
  color: var(--gold-dark);
  padding: 3px 8px;
  border-radius: 999px;
}
.dossier-body {
  padding: 16px 16px 26px;
}
.dossier-vuoto {
  font-style: italic;
  color: var(--ink-faint);
}
.dossier-stagioni {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin: -2px 0 12px;
}
.dossier-stagioni .pill {
  padding: 6px 12px;
  font-size: 11px;
}
.dossier-more {
  margin-top: 6px;
  background: none;
  border: none;
  cursor: pointer;
  font: 400 11px/1.4 var(--font-sans);
  color: var(--sage-dark);
  padding: 2px 0;
}
.notelist {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.notelist li {
  display: flex;
  gap: 8px;
  font: 400 11.5px/1.45 var(--font-sans);
  color: var(--ink-mid);
}
.notelist li::before {
  content: "";
  width: 5px; height: 5px;
  border-radius: 50%;
  background: var(--rose);
  flex: none;
  margin-top: 6px;
}
</style>
