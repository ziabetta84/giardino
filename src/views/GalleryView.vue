<template>
  <div>
    <div class="page-title__row">
      <h1 class="page-title">Galleria</h1>
      <button type="button" class="pill" @click="mostraFormUpload = true">＋ Aggiungi</button>
    </div>

    <!-- Skeleton -->
    <div v-if="caricandoLista" style="display:flex;flex-direction:column;gap:28px;">
      <div v-for="i in 2" :key="i">
        <div class="skeleton" style="height:13px;width:45%;margin-bottom:10px;border-radius:6px;"></div>
        <div class="skeleton" style="aspect-ratio:4/5;border-radius:14px;"></div>
      </div>
    </div>

    <template v-else>
      <!-- Errore di caricamento: distinto dal vero vuoto (nessuna foto ancora
           caricata) — prima i due stati erano indistinguibili, con lo stesso
           messaggio incoraggiante mostrato anche su un fallimento reale della
           lista, senza alcun modo di riprovare se non uscire e rientrare. -->
      <div v-if="errore && !gruppi.length" class="empty">
        <Icon name="allerta" />
        <p><b>Non sono riuscito a caricare le foto</b>Controlla la connessione e riprova.</p>
        <button type="button" class="btn btn-ghost" style="margin-top:14px;" @click="caricaLista">Riprova</button>
      </div>

      <!-- Nessuna foto -->
      <div v-else-if="!gruppi.length" class="empty">
        <Icon name="cornice" />
        <p><b>Nessuna foto ancora</b>Fotografa le tue piante e documenta la crescita</p>
      </div>

      <!-- Feed: un post per pianta -->
      <div v-else style="display:flex;flex-direction:column;gap:26px;">
        <article v-for="g in gruppi" :key="g.piantaId" class="gpost">
          <!-- Header post: nome sempre su una riga propria (mai schiacciato
               dalle chip), zona/sottozona/coltivato_in/conteggio su una
               seconda riga che va a capo da sola quando lo spazio non basta —
               vedi critica del 07/09/2026 sull'affollamento su mobile stretto. -->
          <div class="gpost__hd">
            <span v-if="g.isGenerale" class="gpost__name">Foto generiche</span>
            <RouterLink v-else :to="`/piante/${g.piantaId}`" class="gpost__name">{{ g.nomeSpecie }}</RouterLink>
            <div class="gpost__hd-meta">
              <span v-if="!g.isGenerale && g.zona" class="chip">
                <Icon :name="g.sottozona ? store.iconaSottozona(g.zona, g.sottozona) : store.iconaZona(g.zona)" />{{ g.sottozona ? `${g.zona} · ${g.sottozona}` : g.zona }}
              </span>
              <span v-if="!g.isGenerale && g.coltivatoIn" class="chip" role="img" :aria-label="labelColtivatoIn(g.coltivatoIn)" :title="labelColtivatoIn(g.coltivatoIn)">
                <Icon :name="iconaColtivatoIn(g.coltivatoIn)" />
              </span>
              <span class="gpost__n">{{ g.foto.length }} foto</span>
            </div>
          </div>

          <!-- Foto singola: nessuna pila, nessun toggle — non c'è altro da sfogliare. -->
          <figure v-if="g.foto.length === 1" class="polaroid"
            :style="{ '--rot': rotazione(g.foto[0].path) + 'deg' }"
            @contextmenu.prevent="daEliminareFoto = g.foto[0]"
            @touchstart.passive="iniziaPressione(g.foto[0])"
            @touchend="annullaPressione" @touchmove.passive="annullaPressione" @touchcancel="annullaPressione">
            <img class="polaroid__img" :src="g.foto[0].thumbUrl" :alt="altFoto(g, g.foto[0])" loading="lazy">
            <figcaption class="polaroid__cap">
              <span class="polaroid__data">{{ g.foto[0].dataBreve }}</span>
            </figcaption>
            <button type="button" class="gdel" @click.stop="daEliminareFoto = g.foto[0]" aria-label="Elimina foto">
              <Icon name="cestino" />
            </button>
          </figure>

          <template v-else>
            <!-- Pila chiusa: le 3 foto più recenti sfalsate e ruotate, la più
                 recente sempre in primo piano. Tap/Invio/Spazio apre il
                 ventaglio con tutte le foto — stesso controllo per 2 come
                 per 30 foto, invece di due modelli di interazione diversi a
                 seconda del conteggio. Il bottone di eliminazione è un
                 fratello del contenitore, non un figlio: un bottone reale
                 annidato dentro un div[role=button] è un anti-pattern ARIA
                 (due controlli interattivi innestati) — vedi critica del
                 07/09/2026. -->
            <div v-if="!stackAperta[g.piantaId]" class="stack-wrap">
              <div class="stack"
                role="button" tabindex="0"
                :aria-label="`Apri tutte le ${g.foto.length} foto di ${g.isGenerale ? 'questo gruppo' : g.nomeSpecie}`"
                @click="apriStack(g.piantaId)"
                @keydown.enter="apriStack(g.piantaId)"
                @keydown.space.prevent="apriStack(g.piantaId)">
                <figure v-for="f in g.pilaVisibile" :key="f.path" class="polaroid polaroid--pila"
                  :style="{ '--rot': rotazione(f.path) + 'deg', '--i': f.profondita }">
                  <img class="polaroid__img" :src="f.thumbUrl" :alt="altFoto(g, f)" loading="lazy">
                  <figcaption v-if="f.profondita === 0" class="polaroid__cap">
                    <span class="polaroid__data">{{ f.dataBreve }}</span>
                  </figcaption>
                </figure>
                <span v-if="g.foto.length > 3" class="stack__piu">+{{ g.foto.length - 3 }} altre</span>
              </div>
              <button type="button" class="gdel" @click.stop="daEliminareFoto = g.foto[0]" aria-label="Elimina foto più recente">
                <Icon name="cestino" />
              </button>
            </div>

            <!-- Ventaglio aperto: tutte le foto, stesso meccanismo di scorrimento
                 con scroll-snap di prima, ora vestito da polaroid con un
                 accenno dei vicini invece del ritaglio 4:5 a bordo vivo.
                 tabindex="-1" + focus programmatico all'apertura + Esc per
                 richiudere: stesso pattern già usato da LightboxFoto.vue,
                 non un'invenzione nuova — prima mancava del tutto qui. -->
            <div v-else :ref="el => setVentaglioRef(g.piantaId, el)" tabindex="-1" class="ventaglio-wrap"
              @keydown.esc="chiudiStack(g.piantaId)">
              <div class="carosello carosello--ventaglio" @scroll="e => onScrollCarosello(e, g.piantaId)">
                <figure v-for="f in g.foto" :key="f.path" class="polaroid polaroid--ventaglio slide"
                  :style="{ '--rot': rotazione(f.path) + 'deg' }"
                  @contextmenu.prevent="daEliminareFoto = f"
                  @touchstart.passive="iniziaPressione(f)"
                  @touchend="annullaPressione" @touchmove.passive="annullaPressione" @touchcancel="annullaPressione">
                  <img class="polaroid__img" :src="f.thumbUrl" :alt="altFoto(g, f)" loading="lazy">
                  <figcaption class="polaroid__cap">
                    <span class="polaroid__data">{{ f.dataBreve }}</span>
                  </figcaption>
                  <button type="button" class="gdel" @click.stop="daEliminareFoto = f" aria-label="Elimina foto">
                    <Icon name="cestino" />
                  </button>
                </figure>
              </div>

              <div class="puntini">
                <span v-for="(f, i) in g.foto" :key="f.path"
                  :class="{ on: (slideAttiva[g.piantaId] || 0) === i }"></span>
              </div>

              <button type="button" class="pill stack__chiudi" @click="chiudiStack(g.piantaId)">Richiudi</button>
            </div>
          </template>
        </article>
      </div>
    </template>

    <ModalConferma
      :aperto="!!daEliminareFoto"
      titolo="Eliminare questa foto?"
      messaggio="Questa azione non può essere annullata."
      :caricamento="eliminandoFoto"
      :errore="erroreEliminazione"
      @conferma="confermaEliminaFoto"
      @annulla="daEliminareFoto = null; erroreEliminazione = null"
    />

    <!-- Foglio upload -->
    <FoglioLaterale
      :model-value="mostraFormUpload"
      @update:model-value="v => mostraFormUpload = v"
      titolo="Aggiungi foto"
    >
      <div class="foglio-form">
        <!-- Selezione pianta -->
        <label class="field-label">Pianta</label>
        <select v-model="uploadPiantaId" class="form-input" style="margin-bottom:14px;">
          <option value="">Nessuna (foto generica)</option>
          <optgroup v-for="(ps, zona) in piantaPerZona" :key="zona" :label="zona">
            <option v-for="p in ps" :key="p.id" :value="p.id">{{ p.etichetta }}</option>
          </optgroup>
        </select>

        <!-- Selezione foto: due bottoni separati invece di un unico input
             generico, perché su alcuni browser/telefoni Android un input
             "accept=image/*" senza capture viene comunque risolto dal
             sistema verso la fotocamera, saltando la scelta della libreria
             (stesso pattern di AgenteView.vue). -->
        <div v-if="uploadPreview" style="display:flex;align-items:center;gap:10px;padding:10px 14px;border:1.5px solid var(--sage-light);border-radius:12px;background:var(--sage-pale);">
          <img :src="uploadPreview" alt="Anteprima della foto selezionata" style="width:44px;height:44px;object-fit:cover;border-radius:8px;flex-shrink:0;">
          <div style="flex:1;font-size:13px;font-weight:600;color:var(--sage-dark);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">{{ uploadNomeFile }}</div>
          <button type="button" @click="rimuoviUpload" aria-label="Rimuovi foto" style="background:none;border:none;color:var(--ink-faint);font-size:20px;line-height:1;cursor:pointer;flex-shrink:0;">×</button>
        </div>

        <div v-else style="display:flex;gap:8px;">
          <label style="flex:1;display:flex;align-items:center;justify-content:center;gap:6px;padding:16px;border:2px dashed var(--sage-light);border-radius:14px;cursor:pointer;background:var(--sage-pale);font-size:13px;font-weight:600;color:var(--sage-dark);">
            <Icon name="cornice" style="width:16px;height:16px;flex-shrink:0;" />Libreria
            <input type="file" accept="image/*" @change="selezionaUpload" style="display:none;">
          </label>
          <label style="flex:1;display:flex;align-items:center;justify-content:center;gap:6px;padding:16px;border:2px dashed var(--sage-light);border-radius:14px;cursor:pointer;background:var(--sage-pale);font-size:13px;font-weight:600;color:var(--sage-dark);">
            <Icon name="fotocamera" style="width:16px;height:16px;flex-shrink:0;" />Fotocamera
            <input type="file" accept="image/*" capture="environment" @change="selezionaUpload" style="display:none;">
          </label>
        </div>
        <p v-if="!uploadPreview" style="font-size:11px;color:var(--ink-faint);margin-top:6px;text-align:center;">JPG o PNG · max 10 MB</p>

        <p v-if="dataScattoRilevata" style="display:flex;align-items:center;gap:5px;font-size:11px;color:var(--sage-dark);margin-top:8px;">
          <Icon name="calendario" style="width:13px;height:13px;flex-shrink:0;" />Data rilevata dai metadati: {{ dataScattoRilevata.toLocaleDateString('it-IT', { day:'numeric', month:'long', year:'numeric' }) }}
        </p>

        <p v-if="erroreUpload" style="display:flex;align-items:center;gap:6px;font-size:12px;color:var(--rose-dark);margin-top:8px;">
          <Icon name="campanella" style="width:13px;height:13px;flex-shrink:0;" />{{ erroreUpload }}
        </p>

        <div class="foglio-actions">
          <button @click="mostraFormUpload = false" class="btn btn-ghost" style="flex:1;min-height:44px;">Annulla</button>
          <button @click="caricaFoto" :disabled="!uploadFileObj || caricandoUpload" class="btn btn-sage" style="flex:2;min-height:44px;">
            <Spinner v-if="caricandoUpload" />{{ caricandoUpload ? 'Caricamento…' : 'Carica foto' }}
          </button>
        </div>
      </div>
    </FoglioLaterale>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useGalleria } from '@/composables/useGalleria'
