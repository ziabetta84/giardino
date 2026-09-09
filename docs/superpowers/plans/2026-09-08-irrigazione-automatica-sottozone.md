# Irrigazione automatica — livello sottozona — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Inserire il livello sottozona nella cascata di irrigazione automatica, tra zona e pianta: giardino → zona → sottozona → pianta, con una sottozona che eredita dalla propria zona se priva di programma proprio, e una pianta che eredita dalla propria sottozona (se ne ha una) prima di ricadere sulla zona.

**Architecture:** Addendum al piano `2026-09-08-irrigazione-automatica.md` (già implementato, mergiato su questo stesso branch, revisione finale già chiusa). Aggiunge una colonna `sottozona_id` alla tabella esistente; lo store rappresenta i programmi di sottozona in una mappa piatta con chiave composta `"<zona>|<sottozona>"` (stesso separatore già usato da `raggruppaAttivita.js` per lo stesso tipo di ambiguità — nomi di sottozona unici solo dentro la propria zona, non globalmente); il resolver guadagna un quarto parametro posizionale (`sottozonaNome`) inserito tra `zonaNome` e `programmi`; i 6 punti dell'app che già chiamano il resolver (Fase 1) vengono aggiornati per passare `pianta.sottozona`; `useIrrigazioneApi.js` guadagna un ramo `chiaviTarget` per `{ zona, sottozona }`, che si appoggia al meccanismo generico già esistente (nessun cambiamento a `patchStore`); `IrrigazioneView.vue` guadagna un livello di albero annidato tra zona e pianta.

**Tech Stack:** Vue 3 `<script setup>` SFC, Vite, Supabase JS client + Postgres/RLS, Pinia. Nessun runner di test in questo progetto.

**Spec:** nessuna spec formale — richiesta dell'utente in chat l'8 settembre 2026, dopo la revisione finale della Fase 1 (`2026-09-08-irrigazione-automatica.md`, già chiusa pulita). Vincolo su Supabase verificato dal vivo prima di scrivere questo piano (`select conname, pg_get_constraintdef(oid) from pg_constraint where conrelid = 'programmi_irrigazione'::regclass`): il check di mutua esclusione si chiama `programmi_irrigazione_check`.

## Global Constraints

