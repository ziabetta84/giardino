<template>
  <div>
    <div class="page-title__row">
      <h1 class="page-title">Concimi</h1>
      <button @click="apriNuovo" class="pill pill--cta">＋ Aggiungi</button>
    </div>

    <!-- Ricerca: stesso pattern di PianteView.vue, utile con una dispensa
         ampia (macerati fatti in casa, prodotti diversi per stagione). -->
    <div style="position:relative;margin-bottom:12px;">
      <Icon name="cerca" style="position:absolute;left:14px;top:50%;transform:translateY(-50%);width:15px;height:15px;color:var(--ink-faint);pointer-events:none;" />
      <input class="search-input" v-model="cerca" type="search" placeholder="Cerca per nome…" style="padding-right:40px;">
      <button v-if="cerca" type="button" class="search-clear" @click="cerca = ''" aria-label="Cancella ricerca">×</button>
    </div>

    <!-- Skeleton -->
    <div v-if="store.loading" style="display:flex;flex-direction:column;gap:10px;">
      <div v-for="i in 3" :key="i" class="card" style="padding:16px;">
        <div class="skeleton" style="height:16px;width:50%;margin-bottom:8px;"></div>
        <div class="skeleton" style="height:11px;width:30%;"></div>
      </div>
    </div>

    <template v-else>
      <div v-if="concimiFiltrati.length" class="feedlist">
        <div v-for="c in concimiFiltrati" :key="c.id" class="feed feed--tap"
          role="button" tabindex="0"
          @click="apriModifica(c)" @keydown.enter="apriModifica(c)" @keydown.space.prevent="apriModifica(c)">
          <div class="feed__m">
            <div class="feed__n">
              {{ c.nome }}<span v-if="c.disponibile === false" class="feed__tag">terminato</span>
            </div>
            <div v-if="c.descrizione" class="feed__d">{{ c.descrizione }}</div>
            <div class="feed__meta">
              <span class="feed__npk">{{ formattaNPK(c.npk) }}</span>
              <span v-if="elencoAbbinati(c.id)" class="feed__match">Adatto per: {{ elencoAbbinati(c.id) }}</span>
            </div>
            <div v-if="erroriDisponibile[c.id]" class="feed__err">{{ erroriDisponibile[c.id] }}</div>
          </div>
          <button @click.stop="toggleDisponibile(c)" :disabled="salvandoDisponibile === c.id"
            :aria-label="c.disponibile === false ? 'Segna come disponibile' : 'Segna come terminato'"
            class="toggle-switch" :class="{ attivo: c.disponibile !== false, salvando: salvandoDisponibile === c.id }">
            <span class="toggle-switch-track">
              <span class="toggle-switch-knob"><Spinner v-if="salvandoDisponibile === c.id" /></span>
            </span>
          </button>
          <button @click.stop="avviaElimina(c)" aria-label="Elimina concime" class="feed__del">×</button>
        </div>
      </div>

      <div v-else-if="concimi.length" class="empty">
        <Icon name="cerca" />
        <p><b>Nessun concime trovato</b>Prova a cambiare la ricerca</p>
      </div>

      <div v-else class="empty">
        <Icon name="concimazione" />
        <p><b>Nessun concime ancora</b>Aggiungi i concimi che possiedi per ricevere suggerimenti quando una pianta ha bisogno di concimazione</p>
        <button type="button" @click="apriNuovo" class="pill pill--cta" style="margin-top:14px;">＋ Aggiungi un concime</button>
      </div>
    </template>

    <!-- Foglio nuovo/modifica -->
    <FoglioLaterale
      :model-value="mostraForm"
      @update:model-value="v => { if (!v) chiudiForm() }"
      :titolo="modificaId ? 'Modifica concime' : 'Nuovo concime'"
    >
      <div v-if="mostraForm" class="foglio-form">
        <template v-if="modificaId && abbinamentiPerConcime[modificaId]">
          <template v-if="abbinamentiPerConcime[modificaId].migliori.length">
            <label class="field-label">Scelta migliore per</label>
            <div class="concime-match-list">
              <span v-for="nome in abbinamentiPerConcime[modificaId].migliori" :key="nome" class="badge badge-ok concime-match-chip">{{ nome }}</span>
            </div>
          </template>
          <template v-if="abbinamentiPerConcime[modificaId].altri.length">
            <label class="field-label">Adatto anche per</label>
            <div class="concime-match-list">
              <span v-for="nome in abbinamentiPerConcime[modificaId].altri" :key="nome" class="badge concime-match-chip concime-match-chip--secondario">{{ nome }}</span>
            </div>
          </template>
        </template>
        <input v-model="form.nome" placeholder="Nome *" class="form-input" style="margin-bottom:10px;">
        <label class="field-label">NPK</label>
        <div style="display:flex;gap:8px;margin-bottom:16px;">
          <input v-model.number="form.n" type="number" min="0" placeholder="N" class="form-input" style="text-align:center;">
          <input v-model.number="form.p" type="number" min="0" placeholder="P" class="form-input" style="text-align:center;">
          <input v-model.number="form.k" type="number" min="0" placeholder="K" class="form-input" style="text-align:center;">
        </div>
        <label class="field-label">Descrizione (opzionale)</label>
        <textarea v-model="form.descrizione" placeholder="Preparazione, dosi, tempo di macerazione…"
          rows="3" class="form-input" style="resize:vertical;font-family:inherit;margin-bottom:16px;"></textarea>
        <div style="display:flex;align-items:center;justify-content:space-between;gap:8px;">
          <span style="font-size:13px;color:var(--ink-mid);">Disponibile in dispensa</span>
          <button type="button" @click="form.disponibile = !form.disponibile"
            class="toggle-switch" :class="{ attivo: form.disponibile }"
            :aria-label="form.disponibile ? 'Segna come terminato' : 'Segna come disponibile'">
            <span class="toggle-switch-track">
              <span class="toggle-switch-knob"></span>
            </span>
          </button>
        </div>
        <p v-if="erroreSalvataggio" style="font-size:12px;color:var(--rose-ink);margin:-6px 0 10px;">{{ erroreSalvataggio }}</p>
        <div class="foglio-actions">
          <button class="btn btn-ghost" @click="chiudiForm">Annulla</button>
          <button class="btn btn-sage" @click="salva" :disabled="!form.nome.trim() || salvando">
            <Spinner v-if="salvando" /><span v-else>Salva</span>
          </button>
        </div>
      </div>
    </FoglioLaterale>

    <ModalConferma
      :aperto="daEliminare !== null"
      titolo="Eliminare questo concime?"
      messaggio="Questa azione non può essere annullata."
      :caricamento="eliminando"
      :errore="erroreEliminazione"
      @conferma="eliminaConcime"
      @annulla="daEliminare = null; erroreEliminazione = null"
    />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'