import ModalConferma from '@/components/ModalConferma.vue'
import FoglioLaterale from '@/components/FoglioLaterale.vue'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const store = useDatiStore()
const galleria = useGalleria()

const foto            = ref([])
const caricandoLista  = ref(false)
const caricandoUpload = ref(false)
const errore          = ref(null)
const erroreUpload    = ref(null)
const daEliminareFoto = ref(null)
const erroreEliminazione = ref(null)
const eliminandoFoto  = ref(false)
const mostraFormUpload = ref(false)
const uploadPiantaId  = ref('')
const uploadFileObj   = ref(null)
const uploadPreview   = ref(null)
const uploadNomeFile  = ref('')
const dataScattoRilevata = ref(null)

// Indice della slide visibile per ogni carosello (chiave = piantaId),
// aggiornato mentre si scorre orizzontalmente — alimenta i puntini.
const slideAttiva = ref({})

// Pila chiusa/aperta per pianta (chiave = piantaId). Aprirne una richiude
// tutte le altre (vedi apriStack) — più ventagli aperti insieme fanno
// silenziosamente ricomparire il "muro di foto" che la pila dovrebbe
// evitare, specie scorrendo un giardino con molte piante (critica del
// 07/09/2026).
const stackAperta = ref({})

// Elemento DOM del ventaglio aperto per pianta, per spostarci il focus
// all'apertura (stesso pattern di LightboxFoto.vue) e permettere l'Esc
// per richiudere.
const ventaglioRefs = {}
function setVentaglioRef(piantaId, el) { if (el) ventaglioRefs[piantaId] = el }