- **Lingua:** testi UI, commenti e messaggi di commit in italiano.
- **Nessun framework di test in questo repo.** Verifica automatica = solo `npm run build` (exit 0). Per le funzioni pure, script Node usa-e-getta con import relativo, eseguito e poi cancellato (stesso pattern della Fase 1).
- **Nessuna riga esistente in `programmi_irrigazione` da migrare**: la tabella ha 0 righe in produzione (verificato durante la revisione finale della Fase 1) — la migration è puramente additiva, nessun backfill necessario.
- **Chiave composta `"<zona>|<sottozona>"`**: stesso separatore `|` già usato da `raggruppaPerZona` in `src/utils/raggruppaAttivita.js` — non inventarne uno diverso.
- **`useCure.js` non cambia**: opera solo sul valore numerico risolto (`contesto.programmaAutomatico`), indipendentemente da quale livello della cascata l'ha prodotto.
- **Progetto Supabase:** `ncuhhsvtjwcolhpdxbkt`. Usa `mcp__plugin_supabase_supabase__apply_migration` / `execute_sql`.
- **Branch:** `irrigazione-automatica` (stesso della Fase 1, non ancora mergiato). Nessun commit diretto su `main`.
- **Commit:** italiano, footer:
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
  ```

---

## File Structure

| File | Modifica |
|------|----------|
| `supabase/migrations/20260908010000_programmi_irrigazione_sottozona.sql` | **Crea** — colonna `sottozona_id`, check di mutua esclusione a 3 vie, unique su `sottozona_id`. |
| `src/stores/dati.js` | **Modifica** — `mappaProgrammiIrrigazione` guadagna il bucket `sottozone` (chiave composta); `eseguiCaricamento` costruisce la mappa id→{zonaNome,nome} necessaria e la passa. |
| `src/composables/useIrrigazioneAuto.js` | **Modifica** — `programmaIrrigazioneEffettivo` guadagna il parametro `sottozonaNome` e il gradino "sottozona" nella cascata. |
| `src/components/PiantaRiga.vue`, `src/views/PianteView.vue`, `src/components/DossierPianta.vue`, `src/views/PiantaView.vue`, `src/views/AttivitaView.vue`, `src/views/HomeView.vue` | **Modifica** — ogni chiamata al resolver guadagna l'argomento `sottozona` (già disponibile su ogni pianta). |
| `src/composables/useIrrigazioneApi.js` | **Modifica** — `chiaviTarget` riconosce `{ zona, sottozona }`; `salvaProgramma` valorizza `sottozona_id` invece di `zona_id` quando presente. |
| `src/views/IrrigazioneView.vue` | **Modifica** — livello sottozona nell'albero, tra zona e pianta. |

Nessun file di test.

---

### Task 1: Colonna `sottozona_id`

**Files:**
- Create: `supabase/migrations/20260908010000_programmi_irrigazione_sottozona.sql`

**Interfaces:**
- Produce: colonna `programmi_irrigazione.sottozona_id`, consumata da Task 2 (store) e Task 4 (API).

- [ ] **Step 1: Verificare il branch**

```bash
git branch --show-current
```

Expected: `irrigazione-automatica`. Questo lavoro continua sullo stesso branch della Fase 1 (non mergiata).

- [ ] **Step 2: Scrivere la migration**

Crea `supabase/migrations/20260908010000_programmi_irrigazione_sottozona.sql`:

```sql
-- Aggiunge il livello sottozona alla cascata di irrigazione automatica
-- (giardino → zona → sottozona → pianta), tra zona e pianta. Una riga può
-- avere sottozona_id valorizzato invece di zona_id (una sottozona implica
-- già una zona tramite la FK di sottozone → zone), mai insieme a zona_id
-- o pianta_id — check a 3 vie invece del precedente a 2.
alter table programmi_irrigazione
  add column sottozona_id uuid references sottozone(id) on delete cascade;

alter table programmi_irrigazione
  drop constraint programmi_irrigazione_check;

alter table programmi_irrigazione
  add constraint programmi_irrigazione_check
    check (num_nonnulls(zona_id, sottozona_id, pianta_id) <= 1);

alter table programmi_irrigazione
  add constraint programmi_irrigazione_sottozona_id_key unique (sottozona_id);
```

- [ ] **Step 3: Applicare la migration**

Chiama `mcp__plugin_supabase_supabase__apply_migration` con `project_id: "ncuhhsvtjwcolhpdxbkt"`, `name: "programmi_irrigazione_sottozona"`, `query`: il contenuto del file.

- [ ] **Step 4: Verificare**

Chiama `mcp__plugin_supabase_supabase__execute_sql` con `project_id: "ncuhhsvtjwcolhpdxbkt"`, query:
```sql
select conname, pg_get_constraintdef(oid) from pg_constraint where conrelid = 'programmi_irrigazione'::regclass order by conname;
```
Expected: `programmi_irrigazione_check` ora legge `CHECK ((num_nonnulls(zona_id, sottozona_id, pianta_id) <= 1))`; presente `programmi_irrigazione_sottozona_id_key` come `UNIQUE (sottozona_id)`; la colonna `sottozona_id` esiste (verificabile anche con `list_tables`).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260908010000_programmi_irrigazione_sottozona.sql
git commit -m "$(cat <<'EOF'
Aggiunge sottozona_id a programmi_irrigazione per il livello sottozona

Cascata estesa a giardino → zona → sottozona → pianta: check di mutua
esclusione a 3 vie (num_nonnulls <= 1) invece del precedente a 2 colonne.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```

---

### Task 2: Store + resolver

**Files:**
- Modify: `src/stores/dati.js`
- Modify: `src/composables/useIrrigazioneAuto.js`

**Interfaces:**
- Consuma: colonna `sottozona_id` (Task 1).
- Produce: `store.programmiIrrigazione.sottozone` = `{ "<zonaNome>|<sottozonaNome>": {id, ogniGiorni} }`; `programmaIrrigazioneEffettivo(piantaId, zonaNome, sottozonaNome, programmi)` (firma cambiata: nuovo 3° parametro posizionale, `programmi` ora è il 4°) — consumata da Task 3 (i 6 call site) e Task 5 (vista).

