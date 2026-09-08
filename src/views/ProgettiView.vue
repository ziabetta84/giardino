<template>
  <div>
    <div class="page-title__row">
      <h1 class="page-title">Progetti</h1>
      <button class="pill pill--cta" @click="mostraForm = true">＋ Aggiungi</button>
    </div>

    <!-- Skeleton -->
    <div v-if="store.loading">
      <div v-for="i in 3" :key="i" class="prow">
        <div class="prow__m">
          <div class="skeleton" style="height:15px;width:55%;"></div>
          <div class="skeleton" style="height:11px;width:85%;margin-top:8px;"></div>
          <div class="skeleton" style="height:11px;width:40%;margin-top:8px;"></div>
        </div>
      </div>
    </div>

    <template v-else>
      <div v-if="progetti.length">
        <RouterLink v-for="p in progetti" :key="p.id" :to="`/progetti/${p.id}`" class="prow">
          <div class="prow__m">
            <div class="prow__t">{{ p.titolo }}</div>
            <div v-if="p.descrizione" class="prow__d">{{ descrizioneBreve(p) }}</div>
            <div v-if="p.zona || scadenzaCalcolata(p)" class="prow__meta">
              <span v-if="p.zona"><Icon :name="store.iconaZona(p.zona)" />{{ p.zona }}</span>
              <span v-if="scadenzaCalcolata(p)"><Icon :name="scadenzaUrgente(p) ? 'bandiera' : 'bandiera-calma'" />{{ formatData(scadenzaCalcolata(p)) }}</span>
            </div>
          </div>
          <span class="st" :class="classeStato(p.stato)">{{ labelStato(p.stato) }}</span>
        </RouterLink>
      </div>

      <div v-else class="empty">
        <Icon name="lampadina" />
        <p><b>Nessun progetto ancora</b>Pianifica interventi, trapianti o lavori in giardino</p>
      </div>
    </template>

    <!-- Form nuovo progetto -->
    <FoglioLaterale
      :model-value="mostraForm"
      @update:model-value="v => { if (!v) chiudiForm() }"
      titolo="Nuovo progetto"
    >
      <div v-if="mostraForm" class="foglio-form">
        <label class="field-label">Titolo</label>
        <input v-model="form.titolo" placeholder="Titolo" class="form-input" style="margin-bottom:10px;">
        <label class="field-label">Descrizione</label>
        <MiniEditor v-model="form.descrizione" placeholder="Descrizione (opzionale)" />
        <label class="field-label" style="margin-top:10px;">Zona</label>
        <input v-model="form.zona" placeholder="Zona (opzionale)" class="form-input">
        <p v-if="erroreSalvataggio" class="pv-errore" role="alert">{{ erroreSalvataggio }}</p>
        <div class="foglio-actions">
          <button class="btn btn-ghost" @click="chiudiForm" style="min-height:40px;padding:8px 16px;">Annulla</button>
          <button class="btn btn-sage" @click="salvaProgetto" :disabled="!form.titolo.trim() || salvando"
            style="min-height:40px;padding:8px 16px;">
            <Spinner v-if="salvando" /><span v-else>Salva</span>
          </button>
        </div>
      </div>
    </FoglioLaterale>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useProgettiApi } from '@/composables/useProgettiApi'
import { scadenzaCalcolata, statoTappa } from '@/composables/useProgetti'
import MiniEditor from '@/components/MiniEditor.vue'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'
import FoglioLaterale from '@/components/FoglioLaterale.vue'

const store = useDatiStore()
const progettiApi = useProgettiApi()

const mostraForm = ref(false)
const salvando   = ref(false)
const erroreSalvataggio = ref(null)
const form = ref({ titolo: '', descrizione: '', zona: '' })

function chiudiForm() {
  mostraForm.value = false
  erroreSalvataggio.value = null
  form.value = { titolo: '', descrizione: '', zona: '' }
}