function apriStack(piantaId) {
  stackAperta.value = { [piantaId]: true }
  nextTick(() => ventaglioRefs[piantaId]?.focus())
}
function chiudiStack(piantaId) {
  stackAperta.value = {}
}

// Rotazione stabile per foto (non ri-randomizzata a ogni render): un hash
// semplice del path della foto dà un grado deterministico in -4..4°,
// escludendo lo zero perché una polaroid perfettamente dritta legge come
// un rettangolo qualunque, non come un oggetto fisico appoggiato di sbieco.
function rotazione(path) {
  let h = 0
  for (let i = 0; i < path.length; i++) h = (h * 31 + path.charCodeAt(i)) | 0
  const grado = (Math.abs(h) % 9) - 4
  return grado === 0 ? 2 : grado
}

const LABEL_COLTIVATO_IN = { vaso: 'In vaso', terra: 'In terra', acqua: 'In acqua' }
function labelColtivatoIn(v) { return LABEL_COLTIVATO_IN[v] ?? 'In terra' }
function iconaColtivatoIn(v) { return v in LABEL_COLTIVATO_IN ? v : 'terra' }

function altFoto(g, f) {
  return g.isGenerale ? `Foto generica del ${f.dataBreve}` : `Foto di ${g.nomeSpecie}, ${f.dataBreve}`
}

