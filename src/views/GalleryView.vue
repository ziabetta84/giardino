<template>
  <div>
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;">
      <h1 class="title-display gradient-title" style="font-size:1.9rem;font-weight:800;">Galleria</h1>
      <button @click="mostraFormUpload = true" class="btn btn-rose" style="padding:8px 16px;">📷 Aggiungi</button>
    </div>

    <!-- Skeleton -->
    <div v-if="caricandoLista" style="display:flex;flex-direction:column;gap:20px;">
      <div v-for="i in 3" :key="i">
        <div class="skeleton" style="height:13px;width:40%;margin-bottom:10px;border-radius:6px;"></div>
        <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:4px;">
          <div v-for="j in 3" :key="j" class="skeleton" style="aspect-ratio:1;border-radius:8px;"></div>
        </div>
      </div>
    </div>

    <template v-else>
      <!-- Nessuna foto -->
      <div v-if="!gruppi.length" style="text-align:center;padding:60px 20px;color:var(--ink-faint);">
        <div style="font-size:48px;margin-bottom:12px;">📷</div>
        <p class="title-serif" style="font-size:15px;color:var(--ink-soft);font-weight:600;">Nessuna foto ancora</p>
        <p style="font-size:12px;margin-top:6px;">Fotografa le tue piante e documenta la crescita</p>
        <p v-if="errore" style="font-size:11px;color:var(--rose-dark);margin-top:10px;">{{ errore }}</p>
      </div>

      <!-- Gruppi per pianta -->
      <div v-else style="display:flex;flex-direction:column;gap:24px;">
        <div v-for="g in gruppi" :key="g.piantaId">
          <!-- Header gruppo -->
          <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;">
            <div style="display:flex;align-items:center;gap:8px;min-width:0;">
              <RouterLink :to="`/piante/${g.piantaId}`"
                class="title-serif"
                style="font-size:14px;font-weight:600;color:var(--ink);text-decoration:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
                {{ g.nomeSpecie }}
              </RouterLink>
              <span v-if="g.zona" class="badge badge-gold" style="flex-shrink:0;">{{ g.zona }}</span>
            </div>
            <span style="font-size:11px;color:var(--ink-faint);flex-shrink:0;margin-left:8px;">{{ g.foto.length }} foto</span>
          </div>

          <!-- Griglia foto del gruppo -->
          <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:4px;">
            <div v-for="f in g.foto" :key="f.path"
              @click="apriLightbox(f, g)"
              style="aspect-ratio:1;border-radius:8px;overflow:hidden;cursor:pointer;background:var(--cream-dark);position:relative;">
              <img :src="f.url" :alt="f.nome"
                style="width:100%;height:100%;object-fit:cover;transition:transform 0.2s;"
                loading="lazy"
                @mouseenter="e => e.target.style.transform='scale(1.04)'"
                @mouseleave="e => e.target.style.transform='scale(1)'">
              <!-- Data in overlay -->
              <div style="position:absolute;bottom:0;left:0;right:0;padding:4px 6px;background:linear-gradient(transparent,rgba(0,0,0,0.45));pointer-events:none;">
                <span style="font-size:9px;color:rgba(255,255,255,0.85);">{{ f.dataBreve }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>

    <!-- Lightbox -->
    <LightboxFoto
      :foto="luce?.foto ?? null"
      :titolo="luce?.gruppo?.nomeSpecie ?? ''"
      :ha-precedente="indiceLuce > 0"
      :ha-successivo="indiceLuce < tutteLeImmagini.length - 1"
      :indice="indiceLuce"
      :totale="tutteLeImmagini.length"
      @chiudi="luce = null"
      @naviga="navigaLuce"
      @elimina="daEliminareFoto = luce.foto"
    />

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
              <option v-for="p in ps" :key="p.id" :value="p.id">{{ p.nomeSpecie }}</option>
            </optgroup>
          </select>

          <!-- Area drop foto -->
          <label style="display:block;cursor:pointer;">
            <div style="border:2px dashed var(--sage-light);border-radius:14px;padding:24px;text-align:center;background:var(--sage-pale);transition:all 0.18s;"
              :style="uploadPreview ? 'border-color:var(--sage);' : ''">
              <img v-if="uploadPreview" :src="uploadPreview" style="max-height:160px;border-radius:8px;object-fit:contain;margin-bottom:8px;">
              <div v-else style="font-size:32px;margin-bottom:8px;">📷</div>
              <p style="font-size:13px;color:var(--sage-dark);font-weight:600;">{{ uploadPreview ? 'Tocca per cambiare' : 'Seleziona foto' }}</p>
              <p style="font-size:11px;color:var(--ink-faint);margin-top:2px;">JPG o PNG · max 10 MB</p>
            </div>
            <input type="file" accept="image/*" capture="environment" @change="selezionaUpload" style="display:none;">
          </label>

          <p v-if="erroreUpload" style="font-size:12px;color:var(--rose-dark);margin-top:8px;">⚠ {{ erroreUpload }}</p>

          <div style="display:flex;gap:10px;margin-top:16px;">
            <button @click="mostraFormUpload = false" class="btn btn-ghost" style="flex:1;min-height:44px;">Annulla</button>
            <button @click="caricaFoto" :disabled="!uploadFile64 || caricandoUpload" class="btn btn-rose" style="flex:2;min-height:44px;">
              {{ caricandoUpload ? '⏳ Caricamento…' : 'Carica foto' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useGalleria } from '@/composables/useGalleria'
import LightboxFoto from '@/components/LightboxFoto.vue'
import ModalConferma from '@/components/ModalConferma.vue'

const store = useDatiStore()
const galleria = useGalleria()

const foto            = ref([])
const caricandoLista  = ref(false)
const caricandoUpload = ref(false)
const errore          = ref(null)
const erroreUpload    = ref(null)
const luce            = ref(null)   // { foto, gruppo }
const daEliminareFoto = ref(null)
const eliminandoFoto  = ref(false)
const mostraFormUpload = ref(false)
const uploadPiantaId  = ref('')
const uploadFile64    = ref(null)
const uploadDataUrl   = ref(null)
const uploadPreview   = ref(null)

// Piante raggruppate per zona (per il select dell'upload)
const piantaPerZona = computed(() => {
  if (!store.piante) return {}
  const gruppi = {}
  for (const [id, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie]
    const zona = p.zona ?? 'Altro'
    if (!gruppi[zona]) gruppi[zona] = []
    gruppi[zona].push({ id, nomeSpecie: sp?.nome ?? p.specie })
  }
  return gruppi
})

// Raggruppa le foto per pianta, arricchite con dati store
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
      nomeSpecie: specie?.nome ?? pianta?.specie ?? piantaId,
      zona:       pianta?.zona ?? null,
      foto:       fotoList.sort((a, b) => b.nome.localeCompare(a.nome)),
    }
  }).sort((a, b) => a.nomeSpecie.localeCompare(b.nomeSpecie))
})