import { formattaNPK, classificaConcimiPerFabbisogno, SOGLIA_DISTANZA } from '@/composables/useConcimi'
import { stagione } from '@/composables/useCure'
import ModalConferma from '@/components/ModalConferma.vue'
import FoglioLaterale from '@/components/FoglioLaterale.vue'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const store = useDatiStore()
const supabase = useSupabase()

const mostraForm = ref(false)
const modificaId  = ref(null)
const salvando    = ref(false)
const salvandoDisponibile = ref(null)
const form = ref({ nome: '', n: null, p: null, k: null, descrizione: '', disponibile: true })

const daEliminare = ref(null)
const eliminando  = ref(false)
const erroreEliminazione = ref(null)
const erroreSalvataggio  = ref(null)
const erroriDisponibile  = ref({})
const cerca = ref('')

const concimi = computed(() => {
  if (!store.concimi) return []
  return Object.entries(store.concimi)
    .map(([id, c]) => ({ id, ...c }))
    .sort((a, b) => (a.nome ?? '').localeCompare(b.nome ?? ''))
})

const concimiFiltrati = computed(() => {
  if (!cerca.value.trim()) return concimi.value
  const q = cerca.value.trim().toLowerCase()
  return concimi.value.filter(c => (c.nome ?? '').toLowerCase().includes(q) || (c.descrizione ?? '').toLowerCase().includes(q))
})

// Per ogni concime, le specie per cui è oggi un abbinamento NPK entro soglia
// (classifica completa di useConcimi.js, non solo il vincitore: un concime
// può essere utile anche da secondo/terzo scelto, come già mostra "Concimi
// consigliati" in PiantaView.vue — vedi critica del 07/09/2026). "migliori"
// = rango 0 per quella pianta, "altri" = rango successivo ma comunque entro
// soglia; nessun tetto fisso sul numero di piante, è la soglia a limitare la
// lista. Esclude i concimi "terminato": altrimenti un prodotto esaurito
// potrebbe comparire come abbinamento nella stessa riga che lo etichetta
// terminato.
const abbinamentiPerConcime = computed(() => {
  const mappa = {}
  if (!store.piante || !store.specie || !store.concimi) return mappa
  const concimiDisponibili = Object.fromEntries(
    Object.entries(store.concimi).filter(([, c]) => c.disponibile !== false)
  )
  const s = stagione()
  for (const pianta of Object.values(store.piante)) {
    const specie = store.specie[pianta.specie]
    const fabbisogno = specie?.manutenzione?.npk?.[s]
    if (!fabbisogno) continue
    const classifica = classificaConcimiPerFabbisogno(fabbisogno, concimiDisponibili)
      .filter(c => c.distanza <= SOGLIA_DISTANZA)
    if (!classifica.length) continue
    const nome = specie?.nome ?? pianta.specie
    classifica.forEach((c, rango) => {
      const voce = mappa[c.id] ?? (mappa[c.id] = { migliori: [], altri: [] })
      const gruppo = rango === 0 ? voce.migliori : voce.altri
      if (!gruppo.includes(nome)) gruppo.push(nome)
    })
  }
  return mappa
})

