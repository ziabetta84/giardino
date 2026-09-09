# Irrigazione automatica — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permettere di configurare un programma di irrigazione automatica ("ogni N giorni") per l'intero giardino, per una zona o per una singola pianta, con cascata giardino → zona → pianta: quando una pianta è coperta da un programma attivo, l'avviso "irrigazione scaduta" calcolato oggi da specie+stagione smette di comparire (la sospensione per pioggia prevista resta valida).

**Architecture:** Nuova tabella Supabase `programmi_irrigazione` (RLS per `owner_id`, un livello per riga determinato da quali colonne sono valorizzate: `zona_id`/`pianta_id` entrambi null = giardino). Lo store (`stores/dati.js`) la carica insieme al resto e la espone come `programmiIrrigazione` in una forma keyed pronta per la cascata (`{ giardino, zone: {nome: …}, piante: {id: …} }`). Un resolver puro (`useIrrigazioneAuto.js`) calcola il programma effettivo per una pianta; `useCure.js → valutaCura()` lo usa per sostituire completamente la logica di urgenza basata su specie quando un programma è attivo su quella pianta, prima di guardare `ultima_cura`. I 6 punti dell'app che oggi valutano l'urgenza irrigazione vengono aggiornati per passare questo dato nel `contesto` già esistente. Una nuova vista `IrrigazioneView.vue`, raggiungibile da Impostazioni, mostra l'albero Giardino → Zone → Piante e apre `FoglioLaterale` per modificare/rimuovere un programma a ogni livello.

**Tech Stack:** Vue 3 `<script setup>` SFC, Vite, vue-router (`createWebHashHistory`), Supabase JS client + Postgres/RLS, Pinia (`useDatiStore`). Nessun runner di test in questo progetto.

**Spec:** nessuna spec formale — brief discusso e approvato in chat (comando `/impeccable shape`) l'8 settembre 2026. Contesto pre-esistente rilevante: `src/composables/useCure.js` (logica urgenze), `supabase/migrations/20260830010000_fase5_schema_zone_sottozone_piante.sql` e `20260830040000_fase5_completamento_schema.sql` (schema e pattern RLS di riferimento).

## Global Constraints