// Piante raggruppate per zona (per il select dell'upload)
const piantaPerZona = computed(() => {
  if (!store.piante) return {}
  const gruppi = {}
  for (const [id, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie]
    const zona = p.zona ?? 'Altro'
    if (!gruppi[zona]) gruppi[zona] = []
    const nomeSpecie = sp?.nome ?? p.specie
    gruppi[zona].push({ id, nomeSpecie, etichetta: p.varieta ? `${nomeSpecie} — ${p.varieta}` : nomeSpecie })
  }
  return gruppi
})

// Raggruppa le foto per pianta, arricchite con dati store. L'ordine dei post
// segue la foto più recente di ciascun gruppo (feed cronologico): il nome
// file ha come prefisso il timestamp epoch, quindi il confronto di stringa
// sulla prima foto (già ordinata dal più recente) equivale all'ordine per data.
const gruppi = computed(() => {
  if (!foto.value.length) return []
  const byFolder = {}
  for (const f of foto.value) {
    if (!byFolder[f.cartella]) byFolder[f.cartella] = []
    byFolder[f.cartella].push(f)
  }
  return Object.entries(byFolder).map(([piantaId, fotoList]) => {
    const pianta  = store.piante?.[piantaId]
    const specie  = pianta ? (store.specie?.[pianta.specie] ?? null) : null
    const foto    = fotoList.sort((a, b) => b.nome.localeCompare(a.nome))
    return {
      piantaId,
      isGenerale:  piantaId === 'generale',
      nomeSpecie:  specie?.nome ?? pianta?.specie ?? piantaId,
      zona:        pianta?.zona ?? null,
      sottozona:   pianta?.sottozona ?? null,
      coltivatoIn: pianta?.coltivato_in ?? null,
      foto,
      // Le 3 foto più recenti per la pila chiusa, con `profondita` (0 = la più
      // recente, in primo piano) per l'offset/rotazione via CSS — in ordine
      // dal fondo verso la cima cosicché la più recente, renderizzata per
      // ultima, stia sopra alle altre senza bisogno di z-index espliciti.
      pilaVisibile: foto.slice(0, 3).map((f, i) => ({ ...f, profondita: i })).reverse(),
    }
  }).sort((a, b) => (b.foto[0]?.nome ?? '').localeCompare(a.foto[0]?.nome ?? ''))
})

