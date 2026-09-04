<template>
  <div>
    <!-- Skeleton -->
    <template v-if="store.loading">
      <div class="skeleton" style="height:28px;width:60%;margin-bottom:8px;"></div>
      <div class="skeleton" style="height:14px;width:40%;margin-bottom:24px;"></div>
      <div class="skeleton" style="height:100px;border-radius:16px;margin-bottom:12px;"></div>
      <div class="skeleton" style="height:80px;border-radius:16px;"></div>
    </template>

    <template v-else-if="!pianta">
      <RouterLink to="/piante" class="phead-text__back"><Icon name="back" /> Piante</RouterLink>
      <div style="text-align:center;padding:60px 0;color:var(--ink-faint);">
        <div style="width:56px;height:56px;border-radius:50%;background:var(--olive-tile);display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
          <Icon name="foglia" style="width:24px;height:24px;" />
        </div>
        <p>Pianta non trovata</p>
      </div>
    </template>

    <template v-else>
      <!-- Header con foto + galleria. Con foto personali si scorre la
           galleria; senza, si usa l'immagine della specie (Wikimedia) come
           unica slide; senza nemmeno quella, header testuale ridotto. -->
      <div v-if="hasPhotos || fotoHero" class="phead-photo">
        <div class="gtrack" @scroll.passive="onGtrackScroll">
          <figure v-for="f in slides" :key="f.path ?? 'hero'" class="gslide" @click="apriLuce(f)">
            <img class="gimg" :src="f.thumbUrl" :alt="specie?.nome ?? pianta.specie" loading="lazy">
          </figure>
        </div>
        <div class="phead-scrim"></div>
        <span v-if="fotoPianta.length > 1" class="gnote">{{ fotoPianta.length }} foto</span>
        <RouterLink class="pbtn pbtn--back" to="/piante" aria-label="Torna a Piante"><Icon name="back" /></RouterLink>
        <RouterLink class="pbtn pbtn--edit" :to="`/piante/${route.params.id}/modifica`"><Icon name="matita" /> Modifica</RouterLink>
        <div v-if="fotoPianta.length > 1" class="gdots">
          <span v-for="(f, i) in fotoPianta" :key="i" :class="{ on: i === indiceFotoCorrente }"></span>
        </div>
        <div class="phead-cap">
          <span class="phead-cap__chips">
            <span class="chip"><Icon :name="pianta.sottozona ? store.iconaSottozona(pianta.zona, pianta.sottozona) : store.iconaZona(pianta.zona)" />{{ pianta.zona }}{{ pianta.sottozona ? ' · ' + pianta.sottozona : '' }}</span>
            <span v-if="pianta.coltivato_in" class="chip chip--ic" :title="labelColtivatoIn(pianta.coltivato_in)" :aria-label="labelColtivatoIn(pianta.coltivato_in)"><Icon :name="iconaColtivatoIn(pianta.coltivato_in)" /></span>
          </span>
          <h1 class="pname">{{ specie?.nome ?? pianta.specie }}<i v-if="pianta.varieta"> {{ pianta.varieta }}</i></h1>
          <p class="pbino">{{ specie?.specie }}</p>
        </div>
        <a v-if="soloHero && fotoHero?.fallback" :href="fotoHero.fonte_pagina" target="_blank" rel="noopener" class="phead-credit" @click.stop>
          Foto: {{ fotoHero.attribuzione }} / Wikimedia Commons
        </a>
      </div>

      <!-- Header testuale ridotto: nessuna foto disponibile -->
      <div v-else class="phead-text">
        <RouterLink to="/piante" class="phead-text__back"><Icon name="back" /> Piante</RouterLink>
        <div class="phead-text__body">
          <div class="phead-text__id">
            <span class="phead-text__chips">
              <span class="phead-text__chip"><Icon :name="pianta.sottozona ? store.iconaSottozona(pianta.zona, pianta.sottozona) : store.iconaZona(pianta.zona)" />{{ pianta.zona }}{{ pianta.sottozona ? ' · ' + pianta.sottozona : '' }}</span>
              <span v-if="pianta.coltivato_in" class="phead-text__chip phead-text__chip--ic" :title="labelColtivatoIn(pianta.coltivato_in)" :aria-label="labelColtivatoIn(pianta.coltivato_in)"><Icon :name="iconaColtivatoIn(pianta.coltivato_in)" /></span>
            </span>
            <h1 class="phead-text__name">{{ specie?.nome ?? pianta.specie }}<i v-if="pianta.varieta"> {{ pianta.varieta }}</i></h1>
            <p class="phead-text__bino">{{ specie?.specie }}</p>
          </div>
          <RouterLink :to="`/piante/${route.params.id}/modifica`" class="phead-text__edit"><Icon name="matita" /> Modifica</RouterLink>
        </div>
      </div>

      <!-- Alert cura: unico blocco sollevato, tinta olive, solo icona a sinistra -->
      <div v-if="cureUrgenti.length" class="card alertbox">
        <span class="alertbox__ic"><Icon name="campanella" /></span>
        <div class="alertbox__main">
          <div class="alertbox__title">Da curare subito</div>
          <div class="alertbox__rows">
            <div v-for="c in cureUrgenti" :key="c.tipo" class="alert-cura__row">
              <span>{{ c.label }}</span>
              <button class="care-act care-act--rose" type="button" @click="registraCura(c.tipo)" :disabled="salvando === c.tipo">
                <Spinner v-if="salvando === c.tipo" /><span v-else>Registra</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Stato cure -->
      <div class="slabel">Stato cure</div>
      <div class="care">
        <div v-for="tipo in tipiCura" :key="tipo" class="care__row">
          <span class="care__ic" :class="`care__ic--${tipo}`"><Icon :name="iconaCura(tipo)" /></span>
          <span class="care__m">
            <span class="care__n">{{ LABEL_CURA[tipo] ?? tipo }}</span>
            <span class="care__d">{{ statoCura(tipo) }}</span>
          </span>
          <button class="care-act" type="button" @click="registraCura(tipo)" :disabled="salvando === tipo">
            <Spinner v-if="salvando === tipo" /><span v-else>Fatto</span>
          </button>
        </div>
      </div>

      <!-- Concimi consigliati per il fabbisogno attuale -->
      <template v-if="fabbisognoNpk">
        <div class="slabel">Concimi consigliati</div>
        <p class="prose feed-nb">Per il fabbisogno attuale: {{ fabbisognoNpk }}</p>
        <div v-if="classificaConcimiPianta.length" class="feedlist">
          <div v-for="(c, i) in classificaConcimiPianta" :key="c.id" class="feed">
            <span class="feed__rank" :class="{ 'feed__rank--dim': i > 0 }">{{ i + 1 }}</span>
            <div class="feed__m">
              <div class="feed__n">{{ c.nome }}<span v-if="c.disponibile === false" class="feed__tag">terminato</span></div>
            </div>
            <span class="feed__npk">{{ c.npk.n }}-{{ c.npk.p }}-{{ c.npk.k }}</span>
          </div>
        </div>
        <p v-else class="prose">Nessun concime in dispensa per questo fabbisogno.</p>
      </template>

      <!-- La specie -->
      <div v-if="specie && (specie.descrizione || coltivazione)" class="specie">
        <svg class="specie-ghost" viewBox="0 0 512 512" aria-hidden="true"><g transform="translate(0 512) scale(0.1 -0.1)"><path class="sg" d="M3759 4349 c-27 -27 -22 -60 25 -164 55 -122 49 -157 -45 -277 -45 -57 -74 -132 -84 -213 -10 -75 -29 -130 -59 -169 -13 -17 -26 -41 -30 -54 -17 -52 50 -169 115 -202 25 -13 70 -23 120 -27 96 -7 129 -27 129 -76 0 -45 -34 -95 -78 -115 -32 -15 -72 -17 -282 -16 -135 0 -297 6 -360 12 -213 22 -501 26 -660 8 -148 -16 -171 -21 -345 -74 -119 -36 -187 -64 -405 -169 -160 -77 -376 -157 -452 -168 l-38 -6 0 -196 0 -196 68 6 c38 4 114 16 171 28 56 11 104 19 106 17 3 -2 9 -84 15 -182 6 -99 13 -183 16 -187 2 -5 5 -41 6 -82 0 -63 -4 -81 -31 -135 -17 -34 -35 -62 -39 -62 -9 0 -131 -99 -177 -143 -20 -19 -40 -50 -45 -68 -5 -18 -14 -114 -20 -213 -6 -100 -18 -241 -27 -314 -18 -150 -12 -190 34 -237 51 -51 79 -59 211 -63 129 -4 167 3 210 41 16 15 22 31 22 64 0 54 -29 87 -91 103 -24 6 -50 13 -56 15 -21 7 -15 65 17 155 16 47 30 94 30 105 1 11 9 35 18 54 14 29 26 37 67 48 65 16 330 60 419 68 38 4 75 9 83 12 22 8 15 -14 -22 -72 -20 -30 -38 -68 -41 -84 -14 -70 74 -165 281 -302 182 -120 202 -132 275 -162 90 -37 140 -46 251 -47 82 0 102 3 145 25 80 40 95 96 41 150 -36 36 -89 55 -151 55 -38 0 -126 34 -126 49 0 4 -40 42 -90 84 -49 43 -90 83 -90 90 0 18 204 143 315 193 142 64 572 204 649 211 76 7 72 11 122 -142 18 -55 56 -163 84 -240 29 -77 65 -178 81 -225 39 -112 77 -180 116 -206 52 -35 137 -47 300 -42 201 6 263 33 263 115 0 16 -7 39 -16 52 -20 28 -88 60 -126 61 -26 0 -28 3 -28 38 0 21 4 73 9 117 6 44 13 116 16 160 3 44 10 100 15 125 6 25 21 117 35 205 28 171 62 307 126 500 112 334 130 413 155 668 17 183 12 251 -38 502 -91 465 -355 899 -680 1117 -53 36 -104 45 -137 26 -23 -13 -26 -20 -24 -61 2 -26 -1 -47 -6 -47 -5 0 -28 21 -51 47 -64 73 -139 133 -166 133 -13 0 -33 -9 -45 -21z m661 -3244 c0 -17 9 -29 31 -41 31 -16 32 -17 26 -74 -9 -84 -37 -154 -64 -158 -17 -3 -24 3 -29 24 -8 30 2 231 12 257 9 25 24 20 24 -8z"/><path class="sg" d="M124 3636 c-52 -23 -68 -73 -60 -187 26 -406 211 -760 516 -990 108 -82 230 -139 390 -184 66 -19 315 -31 424 -20 l77 7 -3 198 c-2 109 -6 201 -9 204 -3 4 -17 2 -31 -3 -14 -5 -77 -15 -140 -22 -99 -11 -132 -10 -224 2 -60 9 -127 24 -149 34 -161 74 -273 169 -363 308 -86 132 -116 202 -162 377 -48 180 -68 227 -112 260 -38 28 -110 36 -154 16z"/></g></svg>
        <div class="slabel">La specie</div>
        <p v-if="specie.descrizione" class="prose">{{ specie.descrizione }}</p>
        <div v-if="coltivazione" class="kv">
          <div v-if="coltivazione.famiglia_botanica"><span class="k">Famiglia</span><span class="v">{{ coltivazione.famiglia_botanica }}</span></div>
          <div v-if="coltivazione.giorni_germinazione"><span class="k">Germinazione</span><span class="v">{{ coltivazione.giorni_germinazione }} gg</span></div>
          <div v-if="coltivazione.giorni_trapianto"><span class="k">Al trapianto</span><span class="v">{{ coltivazione.giorni_trapianto }} gg dalla semina</span></div>
          <div v-if="coltivazione.giorni_raccolta"><span class="k">Prima raccolta</span><span class="v">{{ coltivazione.giorni_raccolta }} gg dal trapianto</span></div>
          <div v-if="coltivazione.finestra_semina?.length"><span class="k">Finestra semina</span><span class="v">{{ coltivazione.finestra_semina.join(', ') }}</span></div>
          <div v-if="coltivazione.finestra_trapianto?.length"><span class="k">Finestra trapianto</span><span class="v">{{ coltivazione.finestra_trapianto.join(', ') }}</span></div>
          <div v-if="coltivazione.resistenza_gelo"><span class="k">Resistenza al gelo</span><span class="v">{{ coltivazione.resistenza_gelo }}</span></div>
          <div v-if="coltivazione.spaziatura_cm"><span class="k">Spaziatura</span><span class="v">{{ coltivazione.spaziatura_cm }} cm</span></div>
          <div v-if="coltivazione.consociazioni_favorevoli?.length"><span class="k">Si abbina a</span><span class="v">{{ coltivazione.consociazioni_favorevoli.join(', ') }}</span></div>
          <div v-if="coltivazione.consociazioni_sfavorevoli?.length"><span class="k">Evitare vicino a</span><span class="v">{{ coltivazione.consociazioni_sfavorevoli.join(', ') }}</span></div>
        </div>
      </div>

      <!-- Esigenze -->
      <template v-if="specie?.esigenze && Object.keys(specie.esigenze).length">
        <div class="slabel">Esigenze</div>
        <div class="kv">
          <div v-for="(val, chiave) in specie.esigenze" :key="chiave">
            <span class="k"><Icon :name="iconaEsigenza(chiave)" />{{ capitalizza(chiave) }}</span>
            <span class="v">{{ val }}</span>
          </div>
        </div>
      </template>

      <!-- Note tecniche della specie -->
      <template v-if="specie?.alert?.length">
        <div class="slabel">Note tecniche</div>
        <ul class="notelist">
          <li v-for="a in specie.alert" :key="a">{{ a }}</li>
        </ul>
      </template>

      <!-- Note personali -->
      <template v-if="pianta.note">
        <div class="slabel">Note</div>
        <p class="prose">{{ pianta.note }}</p>
      </template>

      <!-- Info impianto -->
      <p v-if="pianta.impianto" class="prose feed-nb">Messa a dimora: <strong>{{ formattaData(pianta.impianto) }}</strong></p>
      <p v-else-if="pianta.impianto_circa" class="prose feed-nb">Messa a dimora: <strong>{{ pianta.impianto_circa }}</strong> (data non certa)</p>

      <button class="delete" type="button" @click="daEliminare = true">Elimina pianta</button>
    </template>

    <ModalConferma
      :aperto="daEliminare"
      titolo="Eliminare questa pianta?"
      :messaggio="messaggioEliminaPianta"
      :caricamento="eliminando"
      @conferma="eliminaPianta"
      @annulla="daEliminare = false"
    />

    <LightboxFoto
      :foto="luce"
      :titolo="specie?.nome ?? pianta?.specie ?? ''"
      :ha-precedente="indiceLuce > 0"
      :ha-successivo="indiceLuce < fotoPianta.length - 1"
      :indice="indiceLuce"
      :totale="fotoPianta.length"
      @chiudi="luce = null"
      @naviga="dir => { luce = fotoPianta[indiceLuce + dir] }"
      @elimina="daEliminareFoto = luce"
    />

    <ModalConferma
      :aperto="!!daEliminareFoto"
      titolo="Eliminare questa foto?"
      messaggio="Questa azione non può essere annullata."
      :caricamento="eliminandoFoto"
      @conferma="confermaEliminaFoto"
      @annulla="daEliminareFoto = null"
    />
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { usePianteApi } from '@/composables/usePianteApi'
import { useGalleria } from '@/composables/useGalleria'
import { urlMiniatura } from '@/composables/useWikimedia'
import { valutaCura, cureUrgentiPianta, stagione } from '@/composables/useCure'
import { classificaConcimiPerFabbisogno } from '@/composables/useConcimi'
import { LABEL_CURA, iconaCura, iconaEsigenza, capitalizza } from '@/composables/useCureVisual'
import ModalConferma from '@/components/ModalConferma.vue'
import LightboxFoto from '@/components/LightboxFoto.vue'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const route  = useRoute()
const router = useRouter()
const store  = useDatiStore()
const pianteApi = usePianteApi()
const galleria = useGalleria()