- **Lingua:** testi UI, commenti e messaggi di commit in **italiano**.
- **Nessun framework di test in questo repo** (nessuna cartella `tests/`, nessun `npm test`, nessuna dipendenza di test in `package.json`). **Verifica automatica = solo `npm run build` (exit 0).** Non introdurre un runner di test o file `*.test.*`: non è una convenzione di questo progetto. L'integrazione DB/store/UI si verifica a mano nel browser (dev server), come già fatto per la Fase 5 e per gli altri piani in `docs/superpowers/plans/`.
- **Zorba** resta nero `#141414`, non toccato da questo lavoro.
- **Palette e token invariati:** riusa `--sage`/`--rose`/`--gold`/`--acqua` e le classi globali esistenti (`.dest`, `.destlist`, `.pill-mini`, `.badge-ok`, `.empty`, `.field-label`, `.foglio-form`, `.foglio-actions`, `.form-input`, `.btn`/`.btn-sage`/`.btn-ghost`) — nessuna nuova classe CSS globale a meno che uno step lo dica esplicitamente.
- **Icona dominio irrigazione:** sempre `goccia` (già usata per le cure di irrigazione in tutta l'app) — non introdurre una nuova icona.
- **Cascata a due soli passaggi:** giardino → zona → pianta. Nessun livello "sottozona" (deciso esplicitamente nel brief).
- **Un programma attivo sostituisce interamente la valutazione da specie per quella pianta** (non la affianca): l'avviso "irrigazione scaduta" da specie/stagione non deve più comparire per una pianta coperta, in nessuna delle viste che oggi calcolano urgenze.
- **La sospensione per pioggia (`SOGLIA_PIOGGIA_MM`, `pioggiaInArrivo` in `useCure.js`) resta valida anche per un programma automatico** — non duplicare questa soglia altrove.
- **Progetto Supabase:** `ncuhhsvtjwcolhpdxbkt` ("Il Giardino di Zorba"). Usa gli strumenti MCP `mcp__plugin_supabase_supabase__apply_migration` / `list_tables` / `execute_sql` con questo `project_id`.
- **Branch:** `irrigazione-automatica` da `main`. Nessun commit diretto su `main`. Merge solo su ok esplicito di Rob.
- **Commit:** messaggi in italiano, ognuno chiude con:
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
  ```

---

## File Structure

| File | Modifica |
|------|----------|
| `supabase/migrations/20260908000000_programmi_irrigazione.sql` | **Crea** — tabella `programmi_irrigazione` + RLS, stesso pattern di `zone`/`concimi`. |
| `src/stores/dati.js` | **Modifica** — nuovo ref `programmiIrrigazione`, `mappaProgrammiIrrigazione()`, caricamento in `eseguiCaricamento()`, esposto nel return. |
| `src/composables/useIrrigazioneAuto.js` | **Crea** — resolver puro `programmaIrrigazioneEffettivo(piantaId, zonaNome, programmi)` per la cascata. |
| `src/composables/useCure.js` | **Modifica** — `valutaCura()` sostituisce la valutazione da specie quando `contesto.programmaAutomatico` è impostato per `tipo === 'irrigazione'`. |
| `src/components/PiantaRiga.vue` | **Modifica** — passa `programmaAutomatico` nel contesto di `cureUrgentiPianta`. |
| `src/components/DossierPianta.vue` | **Modifica** — `contestoCura` include `programmaAutomatico`. |
| `src/views/AttivitaView.vue` | **Modifica** — `contesto` per pianta include `programmaAutomatico`. |
| `src/views/PiantaView.vue` | **Modifica** — `contestoCura` include `programmaAutomatico`. |
| `src/views/PianteView.vue` | **Modifica** — `cureUrgentiPianta` riceve un contesto con `programmaAutomatico`. |
| `src/views/HomeView.vue` | **Modifica** — `contestoPianta(p, id)` include `programmaAutomatico`; i due punti che la chiamano passano anche `id`. |
| `src/composables/useIrrigazioneApi.js` | **Crea** — `salvaProgramma(target, ogniGiorni)` / `rimuoviProgramma(target)` (insert/update/delete + patch dello store). |
| `src/views/IrrigazioneView.vue` | **Crea** — albero Giardino → Zone → Piante, Foglio per modificare/rimuovere un programma. |
| `src/router/index.js` | **Modifica** — nuova route `/impostazioni/irrigazione`. |
| `src/views/SettingsView.vue` | **Modifica** — link a `/impostazioni/irrigazione`, stesso pattern del link "Impostazioni giardino" in `AccountView.vue`. |

Nessun file di test.

---

### Task 1: Tabella Supabase `programmi_irrigazione`

**Files:**
- Create: `supabase/migrations/20260908000000_programmi_irrigazione.sql`

**Interfaces:**
- Produce: tabella `programmi_irrigazione(id, owner_id, zona_id, pianta_id, ogni_giorni)` con RLS "proprietario", consumata da Task 2 (store) e Task 6 (API di scrittura).

- [ ] **Step 1: Verificare il branch**

Il worktree è già sul branch `irrigazione-automatica` (creato dal controller prima del dispatch). Verifica soltanto:

```bash
git branch --show-current
```

Expected: `irrigazione-automatica`. Non creare un nuovo branch.

- [ ] **Step 2: Scrivere la migration**

Crea `supabase/migrations/20260908000000_programmi_irrigazione.sql`:

```sql
-- Irrigazione automatica: programma "ogni N giorni" configurabile in
-- cascata (giardino → zona → pianta). zona_id e pianta_id entrambi null =
-- livello giardino (default per l'utente); zona_id valorizzato = livello
-- zona; pianta_id valorizzato = livello pianta. Mai entrambi valorizzati
-- (vedi check): la cascata è determinata da quale colonna è compilata, non
-- da un campo "livello" separato che potrebbe disallinearsi da essa.
create table programmi_irrigazione (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  zona_id uuid references zone(id) on delete cascade,
  pianta_id text references piante(id) on delete cascade,
  ogni_giorni integer not null check (ogni_giorni > 0),
  check (zona_id is null or pianta_id is null),
  unique (zona_id),
  unique (pianta_id)
);

-- Un solo programma "giardino" (zona_id e pianta_id entrambi null) per
-- utente: un vincolo unique su (zona_id, pianta_id) non basterebbe, perché
-- in Postgres NULL non è mai uguale a NULL in un vincolo unique.
create unique index programmi_irrigazione_giardino_uniq on programmi_irrigazione (owner_id)
  where zona_id is null and pianta_id is null;

alter table programmi_irrigazione enable row level security;

create policy "programmi_irrigazione: proprietario" on programmi_irrigazione for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
```

- [ ] **Step 3: Applicare la migration**

Chiama `mcp__plugin_supabase_supabase__apply_migration` con `project_id: "ncuhhsvtjwcolhpdxbkt"`, `name: "programmi_irrigazione"`, `query`: il contenuto del file appena creato.

- [ ] **Step 4: Verificare schema e RLS**

Chiama `mcp__plugin_supabase_supabase__list_tables` con `project_id: "ncuhhsvtjwcolhpdxbkt"`, `schemas: ["public"]`.
Expected: `programmi_irrigazione` presente, `rls_enabled: true`, colonne `id, owner_id, zona_id, pianta_id, ogni_giorni`.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260908000000_programmi_irrigazione.sql
git commit -m "$(cat <<'EOF'
Aggiunge tabella programmi_irrigazione per l'irrigazione automatica

Un programma "ogni N giorni" per utente, a livello di giardino (default),
zona o singola pianta — RLS per owner_id, stesso pattern di zone/concimi.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```

---

### Task 2: Caricamento nello store

**Files:**
- Modify: `src/stores/dati.js`

**Interfaces:**
- Consuma: tabella `programmi_irrigazione` (Task 1).
- Produce: `store.programmiIrrigazione` nella forma `{ giardino: {id, ogniGiorni} | null, zone: { [nomeZona]: {id, ogniGiorni} }, piante: { [piantaId]: {id, ogniGiorni} } }`, consumata da Task 3 (resolver), Task 5 (call site) e Task 6/7 (UI di gestione).

- [ ] **Step 1: Funzione di mapping**

In `src/stores/dati.js`, subito dopo `mappaConcimi` (prima di `mappaSettings`), aggiungere:

```js
// Irrigazione automatica: righe piatte da Supabase ricostruite come cascata
// pronta all'uso — pianta_id/zona_id entrambi null = livello giardino.
// zona_id orfano ignorato per sicurezza, stesso criterio di mappaSottozone.
export function mappaProgrammiIrrigazione(righeProgrammi, zonaNomePerId) {
  const risultato = { giardino: null, zone: {}, piante: {} }
  for (const r of righeProgrammi) {
    const voce = { id: r.id, ogniGiorni: r.ogni_giorni }
    if (r.pianta_id) {
      risultato.piante[r.pianta_id] = voce
    } else if (r.zona_id) {
      const nomeZona = zonaNomePerId[r.zona_id]
      if (nomeZona) risultato.zone[nomeZona] = voce
    } else {
      risultato.giardino = voce
    }
  }
  return risultato
}
```

- [ ] **Step 2: Ref e caricamento**

Nello stesso file, nel blocco `useDatiStore`, aggiungere il ref dopo `const concimi = ref(null)`:

```js
  const concimi   = ref(null)
  const programmiIrrigazione = ref(null)
```

Nel blocco `Promise.all` di `eseguiCaricamento()`, aggiungere la query e il valore destrutturato:

```js
      const [righeZone, righeSottozone, righePiante, richiesteData, righeProgetti, righeTappe, righeSettings, righeConcimi, righeProgrammiIrrigazione] =
        await Promise.all([
          query(supabase.from('zone').select('*')),
          query(supabase.from('sottozone').select('*')),
          query(supabase.from('piante').select('*')),
          caricaJSON('richieste-agente.json'),
          query(supabase.from('progetti').select('*')),
          query(supabase.from('tappe').select('*')),
          query(supabase.from('settings').select('*')),
          query(supabase.from('concimi').select('*')),
          query(supabase.from('programmi_irrigazione').select('*')),
        ])
```

Subito dopo `concimi.value = mappaConcimi(righeConcimi)`, aggiungere:

```js
      concimi.value   = mappaConcimi(righeConcimi)
      programmiIrrigazione.value = mappaProgrammiIrrigazione(righeProgrammiIrrigazione, zonaNomePerId)
```

- [ ] **Step 3: Esporre dallo store**

Nella riga di `return` in fondo a `useDatiStore` (`return { piante, specie, zone, sottozone, progetti, settings, concimi, meteo, loading, errore, caricaTutto, aggiorna, iconaZona, iconaSottozona }`), aggiungere `programmiIrrigazione`:

```js
  return { piante, specie, zone, sottozone, progetti, settings, concimi, programmiIrrigazione, meteo, loading, errore, caricaTutto, aggiorna, iconaZona, iconaSottozona }
```

- [ ] **Step 4: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 5: Verifica manuale nel browser**

Avvia `npm run dev`, apri la console del browser sull'app autenticata, ed esegui (via Vue devtools o un breakpoint temporaneo) una lettura di `useDatiStore().programmiIrrigazione` dopo il caricamento: deve restituire `{ giardino: null, zone: {}, piante: {} }` (tabella ancora vuota) senza errori in console.

- [ ] **Step 6: Commit**

```bash
git add src/stores/dati.js
git commit -m "$(cat <<'EOF'
Store: carica programmi_irrigazione in una cascata giardino/zona/pianta

mappaProgrammiIrrigazione ricostruisce le righe piatte di Supabase in
{ giardino, zone, piante } pronto per il resolver dell'irrigazione
automatica, stesso pattern di mappaZone/mappaSottozone/mappaConcimi.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```

---

### Task 3: Resolver della cascata

**Files:**
- Create: `src/composables/useIrrigazioneAuto.js`

**Interfaces:**
- Consuma: `store.programmiIrrigazione` (Task 2), nella forma `{ giardino, zone, piante }`.
- Produce: `programmaIrrigazioneEffettivo(piantaId, zonaNome, programmi)` → `{ id, ogniGiorni, livello: 'pianta'|'zona'|'giardino' } | null`, consumata da Task 5 (6 call site) e riusabile da Task 7 (vista di gestione) per mostrare l'eredità.

- [ ] **Step 1: Scrivere il resolver**

Crea `src/composables/useIrrigazioneAuto.js`:

```js
// Risoluzione della cascata giardino → zona → pianta per l'irrigazione
// automatica: la pianta vince se ha un programma proprio, altrimenti la sua
// zona, altrimenti il default dell'intero giardino. null quando nessun
// livello ha un programma — in quel caso l'irrigazione resta valutata da
// specie/stagione come prima di questa funzionalità (vedi useCure.js).
export function programmaIrrigazioneEffettivo(piantaId, zonaNome, programmi) {
  if (!programmi) return null
  if (programmi.piante[piantaId]) return { ...programmi.piante[piantaId], livello: 'pianta' }
  if (zonaNome && programmi.zone[zonaNome]) return { ...programmi.zone[zonaNome], livello: 'zona' }
  if (programmi.giardino) return { ...programmi.giardino, livello: 'giardino' }
  return null
}
```

- [ ] **Step 2: Verifica di lettura rapida (senza framework di test)**

Il file non ha dipendenze (nessun import): verificalo con uno script Node usa-e-getta, poi cancellalo — non è un file da tenere nel repo.

Crea un file temporaneo **nella stessa cartella del sorgente** (`src/composables/verifica-resolver.tmp.mjs`), così l'import relativo funziona senza dover conoscere il percorso assoluto del checkout:

```js
import assert from 'node:assert'
import { programmaIrrigazioneEffettivo } from './useIrrigazioneAuto.js'

const programmi = { giardino: { id: 'g', ogniGiorni: 7 }, zone: { Est: { id: 'z', ogniGiorni: 3 } }, piante: { p1: { id: 'p', ogniGiorni: 1 } } }

assert.deepStrictEqual(programmaIrrigazioneEffettivo('p1', 'Est', programmi), { id: 'p', ogniGiorni: 1, livello: 'pianta' })
assert.deepStrictEqual(programmaIrrigazioneEffettivo('p2', 'Est', programmi), { id: 'z', ogniGiorni: 3, livello: 'zona' })
assert.deepStrictEqual(programmaIrrigazioneEffettivo('p2', 'Ovest', programmi), { id: 'g', ogniGiorni: 7, livello: 'giardino' })
assert.strictEqual(programmaIrrigazioneEffettivo('p2', 'Ovest', { giardino: null, zone: {}, piante: {} }), null)

console.log('OK')
```

Run: `node src/composables/verifica-resolver.tmp.mjs`
Expected: stampa `OK`, nessun errore. Poi cancella il file temporaneo (`rm src/composables/verifica-resolver.tmp.mjs`) — non va committato.

- [ ] **Step 3: Commit**

```bash
git add src/composables/useIrrigazioneAuto.js
git commit -m "$(cat <<'EOF'
Aggiunge il resolver della cascata per l'irrigazione automatica

programmaIrrigazioneEffettivo() sceglie pianta > zona > giardino, null se
nessun livello ha un programma attivo — funzione pura, riusata da tutti i
punti che valutano l'urgenza di cura e dalla vista di gestione.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```

---

### Task 4: `useCure.js` — sostituire l'urgenza quando l'automatico è attivo

**Files:**
- Modify: `src/composables/useCure.js`

**Interfaces:**
- Consuma: `contesto.programmaAutomatico` (numero di giorni o `null/undefined`), che Task 5 popolerà in ogni chiamante usando il resolver di Task 3.
- Produce: nessun cambio di firma per i chiamanti esistenti — `contesto.programmaAutomatico` è un campo opzionale in più nell'oggetto `contesto` già passato a `valutaCura`/`cureUrgentiPianta`.

- [ ] **Step 1: Aggiungere lo short-circuit in `valutaCura`**

In `src/composables/useCure.js`, subito dopo la riga `export function valutaCura(pianta, specie, tipo, contesto = {}) {`, prima di `const stagCorrente = stagione()`, inserire:

```js
export function valutaCura(pianta, specie, tipo, contesto = {}) {
  // Un programma di irrigazione automatica attivo (giardino/zona/pianta,
  // vedi useIrrigazioneAuto.js) sostituisce del tutto la valutazione da
  // specie+stagione per questa pianta: l'utente non deve più vedere un
  // promemoria manuale per un'irrigazione che ha già pianificato altrove.
  // La sospensione per pioggia resta valida — stessa soglia e messaggio
  // già usati per l'irrigazione manuale, per non contraddirsi in due punti
  // diversi dell'app.
  if (tipo === 'irrigazione' && contesto.programmaAutomatico != null) {
    if (pianta?.coltivato_in !== 'acqua' && contesto.esterno && pioggiaInArrivo(contesto.meteo)) {
      return { urgente: false, label: 'irrigazione — pioggia prevista, salta', giorni: null }
    }
    return {
      urgente: false,
      label: `irrigazione — automatica (ogni ${contesto.programmaAutomatico} gg)`,
      giorni: null,
      automatico: true,
    }
  }

  const stagCorrente = stagione()
```

- [ ] **Step 2: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 3: Verifica di lettura rapida (senza framework di test)**

`useCure.js` non ha import: stesso approccio di Task 3 — script Node temporaneo **nella stessa cartella** (`src/composables/verifica-cure.tmp.mjs`), import relativo, poi cancellato.

```js
import assert from 'node:assert'
import { valutaCura } from './useCure.js'

const pianta = { coltivato_in: 'terra', ultima_cura: {} }
const specie = { manutenzione: { irrigazione: { estate: 'ogni 3 giorni' } } }

// Automatico attivo, niente pioggia in arrivo: mai urgente, label "automatica".
let r = valutaCura(pianta, specie, 'irrigazione', { programmaAutomatico: 5, esterno: true, meteo: [] })
assert.strictEqual(r.urgente, false)
assert.match(r.label, /automatica \(ogni 5 gg\)/)

// Automatico attivo + pioggia in arrivo: label di sospensione, non "automatica".
r = valutaCura(pianta, specie, 'irrigazione', { programmaAutomatico: 5, esterno: true, meteo: [{ pioggia: 10 }, { pioggia: 0 }] })
assert.strictEqual(r.urgente, false)
assert.match(r.label, /pioggia prevista, salta/)

// Nessun programma automatico: comportamento invariato (da specie).
r = valutaCura(pianta, specie, 'irrigazione', {})
assert.notStrictEqual(r.label, undefined)
assert.ok(!r.label.includes('automatica'))

console.log('OK')
```

Run: `node src/composables/verifica-cure.tmp.mjs`
Expected: stampa `OK`. Poi cancella il file temporaneo (`rm src/composables/verifica-cure.tmp.mjs`) — non va committato.

- [ ] **Step 4: Commit**

```bash
git add src/composables/useCure.js
git commit -m "$(cat <<'EOF'
useCure: un programma di irrigazione automatica sostituisce l'urgenza da specie

valutaCura() smette di calcolare l'urgenza irrigazione da specie/stagione
quando contesto.programmaAutomatico è impostato — la pioggia prevista
continua comunque a sospendere, stessa soglia di prima.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```

---

### Task 5: Propagare `programmaAutomatico` nei 6 punti che valutano l'urgenza

**Files:**
- Modify: `src/components/PiantaRiga.vue`
- Modify: `src/components/DossierPianta.vue`
- Modify: `src/views/AttivitaView.vue`
- Modify: `src/views/PiantaView.vue`
- Modify: `src/views/PianteView.vue`
- Modify: `src/views/HomeView.vue`

**Interfaces:**
- Consuma: `programmaIrrigazioneEffettivo` (Task 3), `store.programmiIrrigazione` (Task 2), `contesto.programmaAutomatico` (Task 4).
- Produce: nessuna interfaccia nuova per altri task — è l'ultimo anello della catena logica.

- [ ] **Step 1: `PiantaRiga.vue`**

In `src/components/PiantaRiga.vue`, aggiungere l'import dopo `import { cureUrgentiPianta } from '@/composables/useCure'`:

```js
import { programmaIrrigazioneEffettivo } from '@/composables/useIrrigazioneAuto'
```

Sostituire:

```js
const cureUrgenti = computed(() =>
  props.urgente ? cureUrgentiPianta(props.pianta, specie.value) : []
)
```

con:

```js
const programmaAutomatico = computed(() =>
  programmaIrrigazioneEffettivo(props.pianta.id, props.pianta.zona, store.programmiIrrigazione)?.ogniGiorni ?? null
)
const cureUrgenti = computed(() =>
  props.urgente ? cureUrgentiPianta(props.pianta, specie.value, { programmaAutomatico: programmaAutomatico.value }) : []
)
```

- [ ] **Step 2: `PianteView.vue`**

In `src/views/PianteView.vue`, aggiungere l'import dopo `import { cureUrgentiPianta } from '@/composables/useCure'`:

```js
import { programmaIrrigazioneEffettivo } from '@/composables/useIrrigazioneAuto'
```

Sostituire, nel computed `piante`:

```js
  return Object.entries(store.piante).map(([id, p]) => {
    const sp = store.specie?.[p.specie] ?? null
    const urgenti = cureUrgentiPianta(p, sp)
    return { id, ...p, urgente: urgenti.length > 0 }
  })
```

con:

```js
  return Object.entries(store.piante).map(([id, p]) => {
    const sp = store.specie?.[p.specie] ?? null
    const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, store.programmiIrrigazione)?.ogniGiorni ?? null
    const urgenti = cureUrgentiPianta(p, sp, { programmaAutomatico })
    return { id, ...p, urgente: urgenti.length > 0 }
  })
```

- [ ] **Step 3: `DossierPianta.vue`**

In `src/components/DossierPianta.vue`, aggiungere l'import dopo `import { valutaCura, stagione } from '@/composables/useCure'`:

```js
import { programmaIrrigazioneEffettivo } from '@/composables/useIrrigazioneAuto'
```

Sostituire:

```js
const contestoCura = computed(() => ({
  esterno: store.zone?.[pianta.value?.zona]?.tipo === 'esterno',
  meteo: store.meteo,
}))
```

con:

```js
const contestoCura = computed(() => ({
  esterno: store.zone?.[pianta.value?.zona]?.tipo === 'esterno',
  meteo: store.meteo,
  programmaAutomatico: programmaIrrigazioneEffettivo(props.piantaId, pianta.value?.zona, store.programmiIrrigazione)?.ogniGiorni ?? null,
}))
```

- [ ] **Step 4: `PiantaView.vue`**

In `src/views/PiantaView.vue`, aggiungere l'import dopo `import { LABEL_CURA, iconaCura, iconaEsigenza, capitalizza } from '@/composables/useCureVisual'`:

```js
import { programmaIrrigazioneEffettivo } from '@/composables/useIrrigazioneAuto'
```

Sostituire:

```js
const contestoCura = computed(() => ({
  esterno: store.zone?.[pianta.value?.zona]?.tipo === 'esterno',
  meteo: store.meteo,
}))
```

con:

```js
const contestoCura = computed(() => ({
  esterno: store.zone?.[pianta.value?.zona]?.tipo === 'esterno',
  meteo: store.meteo,
  programmaAutomatico: programmaIrrigazioneEffettivo(route.params.id, pianta.value?.zona, store.programmiIrrigazione)?.ogniGiorni ?? null,
}))
```

- [ ] **Step 5: `AttivitaView.vue`**

In `src/views/AttivitaView.vue`, aggiungere l'import dopo `import Spinner from '@/components/Spinner.vue'` (o accanto agli altri import di composable):

```js
import { programmaIrrigazioneEffettivo } from '@/composables/useIrrigazioneAuto'
```

Sostituire:

```js
    const contesto = { ...contestoMeteo, esterno: store.zone?.[p.zona]?.tipo === 'esterno' }
```

con:

```js
    const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, store.programmiIrrigazione)?.ogniGiorni ?? null
    const contesto = { ...contestoMeteo, esterno: store.zone?.[p.zona]?.tipo === 'esterno', programmaAutomatico }
```

- [ ] **Step 6: `HomeView.vue`**

In `src/views/HomeView.vue`, aggiungere l'import dopo `import { iconaCura } from '@/composables/useCureVisual'`:

```js
import { programmaIrrigazioneEffettivo } from '@/composables/useIrrigazioneAuto'
```

Sostituire:

```js
function contestoPianta(p) {
  return { meteo: store.meteo, esterno: store.zone?.[p.zona]?.tipo === 'esterno' }
}
```

con:

```js
function contestoPianta(p, id) {
  const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, store.programmiIrrigazione)?.ogniGiorni ?? null
  return { meteo: store.meteo, esterno: store.zone?.[p.zona]?.tipo === 'esterno', programmaAutomatico }
}
```

Poi aggiornare i due punti che la chiamano. Sostituire:

```js
  for (const [, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie] ?? null
    if (cureUrgentiPianta(p, sp, contestoPianta(p)).length > 0) count++
  }
```

con:

```js
  for (const [id, p] of Object.entries(store.piante)) {
    const sp = store.specie?.[p.specie] ?? null
    if (cureUrgentiPianta(p, sp, contestoPianta(p, id)).length > 0) count++
  }
```

E sostituire, nel computed `daFareOggi`:

```js
    const contesto = contestoPianta(p)
```

con:

```js
    const contesto = contestoPianta(p, id)
```

(quest'ultimo blocco è già dentro un `for (const [id, p] of Object.entries(store.piante))`: solo l'argomento cambia.)

- [ ] **Step 7: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 8: Verifica manuale nel browser (senza ancora un programma configurato)**

Avvia `npm run dev`, apri Home, Attività, Piante e la scheda di una pianta qualsiasi: con `programmi_irrigazione` ancora vuota il comportamento delle urgenze deve essere **identico a prima di questo piano** (nessuna riga sparita, nessuna label cambiata) — è la verifica che lo short-circuit di Task 4 non scatta mai senza un programma attivo.

- [ ] **Step 9: Commit**

```bash
git add src/components/PiantaRiga.vue src/components/DossierPianta.vue src/views/AttivitaView.vue src/views/PiantaView.vue src/views/PianteView.vue src/views/HomeView.vue
git commit -m "$(cat <<'EOF'
Propaga programmaAutomatico ai 6 punti che valutano l'urgenza irrigazione

Home, Attività, Piante, PiantaRiga, scheda pianta e dossier risolvono ora
la cascata giardino/zona/pianta (useIrrigazioneAuto) e la passano nel
contesto già esistente di valutaCura/cureUrgentiPianta — nessuna riga
resta a mostrare un'urgenza da specie per una pianta coperta da automatico.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```

---

### Task 6: CRUD dei programmi (`useIrrigazioneApi.js`)

**Files:**
- Create: `src/composables/useIrrigazioneApi.js`

**Interfaces:**
- Consuma: `store.programmiIrrigazione`, `store.zone` (Task 2), tabella `programmi_irrigazione` (Task 1).
- Produce: `salvaProgramma(target, ogniGiorni)` e `rimuoviProgramma(target)`, dove `target` è `'giardino'`, `{ zona: nomeZona }` o `{ pianta: piantaId }` — consumate da Task 7.

- [ ] **Step 1: Scrivere il composable**

Crea `src/composables/useIrrigazioneApi.js`:

```js
// CRUD dei programmi di irrigazione automatica (tabella
// programmi_irrigazione). A differenza di usePianteApi.js non fa mai
// upsert: gli indici unique sono uno per livello (vedi la migration), e
// PostgREST non sa abbinare un ON CONFLICT a un indice unique parziale —
// un insert/update esplicito in base all'id già noto (o assente) resta più
// semplice e chiaro.
import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'

// target: 'giardino' | { zona: nomeZona } | { pianta: piantaId }
function chiaviTarget(target) {
  if (target === 'giardino') return { chiave: 'giardino', chiaveVoce: null }
  if (target.zona) return { chiave: 'zone', chiaveVoce: target.zona }
  return { chiave: 'piante', chiaveVoce: target.pianta }
}

export function useIrrigazioneApi() {
  const store = useDatiStore()
  const supabase = useSupabase()

  function programmaEsistente(chiave, chiaveVoce) {
    return chiave === 'giardino'
      ? store.programmiIrrigazione?.giardino ?? null
      : store.programmiIrrigazione?.[chiave]?.[chiaveVoce] ?? null
  }

  function patchStore(chiave, chiaveVoce, voce) {
    if (chiave === 'giardino') {
      store.programmiIrrigazione = { ...store.programmiIrrigazione, giardino: voce }
      return
    }
    const copia = { ...store.programmiIrrigazione[chiave] }
    if (voce) copia[chiaveVoce] = voce
    else delete copia[chiaveVoce]
    store.programmiIrrigazione = { ...store.programmiIrrigazione, [chiave]: copia }
  }

  async function salvaProgramma(target, ogniGiorni) {
    const { chiave, chiaveVoce } = chiaviTarget(target)
    const esistente = programmaEsistente(chiave, chiaveVoce)

    const riga = {
      zona_id: target !== 'giardino' && target.zona ? (store.zone?.[target.zona]?.id ?? null) : null,
      pianta_id: target !== 'giardino' && target.pianta ? target.pianta : null,
      ogni_giorni: ogniGiorni,
    }

    let id = esistente?.id ?? null
    if (id) {
      const { error } = await supabase.from('programmi_irrigazione').update(riga).eq('id', id)
      if (error) throw error
    } else {
      const { data, error } = await supabase.from('programmi_irrigazione').insert(riga).select().single()
      if (error) throw error
      id = data.id
    }

    patchStore(chiave, chiaveVoce, { id, ogniGiorni })
  }

  async function rimuoviProgramma(target) {
    const { chiave, chiaveVoce } = chiaviTarget(target)
    const esistente = programmaEsistente(chiave, chiaveVoce)
    if (!esistente) return

    const { error } = await supabase.from('programmi_irrigazione').delete().eq('id', esistente.id)
    if (error) throw error

    patchStore(chiave, chiaveVoce, null)
  }

  return { salvaProgramma, rimuoviProgramma }
}
```

- [ ] **Step 2: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 3: Commit**

```bash
git add src/composables/useIrrigazioneApi.js
git commit -m "$(cat <<'EOF'
Aggiunge useIrrigazioneApi: CRUD dei programmi di irrigazione automatica

salvaProgramma/rimuoviProgramma scrivono su programmi_irrigazione e
aggiornano lo store in locale, stesso pattern di usePianteApi.js — insert
o update espliciti in base all'id già noto, mai upsert (gli indici unique
sono parziali, uno per livello).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```

---

### Task 7: Vista di gestione (`IrrigazioneView.vue`) + accesso da Impostazioni

**Files:**
- Create: `src/views/IrrigazioneView.vue`
- Modify: `src/router/index.js`
- Modify: `src/views/SettingsView.vue`

**Interfaces:**
- Consuma: `useIrrigazioneApi` (Task 6), `store.programmiIrrigazione`/`store.zone`/`store.piante`/`store.specie` (store esistente + Task 2), `FoglioLaterale.vue` (esistente).
- Produce: route `/impostazioni/irrigazione`, nessuna interfaccia consumata da altri task.

- [ ] **Step 1: Route**

In `src/router/index.js`, aggiungere subito dopo la riga `{ path: '/impostazioni', ... }`:

```js
  { path: '/impostazioni',              name: 'impostazioni',   component: () => import('@/views/SettingsView.vue') },
  { path: '/impostazioni/irrigazione',  name: 'irrigazione',    component: () => import('@/views/IrrigazioneView.vue') },
```

- [ ] **Step 2: Link da Impostazioni**

In `src/views/SettingsView.vue`, nel `<template>`, subito prima del blocco `<p v-if="errore" ...>` (cioè dopo l'ultimo `<div class="form-card">`, prima del bottone "Salva"), aggiungere:

```html
    <RouterLink to="/impostazioni/irrigazione" class="form-card" style="display:flex;align-items:center;justify-content:space-between;margin-bottom:12px;text-decoration:none;color:inherit;">
      <span style="font-size:13px;font-weight:600;"><Icon name="goccia" style="width:14px;height:14px;vertical-align:-2px;margin-right:6px;color:var(--acqua);" />Irrigazione automatica</span>
      <Icon name="back" style="width:14px;height:14px;flex-shrink:0;color:var(--ink-faint);transform:rotate(180deg);" />
    </RouterLink>
```

(stesso pattern del link "Impostazioni giardino" in `src/views/AccountView.vue`.)

- [ ] **Step 3: Scrivere la vista**

Crea `src/views/IrrigazioneView.vue`:

```vue
<template>
  <div>
    <div class="page-title__row">
      <h1 class="page-title">Irrigazione automatica</h1>
    </div>
    <p class="prose" style="margin:-6px 0 20px;">
      Imposta un programma "ogni N giorni" per tutto il giardino, per una zona o per una singola pianta. Le piante coperte da un programma attivo non compaiono più tra le cure da fare a mano — la pioggia prevista continua comunque a sospenderlo.
    </p>

    <div v-if="store.loading" class="destlist">
      <div v-for="i in 4" :key="i" class="dest">
        <div class="skeleton dest__ic" style="border-radius:50%;"></div>
        <div class="skeleton" style="height:13px;flex:1;max-width:160px;border-radius:6px;"></div>
      </div>
    </div>

    <div v-else class="destlist">
      <div class="dest">
        <Icon name="goccia" class="dest__ic" style="color:var(--acqua);" />
        <span class="dest__n">Tutto il giardino</span>
        <span v-if="programmaGiardino" class="badge badge-ok">ogni {{ programmaGiardino.ogniGiorni }} gg</span>
        <span v-else class="dest__c" style="color:var(--ink-soft);">nessun programma</span>
        <button type="button" class="pill-mini" @click="apriModifica('giardino', 'Tutto il giardino', programmaGiardino?.ogniGiorni)" aria-label="Modifica programma giardino">
          <Icon name="matita" />
        </button>
        <button v-if="programmaGiardino" type="button" class="pill-mini pill-mini--del" @click="rimuovi('giardino')" aria-label="Rimuovi programma giardino">×</button>
      </div>

      <template v-for="z in zoneList" :key="z.nome">
        <div class="dest" style="cursor:pointer;" @click="toggleZona(z.nome)">
          <Icon :name="store.iconaZona(z.nome)" class="dest__ic" />
          <span class="dest__n">{{ z.nome }}</span>
          <span v-if="programmaZona(z.nome)" class="badge badge-ok">ogni {{ programmaZona(z.nome).ogniGiorni }} gg</span>
          <span v-else class="dest__c" style="color:var(--ink-soft);">{{ ereditaTesto(programmaGiardino) }}</span>
          <button type="button" class="pill-mini" @click.stop="apriModifica({ zona: z.nome }, z.nome, programmaZona(z.nome)?.ogniGiorni)" aria-label="Modifica programma zona">
            <Icon name="matita" />
          </button>
          <button v-if="programmaZona(z.nome)" type="button" class="pill-mini pill-mini--del" @click.stop="rimuovi({ zona: z.nome })" aria-label="Rimuovi programma zona">×</button>
          <Icon name="back" class="dest__chev" :style="{ transform: espanse.has(z.nome) ? 'rotate(-90deg)' : 'rotate(90deg)' }" />
        </div>
        <div v-if="espanse.has(z.nome)" class="destlist" style="padding-left:30px;">
          <div v-for="p in pianteDellaZona(z.nome)" :key="p.id" class="dest">
            <span class="dest__n">{{ nomeSpecie(p) }}<span v-if="p.varieta"> — {{ p.varieta }}</span></span>
            <span v-if="programmaPianta(p.id)" class="badge badge-ok">ogni {{ programmaPianta(p.id).ogniGiorni }} gg</span>
            <span v-else class="dest__c" style="color:var(--ink-soft);">{{ ereditaTesto(programmaEffettivoZona(z.nome)) }}</span>
            <button type="button" class="pill-mini" @click="apriModifica({ pianta: p.id }, nomeSpecie(p), programmaPianta(p.id)?.ogniGiorni)" aria-label="Modifica programma pianta">
              <Icon name="matita" />
            </button>
            <button v-if="programmaPianta(p.id)" type="button" class="pill-mini pill-mini--del" @click="rimuovi({ pianta: p.id })" aria-label="Rimuovi programma pianta">×</button>
          </div>
          <p v-if="!pianteDellaZona(z.nome).length" style="font-size:12px;color:var(--ink-soft);padding:10px 2px;">Nessuna pianta in questa zona.</p>
        </div>
      </template>

      <p v-if="!zoneList.length" style="font-size:12px;color:var(--ink-soft);padding:10px 2px;">Nessuna zona configurata.</p>
    </div>

    <FoglioLaterale :model-value="mostraForm" @update:model-value="v => { if (!v) chiudiForm() }" :titolo="titoloForm">
      <div v-if="mostraForm" class="foglio-form">
        <label class="field-label" for="irr-giorni">Ogni quanti giorni</label>
        <input id="irr-giorni" v-model.number="giorniForm" type="number" min="1" step="1" class="form-input" style="margin-bottom:8px;">
        <p v-if="errore" role="alert" style="font-size:11px;color:var(--rose-ink);margin:0 0 10px;">{{ errore }}</p>
        <div class="foglio-actions">
          <button type="button" class="btn btn-ghost" @click="chiudiForm" style="min-height:40px;padding:8px 16px;">Annulla</button>
          <button type="button" class="btn btn-sage" @click="salva" :disabled="!giorniForm || giorniForm < 1 || salvando" style="min-height:40px;padding:8px 16px;">
            <Spinner v-if="salvando" /><span v-else>Salva</span>
          </button>
        </div>
      </div>
    </FoglioLaterale>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useIrrigazioneApi } from '@/composables/useIrrigazioneApi'
import FoglioLaterale from '@/components/FoglioLaterale.vue'
import Spinner from '@/components/Spinner.vue'
import Icon from '@/components/Icon.vue'

const store = useDatiStore()
const irrigazioneApi = useIrrigazioneApi()

onMounted(() => store.caricaTutto())

const zoneList = computed(() => Object.values(store.zone ?? {}))
const piante = computed(() => Object.entries(store.piante ?? {}).map(([id, p]) => ({ id, ...p })))

function pianteDellaZona(nomeZona) {
  return piante.value.filter(p => p.zona === nomeZona)
}
function nomeSpecie(p) {
  return store.specie?.[p.specie]?.nome ?? p.specie
}

const programmaGiardino = computed(() => store.programmiIrrigazione?.giardino ?? null)
function programmaZona(nome) { return store.programmiIrrigazione?.zone?.[nome] ?? null }
function programmaPianta(id) { return store.programmiIrrigazione?.piante?.[id] ?? null }

// Cosa vince davvero per una zona/pianta senza programma proprio, secondo
// la stessa cascata di useIrrigazioneAuto.js — qui espansa a mano perché la
// vista deve mostrare l'eredità anche quando manca il livello intermedio.
function programmaEffettivoZona(nome) {
  return programmaZona(nome) ?? programmaGiardino.value
}
function ereditaTesto(effettivo) {
  return effettivo ? `eredita: ogni ${effettivo.ogniGiorni} gg` : 'nessun programma'
}

const espanse = ref(new Set())
function toggleZona(nome) {
  const copia = new Set(espanse.value)
  copia.has(nome) ? copia.delete(nome) : copia.add(nome)
  espanse.value = copia
}

const mostraForm = ref(false)
const targetForm = ref(null)
const titoloForm = ref('')
const giorniForm = ref(null)
const salvando = ref(false)
const errore = ref(null)

function apriModifica(target, titolo, valoreAttuale) {
  targetForm.value = target
  titoloForm.value = titolo
  giorniForm.value = valoreAttuale ?? null
  errore.value = null
  mostraForm.value = true
}
function chiudiForm() {
  mostraForm.value = false
  targetForm.value = null
}
async function salva() {
  if (!giorniForm.value || giorniForm.value < 1 || !targetForm.value) return
  salvando.value = true
  errore.value = null
  try {
    await irrigazioneApi.salvaProgramma(targetForm.value, giorniForm.value)
    chiudiForm()
  } catch (e) {
    errore.value = 'Salvataggio non riuscito. Riprova.'
  } finally {
    salvando.value = false
  }
}
async function rimuovi(target) {
  await irrigazioneApi.rimuoviProgramma(target)
}
</script>
```

- [ ] **Step 4: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 5: Verifica manuale nel browser (percorso completo)**

Con `npm run dev` avviato e sessione autenticata:

1. Apri `/impostazioni` → il link "Irrigazione automatica" porta a `/impostazioni/irrigazione`.
2. Imposta un programma "ogni 7 giorni" per "Tutto il giardino" → badge "ogni 7 gg" compare sulla riga giardino; ricarica la pagina e verifica che il valore resti (letto da Supabase, non solo in memoria).
3. Espandi una zona con piante → ogni pianta mostra "eredita: ogni 7 gg".
4. Imposta un programma diverso (es. "ogni 2 giorni") su quella zona → il badge compare sulla zona; le piante di quella zona ora mostrano "eredita: ogni 2 gg" (non più 7).
5. Imposta un programma su una singola pianta di quella zona (es. "ogni 1 giorno") → solo quella pianta mostra il proprio badge, le altre restano su "eredita: ogni 2 gg".
6. Vai su Home/Attività/Piante/scheda della pianta modificata al punto 5: la riga "irrigazione" per quella pianta non compare più tra le urgenze anche se `ultima_cura.irrigazione` è vecchia o assente (usa una pianta di test se necessario); nella sua scheda (`/piante/:id`) lo stato cure per irrigazione mostra "irrigazione — automatica (ogni 1 gg)" invece del calcolo da specie.
7. Rimuovi il programma della pianta (×) → la scheda pianta torna a mostrare l'urgenza calcolata da specie/stagione come prima.
8. Se il meteo di oggi/domani prevede pioggia ≥ 5mm (controllabile da `/meteo`), verifica che una pianta automatica esterna mostri "irrigazione — pioggia prevista, salta" invece del programma.

- [ ] **Step 6: Commit**

```bash
git add src/views/IrrigazioneView.vue src/router/index.js src/views/SettingsView.vue
git commit -m "$(cat <<'EOF'
Aggiunge la vista di gestione dell'irrigazione automatica

Nuova pagina /impostazioni/irrigazione con l'albero giardino → zone →
piante: ogni livello mostra il proprio programma o cosa eredita, e si
modifica/rimuove dal Foglio laterale esistente. Link da Impostazioni,
stesso pattern del link "Impostazioni giardino" in AccountView.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```

---

## Dopo l'esecuzione

Questo piano costruisce la funzionalità end-to-end ma non passa per una critica UX dedicata: coerente con l'abitudine recente di questo progetto (vedi i commit "critica impeccable" su Attività/Progetti/Account/Modifica pianta), vale la pena eseguire `/impeccable critique` su `IrrigazioneView.vue` una volta mergiato, prima di considerarlo rifinito allo stesso livello del resto dell'app.
