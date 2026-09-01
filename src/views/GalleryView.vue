<template>
  <div>
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;">
      <h1 class="title-display gradient-title title-settle" style="font-size:1.9rem;font-weight:800;">Galleria</h1>
      <button @click="mostraFormUpload = true" class="btn btn-rose" style="padding:8px 16px;">＋ Aggiungi</button>
    </div>

    <!-- Skeleton -->
    <div v-if="caricandoLista" style="display:flex;flex-direction:column;gap:28px;">
      <div v-for="i in 2" :key="i">
        <div class="skeleton" style="height:13px;width:45%;margin-bottom:10px;border-radius:6px;"></div>
        <div class="skeleton" style="aspect-ratio:4/5;border-radius:14px;"></div>
      </div>
    </div>

    <template v-else>
      <!-- Nessuna foto -->
      <div v-if="!gruppi.length" style="text-align:center;padding:60px 20px;color:var(--ink-faint);">
        <div style="width:64px;height:64px;border-radius:50%;background:var(--sage-tile);display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
          <Icon name="cornice" style="width:28px;height:28px;" />
        </div>
        <p class="title-serif" style="font-size:15px;color:var(--ink-soft);font-weight:600;">Nessuna foto ancora</p>
        <p style="font-size:12px;margin-top:6px;">Fotografa le tue piante e documenta la crescita</p>
        <p v-if="errore" style="font-size:11px;color:var(--rose-dark);margin-top:10px;">{{ errore }}</p>
      </div>

      <!-- Feed: un post per pianta -->
      <div v-else style="display:flex;flex-direction:column;gap:28px;">
        <article v-for="g in gruppi" :key="g.piantaId" class="post">
          <!-- Header post -->
          <header style="display:flex;align-items:center;gap:8px;margin-bottom:8px;">
            <span v-if="g.isGenerale" class="title-serif" style="font-size:14px;font-weight:600;color:var(--ink);">Foto generiche</span>
            <template v-else>
              <RouterLink :to="`/piante/${g.piantaId}`"
                class="title-serif"
                style="font-size:14px;font-weight:600;color:var(--ink);text-decoration:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
                {{ g.nomeSpecie }}
              </RouterLink>
              <span v-if="g.zona" class="badge badge-gold" style="flex-shrink:0;display:inline-flex;align-items:center;gap:4px;"><Icon :name="store.iconaZona(g.zona)" style="width:11px;height:11px;flex-shrink:0;" />{{ g.zona }}</span>
            </template>
            <span style="font-size:11px;color:var(--ink-faint);flex-shrink:0;margin-left:auto;">{{ g.foto.length }} foto</span>
          </header>

          <!-- Carosello foto -->
          <div class="carosello" @scroll="e => onScrollCarosello(e, g.piantaId)">
            <div v-for="f in g.foto" :key="f.path" class="slide"
              @contextmenu.prevent="daEliminareFoto = f"
              @touchstart.passive="iniziaPressione(f)"
              @touchend="annullaPressione"
              @touchmove.passive="annullaPressione"
              @touchcancel="annullaPressione">
              <img :src="f.thumbUrl" :alt="f.nome" loading="lazy"
                style="width:100%;height:100%;object-fit:cover;display:block;">
              <!-- Overlay: data, zona/sottozona, coltivato_in -->
              <div class="overlay">
                <span style="font-size:11px;font-weight:600;color:#fff;">{{ f.dataBreve }}</span>
                <span v-if="!g.isGenerale && g.zona" style="display:inline-flex;align-items:center;gap:4px;font-size:11px;color:rgba(255,255,255,0.92);">
                  <Icon :name="g.sottozona ? store.iconaSottozona(g.zona, g.sottozona) : store.iconaZona(g.zona)" style="width:12px;height:12px;flex-shrink:0;" />{{ g.sottozona ? `${g.zona} · ${g.sottozona}` : g.zona }}
                </span>
                <span v-if="!g.isGenerale && g.coltivatoIn" :title="labelColtivatoIn(g.coltivatoIn)" style="display:inline-flex;align-items:center;color:rgba(255,255,255,0.92);">
                  <Icon :name="iconaColtivatoIn(g.coltivatoIn)" style="width:12px;height:12px;flex-shrink:0;" />
                </span>
              </div>
            </div>
          </div>

          <!-- Puntini indicatori -->
          <div v-if="g.foto.length > 1" style="display:flex;justify-content:center;gap:5px;margin-top:8px;">
            <span v-for="(f, i) in g.foto" :key="f.path"
              :style="{ width:'6px', height:'6px', borderRadius:'50%', transition:'background 0.2s', background: (slideAttiva[g.piantaId] || 0) === i ? 'var(--rose)' : 'var(--cream-dark)' }"></span>
          </div>
        </article>
      </div>
    </template>

    <ModalConferma
      :aperto="!!daEliminareFoto"
      titolo="Eliminare questa foto?"
      messaggio="Questa azione non può essere annullata."
      :caricamento="eliminandoFoto"
      @conferma="confermaEliminaFoto"
      @annulla="daEliminareFoto = null"
    />

    <!-- Modal upload -->
    <Teleport to="body">
      <div v-if="mostraFormUpload" @click.self="mostraFormUpload = false"
        style="position:fixed;inset:0;z-index:200;background:rgba(42,34,24,0.4);display:flex;align-items:flex-end;justify-content:center;padding:0;">
        <div style="background:var(--white);border-radius:24px 24px 0 0;padding:24px;width:100%;max-width:520px;box-shadow:0 -8px 40px rgba(42,34,24,0.15);">
          <div style="width:36px;height:4px;background:var(--cream-dark);border-radius:2px;margin:0 auto 20px;"></div>
          <h3 class="title-serif" style="font-size:16px;font-weight:600;margin-bottom:16px;">Aggiungi foto</h3>

          <!-- Selezione pianta -->
          <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Pianta</label>
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

          <div style="display:flex;gap:10px;margin-top:16px;">
            <button @click="mostraFormUpload = false" class="btn btn-ghost" style="flex:1;min-height:44px;">Annulla</button>
            <button @click="caricaFoto" :disabled="!uploadFileObj || caricandoUpload" class="btn btn-rose" style="flex:2;min-height:44px;">
              <Spinner v-if="caricandoUpload" />{{ caricandoUpload ? 'Caricamento…' : 'Carica foto' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useGalleria } from '@/composables/useGalleria'
import ModalConferma from '@/components/ModalConferma.vue'
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

const LABEL_COLTIVATO_IN = { vaso: 'In vaso', terra: 'In terra', acqua: 'In acqua' }
function labelColtivatoIn(v) { return LABEL_COLTIVATO_IN[v] ?? 'In terra' }
function iconaColtivatoIn(v) { return v in LABEL_COLTIVATO_IN ? v : 'terra' }

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
    return {
      piantaId,
      isGenerale:  piantaId === 'generale',
      nomeSpecie:  specie?.nome ?? pianta?.specie ?? piantaId,
      zona:        pianta?.zona ?? null,
      sottozona:   pianta?.sottozona ?? null,
      coltivatoIn: pianta?.coltivato_in ?? null,
      foto:        fotoList.sort((a, b) => b.nome.localeCompare(a.nome)),
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
  try {
    await galleria.elimina(daEliminareFoto.value)
    foto.value = foto.value.filter(f => f.path !== daEliminareFoto.value.path)
    daEliminareFoto.value = null
  } finally {
    eliminandoFoto.value = false
  }
}

onMounted(async () => {
  await store.caricaTutto()
  caricandoLista.value = true
  errore.value = null
  try {
    foto.value = await galleria.listaTutte()
  } catch (e) {
    errore.value = e.message
  } finally {
    caricandoLista.value = false
  }
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
  } catch (e) {
    erroreUpload.value = e.message
  } finally {
    caricandoUpload.value = false
  }
}
</script>

<style scoped>
/* Colonna feed stile Instagram: a tutta larghezza su mobile, ma limitata
   e centrata su desktop (senza il cap le foto 4:5 diventano enormi dentro
   il max-width di 920px di .app-main). */
.post {
  width: 100%;
  max-width: 460px;
  margin: 0 auto;
}

.carosello {
  display: flex;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  -webkit-overflow-scrolling: touch;
  border-radius: 14px;
  background: var(--cream-dark);
  scrollbar-width: none;
}
.carosello::-webkit-scrollbar { display: none; }

.slide {
  position: relative;
  flex: 0 0 100%;
  scroll-snap-align: center;
  aspect-ratio: 4 / 5;
  user-select: none;
  -webkit-user-select: none;
  -webkit-touch-callout: none;
}

.overlay {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 20px 12px 10px;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 4px 10px;
  background: linear-gradient(transparent, rgba(0, 0, 0, 0.55));
  pointer-events: none;
}
</style>