const salvando   = ref(null)
const daEliminare = ref(false)
const eliminando  = ref(false)

const fotoPianta    = ref([])
const luce          = ref(null)
const daEliminareFoto = ref(null)
const eliminandoFoto  = ref(false)
const indiceFotoCorrente = ref(0)

// La galleria in cima alla scheda: le foto personali se ci sono, altrimenti
// come ripiego l'immagine della specie (Wikimedia Commons, licenze
// CC0/CC BY/CC BY-SA — mai selezionata visivamente una per una, va citata
// l'attribuzione richiesta dalla licenza). Solo header testuale se manca
// anche quella.
const fotoHero = computed(() => {
  const img = specie.value?.immagine
  return img ? { url: img.url, thumbUrl: urlMiniatura(img.url, 800), fallback: true, attribuzione: img.attribuzione, fonte_pagina: img.fonte_pagina } : null
})
const hasPhotos = computed(() => fotoPianta.value.length > 0)
const soloHero  = computed(() => !hasPhotos.value && !!fotoHero.value)
const slides    = computed(() => (hasPhotos.value ? fotoPianta.value : (fotoHero.value ? [fotoHero.value] : [])))

// Pallini della galleria in sincrono con lo scorrimento (porta della logica
// del mockup, adattata a un ref Vue).
function onGtrackScroll(e) {
  const el = e.target
  const n = slides.value.length
  if (!n) return
  const i = Math.round(el.scrollLeft / (el.scrollWidth / n))
  indiceFotoCorrente.value = Math.min(i, n - 1)
}