Questi due file cambiano insieme perché sono la stessa decisione di forma dati: un reviewer non potrebbe approvare l'uno senza l'altro.

- [ ] **Step 1: `dati.js` — mapping**

In `src/stores/dati.js`, la funzione `mappaProgrammiIrrigazione` (attualmente):

```js
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

diventa (nuovo parametro `sottozonaInfoPerId`, nuovo ramo, controllato PRIMA di `zona_id`):

```js
export function mappaProgrammiIrrigazione(righeProgrammi, zonaNomePerId, sottozonaInfoPerId) {
  const risultato = { giardino: null, zone: {}, sottozone: {}, piante: {} }
  for (const r of righeProgrammi) {
    const voce = { id: r.id, ogniGiorni: r.ogni_giorni }
    if (r.pianta_id) {
      risultato.piante[r.pianta_id] = voce
    } else if (r.sottozona_id) {
      const info = sottozonaInfoPerId[r.sottozona_id]
      if (info?.zonaNome) risultato.sottozone[`${info.zonaNome}|${info.nome}`] = voce
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

- [ ] **Step 2: `dati.js` — costruire `sottozonaInfoPerId` e passarlo**

Nello stesso file, dentro `eseguiCaricamento()`, subito dopo la riga esistente:

```js
      const sottozonaNomePerId = Object.fromEntries(righeSottozone.map(s => [s.id, s.nome]))
```

aggiungere:

```js
      const sottozonaInfoPerId = Object.fromEntries(righeSottozone.map(s => [s.id, { zonaNome: zonaNomePerId[s.zona_id], nome: s.nome }]))
```

E sostituire la chiamata esistente:

```js
      programmiIrrigazione.value = mappaProgrammiIrrigazione(righeProgrammiIrrigazione, zonaNomePerId)
```

con:

```js
      programmiIrrigazione.value = mappaProgrammiIrrigazione(righeProgrammiIrrigazione, zonaNomePerId, sottozonaInfoPerId)
```

- [ ] **Step 3: `useIrrigazioneAuto.js` — resolver**

Sostituire l'intero contenuto di `src/composables/useIrrigazioneAuto.js`:

```js
// Risoluzione della cascata giardino → zona → sottozona → pianta per
// l'irrigazione automatica: la pianta vince se ha un programma proprio,
// poi la sua sottozona (se ne ha una), poi la sua zona, poi il default
// dell'intero giardino. null quando nessun livello ha un programma — in
// quel caso l'irrigazione resta valutata da specie/stagione come prima di
// questa funzionalità (vedi useCure.js).
export function programmaIrrigazioneEffettivo(piantaId, zonaNome, sottozonaNome, programmi) {
  if (!programmi) return null
  if (programmi.piante?.[piantaId]) return { ...programmi.piante[piantaId], livello: 'pianta' }
  if (zonaNome && sottozonaNome && programmi.sottozone?.[`${zonaNome}|${sottozonaNome}`]) {
    return { ...programmi.sottozone[`${zonaNome}|${sottozonaNome}`], livello: 'sottozona' }
  }
  if (zonaNome && programmi.zone?.[zonaNome]) return { ...programmi.zone[zonaNome], livello: 'zona' }
  if (programmi.giardino) return { ...programmi.giardino, livello: 'giardino' }
  return null
}
```

Nota: questo cambia la firma della funzione (3° parametro nuovo, `programmi` passa da 3° a 4°). Il Task 3 aggiorna tutti i chiamanti esistenti — finché non lo fa, l'app ha chiamate con firma sbagliata (il vecchio `programmi` finirebbe nel nuovo slot `sottozonaNome`, e `programmi` sarebbe `undefined`): è previsto, i Task 2 e 3 vanno eseguiti in sequenza sullo stesso branch, non in parallelo.

- [ ] **Step 4: Build**

Run: `npm run build`
Expected: exit 0 (il build non tipizza gli argomenti, quindi non fallisce per la firma cambiata — è solo un difetto runtime finché il Task 3 non chiude il cerchio; annotalo nel report ma non bloccarti).

- [ ] **Step 5: Verifica di lettura rapida (senza framework di test)**

Script Node temporaneo nella stessa cartella (`src/composables/verifica-resolver-sottozona.tmp.mjs`), import relativo, poi cancellato:

```js
import assert from 'node:assert'
import { programmaIrrigazioneEffettivo } from './useIrrigazioneAuto.js'

const programmi = {
  giardino: { id: 'g', ogniGiorni: 7 },
  zone: { Est: { id: 'z', ogniGiorni: 3 } },
  sottozone: { 'Est|Aiuola': { id: 'sz', ogniGiorni: 1 } },
  piante: { p1: { id: 'p', ogniGiorni: 5 } },
}

// pianta vince su tutto
assert.deepStrictEqual(programmaIrrigazioneEffettivo('p1', 'Est', 'Aiuola', programmi), { id: 'p', ogniGiorni: 5, livello: 'pianta' })
// sottozona vince su zona
assert.deepStrictEqual(programmaIrrigazioneEffettivo('p2', 'Est', 'Aiuola', programmi), { id: 'sz', ogniGiorni: 1, livello: 'sottozona' })
// senza sottozona (pianta direttamente in zona), cade sulla zona
assert.deepStrictEqual(programmaIrrigazioneEffettivo('p2', 'Est', null, programmi), { id: 'z', ogniGiorni: 3, livello: 'zona' })
// sottozona diversa non configurata, cade sulla zona
assert.deepStrictEqual(programmaIrrigazioneEffettivo('p2', 'Est', 'AltraSottozona', programmi), { id: 'z', ogniGiorni: 3, livello: 'zona' })
// zona diversa senza programma proprio, cade sul giardino
assert.deepStrictEqual(programmaIrrigazioneEffettivo('p2', 'Ovest', null, programmi), { id: 'g', ogniGiorni: 7, livello: 'giardino' })
// niente di niente
assert.strictEqual(programmaIrrigazioneEffettivo('p2', 'Ovest', null, { giardino: null, zone: {}, sottozone: {}, piante: {} }), null)

console.log('OK')
```

Run: `node src/composables/verifica-resolver-sottozona.tmp.mjs`
Expected: stampa `OK`. Poi cancella il file (`rm src/composables/verifica-resolver-sottozona.tmp.mjs`) — non va committato.

- [ ] **Step 6: Commit**

```bash
git add src/stores/dati.js src/composables/useIrrigazioneAuto.js
git commit -m "$(cat <<'EOF'
Store e resolver: aggiungono il livello sottozona alla cascata

mappaProgrammiIrrigazione popola un bucket "sottozone" a chiave composta
"<zona>|<sottozona>" (stesso separatore di raggruppaAttivita.js);
programmaIrrigazioneEffettivo guadagna il parametro sottozonaNome e il
gradino sottozona tra zona e pianta. I chiamanti si aggiornano nel
prossimo commit sullo stesso branch.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```

---

### Task 3: Aggiornare i 6 chiamanti del resolver

**Files:**
- Modify: `src/components/PiantaRiga.vue`
- Modify: `src/views/PianteView.vue`
- Modify: `src/components/DossierPianta.vue`
- Modify: `src/views/PiantaView.vue`
- Modify: `src/views/AttivitaView.vue`
- Modify: `src/views/HomeView.vue`

**Interfaces:**
- Consuma: `programmaIrrigazioneEffettivo(piantaId, zonaNome, sottozonaNome, programmi)` (Task 2, nuova firma a 4 argomenti).
- Produce: nessuna interfaccia nuova per altri task — chiude il collegamento aperto dal Task 2.

Ogni pianta nello store porta già il campo `sottozona` (`null` se non assegnata) — vedi `mappaPiante` in `dati.js`. Il cambiamento in ognuno dei 6 file è: inserire l'argomento `sottozona` tra `zona` e `store.programmiIrrigazione` nella chiamata già esistente.

- [ ] **Step 1: `PiantaRiga.vue`**

Sostituire:

```js
const programmaAutomatico = computed(() =>
  programmaIrrigazioneEffettivo(props.pianta.id, props.pianta.zona, store.programmiIrrigazione)?.ogniGiorni ?? null
)
```

con:

```js
const programmaAutomatico = computed(() =>
  programmaIrrigazioneEffettivo(props.pianta.id, props.pianta.zona, props.pianta.sottozona, store.programmiIrrigazione)?.ogniGiorni ?? null
)
```

- [ ] **Step 2: `PianteView.vue`**

Sostituire:

```js
    const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, store.programmiIrrigazione)?.ogniGiorni ?? null
```

con:

```js
    const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, p.sottozona, store.programmiIrrigazione)?.ogniGiorni ?? null
```

- [ ] **Step 3: `DossierPianta.vue`**

Sostituire:

```js
  programmaAutomatico: programmaIrrigazioneEffettivo(props.piantaId, pianta.value?.zona, store.programmiIrrigazione)?.ogniGiorni ?? null,
```

con:

```js
  programmaAutomatico: programmaIrrigazioneEffettivo(props.piantaId, pianta.value?.zona, pianta.value?.sottozona, store.programmiIrrigazione)?.ogniGiorni ?? null,
```

- [ ] **Step 4: `PiantaView.vue`**

Sostituire:

```js
  programmaAutomatico: programmaIrrigazioneEffettivo(route.params.id, pianta.value?.zona, store.programmiIrrigazione)?.ogniGiorni ?? null,
```

con:

```js
  programmaAutomatico: programmaIrrigazioneEffettivo(route.params.id, pianta.value?.zona, pianta.value?.sottozona, store.programmiIrrigazione)?.ogniGiorni ?? null,
```

- [ ] **Step 5: `AttivitaView.vue`**

Sostituire:

```js
    const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, store.programmiIrrigazione)?.ogniGiorni ?? null
```

con:

```js
    const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, p.sottozona, store.programmiIrrigazione)?.ogniGiorni ?? null
```

- [ ] **Step 6: `HomeView.vue`**

Sostituire:

```js
  const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, store.programmiIrrigazione)?.ogniGiorni ?? null
```

con:

```js
  const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, p.sottozona, store.programmiIrrigazione)?.ogniGiorni ?? null
```

(questa riga vive dentro `contestoPianta(p, id)`, già aggiornata nella Fase 1 — nessun altro cambiamento a quella funzione.)

- [ ] **Step 7: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 8: Verifica manuale nel browser (comportamento invariato senza sottozone configurate)**

Con `programmi_irrigazione` ancora priva di righe a livello sottozona (0 righe in produzione), tutte le urgenze devono comportarsi come prima di questo task in tutte le viste (Home, Attività, Piante, scheda pianta) — stessa verifica di non-regressione già fatta nella Fase 1.

- [ ] **Step 9: Commit**

```bash
git add src/components/PiantaRiga.vue src/views/PianteView.vue src/components/DossierPianta.vue src/views/PiantaView.vue src/views/AttivitaView.vue src/views/HomeView.vue
git commit -m "$(cat <<'EOF'
Passa sottozona ai 6 punti che risolvono il programma di irrigazione

Chiude il collegamento aperto dal commit precedente: ogni chiamante di
programmaIrrigazioneEffettivo passa ora anche pianta.sottozona, così una
pianta può ereditare dal programma della propria sottozona prima di
ricadere sulla zona.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```

---

### Task 4: `useIrrigazioneApi.js` — supporto sottozona

**Files:**
- Modify: `src/composables/useIrrigazioneApi.js`

**Interfaces:**
- Consuma: colonna `sottozona_id` (Task 1); `store.sottozone[zona][sottozona].id` (store esistente, invariato).
- Produce: `salvaProgramma`/`rimuoviProgramma` accettano anche `target = { zona, sottozona }`, consumato da Task 5.

- [ ] **Step 1: `chiaviTarget` — nuovo ramo**

Sostituire:

```js
// target: 'giardino' | { zona: nomeZona } | { pianta: piantaId }
function chiaviTarget(target) {
  if (target === 'giardino') return { chiave: 'giardino', chiaveVoce: null }
  if (target.zona) return { chiave: 'zone', chiaveVoce: target.zona }
  return { chiave: 'piante', chiaveVoce: target.pianta }
}
```

con:

```js
// target: 'giardino' | { zona: nomeZona } | { zona: nomeZona, sottozona: nomeSottozona } | { pianta: piantaId }
// La chiave composta "<zona>|<sottozona>" (stesso separatore di
// raggruppaAttivita.js) evita di dover annidare un altro livello di
// oggetti solo per questa mappa: i nomi di sottozona sono unici solo
// dentro la propria zona, non globalmente.
function chiaviTarget(target) {
  if (target === 'giardino') return { chiave: 'giardino', chiaveVoce: null }
  if (target.pianta) return { chiave: 'piante', chiaveVoce: target.pianta }
  if (target.sottozona) return { chiave: 'sottozone', chiaveVoce: `${target.zona}|${target.sottozona}` }
  return { chiave: 'zone', chiaveVoce: target.zona }
}
```

Nota: `patchStore` e `programmaEsistente` non cambiano — operano già in modo generico su `chiave`/`chiaveVoce`, e `sottozone` si comporta esattamente come `zone`/`piante` (mappa piatta, chiave stringa).

- [ ] **Step 2: `salvaProgramma` — valorizzare `sottozona_id`**

Sostituire:

```js
    const riga = {
      zona_id: target !== 'giardino' && target.zona ? (store.zone?.[target.zona]?.id ?? null) : null,
      pianta_id: target !== 'giardino' && target.pianta ? target.pianta : null,
      ogni_giorni: ogniGiorni,
    }
```

con:

```js
    const riga = {
      zona_id: target !== 'giardino' && target.zona && !target.sottozona ? (store.zone?.[target.zona]?.id ?? null) : null,
      sottozona_id: target !== 'giardino' && target.sottozona ? (store.sottozone?.[target.zona]?.[target.sottozona]?.id ?? null) : null,
      pianta_id: target !== 'giardino' && target.pianta ? target.pianta : null,
      ogni_giorni: ogniGiorni,
    }
```

(`zona_id` resta null quando è presente `sottozona`, per rispettare il check di mutua esclusione a 3 vie della migration — una riga a livello sottozona non deve avere anche `zona_id` valorizzato.)

- [ ] **Step 3: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 4: Commit**

```bash
git add src/composables/useIrrigazioneApi.js
git commit -m "$(cat <<'EOF'
useIrrigazioneApi: supporto al target { zona, sottozona }

chiaviTarget riconosce il livello sottozona con la stessa chiave composta
dello store; salvaProgramma valorizza sottozona_id invece di zona_id
quando presente, rispettando il check di mutua esclusione a 3 vie.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```

---

### Task 5: `IrrigazioneView.vue` — livello sottozona nell'albero

**Files:**
- Modify: `src/views/IrrigazioneView.vue`

**Interfaces:**
- Consuma: `store.sottozone[zona]` (store esistente, keyed by nome — vedi `mappaSottozone` in `dati.js`); `store.programmiIrrigazione.sottozone` (Task 2); `salvaProgramma`/`rimuoviProgramma` con `target = { zona, sottozona }` (Task 4).

- [ ] **Step 1: Nuove funzioni nello script**

Nel blocco `<script setup>`, dopo la funzione esistente:

```js
function programmaEffettivoZona(nome) {
  return programmaZona(nome) ?? programmaGiardino.value
}
```

aggiungere:

```js
// Chiave composta "<zona>|<sottozona>", stesso separatore di
// raggruppaAttivita.js — usata sia per leggere store.programmiIrrigazione.sottozone
// sia come chiave del Set `espanse` (nessuna collisione: i nomi di zona non
// contengono mai "|").
function chiaveSottozona(zona, sottozona) {
  return `${zona}|${sottozona}`
}
function sottozoneDellaZona(nomeZona) {
  return Object.values(store.sottozone?.[nomeZona] ?? {})
}
function programmaSottozona(zona, sottozona) {
  return store.programmiIrrigazione?.sottozone?.[chiaveSottozona(zona, sottozona)] ?? null
}
function programmaEffettivoSottozona(zona, sottozona) {
  return programmaSottozona(zona, sottozona) ?? programmaEffettivoZona(zona)
}
```

- [ ] **Step 2: `pianteDellaZona` guadagna un secondo parametro**

Sostituire:

```js
function pianteDellaZona(nomeZona) {
  return piante.value.filter(p => p.zona === nomeZona)
}
```

con:

```js
// nomeSottozona: null per le piante senza sottozona (mostrate direttamente
// sotto la zona), altrimenti filtra sulla sottozona specifica.
function pianteDellaZona(nomeZona, nomeSottozona) {
  return piante.value.filter(p => p.zona === nomeZona && (p.sottozona ?? null) === nomeSottozona)
}
```

- [ ] **Step 3: Template — sostituire il blocco espanso della zona**

Sostituire l'intero blocco (dal `<div v-if="espanse.has(z.nome)" class="destlist" style="padding-left:30px;">` di apertura fino al suo `</div>` di chiusura, prima di `</template>` che chiude il `v-for="z in zoneList"`):

```html
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
```

con:

```html
        <div v-if="espanse.has(z.nome)" class="destlist" style="padding-left:30px;">
          <template v-for="sz in sottozoneDellaZona(z.nome)" :key="sz.nome">
            <div class="dest">
              <div class="irr-zrow__main" role="button" tabindex="0"
                :aria-expanded="espanse.has(chiaveSottozona(z.nome, sz.nome))"
                :aria-label="`${espanse.has(chiaveSottozona(z.nome, sz.nome)) ? 'Comprimi' : 'Espandi'} sottozona ${sz.nome}`"
                @click="toggleZona(chiaveSottozona(z.nome, sz.nome))" @keydown.enter="toggleZona(chiaveSottozona(z.nome, sz.nome))" @keydown.space.prevent="toggleZona(chiaveSottozona(z.nome, sz.nome))">
                <span class="dest__n">{{ sz.nome }}</span>
                <span v-if="programmaSottozona(z.nome, sz.nome)" class="badge badge-ok">ogni {{ programmaSottozona(z.nome, sz.nome).ogniGiorni }} gg</span>
                <span v-else class="dest__c" style="color:var(--ink-soft);">{{ ereditaTesto(programmaEffettivoZona(z.nome)) }}</span>
                <Icon name="back" class="dest__chev" :style="{ transform: espanse.has(chiaveSottozona(z.nome, sz.nome)) ? 'rotate(-90deg)' : 'rotate(90deg)' }" />
              </div>
              <div class="irr-zrow__act">
                <button type="button" class="pill-mini" @click="apriModifica({ zona: z.nome, sottozona: sz.nome }, `${z.nome} · ${sz.nome}`, programmaSottozona(z.nome, sz.nome)?.ogniGiorni)" aria-label="Modifica programma sottozona">
                  <Icon name="matita" />
                </button>
                <button v-if="programmaSottozona(z.nome, sz.nome)" type="button" class="pill-mini pill-mini--del" @click="rimuovi({ zona: z.nome, sottozona: sz.nome })" aria-label="Rimuovi programma sottozona">×</button>
              </div>
            </div>
            <div v-if="espanse.has(chiaveSottozona(z.nome, sz.nome))" class="destlist" style="padding-left:30px;">
              <div v-for="p in pianteDellaZona(z.nome, sz.nome)" :key="p.id" class="dest">
                <span class="dest__n">{{ nomeSpecie(p) }}<span v-if="p.varieta"> — {{ p.varieta }}</span></span>
                <span v-if="programmaPianta(p.id)" class="badge badge-ok">ogni {{ programmaPianta(p.id).ogniGiorni }} gg</span>
                <span v-else class="dest__c" style="color:var(--ink-soft);">{{ ereditaTesto(programmaEffettivoSottozona(z.nome, sz.nome)) }}</span>
                <button type="button" class="pill-mini" @click="apriModifica({ pianta: p.id }, nomeSpecie(p), programmaPianta(p.id)?.ogniGiorni)" aria-label="Modifica programma pianta">
                  <Icon name="matita" />
                </button>
                <button v-if="programmaPianta(p.id)" type="button" class="pill-mini pill-mini--del" @click="rimuovi({ pianta: p.id })" aria-label="Rimuovi programma pianta">×</button>
              </div>
              <p v-if="!pianteDellaZona(z.nome, sz.nome).length" style="font-size:12px;color:var(--ink-soft);padding:10px 2px;">Nessuna pianta in questa sottozona.</p>
            </div>
          </template>

          <div v-for="p in pianteDellaZona(z.nome, null)" :key="p.id" class="dest">
            <span class="dest__n">{{ nomeSpecie(p) }}<span v-if="p.varieta"> — {{ p.varieta }}</span></span>
            <span v-if="programmaPianta(p.id)" class="badge badge-ok">ogni {{ programmaPianta(p.id).ogniGiorni }} gg</span>
            <span v-else class="dest__c" style="color:var(--ink-soft);">{{ ereditaTesto(programmaEffettivoZona(z.nome)) }}</span>
            <button type="button" class="pill-mini" @click="apriModifica({ pianta: p.id }, nomeSpecie(p), programmaPianta(p.id)?.ogniGiorni)" aria-label="Modifica programma pianta">
              <Icon name="matita" />
            </button>
            <button v-if="programmaPianta(p.id)" type="button" class="pill-mini pill-mini--del" @click="rimuovi({ pianta: p.id })" aria-label="Rimuovi programma pianta">×</button>
          </div>

          <p v-if="!sottozoneDellaZona(z.nome).length && !pianteDellaZona(z.nome, null).length" style="font-size:12px;color:var(--ink-soft);padding:10px 2px;">Nessuna sottozona né pianta in questa zona.</p>
        </div>
```

Nota consapevole: la riga-pianta (nome specie, badge/eredita, matita, ×) è ripetuta due volte (dentro una sottozona e direttamente sotto la zona) invece di essere astratta in un componente separato — stessa scelta già accettata nella Fase 1 per la duplicazione a 3 righe del controllo pioggia in `useCure.js` (una vera astrazione per due varianti di una riga da 6 righe di markup non vale la complessità in più). Non introdurre un componente `RigaProgrammaPianta.vue` per questo: se un reviewer lo propone come Minor, va parcheggiato per la critica post-merge già pianificata, non risolto qui.

- [ ] **Step 4: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 5: Verifica manuale nel browser**

Con `npm run dev` avviato e sessione autenticata, su una zona che ha almeno una sottozona configurata (o creane una da `/zone/<nome>/sottozone` se serve) e almeno una pianta assegnata a quella sottozona:

1. Apri `/impostazioni/irrigazione`, espandi la zona: la sottozona compare come riga propria, con "eredita: ogni N gg" dal giardino/zona se non ha programma.
2. Espandi la sottozona: le sue piante compaiono, con "eredita" dalla sottozona (non dalla zona).
3. Imposta un programma sulla sottozona → badge sulla sottozona; le sue piante ora ereditano da lì.
4. Imposta un programma su una pianta di quella sottozona → solo quella pianta mostra il proprio badge, le sorelle nella stessa sottozona restano su "eredita" dalla sottozona.
5. Rimuovi il programma di sottozona → le piante che ereditavano da lì tornano a mostrare "eredita" dalla zona (o dal giardino).
6. Una pianta SENZA sottozona nella stessa zona compare direttamente sotto la zona (non dentro nessuna sottozona) e continua a ereditare dalla zona/giardino come nella Fase 1.
7. Vai su Home/Attività/Piante/scheda pianta per la pianta di sottozona con programma proprio (punto 4): l'urgenza irrigazione non compare più, stessa verifica end-to-end già descritta nel Task 7 della Fase 1.

- [ ] **Step 6: Commit**

```bash
git add src/views/IrrigazioneView.vue
git commit -m "$(cat <<'EOF'
IrrigazioneView: aggiunge il livello sottozona all'albero

Tra zona e pianta: ogni sottozona mostra il proprio programma o
l'eredità dalla zona, le sue piante ereditano da lì prima di ricadere
sulla zona; le piante senza sottozona restano direttamente sotto la zona
come nella Fase 1.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```
