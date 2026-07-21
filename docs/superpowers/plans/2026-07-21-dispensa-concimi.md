# Dispensa concimi e suggerimento NPK — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aggiungere una dispensa di concimi (nome + NPK), un fabbisogno NPK per stagione nelle specie, e un suggerimento automatico del concime più adatto visibile nella scheda Attività e nella scheda della singola pianta.

**Architecture:** Nuovo file dati `concimi.json` caricato dallo store Pinia esistente; nuova vista CRUD `ConcimiView.vue` sul modello di `ProgettiView.vue`; nuovo composable puro `useConcimi.js` (mirror di `useCure.js`) che calcola il concime più vicino per rapporto N:P:K normalizzato; il fabbisogno NPK si aggiunge alla griglia manutenzione già esistente in `EditPiantaView.vue`; il suggerimento si inserisce nei punti dove oggi si mostra lo stato della cura "concimazione" (`AttivitaRiga.vue`, `PiantaView.vue`).

**Tech Stack:** Vue 3 `<script setup>`, Pinia (`useDatiStore`), nessun framework di test nel progetto.

Spec di riferimento: `docs/superpowers/specs/2026-07-21-dispensa-concimi-design.md`

## Global Constraints

- Nessuna nuova dipendenza esterna.
- Nessun framework di test nel progetto: verifica della logica pura (`useConcimi.js`) con script Node temporanei non committati; verifica della UI con `npm run dev` manuale.
- Ogni nuova scrittura verso `saveJSON` usa il pattern updater `(correnti) => nuovoContenuto`, mai un oggetto fisso — beneficia del retry automatico su conflitto SHA già presente in `useApi.js`.
- Formato NPK: stringa `"N-P-K"` in `specie.json` (`manutenzione.npk[stagione]`), oggetto `{ n, p, k }` in `concimi.json`.
- Confronto tra rapporti N:P:K **normalizzati** (proporzioni sommate a 1), non valori assoluti.
- `SOGLIA_DISTANZA = 0.15`: oltre questa distanza euclidea tra rapporti normalizzati, nessun concime viene suggerito.
- Stile inline esistente (attributo `style` diretto), pattern esistenti per form (`Teleport`/`overlay`/`modal-box` come in `ProgettiView.vue`/`EditPiantaView.vue`) ed eliminazioni (`ModalConferma.vue`).

---

## File Structure

- **Create** `src/composables/useConcimi.js` — logica pura di parsing e matching NPK.
- **Create** `public/data/concimi.json` — dispensa iniziale vuota (`{}`).
- **Modify** `src/stores/dati.js` — carica `concimi.json`.
- **Create** `src/views/ConcimiView.vue` — lista + form aggiungi/modifica + eliminazione.
- **Modify** `src/router/index.js` — route `/concimi`.
- **Modify** `src/components/NavBar.vue` — voce di navigazione.
- **Modify** `src/views/EditPiantaView.vue` — riga NPK nella griglia manutenzione (creazione specie).
- **Modify** `src/views/AttivitaView.vue` — calcolo del suggerimento per le righe di concimazione.
- **Modify** `src/components/AttivitaRiga.vue` — visualizzazione del suggerimento.
- **Modify** `src/views/PiantaView.vue` — visualizzazione del suggerimento (o messaggio "nessun concime adatto").

---

### Task 1: Composable `useConcimi.js`

**Files:**
- Create: `src/composables/useConcimi.js`
- Test: script Node temporaneo in `/private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/46a90c20-7a94-411b-9167-3358fb94d4b8/scratchpad/verifica-concimi.mjs` (non committato, cancellato a fine task)

**Interfaces:**
- Produces: `concimeConsigliato(npkRichiestoTesto: string|null, concimi: Record<string, {nome: string, npk: {n,p,k}}>|null) => {id, nome, npk, distanza} | null`. Usata da `AttivitaView.vue` (Task 4) e `PiantaView.vue` (Task 5).