// Solo una foto vera (path presente) apre il lightbox; l'immagine di ripiego
// della specie non è una foto della galleria.
function apriLuce(f) {
  if (f?.path) luce.value = f
}

const LABEL_COLTIVATO_IN = { vaso: 'in vaso', terra: 'in terra', acqua: 'in acqua' }
function labelColtivatoIn(coltivatoIn) { return LABEL_COLTIVATO_IN[coltivatoIn] ?? 'in terra' }
function iconaColtivatoIn(coltivatoIn) { return coltivatoIn in LABEL_COLTIVATO_IN ? coltivatoIn : 'terra' }

const indiceLuce = computed(() => luce.value ? fotoPianta.value.findIndex(f => f.path === luce.value.path) : -1)

// Solo per la visualizzazione: pianta.impianto resta "yyyy-mm-dd" ovunque
// altrove (è anche il formato richiesto da <input type="date"> nel form di
// modifica). Niente new Date(): eviterebbe il fuso orario invece di
// aggirarlo, dato che una stringa "yyyy-mm-dd" viene interpretata come
// UTC mentre toLocaleDateString formatta nel fuso locale.
const MESI = ['gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', 'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre']
function formattaData(iso) {
  if (!iso) return ''
  const [anno, mese, giorno] = iso.split('-').map(Number)
  if (!anno || !mese || !giorno) return iso
  return `${giorno} ${MESI[mese - 1]} ${anno}`
}

