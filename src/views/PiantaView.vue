<template>
  <div>
    <!-- Back (assente quando c'è la foto hero: il back vive nell'overlay) -->
    <RouterLink v-if="!fotoHero" to="/piante" style="display:inline-flex;align-items:center;gap:6px;font-size:13px;color:var(--ink-soft);text-decoration:none;margin-bottom:20px;">
      ← Piante
    </RouterLink>

    <!-- Skeleton -->
    <template v-if="store.loading">
      <div class="skeleton" style="height:28px;width:60%;margin-bottom:8px;"></div>
      <div class="skeleton" style="height:14px;width:40%;margin-bottom:24px;"></div>
      <div class="skeleton" style="height:100px;border-radius:16px;margin-bottom:12px;"></div>
      <div class="skeleton" style="height:80px;border-radius:16px;"></div>
    </template>

    <template v-else-if="!pianta">
      <div style="text-align:center;padding:60px 0;color:var(--ink-faint);">
        <div style="width:56px;height:56px;border-radius:50%;background:var(--olive-tile);display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
          <Icon name="foglia" style="width:24px;height:24px;" />
        </div>
        <p>Pianta non trovata</p>
      </div>
    </template>

    <template v-else>
      <!-- Header con foto: solo quando la pianta ha almeno una foto in
           galleria. Senza foto resta l'header testuale, invece di uno
           spazio vuoto o un placeholder. -->
      <div v-if="fotoHero" class="plant-hero" :style="`background-image:url(${fotoHero.url});`">
        <RouterLink to="/piante" class="plant-back"><Icon name="back" style="width:16px;height:16px;" /></RouterLink>
        <RouterLink :to="`/piante/${route.params.id}/modifica`" class="plant-edit">
          <Icon name="matita" style="width:12px;height:12px;" />Modifica
        </RouterLink>
        <div class="plant-hero-text">
          <span class="zone-chip">{{ pianta.sottozona ? `${pianta.zona} · ${pianta.sottozona}` : pianta.zona }}</span>
          <h1 class="plant-hero-title title-settle">{{ specie?.nome ?? pianta.specie }}</h1>
          <p class="plant-hero-lat">
            {{ specie?.specie }}<span v-if="pianta.varieta"> — {{ pianta.varieta }}</span>
            <span v-if="badgeVerifica" class="badge" :class="badgeVerifica.classe" style="margin-left:6px;vertical-align:middle;">{{ badgeVerifica.testo }}</span>
          </p>
        </div>
      </div>

      <!-- Header testuale: quando non c'è ancora una foto -->
      <div v-else style="display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:20px;gap:12px;">
        <div>
          <h1 class="title-display gradient-title title-settle" style="font-size:1.7rem;font-weight:800;line-height:1.2;">
            {{ specie?.nome ?? pianta.specie }}
          </h1>
          <p class="title-serif" style="font-size:13px;color:var(--ink-soft);margin-top:4px;font-style:italic;">
            {{ specie?.specie }}<span v-if="pianta.varieta"> — {{ pianta.varieta }}</span>
          </p>
          <div style="display:flex;gap:6px;flex-wrap:wrap;margin-top:8px;">
            <span class="badge badge-gold">{{ pianta.zona }}</span>
            <span v-if="pianta.sottozona" class="badge" style="background:var(--sage-pale);color:var(--sage-dark);">{{ pianta.sottozona }}</span>
            <span v-if="badgeVerifica" class="badge" :class="badgeVerifica.classe">{{ badgeVerifica.testo }}</span>
          </div>
        </div>
        <RouterLink :to="`/piante/${route.params.id}/modifica`" class="btn btn-ghost"
          style="flex-shrink:0;padding:8px 14px;font-size:13px;display:flex;align-items:center;gap:6px;">
          <Icon name="matita" style="width:13px;height:13px;flex-shrink:0;" />Modifica
        </RouterLink>
      </div>

      <!-- Urgenze -->
      <div v-if="cureUrgenti.length" class="card" style="padding:14px 16px;border-color:var(--rose-light);background:var(--rose-pale);margin-bottom:12px;">
        <p style="display:flex;align-items:center;gap:6px;font-size:12px;font-weight:600;color:var(--rose-dark);margin-bottom:8px;">
          <Icon name="campanella" style="width:13px;height:13px;flex-shrink:0;" />Da curare subito
        </p>
        <div style="display:flex;flex-direction:column;gap:6px;">
          <div v-for="c in cureUrgenti" :key="c.tipo" style="display:flex;align-items:center;justify-content:space-between;">
            <span style="font-size:13px;color:var(--rose-dark);">{{ c.label }}</span>
            <button @click="registraCura(c.tipo)" :disabled="salvando === c.tipo" class="btn btn-rose"
              style="font-size:11px;padding:4px 10px;min-height:28px;">
              <Spinner v-if="salvando === c.tipo" /><span v-else>Registra</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Cure -->
      <div class="card" style="padding:16px;margin-bottom:12px;">
        <p class="section-label" style="margin-bottom:10px;">Stato cure</p>
        <div style="display:flex;flex-direction:column;gap:10px;">
          <div v-for="tipo in tipiCura" :key="tipo"
            style="display:flex;align-items:center;gap:12px;">
            <div class="cura-ic" :style="`background:var(--${tintaCura(tipo)}-tile);`"><Icon :name="iconaCura(tipo)" style="width:17px;height:17px;" /></div>
            <div style="flex:1;min-width:0;">
              <div style="font-size:13px;font-weight:500;text-transform:capitalize;">{{ tipo }}</div>
              <div style="font-size:11px;color:var(--ink-soft);margin-top:2px;">
                {{ valutaCura(pianta, specie, tipo, contestoCura).label ?? 'Non configurata' }}
              </div>
              <div v-if="tipo === 'concimazione' && fabbisognoNpk && !classificaConcimiPianta.length" style="font-size:11px;color:var(--ink-faint);margin-top:2px;">
                Nessun concime in dispensa (fabbisogno {{ fabbisognoNpk }})
              </div>
            </div>
            <button @click="registraCura(tipo)" :disabled="salvando === tipo" class="btn btn-sage"
              style="font-size:11px;padding:4px 10px;min-height:28px;flex-shrink:0;white-space:nowrap;">
              <Spinner v-if="salvando === tipo" /><span v-else>✓ Fatto</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Concimi consigliati per il fabbisogno attuale -->
      <div v-if="fabbisognoNpk && classificaConcimiPianta.length" class="card" style="padding:16px;margin-bottom:12px;">
        <p class="section-label" style="display:flex;align-items:center;gap:6px;margin-bottom:2px;">
          <Icon name="concimazione" style="width:13px;height:13px;flex-shrink:0;" />Concimi consigliati
        </p>
        <p style="font-size:11px;color:var(--ink-faint);margin:0 0 10px;">Per il fabbisogno di concimazione attuale: {{ fabbisognoNpk }}</p>
        <div style="display:flex;flex-direction:column;gap:6px;">
          <div v-for="(c, i) in classificaConcimiPianta" :key="c.id"
            :style="`display:flex;align-items:center;gap:10px;padding:8px 10px;border-radius:12px;${i === 0 ? 'background:var(--sage-pale);' : ''}`">
            <span :style="`width:22px;height:22px;border-radius:50%;flex-shrink:0;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;${i === 0 ? 'background:var(--sage);color:white;' : 'background:var(--cream-dark);color:var(--ink-soft);'}`">
              {{ i + 1 }}
            </span>
            <span style="flex:1;min-width:0;font-size:13px;font-weight:500;line-height:1.4;">{{ c.nome }}</span>
            <span class="badge" style="background:var(--white);color:var(--ink-soft);border:1px solid var(--cream-dark);flex-shrink:0;">
              {{ c.npk.n }}-{{ c.npk.p }}-{{ c.npk.k }}
            </span>
          </div>
        </div>
      </div>

      <!-- Esigenze specie -->
      <div v-if="specie?.esigenze" class="card" style="padding:16px;margin-bottom:12px;">
        <p class="section-label" style="margin-bottom:10px;">Esigenze</p>
        <div style="display:flex;flex-direction:column;gap:6px;">
          <div v-for="(val, chiave) in specie.esigenze" :key="chiave"
            style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);text-transform:capitalize;min-width:70px;">{{ chiave }}</span>
            <span class="text-light" style="color:var(--ink-mid);">{{ val }}</span>
          </div>
        </div>
      </div>

      <!-- Coltivazione specie (solo annuali/biennali, vedi tab Coltivazione del form specie) -->
      <div v-if="coltivazione" class="card" style="padding:16px;margin-bottom:12px;">
        <p class="section-label" style="margin-bottom:10px;">Coltivazione</p>
        <div style="display:flex;flex-direction:column;gap:6px;">
          <div v-if="coltivazione.famiglia_botanica" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Famiglia</span>
            <span class="text-light" style="color:var(--ink-mid);">{{ coltivazione.famiglia_botanica }}</span>
          </div>
          <div v-if="coltivazione.giorni_germinazione" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Germinazione</span>
            <span class="text-light" style="color:var(--ink-mid);">{{ coltivazione.giorni_germinazione }} gg</span>
          </div>
          <div v-if="coltivazione.giorni_trapianto" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Giorni al trapianto</span>
            <span class="text-light" style="color:var(--ink-mid);">{{ coltivazione.giorni_trapianto }} gg dalla semina</span>
          </div>
          <div v-if="coltivazione.giorni_raccolta" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Prima raccolta</span>
            <span class="text-light" style="color:var(--ink-mid);">{{ coltivazione.giorni_raccolta }} gg dal trapianto</span>
          </div>
          <div v-if="coltivazione.finestra_semina?.length" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Finestra semina</span>
            <span class="text-light" style="color:var(--ink-mid);text-transform:capitalize;">{{ coltivazione.finestra_semina.join(', ') }}</span>
          </div>
          <div v-if="coltivazione.finestra_trapianto?.length" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Finestra trapianto</span>
            <span class="text-light" style="color:var(--ink-mid);text-transform:capitalize;">{{ coltivazione.finestra_trapianto.join(', ') }}</span>
          </div>
          <div v-if="coltivazione.resistenza_gelo" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Resistenza al gelo</span>
            <span class="text-light" style="color:var(--ink-mid);text-transform:capitalize;">{{ coltivazione.resistenza_gelo }}</span>
          </div>
          <div v-if="coltivazione.spaziatura_cm" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Spaziatura</span>
            <span class="text-light" style="color:var(--ink-mid);">{{ coltivazione.spaziatura_cm }} cm</span>
          </div>
          <div v-if="coltivazione.consociazioni_favorevoli?.length" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Si abbina bene con</span>
            <span class="text-light" style="color:var(--sage-dark);">{{ coltivazione.consociazioni_favorevoli.join(', ') }}</span>
          </div>
          <div v-if="coltivazione.consociazioni_sfavorevoli?.length" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Evitare vicino a</span>
            <span class="text-light" style="color:var(--rose-dark);">{{ coltivazione.consociazioni_sfavorevoli.join(', ') }}</span>
          </div>
        </div>
      </div>

      <!-- Alert specie -->
      <div v-if="specie?.alert?.length" class="card" style="padding:16px;margin-bottom:12px;border-color:var(--gold-light);background:var(--gold-pale);">
        <p class="section-label" style="margin-bottom:10px;color:var(--gold-dark);">Note tecniche</p>
        <ul style="padding-left:16px;margin:0;display:flex;flex-direction:column;gap:4px;">
          <li v-for="a in specie.alert" :key="a" class="text-light" style="font-size:12px;color:var(--ink-mid);">{{ a }}</li>
        </ul>
      </div>

      <!-- Note personali -->
      <div v-if="pianta.note" class="card" style="padding:16px;margin-bottom:12px;">
        <p class="section-label" style="margin-bottom:6px;">Note</p>
        <p class="text-light" style="font-size:13px;color:var(--ink-mid);line-height:1.6;">{{ pianta.note }}</p>
      </div>

      <!-- Foto -->
      <div v-if="caricandoFoto || fotoPianta.length" class="card" style="padding:16px;margin-bottom:12px;">
        <p class="section-label" style="margin-bottom:10px;">Foto</p>
        <div v-if="caricandoFoto" style="display:flex;gap:8px;">
          <div v-for="i in 3" :key="i" class="skeleton" style="width:72px;height:72px;border-radius:12px;flex-shrink:0;"></div>
        </div>
        <div v-else style="display:flex;gap:8px;overflow-x:auto;padding-bottom:4px;">
          <div v-for="f in fotoPianta" :key="f.path"
            @click="luce = f"
            style="width:72px;height:72px;border-radius:12px;overflow:hidden;cursor:pointer;background:var(--cream-dark);flex-shrink:0;">
            <img :src="f.url" :alt="f.nome" style="width:100%;height:100%;object-fit:cover;" loading="lazy">
          </div>
        </div>
      </div>

      <!-- Info impianto -->
      <div v-if="pianta.impianto" class="card" style="padding:14px 16px;margin-bottom:12px;">
        <p style="font-size:12px;color:var(--ink-soft);">Messa a dimora: <strong>{{ formattaData(pianta.impianto) }}</strong></p>
      </div>
      <div v-else-if="pianta.impianto_circa" class="card" style="padding:14px 16px;margin-bottom:12px;">
        <p style="font-size:12px;color:var(--ink-soft);">Messa a dimora: <strong>{{ pianta.impianto_circa }}</strong> <span style="color:var(--ink-faint);">(data non certa)</span></p>
      </div>

      <!-- Elimina -->
      <div style="margin-top:24px;text-align:center;">
        <button @click="daEliminare = true" class="btn" style="font-size:13px;color:var(--rose-dark);background:transparent;border-color:var(--rose-light);">
          Elimina pianta
        </button>
      </div>
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
import { useApi } from '@/composables/useApi'
import { useGalleria } from '@/composables/useGalleria'
import { valutaCura, cureUrgentiPianta, stagione } from '@/composables/useCure'
import { classificaConcimiPerFabbisogno } from '@/composables/useConcimi'
import ModalConferma from '@/components/ModalConferma.vue'
import LightboxFoto from '@/components/LightboxFoto.vue'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const route  = useRoute()
const router = useRouter()
const store  = useDatiStore()
const { saveJSON } = useApi()
const galleria = useGalleria()