function onScrollCarosello(e, piantaId) {
  const el = e.target
  const idx = Math.round(el.scrollLeft / el.clientWidth)
  if (slideAttiva.value[piantaId] !== idx) slideAttiva.value[piantaId] = idx
}

// Pressione lunga su una slide → conferma eliminazione (sostituisce il punto
// di cancellazione che prima viveva nella lightbox). Il timer viene annullato
// allo scroll orizzontale (touchmove) per non scattare mentre si sfoglia.
let timerPressione = null
function iniziaPressione(f) {
  annullaPressione()
  timerPressione = setTimeout(() => { daEliminareFoto.value = f }, 550)
}
function annullaPressione() {
  if (timerPressione) { clearTimeout(timerPressione); timerPressione = null }
}

async function confermaEliminaFoto() {
  if (!daEliminareFoto.value) return
  eliminandoFoto.value = true
  erroreEliminazione.value = null
  try {
    await galleria.elimina(daEliminareFoto.value)
    foto.value = foto.value.filter(f => f.path !== daEliminareFoto.value.path)
    daEliminareFoto.value = null
  } catch {
    erroreEliminazione.value = 'Non sono riuscito a eliminare la foto. Riprova.'
  } finally {
    eliminandoFoto.value = false
  }
}

async function caricaLista() {
  caricandoLista.value = true
  errore.value = null
  try {
    foto.value = await galleria.listaTutte()
  } catch {
    errore.value = 'Non sono riuscito a caricare le foto. Riprova.'
  } finally {
    caricandoLista.value = false
  }
}

onMounted(async () => {
  await store.caricaTutto()
  await caricaLista()
})

onBeforeUnmount(annullaPressione)

function selezionaUpload(e) {
  const file = e.target.files?.[0]
  if (!file) return
  uploadFileObj.value = file
  uploadNomeFile.value = file.name
  dataScattoRilevata.value = null
  galleria.leggiDataScatto(file).then(d => { dataScattoRilevata.value = d })
  const reader = new FileReader()
  reader.onload = () => {
    uploadPreview.value = reader.result
  }
  reader.readAsDataURL(file)
}

function rimuoviUpload() {
  uploadFileObj.value  = null
  uploadPreview.value = null
  uploadNomeFile.value = ''
  dataScattoRilevata.value = null
}

async function caricaFoto() {
  if (!uploadFileObj.value || caricandoUpload.value) return
  caricandoUpload.value = true
  erroreUpload.value = null
  try {
    const cartella = uploadPiantaId.value || 'generale'
    const nuovaFoto = await galleria.carica(cartella, uploadFileObj.value, dataScattoRilevata.value)
    foto.value.unshift(nuovaFoto)
    mostraFormUpload.value = false
    rimuoviUpload()
    uploadPiantaId.value = ''
  } catch {
    erroreUpload.value = 'Non sono riuscito a caricare la foto. Riprova.'
  } finally {
    caricandoUpload.value = false
  }
}
</script>