const messaggioEliminaPianta = computed(() => {
  const n = fotoPianta.value.length
  if (!n) return 'Questa azione non può essere annullata.'
  return n === 1
    ? 'Questa azione non può essere annullata. Verrà eliminata anche la foto associata.'
    : `Questa azione non può essere annullata. Verranno eliminate anche le ${n} foto associate.`
})

async function caricaFotoPianta(id) {
  if (!id) { fotoPianta.value = []; return }
  try {
    fotoPianta.value = await galleria.listaFoto(id)
  } catch {
    fotoPianta.value = []
  } finally {
    indiceFotoCorrente.value = 0
  }
}

onMounted(() => caricaFotoPianta(route.params.id))
watch(() => route.params.id, (id) => caricaFotoPianta(id))

async function confermaEliminaFoto() {
  if (!daEliminareFoto.value) return
  eliminandoFoto.value = true
  try {
    await galleria.elimina(daEliminareFoto.value)
    fotoPianta.value = fotoPianta.value.filter(f => f.path !== daEliminareFoto.value.path)
    if (luce.value?.path === daEliminareFoto.value.path) luce.value = null
    daEliminareFoto.value = null
  } finally {
    eliminandoFoto.value = false
  }
}

const pianta = computed(() => {
  if (!store.piante) return null
  const p = store.piante[route.params.id]
  return p ? { id: route.params.id, ...p } : null
})

