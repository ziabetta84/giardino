<template>
  <div>
    <!-- Back -->
    <RouterLink to="/piante" style="display:inline-flex;align-items:center;gap:6px;font-size:13px;color:var(--ink-soft);text-decoration:none;margin-bottom:20px;">
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
        <div style="font-size:40px;margin-bottom:12px;">🌾</div>
        <p>Pianta non trovata</p>
      </div>
    </template>

    <template v-else>
      <!-- Header -->
      <div style="display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:20px;gap:12px;">
        <div>
          <h1 class="title-display gradient-title" style="font-size:1.7rem;font-weight:800;line-height:1.2;">
            {{ specie?.nome ?? pianta.specie }}
          </h1>
          <p style="font-size:13px;color:var(--ink-soft);margin-top:4px;font-style:italic;">
            {{ specie?.specie }}<span v-if="pianta.varieta"> — {{ pianta.varieta }}</span>
          </p>
          <div style="display:flex;gap:6px;flex-wrap:wrap;margin-top:8px;">
            <span class="badge badge-gold">{{ pianta.zona }}</span>
            <span v-if="pianta.sottozona" class="badge" style="background:var(--sage-pale);color:var(--sage-dark);">{{ pianta.sottozona }}</span>
          </div>
        </div>
        <RouterLink :to="`/piante/${route.params.id}/modifica`" class="btn btn-ghost"
          style="flex-shrink:0;padding:8px 14px;font-size:13px;">✏️ Modifica</RouterLink>
      </div>

      <!-- Urgenze -->
      <div v-if="cureUrgenti.length" class="card" style="padding:14px 16px;border-color:var(--rose-light);background:var(--rose-pale);margin-bottom:12px;">
        <p style="font-size:12px;font-weight:600;color:var(--rose-dark);margin-bottom:8px;">⚠ Da curare subito</p>
        <div style="display:flex;flex-direction:column;gap:6px;">
          <div v-for="c in cureUrgenti" :key="c.tipo" style="display:flex;align-items:center;justify-content:space-between;">
            <span style="font-size:13px;color:var(--rose-dark);">{{ c.label }}</span>
            <button @click="registraCura(c.tipo)" :disabled="salvando === c.tipo" class="btn btn-rose"
              style="font-size:11px;padding:4px 10px;min-height:28px;">
              {{ salvando === c.tipo ? '⏳' : 'Registra' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Cure -->
      <div class="card" style="padding:16px;margin-bottom:12px;">
        <p class="section-label" style="margin-bottom:10px;">Stato cure</p>
        <div style="display:flex;flex-direction:column;gap:10px;">
          <div v-for="tipo in tipiCura" :key="tipo"
            style="display:flex;align-items:center;justify-content:space-between;">
            <div>
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
              {{ salvando === tipo ? '⏳' : '✓ Fatto' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Concimi consigliati per il fabbisogno attuale -->
      <div v-if="fabbisognoNpk && classificaConcimiPianta.length" class="card" style="padding:16px;margin-bottom:12px;">
        <p class="section-label" style="margin-bottom:2px;">🌱 Concimi consigliati</p>
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
            <span style="color:var(--ink-mid);">{{ val }}</span>
          </div>
        </div>
      </div>

      <!-- Coltivazione specie (solo annuali/biennali, vedi tab Coltivazione del form specie) -->
      <div v-if="coltivazione" class="card" style="padding:16px;margin-bottom:12px;">
        <p class="section-label" style="margin-bottom:10px;">Coltivazione</p>
        <div style="display:flex;flex-direction:column;gap:6px;">
          <div v-if="coltivazione.famiglia_botanica" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Famiglia</span>
            <span style="color:var(--ink-mid);">{{ coltivazione.famiglia_botanica }}</span>
          </div>
          <div v-if="coltivazione.giorni_germinazione" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Germinazione</span>
            <span style="color:var(--ink-mid);">{{ coltivazione.giorni_germinazione }} gg</span>
          </div>
          <div v-if="coltivazione.giorni_trapianto" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Giorni al trapianto</span>
            <span style="color:var(--ink-mid);">{{ coltivazione.giorni_trapianto }} gg dalla semina</span>
          </div>
          <div v-if="coltivazione.giorni_raccolta" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Prima raccolta</span>
            <span style="color:var(--ink-mid);">{{ coltivazione.giorni_raccolta }} gg dal trapianto</span>
          </div>
          <div v-if="coltivazione.finestra_semina?.length" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Finestra semina</span>
            <span style="color:var(--ink-mid);text-transform:capitalize;">{{ coltivazione.finestra_semina.join(', ') }}</span>
          </div>
          <div v-if="coltivazione.finestra_trapianto?.length" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Finestra trapianto</span>
            <span style="color:var(--ink-mid);text-transform:capitalize;">{{ coltivazione.finestra_trapianto.join(', ') }}</span>
          </div>
          <div v-if="coltivazione.resistenza_gelo" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Resistenza al gelo</span>
            <span style="color:var(--ink-mid);text-transform:capitalize;">{{ coltivazione.resistenza_gelo }}</span>
          </div>
          <div v-if="coltivazione.spaziatura_cm" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Spaziatura</span>
            <span style="color:var(--ink-mid);">{{ coltivazione.spaziatura_cm }} cm</span>
          </div>
          <div v-if="coltivazione.consociazioni_favorevoli?.length" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Si abbina bene con</span>
            <span style="color:var(--sage-dark);">{{ coltivazione.consociazioni_favorevoli.join(', ') }}</span>
          </div>
          <div v-if="coltivazione.consociazioni_sfavorevoli?.length" style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);min-width:120px;">Evitare vicino a</span>
            <span style="color:var(--rose-dark);">{{ coltivazione.consociazioni_sfavorevoli.join(', ') }}</span>
          </div>
        </div>
      </div>

      <!-- Alert specie -->
      <div v-if="specie?.alert?.length" class="card" style="padding:16px;margin-bottom:12px;border-color:var(--gold-light);background:var(--gold-pale);">
        <p class="section-label" style="margin-bottom:10px;color:var(--gold-dark);">Note tecniche</p>
        <ul style="padding-left:16px;margin:0;display:flex;flex-direction:column;gap:4px;">
          <li v-for="a in specie.alert" :key="a" style="font-size:12px;color:var(--ink-mid);">{{ a }}</li>
        </ul>
      </div>

      <!-- Note personali -->
      <div v-if="pianta.note" class="card" style="padding:16px;margin-bottom:12px;">
        <p class="section-label" style="margin-bottom:6px;">Note</p>
        <p style="font-size:13px;color:var(--ink-mid);line-height:1.6;">{{ pianta.note }}</p>
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