// Elenco troncato ("A, B, C +2 altre") invece del join intero: una lista di
// piante abbinate senza limite può allungare una riga ben oltre le vicine
// (vedi critica del 07/09/2026). In riga niente distinzione di rango — è già
// un riepilogo troncato, non la superficie autorevole; quella vive nel
// Foglio (vedi "Scelta migliore per"/"Adatto anche per" più sotto).
function elencoAbbinati(id) {
  const voce = abbinamentiPerConcime.value[id]
  if (!voce) return null
  const lista = [...voce.migliori, ...voce.altri]
  if (!lista.length) return null
  if (lista.length <= 3) return lista.join(', ')
  return `${lista.slice(0, 3).join(', ')} +${lista.length - 3} altre`
}

function apriNuovo() {
  modificaId.value = null
  form.value = { nome: '', n: null, p: null, k: null, descrizione: '', disponibile: true }
  erroreSalvataggio.value = null
  mostraForm.value = true
}

function apriModifica(c) {
  modificaId.value = c.id
  form.value = { nome: c.nome, n: c.npk.n, p: c.npk.p, k: c.npk.k, descrizione: c.descrizione ?? '', disponibile: c.disponibile !== false }
  erroreSalvataggio.value = null
  mostraForm.value = true
}

function chiudiForm() {
  mostraForm.value = false
}

async function salva() {
  const nome = form.value.nome.trim()
  if (!nome || salvando.value) return
  salvando.value = true
  erroreSalvataggio.value = null
  // Un negativo incollato o un valore non numerico non deve arrivare a
  // Supabase as-is: min="0" sull'input è solo un suggerimento della spinner,
  // non un vincolo (vedi critica del 07/09/2026).
  const npkONull = v => {
    if (v === '' || v === null || v === undefined) return null
    const n = Number(v)
    return Number.isFinite(n) ? Math.max(0, n) : null
  }
  const riga = {
    nome,
    npk: { n: npkONull(form.value.n), p: npkONull(form.value.p), k: npkONull(form.value.k) },
    descrizione: form.value.descrizione.trim() || null,
    disponibile: form.value.disponibile,
  }
  try {
    let id = modificaId.value
    if (id) {
      const { error } = await supabase.from('concimi').update(riga).eq('id', id)
      if (error) throw error
    } else {
      const { data, error } = await supabase.from('concimi').insert(riga).select().single()
      if (error) throw error
      id = data.id
    }
    store.concimi = { ...store.concimi, [id]: riga }
    mostraForm.value = false
  } catch {
    erroreSalvataggio.value = 'Non sono riuscito a salvare il concime. Riprova.'
  } finally {
    salvando.value = false
  }
}

async function toggleDisponibile(c) {
  if (salvandoDisponibile.value) return
  salvandoDisponibile.value = c.id
  delete erroriDisponibile.value[c.id]
  const disponibile = c.disponibile === false
  try {
    const { error } = await supabase.from('concimi').update({ disponibile }).eq('id', c.id)
    if (error) throw error
    store.concimi = { ...store.concimi, [c.id]: { ...store.concimi[c.id], disponibile } }
  } catch {
    erroriDisponibile.value[c.id] = `Non sono riuscito ad aggiornare "${c.nome}". Riprova.`
  } finally {
    salvandoDisponibile.value = null
  }
}

function avviaElimina(c) {
  daEliminare.value = c.id
}

async function eliminaConcime() {
  if (!daEliminare.value) return
  eliminando.value = true
  erroreEliminazione.value = null
  const id = daEliminare.value
  try {
    const { error } = await supabase.from('concimi').delete().eq('id', id)
    if (error) throw error
    const nuovi = { ...store.concimi }
    delete nuovi[id]
    store.concimi = nuovi
    daEliminare.value = null
  } catch {
    erroreEliminazione.value = 'Non sono riuscito a eliminare il concime. Riprova.'
  } finally {
    eliminando.value = false
  }
}
</script>

<style scoped>
/* Riga concime: tap sull'intera riga apre il foglio di modifica.
   Override parent-qualificato: non ridefinisce la .feed globale,
   aggiunge solo il cursore per la riga interattiva. */
.feedlist .feed--tap { cursor: pointer; }

/* Regola del Nome in Fraunces (DESIGN.md): il nome del concime è un nome
   di prodotto come qualunque altro nome nell'app, non testo di servizio. */
.feedlist .feed__n { font-family: var(--font-display); font-weight: 600; }