const specie = computed(() =>
  pianta.value ? (store.specie?.[pianta.value.specie] ?? null) : null
)

// Presente solo per le specie annuali/biennali curate dalla tab
// Coltivazione del form specie (vedi SelettoreSpecie.vue) — assente per le
// perenni, dove semina/trapianto non si applicano.
const coltivazione = computed(() => specie.value?.coltivazione ?? null)

const contestoCura = computed(() => ({
  esterno: store.zone?.[pianta.value?.zona]?.tipo === 'esterno',
  meteo: store.meteo,
}))

// I tipi di cura con cadenza/urgenza sono irrigazione, concimazione e —
// solo per le poche specie con beneficio documentato — calcio. La potatura
// non è mai valutata per urgenza: resta però in coda come riga registrabile
// ("ultima: N giorni fa", bottone "Fatto").
const tipiCura = computed(() => {
  const base = ['irrigazione', 'concimazione']
  if (specie.value?.manutenzione?.calcio) base.push('calcio')
  base.push('potatura')
  return base
})

const giorniDaPotatura = computed(() => {
  const s = pianta.value?.ultima_cura?.potatura
  if (!s) return null
  return Math.floor((Date.now() - new Date(s).getTime()) / 86400000)
})

function statoCura(tipo) {
  if (tipo === 'potatura') {
    return giorniDaPotatura.value == null
      ? 'mai registrata'
      : `ultima: ${giorniDaPotatura.value} giorni fa`
  }
  return valutaCura(pianta.value, specie.value, tipo, contestoCura.value).label ?? 'non configurata'
}

