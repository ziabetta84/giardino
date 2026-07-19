# Azione bulk per zona in Attività — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Raggruppare le attività (irrigazione/concimazione/potatura) per zona+sottozona in `AttivitaView.vue`, con un pulsante che marca come fatte tutte le attività di un gruppo in un'unica scrittura.

**Architecture:** Estrarre la riga singola (`AttivitaRiga.vue`) e il gruppo-zona (`AttivitaGruppoZona.vue`) come componenti presentazionali; `AttivitaView.vue` resta l'orchestratore con una funzione pura di raggruppamento (`src/utils/raggruppaAttivita.js`) e la logica di salvataggio (individuale già esistente, bulk nuova).

**Tech Stack:** Vue 3 `<script setup>`, Pinia (store esistente `useDatiStore`), nessun framework di test nel progetto.

Spec di riferimento: `docs/superpowers/specs/2026-07-20-attivita-bulk-zona-design.md`

## Global Constraints

- Nessuna nuova dipendenza, nessun composable aggiuntivo — la logica di raggruppamento è una funzione pura importata, non un composable Vue.
- Nessun framework di test nel progetto: verifica delle parti UI tramite `npm run dev` (dev server manuale); verifica della logica pura tramite script Node temporanei in scratchpad, **non committati**.
- Stile inline esistente (attributo `style` diretto, niente CSS scoped nuovo), coerente col resto del file.
- Chiave di gruppo: `zona` da sola se la pianta non ha `sottozona`, altrimenti `"${zona}|${sottozona}"` (il `|` è solo la chiave interna; il testo mostrato all'utente usa `" – "` come separatore).
- Il salvataggio bulk usa **una singola chiamata `saveJSON`** per l'intero gruppo (un solo commit), non una chiamata per pianta.
- Palette/font da `CLAUDE.md`: variabili CSS già definite (`--rose-light`, `--rose-pale`, `--rose-dark`, `--gold-pale`, `--ink-soft`), nessuna nuova variabile da introdurre.

---

## File Structure

- **Create** `src/utils/raggruppaAttivita.js` — funzione pura `raggruppaPerZona(itemsOrdinati, piante)`.
- **Create** `src/components/AttivitaRiga.vue` — riga singola pianta+cura (estratta dal markup duplicato attuale).
- **Create** `src/components/AttivitaGruppoZona.vue` — intestazione zona + pulsante bulk + lista di `AttivitaRiga`.
- **Modify** `src/views/AttivitaView.vue` — usa i due componenti sopra, calcola i gruppi, aggiunge `registraGruppo`.

---

### Task 1: Funzione di raggruppamento per zona

**Files:**
- Create: `src/utils/raggruppaAttivita.js`
- Test: script Node temporaneo in `/private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/46a90c20-7a94-411b-9167-3358fb94d4b8/scratchpad/verifica-raggruppa.mjs` (non committato, cancellato a fine task)

**Interfaces:**
- Produces: `raggruppaPerZona(itemsOrdinati: Array<{key, piantaId, tipo, giorni, ...}>, piante: Record<string, {zona: string, sottozona: string|null}>) => Array<{chiave: string, zona: string, sottozona: string|null, items: Array}>`. Usata dai Task 3 (computed `gruppiDaFare`/`gruppiInScadenza` in `AttivitaView.vue`).
- Assunzione sull'input: `itemsOrdinati` è già ordinato per `giorni` crescente (stesso ordinamento già prodotto oggi da `daFare`/`inScadenza` in `AttivitaView.vue`). La funzione **non** riordina gli item al suo interno, si limita a raggrupparli preservando l'ordine di arrivo — questo è ciò che garantisce che il primo gruppo incontrato sia anche quello con l'attività più urgente in assoluto (vedi commento nel codice).

- [ ] **Step 1: Scrivi lo script di verifica (prima dell'implementazione)**

Crea `/private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/46a90c20-7a94-411b-9167-3358fb94d4b8/scratchpad/verifica-raggruppa.mjs`:

```js
import assert from 'node:assert/strict'
import { raggruppaPerZona } from '/Users/rob/Sites/localhost/giardino/src/utils/raggruppaAttivita.js'

const piante = {
  'agave-1': { zona: 'Casa', sottozona: 'Soggiorno' },
  'basilico-1': { zona: 'Casa', sottozona: 'Cucina' },
  'ulivo-1': { zona: 'Crinale', sottozona: null },
  'rosmarino-1': { zona: 'Crinale', sottozona: null },
}

// giorni crescente = stesso ordinamento già applicato oggi a daFare/inScadenza
const items = [
  { key: 'ulivo-1-irrigazione', piantaId: 'ulivo-1', tipo: 'irrigazione', giorni: -6 },
  { key: 'agave-1-irrigazione', piantaId: 'agave-1', tipo: 'irrigazione', giorni: -3 },
  { key: 'rosmarino-1-irrigazione', piantaId: 'rosmarino-1', tipo: 'irrigazione', giorni: -1 },
  { key: 'basilico-1-irrigazione', piantaId: 'basilico-1', tipo: 'irrigazione', giorni: 0 },
]

const gruppi = raggruppaPerZona(items, piante)

assert.equal(gruppi.length, 3, 'devono esserci 3 gruppi: Crinale, Casa|Soggiorno, Casa|Cucina')

assert.equal(gruppi[0].chiave, 'Crinale', 'il gruppo con l\'attività più urgente (giorni -6) deve essere primo')
assert.equal(gruppi[0].zona, 'Crinale')
assert.equal(gruppi[0].sottozona, null)
assert.equal(gruppi[0].items.length, 2, 'Crinale deve contenere ulivo e rosmarino')
assert.deepEqual(gruppi[0].items.map(i => i.piantaId), ['ulivo-1', 'rosmarino-1'])

assert.equal(gruppi[1].chiave, 'Casa|Soggiorno')
assert.equal(gruppi[1].zona, 'Casa')
assert.equal(gruppi[1].sottozona, 'Soggiorno')
assert.equal(gruppi[1].items.length, 1)

assert.equal(gruppi[2].chiave, 'Casa|Cucina')
assert.equal(gruppi[2].zona, 'Casa')
assert.equal(gruppi[2].sottozona, 'Cucina')

console.log('OK: tutte le assert passate')
```

- [ ] **Step 2: Esegui lo script e verifica che fallisca**

Run: `node /private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/46a90c20-7a94-411b-9167-3358fb94d4b8/scratchpad/verifica-raggruppa.mjs`
Expected: errore di import — `Cannot find module '/Users/rob/Sites/localhost/giardino/src/utils/raggruppaAttivita.js'` (il file non esiste ancora)

- [ ] **Step 3: Crea l'implementazione**

Crea `src/utils/raggruppaAttivita.js`:

```js
export function raggruppaPerZona(itemsOrdinati, piante) {
  const gruppi = new Map()
  for (const item of itemsOrdinati) {
    const p = piante[item.piantaId]
    const chiave = p.sottozona ? `${p.zona}|${p.sottozona}` : p.zona
    if (!gruppi.has(chiave)) {
      gruppi.set(chiave, { chiave, zona: p.zona, sottozona: p.sottozona, items: [] })
    }
    gruppi.get(chiave).items.push(item)
  }
  // Map preserva l'ordine di inserimento: poiché itemsOrdinati è già ordinato
  // per giorni crescenti, il primo item incontrato per ogni gruppo determina
  // anche l'ordine relativo tra i gruppi (equivalente a ordinare per il minimo).
  return [...gruppi.values()]
}
```

- [ ] **Step 4: Esegui lo script e verifica che passi**

Run: `node /private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/46a90c20-7a94-411b-9167-3358fb94d4b8/scratchpad/verifica-raggruppa.mjs`
Expected: `OK: tutte le assert passate`

- [ ] **Step 5: Elimina lo script di verifica temporaneo**

Run: `rm /private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/46a90c20-7a94-411b-9167-3358fb94d4b8/scratchpad/verifica-raggruppa.mjs`

- [ ] **Step 6: Commit**

```bash
git add src/utils/raggruppaAttivita.js
git commit -m "Aggiunge funzione di raggruppamento attività per zona"
```

---

### Task 2: Estrarre `AttivitaRiga.vue`

Refactor puro: nessun cambiamento di comportamento o aspetto visibile. Sostituisce il markup della riga, oggi duplicato identico (a parte lo stile) tra le sezioni "Da fare" e "In scadenza" di `AttivitaView.vue`.

**Files:**
- Create: `src/components/AttivitaRiga.vue`
- Modify: `src/views/AttivitaView.vue:18-63` (blocchi template "Da fare" e "In scadenza")
- Test: verifica manuale (nessun framework di test nel progetto)

**Interfaces:**
- Consumes: nessuno (componente foglia).
- Produces: componente `AttivitaRiga` con props `item: {key, tipo, nomeSpecie, label}`, `variante: 'urgente' | 'scadenza'`, `disabled: boolean` (default `false`); emette `registra` con payload `item`. Usato da `AttivitaGruppoZona.vue` nel Task 3.

- [ ] **Step 1: Crea il componente**

Crea `src/components/AttivitaRiga.vue`:

```vue
<template>
  <div class="card" :style="cardStyle">
    <div :style="iconStyle">{{ icona(item.tipo) }}</div>
    <div style="flex:1;min-width:0;">
      <div class="title-serif" style="font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
        {{ item.nomeSpecie }}
      </div>
      <div :style="labelStyle">{{ item.label }}</div>
    </div>
    <button @click="$emit('registra', item)" :disabled="disabled"
      :class="['btn', variante === 'urgente' ? 'btn-rose' : 'btn-ghost']"
      style="font-size:11px;padding:5px 10px;min-height:30px;flex-shrink:0;">
      {{ disabled ? '⏳' : '✓ Fatto' }}
    </button>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  item: { type: Object, required: true },
  variante: { type: String, required: true },
  disabled: { type: Boolean, default: false },
})
defineEmits(['registra'])

function icona(tipo) {
  return tipo === 'irrigazione' ? '💧' : tipo === 'concimazione' ? '🌱' : '✂️'
}

const cardStyle = computed(() => {
  const base = 'display:flex;align-items:center;gap:12px;padding:12px 16px;'
  return props.variante === 'urgente'
    ? base + 'border-color:var(--rose-light);background:var(--rose-pale);'
    : base
})

const iconStyle = computed(() => {
  const base = 'width:40px;height:40px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;'
  return base + (props.variante === 'urgente' ? 'background:var(--rose-light);' : 'background:var(--gold-pale);')
})

const labelStyle = computed(() => {
  const base = 'font-size:11px;margin-top:2px;'
  return base + (props.variante === 'urgente' ? 'color:var(--rose-dark);' : 'color:var(--ink-soft);')
})
</script>
```

- [ ] **Step 2: Sostituisci il blocco "Da fare" in `AttivitaView.vue`**

In `src/views/AttivitaView.vue`, sostituisci (righe 19-40 del file originale):

```html
      <!-- Da fare -->
      <template v-if="daFare.length">
        <p class="section-label">⚠ Da fare</p>
        <div style="display:flex;flex-direction:column;gap:8px;margin-bottom:24px;">
          <div v-for="item in daFare" :key="item.key" class="card"
            style="display:flex;align-items:center;gap:12px;padding:12px 16px;border-color:var(--rose-light);background:var(--rose-pale);">
            <div style="width:40px;height:40px;border-radius:12px;background:var(--rose-light);display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;">
              {{ icona(item.tipo) }}
            </div>
            <div style="flex:1;min-width:0;">
              <div class="title-serif" style="font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
                {{ item.nomeSpecie }}
              </div>
              <div style="font-size:11px;color:var(--rose-dark);margin-top:2px;">{{ item.label }}</div>
            </div>
            <button @click="registra(item)" :disabled="salvando === item.key" class="btn btn-rose"
              style="font-size:11px;padding:5px 10px;min-height:30px;flex-shrink:0;">
              {{ salvando === item.key ? '⏳' : '✓ Fatto' }}
            </button>
          </div>
        </div>
      </template>
```

con:

```html
      <!-- Da fare -->
      <template v-if="daFare.length">
        <p class="section-label">⚠ Da fare</p>
        <div style="display:flex;flex-direction:column;gap:8px;margin-bottom:24px;">
          <AttivitaRiga
            v-for="item in daFare"
            :key="item.key"
            :item="item"
            variante="urgente"
            :disabled="salvando === item.key"
            @registra="registra"
          />
        </div>
      </template>
```

- [ ] **Step 3: Sostituisci il blocco "In scadenza" in `AttivitaView.vue`**

Sostituisci (righe 42-63 del file originale):

```html
      <!-- In scadenza -->
      <template v-if="inScadenza.length">
        <p class="section-label">🕐 In scadenza (entro 3 giorni)</p>
        <div style="display:flex;flex-direction:column;gap:8px;margin-bottom:24px;">
          <div v-for="item in inScadenza" :key="item.key" class="card"
            style="display:flex;align-items:center;gap:12px;padding:12px 16px;">
            <div style="width:40px;height:40px;border-radius:12px;background:var(--gold-pale);display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;">
              {{ icona(item.tipo) }}
            </div>
            <div style="flex:1;min-width:0;">
              <div class="title-serif" style="font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
                {{ item.nomeSpecie }}
              </div>
              <div style="font-size:11px;color:var(--ink-soft);margin-top:2px;">{{ item.label }}</div>
            </div>
            <button @click="registra(item)" :disabled="salvando === item.key" class="btn btn-ghost"
              style="font-size:11px;padding:5px 10px;min-height:30px;flex-shrink:0;">
              {{ salvando === item.key ? '⏳' : '✓ Fatto' }}
            </button>
          </div>
        </div>
      </template>
```

con:

```html
      <!-- In scadenza -->
      <template v-if="inScadenza.length">
        <p class="section-label">🕐 In scadenza (entro 3 giorni)</p>
        <div style="display:flex;flex-direction:column;gap:8px;margin-bottom:24px;">
          <AttivitaRiga
            v-for="item in inScadenza"
            :key="item.key"
            :item="item"
            variante="scadenza"
            :disabled="salvando === item.key"
            @registra="registra"
          />
        </div>
      </template>
```

- [ ] **Step 4: Aggiungi l'import nello script**

In `src/views/AttivitaView.vue`, riga 76 (subito dopo `import { valutaCura } from '@/composables/useCure'`), aggiungi:

```js
import AttivitaRiga from '@/components/AttivitaRiga.vue'
```

La funzione `icona()` locale (righe 87-89) resta invariata: è ancora usata da `AttivitaRiga.vue` al suo interno (copiata, non condivisa) — non serve più in `AttivitaView.vue` a questo punto, ma la rimuoviamo solo se davvero non ha più chiamanti nel file dopo questo step. Verifica con:

Run: `grep -n "icona(" src/views/AttivitaView.vue`
Expected: nessuna occorrenza di `icona(item.tipo)` nel template (rimosso con gli step 2-3); se la funzione `function icona(tipo) {...}` non è più referenziata, rimuovila da `AttivitaView.vue`.

- [ ] **Step 5: Verifica manuale — nessuna regressione visiva**

Run: `npm run dev`

Apri `http://localhost:5173/#/attivita` nel browser. Verifica:
- Le sezioni "Da fare" e "In scadenza" mostrano le stesse righe di prima (icona, nome specie, label, pulsante), con gli stessi colori (rosa per "Da fare", neutro per "In scadenza").
- Cliccando "✓ Fatto" su una riga reale, il pulsante mostra ⏳, la richiesta va a buon fine (o fallisce con lo stesso comportamento di prima se manca il token GitHub) e la riga sparisce dalla lista in caso di successo.
- Nessun errore in console del browser.

- [ ] **Step 6: Commit**

```bash
git add src/components/AttivitaRiga.vue src/views/AttivitaView.vue
git commit -m "Estrae AttivitaRiga.vue dal markup duplicato in AttivitaView"
```

---

### Task 3: Raggruppamento per zona e azione bulk

**Files:**
- Create: `src/components/AttivitaGruppoZona.vue`
- Modify: `src/views/AttivitaView.vue` (script: import, stato, computed, `registraGruppo`; template: sostituzione dei due blocchi `AttivitaRiga` con `AttivitaGruppoZona`)
- Test: verifica manuale (nessun framework di test nel progetto)

**Interfaces:**
- Consumes: `raggruppaPerZona` da `src/utils/raggruppaAttivita.js` (Task 1); `AttivitaRiga` da `src/components/AttivitaRiga.vue` (Task 2, con props/emit già definiti sopra).
- Produces: componente `AttivitaGruppoZona` con props `gruppo: {chiave, zona, sottozona, items}`, `variante: 'urgente' | 'scadenza'`, `salvando: string|null` (default `null`), `salvandoGruppo: string|null` (default `null`); emette `registra` (payload `item`) e `registraGruppo` (payload `gruppo`).

- [ ] **Step 1: Crea `AttivitaGruppoZona.vue`**

Crea `src/components/AttivitaGruppoZona.vue`:

```vue
<template>
  <div style="margin-bottom:16px;">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px;padding:0 2px;">
      <span style="font-size:12px;font-weight:600;color:var(--ink-soft);">
        {{ etichettaZona }} ({{ gruppo.items.length }})
      </span>
      <button @click="$emit('registraGruppo', gruppo)" :disabled="salvandoGruppo === gruppo.chiave"
        :class="['btn', variante === 'urgente' ? 'btn-rose' : 'btn-ghost']"
        style="font-size:11px;padding:4px 9px;min-height:26px;">
        {{ salvandoGruppo === gruppo.chiave ? '⏳' : '✓ Segna tutto fatto' }}
      </button>
    </div>
    <div style="display:flex;flex-direction:column;gap:8px;">
      <AttivitaRiga
        v-for="item in gruppo.items"
        :key="item.key"
        :item="item"
        :variante="variante"
        :disabled="salvando === item.key || salvandoGruppo === gruppo.chiave"
        @registra="$emit('registra', $event)"
      />
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import AttivitaRiga from './AttivitaRiga.vue'

const props = defineProps({
  gruppo: { type: Object, required: true },
  variante: { type: String, required: true },
  salvando: { type: String, default: null },
  salvandoGruppo: { type: String, default: null },
})
defineEmits(['registra', 'registraGruppo'])

const etichettaZona = computed(() =>
  props.gruppo.sottozona ? `${props.gruppo.zona} – ${props.gruppo.sottozona}` : props.gruppo.zona
)
</script>
```

- [ ] **Step 2: Aggiungi import e stato in `AttivitaView.vue`**

Dopo l'import aggiunto nel Task 2 (`import AttivitaRiga from '@/components/AttivitaRiga.vue'`), aggiungi:

```js
import AttivitaGruppoZona from '@/components/AttivitaGruppoZona.vue'
import { raggruppaPerZona } from '@/utils/raggruppaAttivita'
```

Dopo la riga `const salvando = ref(null)`, aggiungi:

```js
const salvandoGruppo = ref(null)
```

- [ ] **Step 3: Aggiungi i computed di raggruppamento**

Subito dopo la definizione di `inScadenza` (riga con `const inScadenza = computed(...)`), aggiungi:

```js
const gruppiDaFare = computed(() => raggruppaPerZona(daFare.value, store.piante))
const gruppiInScadenza = computed(() => raggruppaPerZona(inScadenza.value, store.piante))
```

- [ ] **Step 4: Aggiungi `registraGruppo`**

Dopo la funzione `registra(item)` esistente, aggiungi:

```js
async function registraGruppo(gruppo) {
  if (salvandoGruppo.value) return
  salvandoGruppo.value = gruppo.chiave
  try {
    const nuove = { ...store.piante }
    const oggi = new Date().toISOString().split('T')[0]
    for (const item of gruppo.items) {
      nuove[item.piantaId] = {
        ...nuove[item.piantaId],
        ultima_cura: { ...nuove[item.piantaId].ultima_cura, [item.tipo]: oggi },
      }
    }
    await saveJSON('piante.json', nuove)
    store.piante = nuove
  } finally {
    salvandoGruppo.value = null
  }
}
```

- [ ] **Step 5: Sostituisci il rendering "Da fare" per usare i gruppi**

Sostituisci il blocco introdotto nel Task 2:

```html
      <!-- Da fare -->
      <template v-if="daFare.length">
        <p class="section-label">⚠ Da fare</p>
        <div style="display:flex;flex-direction:column;gap:8px;margin-bottom:24px;">
          <AttivitaRiga
            v-for="item in daFare"
            :key="item.key"
            :item="item"
            variante="urgente"
            :disabled="salvando === item.key"
            @registra="registra"
          />
        </div>
      </template>
```

con:

```html
      <!-- Da fare -->
      <template v-if="daFare.length">
        <p class="section-label">⚠ Da fare</p>
        <div style="margin-bottom:24px;">
          <AttivitaGruppoZona
            v-for="gruppo in gruppiDaFare"
            :key="gruppo.chiave"
            :gruppo="gruppo"
            variante="urgente"
            :salvando="salvando"
            :salvando-gruppo="salvandoGruppo"
            @registra="registra"
            @registra-gruppo="registraGruppo"
          />
        </div>
      </template>
```

- [ ] **Step 6: Sostituisci il rendering "In scadenza" per usare i gruppi**

Sostituisci il blocco introdotto nel Task 2:

```html
      <!-- In scadenza -->
      <template v-if="inScadenza.length">
        <p class="section-label">🕐 In scadenza (entro 3 giorni)</p>
        <div style="display:flex;flex-direction:column;gap:8px;margin-bottom:24px;">
          <AttivitaRiga
            v-for="item in inScadenza"
            :key="item.key"
            :item="item"
            variante="scadenza"
            :disabled="salvando === item.key"
            @registra="registra"
          />
        </div>
      </template>
```

con:

```html
      <!-- In scadenza -->
      <template v-if="inScadenza.length">
        <p class="section-label">🕐 In scadenza (entro 3 giorni)</p>
        <div style="margin-bottom:24px;">
          <AttivitaGruppoZona
            v-for="gruppo in gruppiInScadenza"
            :key="gruppo.chiave"
            :gruppo="gruppo"
            variante="scadenza"
            :salvando="salvando"
            :salvando-gruppo="salvandoGruppo"
            @registra="registra"
            @registra-gruppo="registraGruppo"
          />
        </div>
      </template>
```

- [ ] **Step 7: Verifica manuale — raggruppamento e ordinamento**

Run: `npm run dev`

Apri `http://localhost:5173/#/attivita`. Verifica:
- Le attività pendenti sono raggruppate per zona (e sottozona quando presente), con intestazione tipo `"Vialetto (3)"` o `"Casa – Soggiorno (2)"`.
- I gruppi sono ordinati per urgenza: il gruppo che contiene l'attività più scaduta appare per primo.
- Un gruppo con una sola attività mostra comunque intestazione e pulsante bulk.
- Nessun errore in console.

- [ ] **Step 8: Verifica manuale — salvataggio bulk**

Nella stessa pagina, individua un gruppo con almeno 2 attività (o forza temporaneamente una data vecchia in `ultima_cura` per due piante della stessa zona in `public/data/piante.json`, **senza committare**, solo per il test locale). Clicca "✓ Segna tutto fatto":
- Il pulsante del gruppo mostra ⏳ e si disabilita.
- Tutte le righe del gruppo mostrano ⏳ e si disabilitano.
- I pulsanti degli altri gruppi restano cliccabili durante l'operazione.
- Al termine, tutte le righe del gruppo spariscono insieme (o, in caso di errore di rete/token, nessuna riga sparisce — comportamento invariato rispetto al salvataggio individuale).
- Se hai modificato `public/data/piante.json` per il test, esegui `git checkout -- public/data/piante.json` per annullare la modifica prima di committare.

- [ ] **Step 9: Verifica manuale — separazione per sottozona**

Forza temporaneamente (senza committare) date vecchie in `ultima_cura` per due piante in sottozone diverse di "Casa" (es. una in "Soggiorno", una in "Scalinata"). Ricarica `/attivita` e verifica che compaiano come due gruppi separati (`"Casa – Soggiorno"` e `"Casa – Scalinata"`), ciascuno con il proprio pulsante bulk indipendente. Poi esegui `git checkout -- public/data/piante.json`.

- [ ] **Step 10: Commit**

```bash
git add src/components/AttivitaGruppoZona.vue src/views/AttivitaView.vue
git commit -m "Aggiunge raggruppamento per zona e azione bulk in Attività"
```

---

## Self-Review

**Copertura spec:**
- Componenti e architettura → Task 2 (`AttivitaRiga.vue`) + Task 3 (`AttivitaGruppoZona.vue`), nessun composable aggiuntivo. ✓
- Logica di raggruppamento (chiave zona/sottozona, ordinamento per urgenza) → Task 1, verificata con script Node prima dell'integrazione UI. ✓
- Azione bulk con singola `saveJSON` → Task 3 Step 4 (`registraGruppo`). ✓
- Stato di caricamento (pulsante gruppo disabilitato, righe del gruppo disabilitate, altri gruppi attivi) → Task 3 Step 1 (props `salvando`/`salvandoGruppo` su `AttivitaGruppoZona`) e Step 8 di verifica. ✓
- Gruppi con 1 sola attività mostrati con intestazione e bulk → Task 3 Step 7 di verifica. ✓
- Nessun error handling nuovo (comportamento invariato in caso di fallimento `saveJSON`) → confermato nel codice di `registraGruppo`, identico pattern try/finally di `registra`. ✓
- Verifica su "Casa" con più sottozone → Task 3 Step 9. ✓

**Placeholder scan:** nessun TBD/TODO; ogni step ha codice completo o comando+output atteso espliciti.

**Coerenza tipi/nomi:** `raggruppaPerZona(itemsOrdinati, piante)` (Task 1) usato identicamente in Task 3 Step 3; struttura gruppo `{chiave, zona, sottozona, items}` usata coerentemente in `AttivitaGruppoZona.vue` (Task 3 Step 1) e nel confronto `salvandoGruppo === gruppo.chiave` sia in `AttivitaView.vue` (Step 4) sia in `AttivitaGruppoZona.vue` (Step 1). Props/emit di `AttivitaRiga` (Task 2 Step 1: `item`, `variante`, `disabled`, emit `registra`) usati identicamente da `AttivitaGruppoZona.vue` in Task 3 Step 1.