// Lista piatta per navigazione lightbox
const tutteLeImmagini = computed(() => gruppi.value.flatMap(g => g.foto.map(f => ({ foto: f, gruppo: g }))))
const indiceLuce = computed(() => {
  if (!luce.value) return -1
  return tutteLeImmagini.value.findIndex(i => i.foto.path === luce.value.foto.path)
})

function apriLightbox(f, g) { luce.value = { foto: f, gruppo: g } }
function navigaLuce(dir) {
  const idx = indiceLuce.value + dir
  if (idx >= 0 && idx < tutteLeImmagini.value.length) {
    luce.value = tutteLeImmagini.value[idx]
  }
}

async function confermaEliminaFoto() {
  if (!daEliminareFoto.value) return
  eliminandoFoto.value = true
  try {
    await galleria.elimina(daEliminareFoto.value)
    foto.value = foto.value.filter(f => f.path !== daEliminareFoto.value.path)
    if (luce.value?.foto.path === daEliminareFoto.value.path) luce.value = null
    daEliminareFoto.value = null
  } finally {
    eliminandoFoto.value = false
  }
}

// Tastiera per lightbox
function onKey(e) {
  if (!luce.value) return
  if (e.key === 'ArrowLeft')  navigaLuce(-1)
  if (e.key === 'ArrowRight') navigaLuce(1)
  if (e.key === 'Escape')     luce.value = null
}

onMounted(async () => {
  window.addEventListener('keydown', onKey)
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

function selezionaUpload(e) {
  const file = e.target.files?.[0]
  if (!file) return
  const reader = new FileReader()
  reader.onload = () => {
    uploadPreview.value = reader.result
    uploadDataUrl.value = reader.result
    uploadFile64.value  = reader.result.split(',')[1]
  }
  reader.readAsDataURL(file)
}

async function caricaFoto() {
  if (!uploadFile64.value || caricandoUpload.value) return
  caricandoUpload.value = true
  erroreUpload.value = null
  try {
    const cartella = uploadPiantaId.value || 'generale'
    const nuovaFoto = await galleria.carica(cartella, uploadDataUrl.value, uploadFile64.value)
    foto.value.unshift(nuovaFoto)
    mostraFormUpload.value = false
    uploadFile64.value  = null
    uploadDataUrl.value = null
    uploadPreview.value = null
    uploadPiantaId.value = ''
  } catch (e) {
    erroreUpload.value = e.message
  } finally {
    caricandoUpload.value = false
  }
}
</script>