const cureUrgenti = computed(() =>
  pianta.value ? cureUrgentiPianta(pianta.value, specie.value, contestoCura.value) : []
)

const fabbisognoNpk = computed(() => specie.value?.manutenzione?.npk?.[stagione()] ?? null)
// Solo i primi 3: la dispensa può avere una decina di concimi, l'intera
// classifica affollerebbe la sezione senza aggiungere utilità oltre i
// migliori candidati.
const classificaConcimiPianta = computed(() =>
  fabbisognoNpk.value ? classificaConcimiPerFabbisogno(fabbisognoNpk.value, store.concimi).slice(0, 3) : []
)

async function registraCura(tipo) {
  if (!pianta.value || salvando.value) return
  salvando.value = tipo
  const id = pianta.value.id
  try {
    await pianteApi.registraCura(id, tipo)
  } finally {
    salvando.value = null
  }
}

async function eliminaPianta() {
  if (!pianta.value) return
  eliminando.value = true
  const id = pianta.value.id
  try {
    await galleria.eliminaCartella(id)
    await pianteApi.eliminaPianta(id)
    router.push('/piante')
  } finally {
    eliminando.value = false
  }
}
</script>

<style scoped>
/* Header foto a tutta larghezza, a filo del bordo superiore del contenuto. */
.phead-photo { margin: -28px -16px 0; }
.phead-credit {
  position: absolute; right: 12px; bottom: 8px; z-index: 2;
  font: 400 9px/1.3 var(--font-sans); color: rgba(253, 248, 238, 0.72);
  text-decoration: none; background: rgba(22, 16, 8, 0.32);
  padding: 2px 7px; border-radius: 999px;
}
.phead-credit:hover { color: #fdf8ee; }

/* Header testuale ridotto (nessuna foto disponibile). */
.phead-text { margin: -8px 0 4px; }
.phead-text__back {
  display: inline-flex; align-items: center; gap: 6px;
  font: 400 13px/1 var(--font-sans); color: var(--ink-soft);
  text-decoration: none; margin-bottom: 16px;
}
.phead-text__back svg { width: 15px; height: 15px; }
.phead-text__body { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; }
.phead-text__chip {
  display: inline-flex; align-items: center; gap: 5px;
  font: 700 9.5px/1 var(--font-sans); letter-spacing: .05em; text-transform: uppercase;
  color: var(--ink-mid); background: var(--cream-dark);
  padding: 4px 9px; border-radius: 999px;
}
.phead-text__chip svg { width: 11px; height: 11px; }
.phead-text__name {
  font: 700 24px/1.12 var(--font-display); color: var(--ink);
  letter-spacing: -0.01em; margin: 8px 0 2px; text-wrap: balance;
}
.phead-text__name i { font-weight: 400; }
.phead-text__bino {
  font: 400 12.5px/1.4 var(--font-display); font-style: italic;
  color: var(--ink-soft); margin: 0;
}
.phead-text__chips { display: flex; gap: 6px; flex-wrap: wrap; }
.phead-text__chip--ic { padding: 4px 7px; }
.phead-text__edit {
  flex: none; display: inline-flex; align-items: center; gap: 6px;
  font: 600 11px/1 var(--font-sans); color: var(--ink-mid);
  background: var(--cream-dark); border-radius: 999px; padding: 8px 12px;
  text-decoration: none;
}
.phead-text__edit svg { width: 12px; height: 12px; }

/* Alert cura: .alertbox* ora globale in main.css. .alert-cura__row resta
   scoped qui: la riga (label + bottone) ha un layout diverso da quella
   degli avvisi meteo. */
.alert-cura__row {
  display: flex; align-items: center; justify-content: space-between; gap: 10px;
  font: 400 12.5px/1.4 var(--font-sans); color: var(--olive-ink);
}

/* Stato cure: .care* / .care-act* / .feed-nb / .notelist ora globali in main.css. */
</style>