const salvando   = ref(null)
const daEliminare = ref(false)
const eliminando  = ref(false)

const fotoPianta    = ref([])
const caricandoFoto = ref(false)
const luce          = ref(null)
const daEliminareFoto = ref(null)
const eliminandoFoto  = ref(false)

// La prima foto in galleria diventa l'header della scheda, al posto del
// testo semplice — se la pianta non ha ancora foto resta l'header testuale.
const fotoHero = computed(() => fotoPianta.value[0] ?? null)

const ICONE_CURA = { irrigazione: 'goccia', concimazione: 'concimazione', potatura: 'potatura', calcio: 'provetta' }
const TINTE_CURA = { irrigazione: 'acqua', concimazione: 'olive', potatura: 'rose', calcio: 'sage' }
function iconaCura(tipo) { return ICONE_CURA[tipo] ?? 'foglia' }
function tintaCura(tipo) { return TINTE_CURA[tipo] ?? 'sage' }

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
  caricandoFoto.value = true
  try {
    fotoPianta.value = await galleria.listaFoto(id)
  } catch {
    fotoPianta.value = []
  } finally {
    caricandoFoto.value = false
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

// Badge di provenienza dati (#120): "verificato" = scheda controllata su
// fonte orticola reale (RHS, Acta Plantarum, vivai); "bozza" = compilata
// dalla sola conoscenza botanica generale, non ancora verificata su fonte.
// stato_verifica manca solo quando i dati vengono dal fallback offline più
// vecchio della migrazione Supabase: in quel caso nessun badge, invece di
// dichiarare un dato che non abbiamo davvero.
const badgeVerifica = computed(() => {
  const stato = specie.value?.stato_verifica
  if (!stato) return null
  return stato === 'verificato'
    ? { testo: 'Verificato', classe: 'badge-ok' }
    : { testo: 'Bozza', classe: 'badge-gold' }
})

// Presente solo per le specie annuali/biennali curate dalla tab
// Coltivazione del form specie (vedi SelettoreSpecie.vue) — assente per le
// perenni, dove semina/trapianto non si applicano.
const coltivazione = computed(() => specie.value?.coltivazione ?? null)

const contestoCura = computed(() => ({
  esterno: store.zone?.[pianta.value?.zona]?.tipo === 'esterno',
  meteo: store.meteo,
}))

// "calcio" riguarda solo le poche specie con un beneficio documentato (vedi
// specie.json): mostrarlo comunque per tutte le altre come "Non configurata"
// sarebbe rumore, a differenza di irrigazione/concimazione/potatura che sono
// pertinenti ovunque.
const tipiCura = computed(() => {
  const base = ['irrigazione', 'concimazione', 'potatura']
  if (specie.value?.manutenzione?.calcio) base.push('calcio')
  return base
})

const cureUrgenti = computed(() =>
  pianta.value ? cureUrgentiPianta(pianta.value, specie.value, contestoCura.value) : []
)

const fabbisognoNpk = computed(() => specie.value?.manutenzione?.npk?.[stagione()] ?? null)
// Solo i primi 3: la dispensa può avere una decina di concimi, l'intera
// classifica affollerebbe la riga della cura senza aggiungere utilità
// oltre i migliori candidati.
const classificaConcimiPianta = computed(() =>
  fabbisognoNpk.value ? classificaConcimiPerFabbisogno(fabbisognoNpk.value, store.concimi).slice(0, 3) : []
)

async function registraCura(tipo) {
  if (!pianta.value || salvando.value) return
  salvando.value = tipo
  const id = pianta.value.id
  try {
    const nuove = await saveJSON('piante.json', (correnti) => {
      const base = { ...(correnti ?? store.piante) }
      const piantaEsistente = base[id] || {}
      base[id] = {
        ...piantaEsistente,
        ultima_cura: {
          ...(piantaEsistente.ultima_cura || {}),
          [tipo]: new Date().toISOString().split('T')[0],
        }
      }
      return base
    })
    store.piante = nuove
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
    const nuove = await saveJSON('piante.json', (correnti) => {
      const base = { ...(correnti ?? store.piante) }
      delete base[id]
      return base
    })
    store.piante = nuove
    router.push('/piante')
  } finally {
    eliminando.value = false
  }
}
</script>

<style scoped>
.plant-hero {
  position: relative; height: 200px; margin: 0 -16px 20px; border-radius: 0;
  background-size: cover; background-position: 50% 35%;
}
.plant-hero::after {
  content: ''; position: absolute; inset: 0;
  background: linear-gradient(180deg, rgba(20,14,8,0.02) 0%, rgba(20,14,8,0.08) 55%, rgba(20,14,8,0.62) 100%);
}
.plant-back, .plant-edit {
  position: absolute; top: 14px; z-index: 2;
  background: rgba(20,14,8,0.32); backdrop-filter: blur(3px);
  color: #fdf8ee; text-decoration: none;
}
.plant-back {
  left: 16px; width: 32px; height: 32px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
}
.plant-edit {
  right: 16px; display: flex; align-items: center; gap: 5px;
  font-size: 11px; font-weight: 700; padding: 7px 12px 7px 10px; border-radius: 999px;
}
.plant-hero-text { position: absolute; left: 18px; right: 18px; bottom: 14px; z-index: 2; color: #fdf8ee; }
.plant-hero-title {
  font-family: var(--font-display); font-weight: 800; font-size: 1.8rem; line-height: 1.1;
  letter-spacing: -0.02em; margin: 0;
  text-shadow: 0 2px 12px rgba(0,0,0,0.28);
}
.plant-hero-lat { font-family: var(--font-serif); font-style: italic; font-size: 12.5px; color: rgba(253,248,238,0.88); margin: 3px 0 0; }
.zone-chip {
  display: inline-block; margin-bottom: 6px; font-size: 9.5px; font-weight: 700;
  letter-spacing: .04em; text-transform: uppercase; background: rgba(253,248,238,0.22);
  color: #fdf8ee; padding: 3px 9px; border-radius: 999px;
}
.cura-ic { width: 38px; height: 38px; border-radius: 12px; flex-shrink: 0; display: flex; align-items: center; justify-content: center; }
</style>