/* NPK e abbinamento pianta su una riga propria sotto il nome (come .pr__zona
   in PiantaRiga.vue), invece che come colonna flex:none a fianco: libera
   spazio per il nome sul chrome fisso della riga (toggle+elimina) — vedi
   critica del 07/09/2026. */
.feedlist .feed__meta { display: flex; align-items: center; gap: 8px; margin-top: 2px; flex-wrap: wrap; }
.feedlist .feed__npk { flex: none; }
.feedlist .feed__match { font: 500 11px/1.35 var(--font-sans); color: var(--sage-dark); }
.feedlist .feed__err { font: 500 11px/1.35 var(--font-sans); color: var(--rose-ink); margin-top: 2px; }

/* Elenco completo delle piante abbinate, in cima al foglio di modifica: la
   riga mostra solo i primi 3 nomi ("+N altre"), qui il dato calcolato in
   abbinamentiPerConcime torna leggibile per intero — niente tooltip (mani
   sporche/bagnate in giardino), niente secondo elemento interattivo
   annidato nella riga già role="button" (vedi critica del 07/09/2026).
   Due gruppi, non un'unica lista piatta: un concime di rango 2/3 non è la
   stessa cosa del migliore abbinamento, e trattarli allo stesso modo
   sovrastimerebbe il match secondario (vedi critica del 07/09/2026). */
.concime-match-list { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 16px; }
.concime-match-chip { font-family: var(--font-display); font-weight: 600; }
.concime-match-chip--secondario {
  background: none;
  border: 1px solid var(--cream-dark);
  color: var(--ink-mid);
}

/* Descrizione su massimo 2 righe: il textarea invita esplicitamente a testi
   articolati ("dosi, tempo di macerazione…"), che altrimenti allungherebbero
   una riga ben oltre le vicine, rompendo il ritmo a filetti della lista. */
.feedlist .feed__d {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Svuota la ricerca in un tocco, stesso pattern di PianteView.vue. */
.search-clear {
  position: absolute; right: 0; top: 0; width: 44px; height: 44px;
  display: flex; align-items: center; justify-content: center;
  border: none; background: transparent; color: var(--ink-faint);
  font-size: 18px; line-height: 1; cursor: pointer;
}

/* CTA "+ Aggiungi": la pillola-filtro condivisa (.pill) è alta 36px, sotto
   il minimo di 44px dell'app; qui è l'unica azione per aggiungere un
   concime, non un filtro, quindi riceve la sua altezza di tocco corretta
   senza toccare .pill globale (riusata altrove come filtro). */
.pill--cta { min-height: 44px; }

/* Bottone elimina: 44px come ogni altro bersaglio di tocco dell'app (era
   ~28px, un rischio concreto di tocco-sbagliato accanto all'interruttore
   in uso mobile/in giardino — vedi critica del 07/09/2026). Il filetto
   verticale separa l'area interattiva dall'azione distruttiva, stesso
   pattern di .pr__del in PiantaRiga.vue. */
.feedlist .feed__del {
  position: relative;
  flex: none;
  width: 44px;
  height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  background: none;
  border: none;
  color: var(--ink-faint);
  font-size: 20px;
  line-height: 1;
  cursor: pointer;
}
.feedlist .feed__del::before {
  content: '';
  position: absolute;
  left: -6px;
  top: 10px;
  bottom: 10px;
  width: 1px;
  background: var(--cream-dark);
}
.feedlist .feed__del:hover { color: var(--rose-dark); }

/* Area di tocco 44px come ogni altro bersaglio dell'app: il binario visibile
   resta 42×24 (.toggle-switch-track), centrato dentro un bottone trasparente
   più grande — invece di ingrandire il binario stesso, che romperebbe la
   proporzione dell'interruttore (vedi critica del 07/09/2026). */
.toggle-switch {
  position: relative;
  width: 44px; height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: none;
  cursor: pointer;
  flex-shrink: 0;
  padding: 0;
}
.toggle-switch.salvando {
  opacity: .7;
  cursor: default;
}
.toggle-switch-track {
  position: relative;
  width: 42px; height: 24px;
  border-radius: 999px;
  background: var(--cream-dark);
  padding: 3px;
  transition: background var(--motion-quick) var(--ease-standard);
}
.toggle-switch.attivo .toggle-switch-track {
  background: var(--sage);
}
.toggle-switch-knob {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 18px; height: 18px;
  border-radius: 50%;
  background: var(--white);
  box-shadow: 0 1px 3px rgba(42,34,24,0.25);
  transform: translateX(0);
  transition: transform var(--motion-quick) var(--ease-standard);
  font-size: 10px;
  color: var(--ink-faint);
}
.toggle-switch.attivo .toggle-switch-knob {
  transform: translateX(18px);
}
</style>