<style scoped>
/* Colonna album: a tutta larghezza su mobile, ma limitata e centrata su
   desktop (senza il cap le polaroid diventano enormi dentro il max-width
   di 920px di .app-main). `.gpost` globale porta solo il margine
   inferiore: qui lo sostituiamo con la centratura, la spaziatura tra i
   post la dà il `gap` del contenitore. */
.gpost {
  width: 100%;
  max-width: 460px;
  margin: 0 auto;
}

/* Il nome ha sempre l'intera larghezza della sua riga (vedi .gpost__hd
   sopra); `max-width:100%` gli impedisce comunque di sfondare la card per
   un nome davvero lunghissimo, attivando l'ellissi solo in quel caso limite. */
.gpost__name {
  min-width: 0;
  max-width: 100%;
}

/* Header a due righe: il nome resta sempre leggibile per intero sulla
   prima riga (mai in gara con le chip per lo spazio); zona/sottozona/
   coltivato_in/conteggio vivono in una riga propria che va a capo da sola
   quando lo spazio non basta, invece di schiacciare il nome — vedi
   critica del 07/09/2026 sull'affollamento su mobile stretto. */
.gpost__hd {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 4px;
}
.gpost__hd-meta {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  width: 100%;
}
/* Chip zona nell'intestazione: la .chip globale è già chiara di base;
   qui serve solo evitare che si comprima quando il nome zona è lungo. */
.gpost__hd .chip {
  flex: none;
  /* .chip di base non forza più --acqua (ora è chiara per default): qui
     serve ancora currentColor, altrimenti l'icona zona (acquerellata,
     dipinta in --acqua/--acqua-dark) torna azzurra invece di seguire il
     testo del chip. */
  --acqua: currentColor;
  --acqua-dark: currentColor;
}

/* Polaroid: cornice bianca (bordo del sistema, non un bianco-su-carta —
   vedi "Background: bianco su fondo carta" in DESIGN.md/Cards), ombra
   "Ambientale" di riposo, angolo minimo del sistema (6px, `rounded.tag`:
   niente scende sotto per restare "morbido", nemmeno un oggetto fisico). */
.polaroid {
  position: relative;
  display: flex;
  flex-direction: column;
  background: var(--white);
  border-radius: 6px;
  padding: 8px 8px 0;
  box-shadow: 0 2px 12px rgba(42, 34, 24, .06);
  transform: rotate(var(--rot, 0deg));
  user-select: none;
  -webkit-user-select: none;
  -webkit-touch-callout: none;
}
.polaroid__img {
  width: 100%;
  aspect-ratio: 4 / 5;
  object-fit: cover;
  border-radius: 3px;
  display: block;
  background: var(--cream-dark);
}
.polaroid__cap {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  padding: 8px 4px 10px;
}
/* Didascalia a mano: seconda comparsa di Caveat nell'app oltre alla data in
   Home (vedi DESIGN.md/Typography) — una data scritta a mano sul bordo è
   il dettaglio "polaroid" più diretto del brief, non un uso decorativo.
   19px (non 17px) e --ink piena (non --ink-mid): è l'unico contenuto della
   didascalia ora che zona/sottozona/coltivato_in sono nell'header, quindi
   porta da sola tutto il carico di leggibilità — allineato alla stessa
   dimensione già documentata per l'Hand font in Home, non un valore nuovo. */
.polaroid__data { font: 400 19px/1 var(--font-hand); color: var(--ink); }

/* Pila chiusa: le 3 figure condividono la stessa cella di griglia (invece
   di un'altezza calcolata a mano), così il contenitore si dimensiona da
   solo sulla carta più grande — quella in primo piano — e le altre due
   sbucano sfalsate oltre i suoi bordi. `.stack-wrap` è il contenitore di
   posizionamento condiviso con `.gdel`, che ora vive come fratello — non
   figlio — di `.stack`: vedi commento nel template. */