// Un progetto "in ritardo senza che nessuno se ne accorga" è esattamente
// il fallimento che il prodotto vuole evitare (vedi PRODUCT.md), quindi
// l'elenco non può restare puramente alfabetico: i progetti ancora attivi
// vengono prima di quelli conclusi/cancellati/falliti (che non richiedono
// più nulla), e tra gli attivi quelli con la tappa più urgente salgono in
// cima — a parità di urgenza, la scadenza più vicina precede le altre.
const STATI_TERMINALI = new Set(['completato', 'cancellato', 'fallito'])
function scadenzaUrgente(p) {
  const data = scadenzaCalcolata(p)
  if (!data) return false
  const tappa = (p.tappe || []).find(t => t.data === data)
  return tappa ? statoTappa(tappa).urgente : false
}
const progetti = computed(() => {
  if (!store.progetti) return []
  return Object.entries(store.progetti)
    .map(([id, p]) => ({ id, ...p }))
    .sort((a, b) => {
      const terminaleA = STATI_TERMINALI.has(a.stato), terminaleB = STATI_TERMINALI.has(b.stato)
      if (terminaleA !== terminaleB) return terminaleA ? 1 : -1
      const urgenteA = scadenzaUrgente(a), urgenteB = scadenzaUrgente(b)
      if (urgenteA !== urgenteB) return urgenteA ? -1 : 1
      const scadA = scadenzaCalcolata(a), scadB = scadenzaCalcolata(b)
      if (scadA && scadB && scadA !== scadB) return scadA.localeCompare(scadB)
      if (scadA !== scadB) return scadA ? -1 : 1
      return (a.titolo ?? '').localeCompare(b.titolo ?? '')
    })
})

const LABEL_STATO = {
  aperto: 'Aperto', in_corso: 'In corso', completato: 'Completato',
  fallito: 'Fallito', cancellato: 'Cancellato',
}
const CLASSE_STATO = {
  aperto: 'st--n', in_corso: 'st--g', completato: 'st--s',
  fallito: 'st--r', cancellato: 'st--n',
}
function labelStato(stato) {
  return LABEL_STATO[stato] ?? 'Aperto'
}
function classeStato(stato) {
  return CLASSE_STATO[stato] ?? 'st--n'
}

function formatData(d){
  if(!d) return ''
  var dt = new Date(d), ora = new Date()
  var s = dt.toLocaleDateString('it-IT', { day:'numeric', month:'long' })
  return dt.getFullYear() !== ora.getFullYear() ? s + ' ' + dt.getFullYear() : s
}

// Anteprima in elenco: niente tag HTML (la formattazione ha senso solo nella
// scheda del progetto). Si tronca alla prima frase (primo ". ") se c'è entro
// ~200 caratteri; altrimenti a confine di parola, mai a metà parola.
function descrizioneBreve(p) {
  const pulito = (p.descrizione || '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim()
  if (!pulito) return ''
  const punto = pulito.indexOf('. ')
  if (punto !== -1 && punto < 200) return pulito.slice(0, punto + 1)
  if (pulito.length <= 150) return pulito
  const taglio = pulito.slice(0, 150)
  const ultimoSpazio = taglio.lastIndexOf(' ')
  return (ultimoSpazio > 0 ? taglio.slice(0, ultimoSpazio) : taglio).replace(/[.,;:]+$/, '') + '…'
}

async function salvaProgetto() {
  if (!form.value.titolo.trim() || salvando.value) return
  salvando.value = true
  erroreSalvataggio.value = null
  try {
    await progettiApi.salvaProgetto(null, {
      titolo: form.value.titolo.trim(),
      descrizione: form.value.descrizione.trim() || null,
      zona: form.value.zona.trim() || null,
      stato: 'aperto',
      creato: new Date().toISOString().split('T')[0],
      tappe: [],
    }, true)
    mostraForm.value = false
    form.value = { titolo: '', descrizione: '', zona: '' }
  } catch {
    erroreSalvataggio.value = 'Non sono riuscito a salvare il progetto. Riprova.'
  } finally {
    salvando.value = false
  }
}
</script>

<style scoped>
/* Bottone "＋ Aggiungi": unica azione di creazione della vista, non un
   filtro — riceve la sua altezza di tocco corretta (44px) senza toccare
   .pill globale (riusata altrove come filtro), stesso fix già applicato
   in ConcimiView.vue il 07/09/2026. */
.pill--cta { min-height: 44px; }
.pv-errore { font: 400 12px/1.4 var(--font-sans); color: var(--rose-ink); margin: -2px 2px 0; }
</style>