- [ ] **Step 1: Scrivi lo script di verifica (prima dell'implementazione)**

Crea `/private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/46a90c20-7a94-411b-9167-3358fb94d4b8/scratchpad/verifica-concimi.mjs`:

```js
import assert from 'node:assert/strict'
import { concimeConsigliato } from '/Users/rob/Sites/localhost/giardino/src/composables/useConcimi.js'

// Stesso rapporto (10:5:5 == 20:10:10), concentrazione diversa: distanza 0, match trovato
const concimiVicini = {
  azotato: { nome: 'Azotato', npk: { n: 20, p: 10, k: 10 } },
  fosforato: { nome: 'Fosforato', npk: { n: 5, p: 20, k: 5 } },
}
const risultato1 = concimeConsigliato('10-5-5', concimiVicini)
assert.ok(risultato1, 'deve trovare un match quando esiste un concime con lo stesso rapporto')
assert.equal(risultato1.id, 'azotato', 'deve scegliere il concime più vicino per rapporto, non il primo della lista')
assert.ok(risultato1.distanza < 0.01, 'lo stesso rapporto normalizzato deve dare distanza ~0')

// Solo il concime lontano è disponibile: nessun match sotto soglia 0.15
const risultato2 = concimeConsigliato('10-5-5', { fosforato: concimiVicini.fosforato })
assert.equal(risultato2, null, 'un concime con rapporto molto diverso non deve essere suggerito')

// Dispensa vuota
assert.equal(concimeConsigliato('10-5-5', {}), null, 'dispensa vuota => nessun suggerimento')
assert.equal(concimeConsigliato('10-5-5', null), null, 'dispensa null => nessun suggerimento')

// Nessun fabbisogno per la stagione
assert.equal(concimeConsigliato(null, concimiVicini), null, 'fabbisogno assente => nessun suggerimento')
assert.equal(concimeConsigliato('', concimiVicini), null, 'fabbisogno vuoto => nessun suggerimento')

// Formato non valido
assert.equal(concimeConsigliato('non-un-npk', concimiVicini), null, 'testo non valido => nessun suggerimento')

// Concime senza npk nella dispensa: ignorato, non deve far crashare la funzione
const conVoceIncompleta = { ...concimiVicini, incompleto: { nome: 'Senza NPK' } }
const risultato3 = concimeConsigliato('10-5-5', conVoceIncompleta)
assert.equal(risultato3.id, 'azotato', 'una voce senza npk viene ignorata, non causa errori')

console.log('OK: tutte le assert passate')
```

- [ ] **Step 2: Esegui lo script e verifica che fallisca**

Run: `node /private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/46a90c20-7a94-411b-9167-3358fb94d4b8/scratchpad/verifica-concimi.mjs`
Expected: errore di import — `Cannot find module '/Users/rob/Sites/localhost/giardino/src/composables/useConcimi.js'` (il file non esiste ancora)

- [ ] **Step 3: Crea l'implementazione**

Crea `src/composables/useConcimi.js`:

```js
// Suggerimento del concime più adatto in base al rapporto N:P:K

function parseNPK(testo) {
  if (!testo) return null
  const m = testo.match(/^(\d+(?:\.\d+)?)-(\d+(?:\.\d+)?)-(\d+(?:\.\d+)?)$/)
  if (!m) return null
  return { n: parseFloat(m[1]), p: parseFloat(m[2]), k: parseFloat(m[3]) }
}

function normalizza({ n, p, k }) {
  const somma = n + p + k
  if (somma === 0) return { n: 0, p: 0, k: 0 }
  return { n: n / somma, p: p / somma, k: k / somma }
}

function distanza(a, b) {
  const na = normalizza(a), nb = normalizza(b)
  return Math.sqrt((na.n - nb.n) ** 2 + (na.p - nb.p) ** 2 + (na.k - nb.k) ** 2)
}

const SOGLIA_DISTANZA = 0.15

export function concimeConsigliato(npkRichiestoTesto, concimi) {
  const richiesto = parseNPK(npkRichiestoTesto)
  if (!richiesto || !concimi || !Object.keys(concimi).length) return null

  let migliore = null
  for (const [id, c] of Object.entries(concimi)) {
    if (!c.npk) continue
    const d = distanza(richiesto, c.npk)
    if (!migliore || d < migliore.distanza) migliore = { id, ...c, distanza: d }
  }
  if (!migliore || migliore.distanza > SOGLIA_DISTANZA) return null
  return migliore
}
```

- [ ] **Step 4: Esegui lo script e verifica che passi**

Run: `node /private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/46a90c20-7a94-411b-9167-3358fb94d4b8/scratchpad/verifica-concimi.mjs`
Expected: `OK: tutte le assert passate`

- [ ] **Step 5: Elimina lo script di verifica temporaneo**

Run: `rm /private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/46a90c20-7a94-411b-9167-3358fb94d4b8/scratchpad/verifica-concimi.mjs`

- [ ] **Step 6: Commit**

```bash
git add src/composables/useConcimi.js
git commit -m "Aggiunge composable per il suggerimento del concime per rapporto NPK"
```

---

### Task 2: Dispensa concimi (dati + vista CRUD)

**Files:**
- Create: `public/data/concimi.json`
- Modify: `src/stores/dati.js`
- Create: `src/views/ConcimiView.vue`
- Modify: `src/router/index.js`
- Modify: `src/components/NavBar.vue`
- Test: verifica manuale (nessun framework di test nel progetto)

**Interfaces:**
- Consumes: nessuno da task precedenti (Task 1 non è ancora usato qui — il suggerimento entra in gioco nei Task 4-5).
- Produces: `store.concimi` (oggetto `{id: {nome, npk: {n,p,k}}}`, caricato da `dati.js`), route `/concimi`. Usati da `AttivitaView.vue` (Task 4) e `PiantaView.vue` (Task 5) per leggere `store.concimi`.

- [ ] **Step 1: Crea il file dati iniziale**

Crea `public/data/concimi.json`:

```json
{}
```

- [ ] **Step 2: Aggiungi `concimi` allo store**

In `src/stores/dati.js`, sostituisci:

```js
export const useDatiStore = defineStore('dati', () => {
  const piante    = ref(null)
  const specie    = ref(null)
  const zone      = ref(null)
  const sottozone = ref(null)
  const progetti  = ref(null)
  const settings  = ref(null)
  const loading   = ref(false)
  const errore    = ref(null)

  async function caricaTutto() {
    if (piante.value) return  // già caricati
    loading.value = true
    errore.value = null
    try {
      ;[piante.value, specie.value, zone.value, sottozone.value, progetti.value, settings.value] =
        await Promise.all([
          caricaJSON('piante.json'),
          caricaJSON('specie.json'),
          caricaJSON('zone.json'),
          caricaJSON('sottozone.json'),
          caricaJSON('progetti.json'),
          caricaJSON('settings.json'),
        ])
    } catch (e) {
      errore.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function aggiorna() {
    piante.value = null
    await caricaTutto()
  }

  return { piante, specie, zone, sottozone, progetti, settings, loading, errore, caricaTutto, aggiorna }
})
```

con:

```js
export const useDatiStore = defineStore('dati', () => {
  const piante    = ref(null)
  const specie    = ref(null)
  const zone      = ref(null)
  const sottozone = ref(null)
  const progetti  = ref(null)
  const settings  = ref(null)
  const concimi   = ref(null)
  const loading   = ref(false)
  const errore    = ref(null)

  async function caricaTutto() {
    if (piante.value) return  // già caricati
    loading.value = true
    errore.value = null
    try {
      ;[piante.value, specie.value, zone.value, sottozone.value, progetti.value, settings.value, concimi.value] =
        await Promise.all([
          caricaJSON('piante.json'),
          caricaJSON('specie.json'),
          caricaJSON('zone.json'),
          caricaJSON('sottozone.json'),
          caricaJSON('progetti.json'),
          caricaJSON('settings.json'),
          caricaJSON('concimi.json'),
        ])
    } catch (e) {
      errore.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function aggiorna() {
    piante.value = null
    await caricaTutto()
  }

  return { piante, specie, zone, sottozone, progetti, settings, concimi, loading, errore, caricaTutto, aggiorna }
})
```

- [ ] **Step 3: Crea `ConcimiView.vue`**

Crea `src/views/ConcimiView.vue`:

```vue
<template>
  <div>
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;">
      <h1 class="title-display gradient-title" style="font-size:1.9rem;font-weight:800;">Concimi</h1>
      <button @click="apriNuovo" class="btn btn-rose" style="padding:8px 16px;">＋ Aggiungi</button>
    </div>

    <!-- Skeleton -->
    <div v-if="store.loading" style="display:flex;flex-direction:column;gap:10px;">
      <div v-for="i in 3" :key="i" class="card" style="padding:16px;">
        <div class="skeleton" style="height:16px;width:50%;margin-bottom:8px;"></div>
        <div class="skeleton" style="height:11px;width:30%;"></div>
      </div>
    </div>

    <template v-else>
      <div v-if="concimi.length" style="display:flex;flex-direction:column;gap:10px;">
        <div v-for="c in concimi" :key="c.id" class="card hover-card"
          style="padding:16px;display:flex;align-items:center;justify-content:space-between;gap:12px;cursor:pointer;"
          @click="apriModifica(c)">
          <div style="flex:1;min-width:0;">
            <h3 class="title-serif" style="font-size:15px;font-weight:600;margin-bottom:4px;">{{ c.nome }}</h3>
            <span class="badge" style="background:var(--sage-pale);color:var(--sage-dark);">{{ c.npk.n }}-{{ c.npk.p }}-{{ c.npk.k }}</span>
          </div>
          <button @click.stop="avviaElimina(c)" aria-label="Elimina concime"
            style="background:none;border:none;color:var(--ink-faint);font-size:20px;line-height:1;cursor:pointer;flex-shrink:0;padding:4px;">×</button>
        </div>
      </div>

      <div v-else style="text-align:center;padding:60px 20px;color:var(--ink-faint);">
        <div style="font-size:48px;margin-bottom:12px;">🧪</div>
        <p class="title-serif" style="font-size:15px;color:var(--ink-soft);font-weight:600;">Nessun concime ancora</p>
        <p style="font-size:12px;margin-top:6px;">Aggiungi i concimi che possiedi per ricevere suggerimenti nelle Attività</p>
      </div>
    </template>

    <!-- Modale nuovo/modifica -->
    <Teleport to="body">
      <div v-if="mostraForm" class="overlay" @click.self="chiudiForm">
        <div class="modal-box">
          <h3 style="font-family:var(--font-serif);font-size:16px;font-weight:600;margin-bottom:16px;">
            {{ modificaId ? 'Modifica concime' : 'Nuovo concime' }}
          </h3>
          <input v-model="form.nome" placeholder="Nome *" class="form-input" style="margin-bottom:10px;">
          <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">NPK</label>
          <div style="display:flex;gap:8px;margin-bottom:16px;">
            <input v-model.number="form.n" type="number" min="0" placeholder="N" class="form-input" style="text-align:center;">
            <input v-model.number="form.p" type="number" min="0" placeholder="P" class="form-input" style="text-align:center;">
            <input v-model.number="form.k" type="number" min="0" placeholder="K" class="form-input" style="text-align:center;">
          </div>
          <div style="display:flex;gap:10px;justify-content:flex-end;">
            <button class="btn btn-ghost" @click="chiudiForm" style="min-height:40px;padding:8px 16px;">Annulla</button>
            <button class="btn btn-sage" @click="salva" :disabled="!form.nome.trim() || salvando"
              style="min-height:40px;padding:8px 16px;">
              {{ salvando ? '⏳' : 'Salva' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>

    <ModalConferma
      :aperto="daEliminare !== null"
      titolo="Eliminare questo concime?"
      messaggio="Questa azione non può essere annullata."
      :caricamento="eliminando"
      @conferma="eliminaConcime"
      @annulla="daEliminare = null"
    />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'
import ModalConferma from '@/components/ModalConferma.vue'

const store = useDatiStore()
const { saveJSON } = useApi()

const mostraForm = ref(false)
const modificaId  = ref(null)
const salvando    = ref(false)
const form = ref({ nome: '', n: null, p: null, k: null })

const daEliminare = ref(null)
const eliminando  = ref(false)

const concimi = computed(() => {
  if (!store.concimi) return []
  return Object.entries(store.concimi)
    .map(([id, c]) => ({ id, ...c }))
    .sort((a, b) => (a.nome ?? '').localeCompare(b.nome ?? ''))
})

function apriNuovo() {
  modificaId.value = null
  form.value = { nome: '', n: null, p: null, k: null }
  mostraForm.value = true
}

function apriModifica(c) {
  modificaId.value = c.id
  form.value = { nome: c.nome, n: c.npk.n, p: c.npk.p, k: c.npk.k }
  mostraForm.value = true
}

function chiudiForm() {
  mostraForm.value = false
}

async function salva() {
  const nome = form.value.nome.trim()
  if (!nome || salvando.value) return
  salvando.value = true
  const id = modificaId.value ?? `concime-${Date.now()}`
  try {
    const nuovi = await saveJSON('concimi.json', (correnti) => ({
      ...(correnti ?? store.concimi),
      [id]: {
        nome,
        npk: { n: form.value.n || 0, p: form.value.p || 0, k: form.value.k || 0 },
      }
    }))
    store.concimi = nuovi
    mostraForm.value = false
  } finally {
    salvando.value = false
  }
}

function avviaElimina(c) {
  daEliminare.value = c.id
}

async function eliminaConcime() {
  if (!daEliminare.value) return
  eliminando.value = true
  const id = daEliminare.value
  try {
    const nuovi = await saveJSON('concimi.json', (correnti) => {
      const base = { ...(correnti ?? store.concimi) }
      delete base[id]
      return base
    })
    store.concimi = nuovi
    daEliminare.value = null
  } finally {
    eliminando.value = false
  }
}
</script>

<style scoped>
.overlay {
  position: fixed; inset: 0; z-index: 200;
  background: rgba(42,34,24,0.4);
  display: flex; align-items: center; justify-content: center; padding: 16px;
}
.modal-box {
  background: var(--white); border-radius: 20px; padding: 24px;
  width: 100%; max-width: 360px;
  box-shadow: 0 20px 60px rgba(42,34,24,0.2);
}
</style>
```

Nota: non serve chiamare `store.caricaTutto()` in `onMounted` qui — `App.vue` lo fa già globalmente all'avvio (verificato in `src/App.vue:40`), stesso pattern di `ProgettiView.vue` e `ZoneView.vue`.

- [ ] **Step 4: Aggiungi la route**

In `src/router/index.js`, sostituisci:

```js
  { path: '/progetti',                  name: 'progetti',       component: () => import('@/views/ProgettiView.vue') },
  { path: '/attivita',                  name: 'attivita',       component: () => import('@/views/AttivitaView.vue') },
```

con:

```js
  { path: '/progetti',                  name: 'progetti',       component: () => import('@/views/ProgettiView.vue') },
  { path: '/concimi',                   name: 'concimi',        component: () => import('@/views/ConcimiView.vue') },
  { path: '/attivita',                  name: 'attivita',       component: () => import('@/views/AttivitaView.vue') },
```

- [ ] **Step 5: Aggiungi la voce di navigazione**

In `src/components/NavBar.vue`, sostituisci:

```js
const nav = [
  { id:'home',     to:'/',          emoji:'🐈‍⬛', label:'Home' },
  { id:'meteo',    to:'/meteo',     emoji:'⛅',   label:'Meteo' },
  { id:'zone',     to:'/zone',      emoji:'📍',   label:'Zone' },
  { id:'piante',   to:'/piante',    emoji:'🌿',   label:'Piante' },
  { id:'progetti', to:'/progetti',  emoji:'🗂️',   label:'Progetti' },
  { id:'attivita', to:'/attivita',  emoji:'🔔',   label:'Attività', badge: null },
  { id:'agente',   to:'/agente',    emoji:'🤖',   label:'Assistente' },
  { id:'gallery',  to:'/gallery',   emoji:'🖼️',   label:'Gallery' },
]
```

con:

```js
const nav = [
  { id:'home',     to:'/',          emoji:'🐈‍⬛', label:'Home' },
  { id:'meteo',    to:'/meteo',     emoji:'⛅',   label:'Meteo' },
  { id:'zone',     to:'/zone',      emoji:'📍',   label:'Zone' },
  { id:'piante',   to:'/piante',    emoji:'🌿',   label:'Piante' },
  { id:'progetti', to:'/progetti',  emoji:'🗂️',   label:'Progetti' },
  { id:'concimi',  to:'/concimi',   emoji:'🧪',   label:'Concimi' },
  { id:'attivita', to:'/attivita',  emoji:'🔔',   label:'Attività', badge: null },
  { id:'agente',   to:'/agente',    emoji:'🤖',   label:'Assistente' },
  { id:'gallery',  to:'/gallery',   emoji:'🖼️',   label:'Gallery' },
]
```

- [ ] **Step 6: Verifica manuale**

Run: `npm run build`
Expected: build senza errori.

Run: `npm run dev`

Apri `http://localhost:5173/#/concimi`. Verifica:
- La voce "Concimi" compare nella barra di navigazione in alto (desktop) e porta alla pagina.
- Stato vuoto mostrato correttamente.
- "＋ Aggiungi" apre il modale; salvare un concime (es. nome "Universale", N=10 P=10 K=10) lo fa comparire nella lista con badge "10-10-10".
- Cliccare sulla card apre il modale precompilato in modifica; cambiare un valore e salvare aggiorna la card.
- La "×" apre `ModalConferma`; confermare elimina il concime dalla lista.
- Nessun errore in console.

- [ ] **Step 7: Commit**

```bash
git add public/data/concimi.json src/stores/dati.js src/views/ConcimiView.vue src/router/index.js src/components/NavBar.vue
git commit -m "Aggiunge dispensa concimi (vista CRUD + dati)"
```

---

### Task 3: Fabbisogno NPK per specie

**Files:**
- Modify: `src/views/EditPiantaView.vue`
- Test: verifica manuale (nessun framework di test nel progetto)

**Interfaces:**
- Consumes: nessuno dai task precedenti.
- Produces: `specie.manutenzione.npk = { primavera, estate, autunno, inverno }` (stringa `"N-P-K"` o `null` per stagione) scritto in `specie.json` per le nuove specie create da questo form. Consumato da `AttivitaView.vue` (Task 4) e `PiantaView.vue` (Task 5) leggendo `specie.manutenzione?.npk?.[stagione()]`.

- [ ] **Step 1: Aggiungi la riga NPK alla griglia manutenzione nel template**

In `src/views/EditPiantaView.vue`, sostituisci (righe 106-111 del file attuale):

```html
            <div class="tipo-label">🌱 Concimazione</div>
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.primavera" placeholder="gg">
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.estate" placeholder="gg">
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.autunno" placeholder="gg">
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.inverno" placeholder="gg">
          </div>
```

con:

```html
            <div class="tipo-label">🌱 Concimazione</div>
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.primavera" placeholder="gg">
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.estate" placeholder="gg">
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.autunno" placeholder="gg">
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.inverno" placeholder="gg">

            <div class="tipo-label">🧪 NPK</div>
            <input v-model="nuovaSpecie.manutenzione.npk.primavera" placeholder="N-P-K">
            <input v-model="nuovaSpecie.manutenzione.npk.estate" placeholder="N-P-K">
            <input v-model="nuovaSpecie.manutenzione.npk.autunno" placeholder="N-P-K">
            <input v-model="nuovaSpecie.manutenzione.npk.inverno" placeholder="N-P-K">
          </div>
```

- [ ] **Step 2: Aggiungi `npk` alla struttura vuota**

In `src/views/EditPiantaView.vue`, sostituisci:

```js
function manutenzioneVuota() {
  const perStagione = () => ({ primavera: '', estate: '', autunno: '', inverno: '' })
  return { irrigazione: perStagione(), concimazione: perStagione(), potatura: perStagione() }
}
```

con:

```js
function manutenzioneVuota() {
  const perStagione = () => ({ primavera: '', estate: '', autunno: '', inverno: '' })
  return { irrigazione: perStagione(), concimazione: perStagione(), potatura: perStagione(), npk: perStagione() }
}
```

- [ ] **Step 3: Genera il campo `npk` in `generaManutenzione`**

In `src/views/EditPiantaView.vue`, sostituisci:

```js
function generaManutenzione(struttura) {
  const risultato = {}
  for (const tipo of ['irrigazione', 'concimazione']) {
    risultato[tipo] = {}
    for (const stagione of ['primavera', 'estate', 'autunno', 'inverno']) {
      const giorni = struttura?.[tipo]?.[stagione]
      risultato[tipo][stagione] = (typeof giorni === 'number' && giorni > 0) ? `ogni ${giorni} giorni` : ''
    }
  }
  risultato.potatura = {}
  for (const stagione of ['primavera', 'estate', 'autunno', 'inverno']) {
    risultato.potatura[stagione] = (struttura?.potatura?.[stagione] || '').trim()
  }
  return risultato
}
```

con:

```js
function generaManutenzione(struttura) {
  const risultato = {}
  for (const tipo of ['irrigazione', 'concimazione']) {
    risultato[tipo] = {}
    for (const stagione of ['primavera', 'estate', 'autunno', 'inverno']) {
      const giorni = struttura?.[tipo]?.[stagione]
      risultato[tipo][stagione] = (typeof giorni === 'number' && giorni > 0) ? `ogni ${giorni} giorni` : ''
    }
  }
  risultato.potatura = {}
  for (const stagione of ['primavera', 'estate', 'autunno', 'inverno']) {
    risultato.potatura[stagione] = (struttura?.potatura?.[stagione] || '').trim()
  }
  risultato.npk = {}
  for (const stagione of ['primavera', 'estate', 'autunno', 'inverno']) {
    const valore = (struttura?.npk?.[stagione] || '').trim()
    risultato.npk[stagione] = valore || null
  }
  return risultato
}
```

- [ ] **Step 4: Verifica manuale**

Run: `npm run build`
Expected: build senza errori.

Run: `npm run dev`

Apri `http://localhost:5173/#/piante/nuova`, digita un nome specie inesistente, clicca "＋ Aggiungi nuova specie", compila almeno il campo NPK primavera (es. "10-5-5") e salva. Verifica:
- Nessun errore in console.
- Se hai un modo per ispezionare il risultato scritto su GitHub (o esamini `public/data/specie.json` dopo un pull), la nuova voce ha `manutenzione.npk.primavera === "10-5-5"` e le altre stagioni `null`.

- [ ] **Step 5: Commit**

```bash
git add src/views/EditPiantaView.vue
git commit -m "Aggiunge fabbisogno NPK per stagione alla creazione di una nuova specie"
```

---

### Task 4: Suggerimento concime nella scheda Attività

**Files:**
- Modify: `src/views/AttivitaView.vue`
- Modify: `src/components/AttivitaRiga.vue`
- Test: verifica manuale (nessun framework di test nel progetto)

**Interfaces:**
- Consumes: `concimeConsigliato` da `src/composables/useConcimi.js` (Task 1); `stagione` da `src/composables/useCure.js` (già esistente, non modificato da questo piano); `store.concimi` (Task 2); `specie.manutenzione.npk[stagione]` (Task 3, dato opzionale — le specie esistenti non ce l'hanno ancora, e va gestito come assente).
- Produces: ogni oggetto `item` in `attivita`/`daFare`/`inScadenza`/`gruppiDaFare`/`gruppiInScadenza` guadagna il campo `suggerimento: {id, nome, npk, distanza} | null`. `AttivitaGruppoZona.vue` non cambia: inoltra `item` invariato a `AttivitaRiga`.

- [ ] **Step 1: Calcola il suggerimento in `AttivitaView.vue`**

In `src/views/AttivitaView.vue`, sostituisci l'import:

```js
import { valutaCura } from '@/composables/useCure'
```

con:

```js
import { valutaCura, stagione } from '@/composables/useCure'
import { concimeConsigliato } from '@/composables/useConcimi'
```

- [ ] **Step 2: Aggiungi il campo `suggerimento` agli item**

In `src/views/AttivitaView.vue`, sostituisci:

```js
const attivita = computed(() => {
  if (!store.piante) return []
  const items = []
  for (const [id, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie] ?? null
    const nomeSpecie = sp?.nome ?? p.specie
    for (const tipo of ['irrigazione', 'concimazione', 'potatura']) {
      const c = valutaCura(p, sp, tipo)
      if (c.giorni !== null) {
        items.push({ key: `${id}-${tipo}`, piantaId: id, tipo, nomeSpecie, label: c.label, giorni: c.giorni, urgente: c.urgente })
      }
    }
  }
  return items
})
```

con:

```js
const attivita = computed(() => {
  if (!store.piante) return []
  const stagioneCorrente = stagione()
  const items = []
  for (const [id, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie] ?? null
    const nomeSpecie = sp?.nome ?? p.specie
    for (const tipo of ['irrigazione', 'concimazione', 'potatura']) {
      const c = valutaCura(p, sp, tipo)
      if (c.giorni !== null) {
        const suggerimento = tipo === 'concimazione'
          ? concimeConsigliato(sp?.manutenzione?.npk?.[stagioneCorrente], store.concimi)
          : null
        items.push({ key: `${id}-${tipo}`, piantaId: id, tipo, nomeSpecie, label: c.label, giorni: c.giorni, urgente: c.urgente, suggerimento })
      }
    }
  }
  return items
})
```

- [ ] **Step 3: Mostra il suggerimento in `AttivitaRiga.vue`**

In `src/components/AttivitaRiga.vue`, sostituisci:

```html
    <div style="flex:1;min-width:0;">
      <div class="title-serif" style="font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
        {{ item.nomeSpecie }}
      </div>
      <div :style="labelStyle">{{ item.label }}</div>
    </div>
```

con:

```html
    <div style="flex:1;min-width:0;">
      <div class="title-serif" style="font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
        {{ item.nomeSpecie }}
      </div>
      <div :style="labelStyle">{{ item.label }}</div>
      <div v-if="item.tipo === 'concimazione' && item.suggerimento" style="font-size:11px;color:var(--sage-dark);margin-top:2px;">
        🌱 Consigliato: {{ item.suggerimento.nome }} ({{ item.suggerimento.npk.n }}-{{ item.suggerimento.npk.p }}-{{ item.suggerimento.npk.k }})
      </div>
    </div>
```

- [ ] **Step 4: Verifica manuale**

Run: `npm run build`
Expected: build senza errori.

Run: `npm run dev`

Per vedere un suggerimento reale hai bisogno di: una specie con `manutenzione.npk` per la stagione corrente (creane una di prova come nel Task 3, o modifica temporaneamente `public/data/specie.json` in locale senza committare), una pianta di quella specie con una cura di concimazione urgente/in scadenza (modifica temporaneamente `ultima_cura.concimazione` a una data vecchia), e almeno un concime in `/concimi` (Task 2) con rapporto NPK abbastanza vicino (entro soglia 0.15).

Apri `http://localhost:5173/#/attivita`. Verifica:
- La riga di concimazione della pianta di prova mostra "🌱 Consigliato: ... (N-P-K)" sotto la label esistente.
- Le righe di irrigazione/potatura non mostrano mai questa riga extra.
- Se rimuovi tutti i concimi dalla dispensa, la riga suggerimento sparisce (nessun errore).
- Ripristina eventuali modifiche locali a `public/data/*.json` con `git checkout -- public/data/` prima di committare.

- [ ] **Step 5: Commit**

```bash
git add src/views/AttivitaView.vue src/components/AttivitaRiga.vue
git commit -m "Mostra il concime consigliato nelle righe di concimazione in Attività"
```

---

### Task 5: Suggerimento concime nella scheda pianta

**Files:**
- Modify: `src/views/PiantaView.vue`
- Test: verifica manuale (nessun framework di test nel progetto)

**Interfaces:**
- Consumes: `concimeConsigliato` da `src/composables/useConcimi.js` (Task 1); `stagione` da `src/composables/useCure.js`; `store.concimi` (Task 2); `specie.manutenzione.npk[stagione]` (Task 3).
- Produces: nessuna interfaccia consumata da altri task (ultimo task del piano).

- [ ] **Step 1: Importa `stagione` e `concimeConsigliato`**

In `src/views/PiantaView.vue`, sostituisci:

```js
import { valutaCura, cureUrgentiPianta } from '@/composables/useCure'
```

con:

```js
import { valutaCura, cureUrgentiPianta, stagione } from '@/composables/useCure'
import { concimeConsigliato } from '@/composables/useConcimi'
```

- [ ] **Step 2: Aggiungi i computed del suggerimento**

In `src/views/PiantaView.vue`, subito dopo la definizione di `cureUrgenti` (dopo la riga che chiude `const cureUrgenti = computed(...)`), aggiungi:

```js
const fabbisognoNpk = computed(() => specie.value?.manutenzione?.npk?.[stagione()] ?? null)
const suggerimentoConcime = computed(() =>
  fabbisognoNpk.value ? concimeConsigliato(fabbisognoNpk.value, store.concimi) : null
)
```

- [ ] **Step 3: Mostra il suggerimento (o l'assenza di match) nel template**

In `src/views/PiantaView.vue`, sostituisci:

```html
          <div v-for="tipo in ['irrigazione','concimazione','potatura']" :key="tipo"
            style="display:flex;align-items:center;justify-content:space-between;">
            <div>
              <div style="font-size:13px;font-weight:500;text-transform:capitalize;">{{ tipo }}</div>
              <div style="font-size:11px;color:var(--ink-soft);margin-top:2px;">
                {{ valutaCura(pianta, specie, tipo).label ?? 'Non configurata' }}
              </div>
            </div>
            <button @click="registraCura(tipo)" :disabled="salvando === tipo" class="btn btn-sage"
              style="font-size:11px;padding:4px 10px;min-height:28px;">
              {{ salvando === tipo ? '⏳' : '✓ Fatto' }}
            </button>
          </div>
```

con:

```html
          <div v-for="tipo in ['irrigazione','concimazione','potatura']" :key="tipo"
            style="display:flex;align-items:center;justify-content:space-between;">
            <div>
              <div style="font-size:13px;font-weight:500;text-transform:capitalize;">{{ tipo }}</div>
              <div style="font-size:11px;color:var(--ink-soft);margin-top:2px;">
                {{ valutaCura(pianta, specie, tipo).label ?? 'Non configurata' }}
              </div>
              <div v-if="tipo === 'concimazione' && fabbisognoNpk && suggerimentoConcime" style="font-size:11px;color:var(--sage-dark);margin-top:2px;">
                🌱 Consigliato: {{ suggerimentoConcime.nome }} ({{ suggerimentoConcime.npk.n }}-{{ suggerimentoConcime.npk.p }}-{{ suggerimentoConcime.npk.k }})
              </div>
              <div v-else-if="tipo === 'concimazione' && fabbisognoNpk && !suggerimentoConcime" style="font-size:11px;color:var(--ink-faint);margin-top:2px;">
                Nessun concime adatto in dispensa
              </div>
            </div>
            <button @click="registraCura(tipo)" :disabled="salvando === tipo" class="btn btn-sage"
              style="font-size:11px;padding:4px 10px;min-height:28px;">
              {{ salvando === tipo ? '⏳' : '✓ Fatto' }}
            </button>
          </div>
```

- [ ] **Step 4: Verifica manuale**

Run: `npm run build`
Expected: build senza errori.

Run: `npm run dev`

Apri la scheda di una pianta la cui specie ha `manutenzione.npk` per la stagione corrente (usa quella creata nei Task 3-4, o modifica temporaneamente `specie.json` in locale senza committare). Verifica tre casi:
1. Con un concime adeguato in dispensa → riga "🌱 Consigliato: ...".
2. Con dispensa vuota o solo concimi troppo lontani (soglia 0.15) → riga "Nessun concime adatto in dispensa".
3. Con una specie senza `manutenzione.npk` per la stagione corrente → nessuna riga aggiuntiva, solo lo stato cura esistente.

Ripristina eventuali modifiche locali a `public/data/*.json` con `git checkout -- public/data/` prima di committare.

- [ ] **Step 5: Commit**

```bash
git add src/views/PiantaView.vue
git commit -m "Mostra il concime consigliato (o l'assenza di match) nella scheda pianta"
```

---

## Self-Review

**Copertura spec:**
- Modello dati (`concimi.json`, `specie.manutenzione.npk`) → Task 1 (interfaccia consumata), Task 2 (file dati), Task 3 (scrittura). ✓
- Logica di suggerimento basata sul rapporto N:P:K normalizzato con soglia 0.15 → Task 1, verificata con script Node prima dell'integrazione UI. ✓
- Dispensa concimi gestibile da UI (nome + NPK, aggiungi/modifica/elimina) → Task 2. ✓
- Fabbisogno NPK per specie editabile da UI (creazione specie) → Task 3. ✓
- Suggerimento visibile in Attività → Task 4. ✓
- Suggerimento visibile nella scheda pianta, incluso il messaggio "nessun concime adatto" → Task 5. ✓
- Store/caricamento dati → Task 2. ✓
- Navigazione (`NavBar`, non `BottomNav`) → Task 2. ✓

**Placeholder scan:** nessun TBD/TODO; ogni step ha codice completo o comando+output atteso espliciti.

**Coerenza tipi/nomi:** `concimeConsigliato(npkRichiestoTesto, concimi)` (Task 1) usato identicamente in Task 4 (`concimeConsigliato(sp?.manutenzione?.npk?.[stagioneCorrente], store.concimi)`) e Task 5 (`concimeConsigliato(fabbisognoNpk.value, store.concimi)`). Struttura del risultato `{id, nome, npk: {n,p,k}, distanza}` usata coerentemente in `AttivitaRiga.vue` (`item.suggerimento.npk.n/p/k`) e `PiantaView.vue` (`suggerimentoConcime.npk.n/p/k`). Il campo `item.suggerimento` introdotto in Task 4 attraversa `AttivitaGruppoZona.vue` senza modifiche a quel file, perché il componente inoltra l'intero oggetto `item` (verificato leggendo `src/components/AttivitaGruppoZona.vue` esistente: passa `:item="item"` a `AttivitaRiga` senza destrutturare i campi). `specie.manutenzione.npk[stagione]` scritto in Task 3 con lo stesso formato (`"N-P-K"` stringa o `null`) letto in Task 4 e Task 5.

**Nota su copertura dati esistenti:** le ~80 specie già presenti in `specie.json` non hanno `manutenzione.npk` e non ottengono un'interfaccia di modifica in questo piano (`EditPiantaView.vue` gestisce solo la creazione di nuove specie — non esiste nel progetto una vista "modifica specie" per quelle esistenti, coerente con lo stato attuale del repository). Per aggiungere il fabbisogno NPK a una specie già esistente serve modificare `specie.json` direttamente (stesso meccanismo già usato in passato per altri campi), fuori dallo scope di questo piano/spec.