.stack-wrap {
  position: relative;
}
.stack {
  display: grid;
  align-items: start;
  cursor: pointer;
  border-radius: 6px;
}
.stack:focus-visible { outline: 2px solid var(--gold); outline-offset: 4px; }
.polaroid--pila {
  grid-column: 1;
  grid-row: 1;
  /* Offset ridotto (era 7px/-6px) e badge rientrato nel bordo della carta
     (era right:-6px, sporgeva fuori): insieme a una rotazione di ±4° al
     massimo, il punto più a destra della pila resta dentro il margine di
     16px della pagina anche su schermi stretti (~375px) — vedi critica
     del 07/09/2026 sul rischio di sconfinamento. */
  transform: rotate(var(--rot, 0deg)) translate(calc(var(--i, 0) * 5px), calc(var(--i, 0) * -5px));
}
.stack__piu {
  position: absolute; bottom: 8px; right: 6px; z-index: 3;
  background: var(--ink); color: var(--cream);
  font: 700 10.5px/1 var(--font-sans); letter-spacing: .04em;
  padding: 5px 10px; border-radius: 999px;
  box-shadow: 0 2px 8px rgba(42, 34, 24, .25);
}

/* Ventaglio aperto: stesso scroll-snap orizzontale di prima, ma ogni carta
   lascia intravedere le vicine invece di occupare tutta la larghezza —
   la differenza che rende "si sfoglia" invece di "si scorre un feed". */
.carosello--ventaglio {
  display: flex;
  gap: 14px;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  -webkit-overflow-scrolling: touch;
  padding: 6px 9% 14px;
  scrollbar-width: none;
}
.carosello--ventaglio::-webkit-scrollbar { display: none; }
.polaroid--ventaglio {
  flex: 0 0 82%;
  scroll-snap-align: center;
}

/* Bersaglio di focus programmatico all'apertura (stesso pattern di
   .lightbox in LightboxFoto.vue): niente anello visibile sul contenitore
   stesso, i controlli reali al suo interno (bottoni elimina, "Richiudi")
   restano focus-visible per conto proprio. */
.ventaglio-wrap { outline: none; }

/* Puntini indicatori: la `.gdots` globale è absolute (header scheda pianta);
   qui vanno nel flusso, sotto il ventaglio. */
.puntini { display: flex; justify-content: center; gap: 5px; margin-top: 4px; }
.puntini span {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--cream-dark);
  transition: background var(--motion-quick) var(--ease-standard), width var(--motion-quick) var(--ease-standard);
}
.puntini span.on { background: var(--sage); width: 14px; border-radius: 3px; }

/* .pill di base è alta 36px (min-height): qui serve il minimo di 44px che
   l'app applica a ogni altro bottone (.btn/.care-act/.lightbox__btn) —
   vedi critica del 07/09/2026 sul target di tocco. */
.stack__chiudi {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 44px;
  margin: 10px auto 0;
}

/* Eliminazione: stesso linguaggio visivo di .pbtn (bottone-icona circolare
   traslucido sopra una foto, vedi PiantaView.vue/main.css), qui sopra la
   sola area fotografica della polaroid, mai sul bordo bianco. */
.gdel {
  position: absolute; top: 8px; right: 8px; z-index: 2;
  width: 32px; height: 32px; border-radius: 50%; border: none;
  display: flex; align-items: center; justify-content: center;
  background: rgba(22, 16, 8, .42);
  -webkit-backdrop-filter: blur(3px); backdrop-filter: blur(3px);
  color: #fdf8ee; cursor: pointer;
  transition: background var(--motion-quick) var(--ease-standard), transform var(--motion-quick) var(--ease-standard);
}
.gdel svg { width: 15px; height: 15px; }
.gdel:hover, .gdel:focus-visible { background: rgba(22, 16, 8, .62); }
.gdel:active { transform: scale(0.92); }
.gdel:focus-visible { outline: 2px solid var(--gold); outline-offset: 2px; }
</style>
