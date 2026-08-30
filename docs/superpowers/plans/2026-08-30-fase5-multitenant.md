# Fase 5 migrazione Supabase: zone/sottozone/piante multi-tenant — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Spostare zone, sottozone e piante da `public/data/{zone,sottozone,piante}.json` (GitHub Contents API) a tabelle Supabase relazionali con RLS per `owner_id = auth.uid()`, ponendo le basi per un vero multi-tenant, senza cambiare la forma dei dati esposta alle view esistenti.

**Architecture:** Tre nuove tabelle Supabase (`zone`, `sottozone`, `piante`) con FK a UUID (`sottozone.zona_id`, `piante.zona_id`, `piante.sottozona_id`) e RLS per riga. Lo store Pinia (`stores/dati.js`) continua a esporre `store.zone`/`store.sottozone`/`store.piante` come oggetti keyed-by-nome identici a oggi, ricostruendoli via join lato client dopo il fetch. Le scritture passano da un nuovo composable `usePianteApi.js` (per le piante, con 8 punti di scrittura sparsi in 6 file) e da chiamate dirette a Supabase nelle view di zone/sottozone (stesso pattern già in uso in `SelettoreSpecie.vue` per le specie).

**Tech Stack:** Vue 3 `<script setup>`, Pinia, Supabase (`@supabase/supabase-js`), nessun framework di test nel progetto — verifica della logica pura con script Node temporanei, verifica UI con `npm run dev` manuale.

**Spec:** `docs/superpowers/specs/2026-08-30-fase5-multitenant-design.md`

## Global Constraints

- Nessuna nuova dipendenza esterna.
- Nessun framework di test nel progetto: logica pura verificata con script Node temporanei non committati (cancellati a fine task); UI verificata con `npm run dev` manuale.
- `owner_id` sulle tre tabelle: `uuid not null references auth.users default auth.uid()` — le insert dell'app (via client Supabase autenticato) NON includono mai `owner_id` nel payload, si affidano al default; la migration di backfill (Task 2), eseguita fuori da un contesto PostgREST/JWT, imposta `owner_id` esplicitamente su ogni riga (il default `auth.uid()` risulterebbe `null` lì).
- Aggiornamenti per riga sempre per `id` (mai per nome/slug), come già stabilito per `specie` in `SelettoreSpecie.vue` — evita di colpire zero righe se il nome è già cambiato in un salvataggio precedente.
- `piante.id` resta testo nel formato `${specieSlug}-${Date.now()}` generato client-side, invariato: non un nuovo UUID (romperebbe la struttura cartelle `docs/gallery/piante/{id-pianta}/`).
- Owner id dell'account esistente (unico oggi): `fc227422-ece8-4dca-b706-956ec7ca9e6e` (`robertagenovese@proton.me`).
- Progetto Supabase: `ncuhhsvtjwcolhpdxbkt`.
- Stile inline esistente (attributo `style` diretto), pattern form/modali già presenti (`Teleport`/`overlay`/`modal-box`, `ModalConferma.vue`).

---

## File Structure

- **Create** `supabase/migrations/20260830010000_fase5_schema_zone_sottozone_piante.sql` — tabelle + RLS.
- **Create** `supabase/migrations/20260830020000_fase5_backfill_zone_sottozone_piante.sql` — dati esistenti (generato da uno script Node temporaneo).
- **Modify** `src/stores/dati.js` — mapping Supabase→forma keyed-by-nome, `caricaTutto()`.
- **Create** `src/composables/usePianteApi.js` — CRUD piante + registrazione cura + rinomina specie a cascata.
- **Modify** `src/views/EditZonaView.vue`, `src/views/ZoneView.vue` — CRUD zone su Supabase.
- **Modify** `src/views/SottozoneView.vue` — CRUD sottozone su Supabase (niente più cascata manuale su piante).
- **Modify** `src/views/EditPiantaView.vue`, `src/views/PianteView.vue`, `src/views/PiantaView.vue` — creazione/modifica/eliminazione pianta.
- **Modify** `src/components/AttivitaRiga.vue`, `src/views/AttivitaView.vue` — registrazione cura.
- **Modify** `src/components/SelettoreSpecie.vue` — rinomina specie a cascata sulle piante.
- **Modify** `vite.config.js` — cache offline per il dominio REST Supabase.
- **Modify** `src/composables/useAuth.js` — pulizia cache al logout.
- **Delete** `public/data/zone.json`, `public/data/sottozone.json`, `public/data/piante.json`.
- **Modify** `.claude/commands/elabora.md`, `CLAUDE.md` — documentazione.

---

### Task 1: Schema Supabase — tabelle zone/sottozone/piante + RLS

**Files:**
- Create: `supabase/migrations/20260830010000_fase5_schema_zone_sottozone_piante.sql`
- Test: `mcp__claude_ai_Supabase__list_tables` / `execute_sql`

**Interfaces:**
- Produces: tabelle `zone(id, owner_id, nome, descrizione, esposizione, microclima, criticita, manutenzione, tipo)`, `sottozone(id, owner_id, zona_id, nome, descrizione, esposizione, microclima, criticita, manutenzione, tipo)`, `piante(id, owner_id, specie, zona_id, sottozona_id, varieta, impianto, impianto_circa, note, coltivato_in, ultima_cura)`, con RLS `owner_id = auth.uid()`. Usate da Task 2 (backfill) e da tutti i task successivi.

- [ ] **Step 1: Scrivi la migration**

Crea `supabase/migrations/20260830010000_fase5_schema_zone_sottozone_piante.sql`:

```sql
-- Fase 5: zone/sottozone/piante diventano tabelle relazionali multi-tenant
-- (prima JSON su GitHub, senza scoping per utente). FK a UUID invece di
-- stringhe libere: rinominare una zona/sottozona non richiede più
-- aggiornare a mano le piante che la referenziano. `piante.id` resta testo
-- (stesso formato "slug-timestamp" generato client-side) per compatibilità
-- con la struttura cartelle della gallery foto.

create table zone (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  nome text not null,
  descrizione text,
  esposizione text[],
  microclima text,
  criticita text,
  manutenzione text,
  tipo text,
  unique (owner_id, nome)
);

create table sottozone (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  zona_id uuid not null references zone(id) on delete cascade,
  nome text not null,
  descrizione text,
  esposizione text[],
  microclima text,
  criticita text,
  manutenzione text,
  tipo text,
  unique (zona_id, nome)
);

create table piante (
  id text primary key,
  owner_id uuid not null references auth.users default auth.uid(),
  specie text not null references specie(slug),
  zona_id uuid not null references zone(id) on delete restrict,
  sottozona_id uuid references sottozone(id) on delete set null,
  varieta text,
  impianto text,
  impianto_circa text,
  note text,
  coltivato_in text,
  ultima_cura jsonb not null default '{}'::jsonb
);

alter table zone enable row level security;
alter table sottozone enable row level security;
alter table piante enable row level security;

create policy "zone: proprietario" on zone for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "sottozone: proprietario" on sottozone for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "piante: proprietario" on piante for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
```

- [ ] **Step 2: Applica la migration**

Chiama `mcp__claude_ai_Supabase__apply_migration` con `project_id: "ncuhhsvtjwcolhpdxbkt"`, `name: "fase5_schema_zone_sottozone_piante"`, `query`: il contenuto del file creato allo Step 1.

- [ ] **Step 3: Verifica schema e RLS**

Chiama `mcp__claude_ai_Supabase__list_tables` con `project_id: "ncuhhsvtjwcolhpdxbkt"`, `schemas: ["public"]`, `verbose: true`.

Expected: `public.zone`, `public.sottozone`, `public.piante` presenti, `rls_enabled: true` su tutte e tre, `foreign_key_constraints` su `sottozone.zona_id`, `piante.zona_id`, `piante.sottozona_id`, `piante.specie`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260830010000_fase5_schema_zone_sottozone_piante.sql
git commit -m "Crea schema Supabase per zone/sottozone/piante multi-tenant (Fase 5)"
```

---

### Task 2: Migrazione dati esistenti (backfill)

**Files:**
- Create: script Node temporaneo in `/private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/e6150380-3ba4-464f-a874-ae075a0e17c7/scratchpad/genera-backfill-fase5.mjs` (non committato, cancellato a fine task)
- Create: `supabase/migrations/20260830020000_fase5_backfill_zone_sottozone_piante.sql` (output dello script, questo sì committato)
- Test: `mcp__claude_ai_Supabase__execute_sql` (conteggio righe)

**Interfaces:**
- Consumes: tabelle create in Task 1; `public/data/zone.json`, `public/data/sottozone.json`, `public/data/piante.json` (letti solo qui, poi cancellati in Task 10).
- Produces: righe `zone`/`sottozone`/`piante` popolate con `owner_id = 'fc227422-ece8-4dca-b706-956ec7ca9e6e'`, pronte per Task 3+.

- [ ] **Step 1: Verifica preliminare — ogni `pianta.specie` esiste nel catalogo**

Run: `node -e "const p = require('./public/data/piante.json'); console.log([...new Set(Object.values(p).map(x => x.specie))].join('\n'))" > /private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/e6150380-3ba4-464f-a874-ae075a0e17c7/scratchpad/slug-piante.txt`

Poi, per ciascuno slug distinto nel file, verifica che esista in Supabase con `execute_sql`:

```sql
select slug from specie where slug in (/* incolla qui la lista, tra apici, separata da virgole */);
```

Expected: lo stesso numero di righe restituite quante sono le slug distinte nel file. Se manca qualche slug (FK `piante.specie references specie(slug)` fallirebbe in Task 2 Step 3), fermati e segnala la discrepanza invece di procedere — non correggerla automaticamente, potrebbe essere un refuso da controllare a mano.

- [ ] **Step 2: Scrivi lo script di generazione**

Crea `/private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/e6150380-3ba4-464f-a874-ae075a0e17c7/scratchpad/genera-backfill-fase5.mjs`:

```js
// Genera la migration SQL di backfill per Fase 5 (zone/sottozone/piante).
// Gli id sono generati qui (non con gen_random_uuid() in SQL) così possono
// essere referenziati come FK letterali nello stesso script, senza round-trip.
import { randomUUID } from 'node:crypto'
import { readFileSync, writeFileSync } from 'node:fs'

const OWNER_ID = 'fc227422-ece8-4dca-b706-956ec7ca9e6e'
const RADICE = '/Users/rob/Sites/localhost/giardino'
const OUT = `${RADICE}/supabase/migrations/20260830020000_fase5_backfill_zone_sottozone_piante.sql`

function sqlString(v) {
  if (v === null || v === undefined || v === '') return 'null'
  return `'${String(v).replace(/'/g, "''")}'`
}
function sqlArray(arr) {
  if (!arr || !arr.length) return 'null'
  return `ARRAY[${arr.map(sqlString).join(',')}]::text[]`
}
function sqlJsonb(obj) {
  return `'${JSON.stringify(obj ?? {}).replace(/'/g, "''")}'::jsonb`
}

const zone = JSON.parse(readFileSync(`${RADICE}/public/data/zone.json`, 'utf8'))
const sottozoneGrezze = JSON.parse(readFileSync(`${RADICE}/public/data/sottozone.json`, 'utf8'))
const pianteGrezze = JSON.parse(readFileSync(`${RADICE}/public/data/piante.json`, 'utf8'))

const zonaIdPerNome = {}
for (const nome of Object.keys(zone)) zonaIdPerNome[nome] = randomUUID()

const sottozonaIdPerChiave = {}
for (const [nomeZona, sz] of Object.entries(sottozoneGrezze)) {
  for (const nomeSz of Object.keys(sz)) {
    sottozonaIdPerChiave[`${nomeZona}|${nomeSz}`] = randomUUID()
  }
}

const righe = []
righe.push('-- Fase 5: backfill zone/sottozone/piante da JSON a Supabase.')
righe.push(`-- owner_id: ${OWNER_ID} (robertagenovese@proton.me, unico account esistente)`)
righe.push('')

righe.push('insert into zone (id, owner_id, nome, descrizione, esposizione, microclima, criticita, manutenzione, tipo) values')
righe.push(Object.entries(zone).map(([nome, z]) =>
  `  (${sqlString(zonaIdPerNome[nome])}, ${sqlString(OWNER_ID)}, ${sqlString(z.nome)}, ${sqlString(z.descrizione)}, ${sqlArray(z.esposizione)}, ${sqlString(z.microclima)}, ${sqlString(z.criticita)}, ${sqlString(z.manutenzione)}, ${sqlString(z.tipo)})`
).join(',\n') + ';')
righe.push('')

const vociSottozone = []
for (const [nomeZona, sz] of Object.entries(sottozoneGrezze)) {
  if (!zonaIdPerNome[nomeZona]) throw new Error(`Sottozona in una zona sconosciuta: "${nomeZona}"`)
  for (const [nomeSz, s] of Object.entries(sz)) {
    vociSottozone.push(`  (${sqlString(sottozonaIdPerChiave[`${nomeZona}|${nomeSz}`])}, ${sqlString(OWNER_ID)}, ${sqlString(zonaIdPerNome[nomeZona])}, ${sqlString(s.nome)}, ${sqlString(s.descrizione)}, ${sqlArray(s.esposizione)}, ${sqlString(s.microclima)}, ${sqlString(s.criticita)}, ${sqlString(s.manutenzione)}, ${sqlString(s.tipo)})`)
  }
}
if (vociSottozone.length) {
  righe.push('insert into sottozone (id, owner_id, zona_id, nome, descrizione, esposizione, microclima, criticita, manutenzione, tipo) values')
  righe.push(vociSottozone.join(',\n') + ';')
  righe.push('')
}

const vociPiante = []
for (const [id, p] of Object.entries(pianteGrezze)) {
  const zonaId = zonaIdPerNome[p.zona]
  if (!zonaId) throw new Error(`Pianta ${id}: zona "${p.zona}" non trovata in zone.json`)
  const sottozonaId = p.sottozona ? (sottozonaIdPerChiave[`${p.zona}|${p.sottozona}`] ?? null) : null
  vociPiante.push(`  (${sqlString(id)}, ${sqlString(OWNER_ID)}, ${sqlString(p.specie)}, ${sqlString(zonaId)}, ${sottozonaId ? sqlString(sottozonaId) : 'null'}, ${sqlString(p.varieta)}, ${sqlString(p.impianto)}, ${sqlString(p.impianto_circa)}, ${sqlString(p.note)}, ${sqlString(p.coltivato_in)}, ${sqlJsonb(p.ultima_cura)})`)
}
righe.push('insert into piante (id, owner_id, specie, zona_id, sottozona_id, varieta, impianto, impianto_circa, note, coltivato_in, ultima_cura) values')
righe.push(vociPiante.join(',\n') + ';')

writeFileSync(OUT, righe.join('\n') + '\n')
console.log(`Generato ${OUT}`)
console.log(`zone: ${Object.keys(zone).length}, sottozone: ${vociSottozone.length}, piante: ${vociPiante.length}`)
```

- [ ] **Step 3: Esegui lo script**

Run: `node /private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/e6150380-3ba4-464f-a874-ae075a0e17c7/scratchpad/genera-backfill-fase5.mjs`

Expected: stampa il percorso del file generato e i tre conteggi. Annota i tre numeri: serviranno allo Step 5.

- [ ] **Step 4: Applica la migration generata**

Leggi il contenuto di `supabase/migrations/20260830020000_fase5_backfill_zone_sottozone_piante.sql` appena generato, poi chiama `mcp__claude_ai_Supabase__apply_migration` con `project_id: "ncuhhsvtjwcolhpdxbkt"`, `name: "fase5_backfill_zone_sottozone_piante"`, `query`: quel contenuto.

Se fallisce per violazione della FK `piante.specie` (slug mancante in `specie`), torna allo Step 1: non l'avevi verificato per quello slug, o è comparso un refuso nel frattempo.

- [ ] **Step 5: Verifica i conteggi**

Chiama `mcp__claude_ai_Supabase__execute_sql` con:

```sql
select
  (select count(*) from zone)      as zone,
  (select count(*) from sottozone) as sottozone,
  (select count(*) from piante)    as piante;
```

Expected: gli stessi tre numeri stampati allo Step 3.

- [ ] **Step 6: Elimina lo script temporaneo e committa la migration generata**

```bash
rm /private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/e6150380-3ba4-464f-a874-ae075a0e17c7/scratchpad/genera-backfill-fase5.mjs /private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/e6150380-3ba4-464f-a874-ae075a0e17c7/scratchpad/slug-piante.txt
git add supabase/migrations/20260830020000_fase5_backfill_zone_sottozone_piante.sql
git commit -m "Backfill zone/sottozone/piante esistenti su Supabase (Fase 5)"
```

---

### Task 3: Store — caricamento da Supabase con forma invariata

**Files:**
- Modify: `src/stores/dati.js`
- Test: script Node temporaneo per le funzioni di mapping pure

**Interfaces:**
- Consumes: tabelle `zone`/`sottozone`/`piante` (Task 1-2), `useSupabase()` (già importato in `dati.js`).
- Produces: `mappaZone(righeZone) => Record<string, {id, nome, descrizione, esposizione, microclima, criticita, manutenzione, tipo}>`, `mappaSottozone(righeSottozone, zonaNomePerId) => Record<string, Record<string, {id, nome, ...}>>`, `mappaPiante(righePiante, zonaNomePerId, sottozonaNomePerId) => Record<string, {specie, zona, sottozona, varieta, impianto, impianto_circa, note, coltivato_in, ultima_cura}>`, esportate da `src/stores/dati.js` (stesso file di `mappaSpecie`). `store.zone`/`store.sottozone`/`store.piante` restano nella stessa forma keyed-by-nome di sempre (con l'aggiunta non invasiva di `id` su ogni voce zona/sottozona). Usate da Task 4-8 per risolvere nome→id nelle scritture.

- [ ] **Step 1: Scrivi lo script di verifica delle funzioni pure**

Crea `/private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/e6150380-3ba4-464f-a874-ae075a0e17c7/scratchpad/verifica-mapping-fase5.mjs`:

```js
import assert from 'node:assert/strict'
import { mappaZone, mappaSottozone, mappaPiante } from '/Users/rob/Sites/localhost/giardino/src/stores/dati.js'

const righeZone = [
  { id: 'z-est', nome: 'Est', descrizione: 'Lato est', esposizione: ['est'], microclima: 'm', criticita: 'c', manutenzione: 'man', tipo: 'esterno' },
  { id: 'z-casa', nome: 'Casa', descrizione: null, esposizione: null, microclima: null, criticita: null, manutenzione: null, tipo: 'interno' },
]
const zone = mappaZone(righeZone)
assert.deepEqual(Object.keys(zone).sort(), ['Casa', 'Est'])
assert.equal(zone.Est.id, 'z-est')
assert.equal(zone.Est.descrizione, 'Lato est')
assert.deepEqual(zone.Casa.esposizione, null)

const zonaNomePerId = { 'z-est': 'Est', 'z-casa': 'Casa' }

const righeSottozone = [
  { id: 'sz-1', zona_id: 'z-casa', nome: 'Cucina', descrizione: 'd', esposizione: ['ovest'], microclima: null, criticita: null, manutenzione: null, tipo: 'interno' },
  { id: 'sz-orfana', zona_id: 'z-inesistente', nome: 'Fantasma', descrizione: null, esposizione: null, microclima: null, criticita: null, manutenzione: null, tipo: null },
]
const sottozone = mappaSottozone(righeSottozone, zonaNomePerId)
assert.deepEqual(Object.keys(sottozone), ['Casa'])
assert.equal(sottozone.Casa.Cucina.id, 'sz-1')
assert.equal(sottozone.Casa.Cucina.descrizione, 'd')
assert.equal(Object.keys(sottozone).includes('undefined'), false, 'una sottozona con zona_id orfano non deve comparire')

const sottozonaNomePerId = { 'sz-1': 'Cucina' }

const righePiante = [
  { id: 'basilico-1', specie: 'basilico', zona_id: 'z-casa', sottozona_id: 'sz-1', varieta: '', impianto: '', impianto_circa: '', note: '', coltivato_in: 'vaso', ultima_cura: { irrigazione: '2026-08-01' } },
  { id: 'ulivo-1', specie: 'ulivo', zona_id: 'z-est', sottozona_id: null, varieta: '', impianto: '', impianto_circa: '', note: '', coltivato_in: 'terra', ultima_cura: null },
]
const piante = mappaPiante(righePiante, zonaNomePerId, sottozonaNomePerId)
assert.equal(piante['basilico-1'].zona, 'Casa')
assert.equal(piante['basilico-1'].sottozona, 'Cucina')
assert.deepEqual(piante['basilico-1'].ultima_cura, { irrigazione: '2026-08-01' })
assert.equal(piante['ulivo-1'].zona, 'Est')
assert.equal(piante['ulivo-1'].sottozona, null, 'sottozona_id null => sottozona null')
assert.deepEqual(piante['ulivo-1'].ultima_cura, {}, 'ultima_cura null => oggetto vuoto, mai null')

console.log('OK: tutte le assert passate')
```

- [ ] **Step 2: Esegui lo script e verifica che fallisca**

Run: `node /private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/e6150380-3ba4-464f-a874-ae075a0e17c7/scratchpad/verifica-mapping-fase5.mjs`
Expected: errore — `mappaZone` non è esportata da `dati.js` (non esiste ancora).

- [ ] **Step 3: Aggiungi le funzioni di mapping a `dati.js`**

In `src/stores/dati.js`, subito prima di `export const useDatiStore = defineStore('dati', () => {`, aggiungi:

```js
// Zone/sottozone/piante (Fase 5): tabelle Supabase con FK a UUID, ma lo
// store espone la stessa forma keyed-by-nome di sempre (store.zone["Est"],
// pianta.zona === "Est") — le ~15 view che leggono zona/sottozona come
// stringa non cambiano. Ogni voce zona/sottozona porta con sé anche `id`
// (non presente prima): serve solo al livello di scrittura (usePianteApi.js
// e le view di zone/sottozone), nessuna view esistente lo usa nel template.
export function mappaZone(righeZone) {
  return Object.fromEntries(righeZone.map(z => [z.nome, {
    id: z.id,
    nome: z.nome,
    descrizione: z.descrizione,
    esposizione: z.esposizione,
    microclima: z.microclima,
    criticita: z.criticita,
    manutenzione: z.manutenzione,
    tipo: z.tipo,
  }]))
}

export function mappaSottozone(righeSottozone, zonaNomePerId) {
  const risultato = {}
  for (const sz of righeSottozone) {
    const nomeZona = zonaNomePerId[sz.zona_id]
    if (!nomeZona) continue  // zona_id orfano: non dovrebbe succedere (FK), ignorata per sicurezza
    if (!risultato[nomeZona]) risultato[nomeZona] = {}
    risultato[nomeZona][sz.nome] = {
      id: sz.id,
      nome: sz.nome,
      descrizione: sz.descrizione,
      esposizione: sz.esposizione,
      microclima: sz.microclima,
      criticita: sz.criticita,
      manutenzione: sz.manutenzione,
      tipo: sz.tipo,
    }
  }
  return risultato
}

export function mappaPiante(righePiante, zonaNomePerId, sottozonaNomePerId) {
  return Object.fromEntries(righePiante.map(p => [p.id, {
    specie: p.specie,
    zona: zonaNomePerId[p.zona_id] ?? null,
    sottozona: p.sottozona_id ? (sottozonaNomePerId[p.sottozona_id] ?? null) : null,
    varieta: p.varieta,
    impianto: p.impianto,
    impianto_circa: p.impianto_circa,
    note: p.note,
    coltivato_in: p.coltivato_in,
    ultima_cura: p.ultima_cura ?? {},
  }]))
}
```

- [ ] **Step 4: Esegui lo script e verifica che passi**

Run: `node /private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/e6150380-3ba4-464f-a874-ae075a0e17c7/scratchpad/verifica-mapping-fase5.mjs`
Expected: `OK: tutte le assert passate`

- [ ] **Step 5: Elimina lo script temporaneo**

Run: `rm /private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/e6150380-3ba4-464f-a874-ae075a0e17c7/scratchpad/verifica-mapping-fase5.mjs`

- [ ] **Step 6: Aggiorna `caricaTutto()` per usare Supabase**

In `src/stores/dati.js`, sostituisci:

```js
  async function caricaTutto() {
    if (piante.value) return  // già caricati
    loading.value = true
    errore.value = null
    try {
      const [pianteData, richiesteData, zoneData, sottozoneData, progettiData, settingsData, concimiData] =
        await Promise.all([
          caricaJSON('piante.json'),
          caricaJSON('richieste-agente.json'),
          caricaJSON('zone.json'),
          caricaJSON('sottozone.json'),
          caricaJSON('progetti.json'),
          caricaJSON('settings.json'),
          caricaJSON('concimi.json'),
        ])

      piante.value    = pianteData
      zone.value      = zoneData
      sottozone.value = sottozoneData
      progetti.value  = progettiData
      settings.value  = settingsData
      concimi.value   = concimiData

      // Slug delle specie da caricare subito: quelle delle piante possedute
      // più quelle citate da richieste di revisione ancora in coda (mostrate
      // per nome nello storico di AgenteView).
      const slugPiante = Object.values(pianteData ?? {}).map(p => p.specie).filter(Boolean)
      const slugRichieste = Object.values(richiesteData ?? {})
        .filter(r => r.tipo === 'revisione_specie' && r.specie)
        .map(r => r.specie)
      const slugReferenziati = [...new Set([...slugPiante, ...slugRichieste])]

      specie.value = await caricaSpecie(slugReferenziati)
    } catch (e) {
      errore.value = e.message
    } finally {
      loading.value = false
    }
```

con:

```js
  async function caricaTutto() {
    if (piante.value) return  // già caricati
    loading.value = true
    errore.value = null
    try {
      const supabase = useSupabase()
      async function query(builder) {
        const { data, error } = await builder
        if (error) throw error
        return data ?? []
      }

      const [righeZone, righeSottozone, righePiante, richiesteData, progettiData, settingsData, concimiData] =
        await Promise.all([
          query(supabase.from('zone').select('*')),
          query(supabase.from('sottozone').select('*')),
          query(supabase.from('piante').select('*')),
          caricaJSON('richieste-agente.json'),
          caricaJSON('progetti.json'),
          caricaJSON('settings.json'),
          caricaJSON('concimi.json'),
        ])

      const zonaNomePerId = Object.fromEntries(righeZone.map(z => [z.id, z.nome]))
      const sottozonaNomePerId = Object.fromEntries(righeSottozone.map(s => [s.id, s.nome]))
      zone.value      = mappaZone(righeZone)
      sottozone.value = mappaSottozone(righeSottozone, zonaNomePerId)
      piante.value    = mappaPiante(righePiante, zonaNomePerId, sottozonaNomePerId)
      progetti.value  = progettiData
      settings.value  = settingsData
      concimi.value   = concimiData

      // Slug delle specie da caricare subito: quelle delle piante possedute
      // più quelle citate da richieste di revisione ancora in coda (mostrate
      // per nome nello storico di AgenteView).
      const slugPiante = Object.values(piante.value ?? {}).map(p => p.specie).filter(Boolean)
      const slugRichieste = Object.values(richiesteData ?? {})
        .filter(r => r.tipo === 'revisione_specie' && r.specie)
        .map(r => r.specie)
      const slugReferenziati = [...new Set([...slugPiante, ...slugRichieste])]

      specie.value = await caricaSpecie(slugReferenziati)
    } catch (e) {
      errore.value = e.message
    } finally {
      loading.value = false
    }
```

- [ ] **Step 7: Verifica manuale**

Run: `npm run build`
Expected: build senza errori.

Run: `npm run dev`

Apri `http://localhost:5173/#/zone`, `/piante`, `/attivita`. Verifica:
- Le zone/piante mostrate corrispondono a quelle viste prima della migrazione (stessi nomi, stesse zone/sottozone assegnate).
- Nessun errore in console.
- La scheda di una pianta (`/piante/:id`) mostra correttamente zona/sottozona/varietà/note.

- [ ] **Step 8: Commit**

```bash
git add src/stores/dati.js
git commit -m "Carica zone/sottozone/piante da Supabase mantenendo la forma esistente dello store"
```

---

### Task 4: Zone — creazione, modifica ed eliminazione

**Files:**
- Modify: `src/views/EditZonaView.vue`
- Modify: `src/views/ZoneView.vue`
- Test: verifica manuale

**Interfaces:**
- Consumes: `store.zone` (Task 3, con `id` su ogni voce), `useSupabase()`.
- Produces: nessuna interfaccia consumata da altri task (le sottozone/piante in Task 5-6 leggono `store.zone[nome].id` autonomamente, non tramite funzioni esportate da queste view).

- [ ] **Step 1: Riscrivi la creazione/modifica in `EditZonaView.vue`**

In `src/views/EditZonaView.vue`, sostituisci l'import:

```js
import { useApi } from '@/composables/useApi'
```

con:

```js
import { useSupabase } from '@/composables/useSupabase'
```

Sostituisci:

```js
const { saveJSON } = useApi()
```

con:

```js
const supabase = useSupabase()
```

Sostituisci:

```js
async function salva() {
  if (!form.value.nome.trim() || salvando.value) return
  salvando.value = true
  const key = isNuova.value ? form.value.nome.trim() : route.params.zona
  try {
    const nuove = await saveJSON('zone.json', (correnti) => {
      const base = { ...(correnti ?? store.zone) }
      base[key] = {
        ...(isNuova.value ? {} : base[key]),
        nome:        form.value.nome.trim(),
        tipo:        form.value.tipo,
        descrizione: form.value.descrizione.trim() || '',
        microclima:  form.value.microclima.trim()  || '',
        esposizione: form.value.esposizione,
      }
      return base
    })
    store.zone = nuove
    router.push('/zone')
  } finally {
    salvando.value = false
  }
}
```

con:

```js
async function salva() {
  if (!form.value.nome.trim() || salvando.value) return
  salvando.value = true
  const idOriginale = isNuova.value ? null : store.zone?.[route.params.zona]?.id
  const riga = {
    nome:        form.value.nome.trim(),
    tipo:        form.value.tipo,
    descrizione: form.value.descrizione.trim() || '',
    microclima:  form.value.microclima.trim()  || '',
    esposizione: form.value.esposizione,
  }
  try {
    let salvata
    if (idOriginale) {
      const { data, error } = await supabase.from('zone').update(riga).eq('id', idOriginale).select().single()
      if (error) throw error
      salvata = data
    } else {
      const { data, error } = await supabase.from('zone').insert(riga).select().single()
      if (error) throw error
      salvata = data
    }

    const nuoveZone = { ...store.zone }
    if (!isNuova.value && route.params.zona !== salvata.nome) delete nuoveZone[route.params.zona]
    nuoveZone[salvata.nome] = {
      id: salvata.id, nome: salvata.nome, descrizione: salvata.descrizione,
      esposizione: salvata.esposizione, microclima: salvata.microclima,
      criticita: salvata.criticita, manutenzione: salvata.manutenzione, tipo: salvata.tipo,
    }
    store.zone = nuoveZone
    router.push('/zone')
  } finally {
    salvando.value = false
  }
}
```

- [ ] **Step 2: Riscrivi l'eliminazione in `ZoneView.vue`**

In `src/views/ZoneView.vue`, sostituisci l'import:

```js
import { useApi } from '@/composables/useApi'
```

con:

```js
import { useSupabase } from '@/composables/useSupabase'
```

Sostituisci:

```js
const store      = useDatiStore()
const { saveJSON } = useApi()
const daEliminare  = ref(null)
const eliminando   = ref(false)
```

con:

```js
const store      = useDatiStore()
const supabase   = useSupabase()
const daEliminare  = ref(null)
const eliminando   = ref(false)
const erroreEliminazione = ref(null)
```

Sostituisci:

```js
async function eliminaZona() {
  if (!daEliminare.value) return
  eliminando.value = true
  const zonaKey = daEliminare.value
  try {
    const nuoveZone = await saveJSON('zone.json', (correnti) => {
      const base = { ...(correnti ?? store.zone) }
      delete base[zonaKey]
      return base
    })
    store.zone = nuoveZone

    // Elimina sottozone collegate
    if (store.sottozone?.[zonaKey]) {
      const nuoveSottozone = await saveJSON('sottozone.json', (correnti) => {
        const base = { ...(correnti ?? store.sottozone) }
        delete base[zonaKey]
        return base
      })
      store.sottozone = nuoveSottozone
    }
    daEliminare.value = null
  } finally {
    eliminando.value = false
  }
}
```

con:

```js
async function eliminaZona() {
  if (!daEliminare.value) return
  eliminando.value = true
  const zonaKey = daEliminare.value
  const idZona = store.zone?.[zonaKey]?.id
  erroreEliminazione.value = null
  try {
    const { error } = await supabase.from('zone').delete().eq('id', idZona)
    if (error) {
      // Violazione della FK piante.zona_id (on delete restrict): la zona
      // contiene ancora piante. A differenza del vecchio comportamento su
      // JSON (cancellava comunque, lasciando le piante orfane), il database
      // ora blocca l'operazione esplicitamente.
      if (error.code === '23503') {
        erroreEliminazione.value = 'Non puoi eliminare una zona che contiene ancora piante: spostale o eliminale prima.'
        daEliminare.value = null
        return
      }
      throw error
    }

    const nuoveZone = { ...store.zone }
    delete nuoveZone[zonaKey]
    store.zone = nuoveZone

    // Le sottozone collegate sono cancellate dal database stesso
    // (sottozone.zona_id on delete cascade): qui aggiorniamo solo lo store.
    if (store.sottozone?.[zonaKey]) {
      const nuoveSottozone = { ...store.sottozone }
      delete nuoveSottozone[zonaKey]
      store.sottozone = nuoveSottozone
    }
    daEliminare.value = null
  } finally {
    eliminando.value = false
  }
}
```

- [ ] **Step 3: Mostra l'eventuale errore nel template**

In `src/views/ZoneView.vue`, sostituisci:

```html
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;">
      <h1 class="title-display gradient-title title-settle" style="font-size:1.9rem;font-weight:800;">Zone</h1>
      <RouterLink to="/zone/nuova" class="btn btn-rose" style="text-decoration:none;">＋ Aggiungi</RouterLink>
    </div>
```

con:

```html
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;">
      <h1 class="title-display gradient-title title-settle" style="font-size:1.9rem;font-weight:800;">Zone</h1>
      <RouterLink to="/zone/nuova" class="btn btn-rose" style="text-decoration:none;">＋ Aggiungi</RouterLink>
    </div>

    <p v-if="erroreEliminazione" style="font-size:12px;color:var(--rose-dark);background:var(--rose-pale);padding:10px 14px;border-radius:12px;margin-bottom:16px;">
      {{ erroreEliminazione }}
    </p>
```

- [ ] **Step 4: Verifica manuale**

Run: `npm run build`
Expected: build senza errori.

Run: `npm run dev`

Apri `http://localhost:5173/#/zone`. Verifica:
- Creare una zona nuova (nome, tipo, descrizione, microclima, esposizione), verificarne la comparsa nella lista.
- Modificarla (incluso il rename del nome), verificare che la card si aggiorni.
- Eliminare una zona **senza piante**: sparisce dalla lista, eventuali sottozone collegate spariscono anch'esse da `/zone/<nome>/sottozone`.
- Tentare di eliminare una zona **con piante**: compare il messaggio di blocco, la zona resta nella lista.
- Nessun errore in console.

- [ ] **Step 5: Commit**

```bash
git add src/views/EditZonaView.vue src/views/ZoneView.vue
git commit -m "Sposta creazione/modifica/eliminazione zone su Supabase (Fase 5)"
```

---

### Task 5: Sottozone — creazione e modifica

**Files:**
- Modify: `src/views/SottozoneView.vue`
- Test: verifica manuale

**Interfaces:**
- Consumes: `store.zone[nome].id` (Task 3/4), `useSupabase()`.
- Produces: nessuna interfaccia consumata da altri task.

- [ ] **Step 1: Sostituisci l'import e l'inizializzazione**

In `src/views/SottozoneView.vue`, sostituisci:

```js
import { useApi } from '@/composables/useApi'
```

con:

```js
import { useSupabase } from '@/composables/useSupabase'
```

Sostituisci:

```js
const { saveJSON } = useApi()
```

con:

```js
const supabase = useSupabase()
```

- [ ] **Step 2: Riscrivi `salva()`**

Sostituisci l'intera funzione (dalla riga `async function salva() {` fino alla sua chiusura, subito prima di `</script>`):

```js
async function salva() {
  if (!form.value.nome.trim() || salvando.value) return
  const nomeOriginale = modificaOriginale.value
  const nomeNuovo = form.value.nome.trim()

  // Evita di sovrascrivere silenziosamente un'altra sottozona già esistente
  // con lo stesso nome (perderebbe esposizione/microclima/criticita/
  // manutenzione non gestiti da questo form).
  const sottozoneDellaZona = store.sottozone?.[route.params.zona] ?? {}
  if (sottozoneDellaZona[nomeNuovo] && nomeNuovo !== nomeOriginale) {
    errore.value = 'Una sottozona con questo nome esiste già in questa zona.'
    return
  }
  errore.value = null

  salvando.value = true
  try {
    const esistente = nomeOriginale ? (sottozoneDellaZona[nomeOriginale] ?? {}) : {}
    const riga = {
      nome:        nomeNuovo,
      descrizione: form.value.descrizione.trim() || '',
      tipo:        form.value.tipo,
      esposizione: form.value.esposizione,
    }

    let salvata
    if (esistente.id) {
      const { data, error } = await supabase.from('sottozone').update(riga).eq('id', esistente.id).select().single()
      if (error) throw error
      salvata = data
    } else {
      const zonaId = store.zone?.[route.params.zona]?.id
      const { data, error } = await supabase.from('sottozone').insert({ ...riga, zona_id: zonaId }).select().single()
      if (error) throw error
      salvata = data
    }

    const nuove = { ...store.sottozone }
    const sottozoneZona = { ...(nuove[route.params.zona] ?? {}) }
    if (nomeOriginale && nomeOriginale !== nomeNuovo) delete sottozoneZona[nomeOriginale]
    sottozoneZona[salvata.nome] = {
      id: salvata.id, nome: salvata.nome, descrizione: salvata.descrizione,
      esposizione: salvata.esposizione, microclima: salvata.microclima,
      criticita: salvata.criticita, manutenzione: salvata.manutenzione, tipo: salvata.tipo,
    }
    nuove[route.params.zona] = sottozoneZona
    store.sottozone = nuove

    // A differenza di prima (sottozona referenziata per nome nelle piante,
    // rinominare qui richiedeva riscrivere anche piante.json), le piante
    // referenziano sottozona_id (FK): rinominare una sottozona non tocca
    // nessuna pianta, il database resta coerente da solo.
    chiudiForm()
  } finally {
    salvando.value = false
  }
}
```

- [ ] **Step 3: Verifica manuale**

Run: `npm run build`
Expected: build senza errori.

Run: `npm run dev`

Apri `http://localhost:5173/#/zone/<una-zona-con-sottozone>/sottozone` (es. Casa). Verifica:
- Creare una nuova sottozona, verificarne la comparsa.
- Modificarla, incluso un rename del nome: verifica che una pianta già assegnata a quella sottozona (`/piante/:id` di una pianta in quella sottozona, prima e dopo il rename) continui a mostrare la sottozona con il nome aggiornato, senza bisogno di modificarla manualmente.
- Tentare di creare una sottozona con un nome già usato nella stessa zona: compare il messaggio di errore, nessuna scrittura avviene.
- Nessun errore in console.

- [ ] **Step 4: Commit**

```bash
git add src/views/SottozoneView.vue
git commit -m "Sposta creazione/modifica sottozone su Supabase, rinomina senza più cascata manuale (Fase 5)"
```

---

### Task 6: Piante — creazione, modifica ed eliminazione

**Files:**
- Create: `src/composables/usePianteApi.js`
- Modify: `src/views/EditPiantaView.vue`
- Modify: `src/views/PianteView.vue`
- Modify: `src/views/PiantaView.vue`
- Test: verifica manuale

**Interfaces:**
- Consumes: `store.zone[nome].id`, `store.sottozone[nomeZona][nomeSottozona].id` (Task 3-5), `useSupabase()`, `useDatiStore()`.
- Produces: `usePianteApi()` → `{ salvaPianta, eliminaPianta, registraCura, registraCuraMultipla, rinominaSpecieInPiante }` (gli ultimi tre implementati in Task 7-8, qui solo dichiarati/esportati vuoti nel file ma non ancora usati altrove). Usata da Task 7 (`registraCura`/`registraCuraMultipla`) e Task 8 (`rinominaSpecieInPiante`), che estendono questo stesso file.

- [ ] **Step 1: Crea `usePianteApi.js` con `salvaPianta` ed `eliminaPianta`**

Crea `src/composables/usePianteApi.js`:

```js
// CRUD piante su Supabase (Fase 5). Centralizza qui la logica comune agli
// 8 punti di scrittura sparsi in EditPiantaView/PianteView/PiantaView/
// AttivitaRiga/AttivitaView/SelettoreSpecie, invece di duplicarla: ognuno
// diventava un update/insert/delete quasi identico una volta lasciato il
// pattern "riscrivi l'intero piante.json" (saveJSON).

import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'

function oggi() {
  return new Date().toISOString().split('T')[0]
}

export function usePianteApi() {
  const store = useDatiStore()
  const supabase = useSupabase()

  // isNuova: se true, id è generato dal chiamante (stesso formato
  // "slug-timestamp" di sempre) e la riga viene creata; altrimenti id
  // identifica una riga esistente da aggiornare.
  async function salvaPianta({ id, isNuova, specie, zona, sottozona, coltivato_in, varieta, impianto, impianto_circa, note }) {
    const zonaId = store.zone?.[zona]?.id ?? null
    const sottozonaId = sottozona ? (store.sottozone?.[zona]?.[sottozona]?.id ?? null) : null
    const riga = {
      specie, zona_id: zonaId, sottozona_id: sottozonaId,
      varieta: varieta || '', impianto: impianto || '', impianto_circa: impianto_circa || '',
      note: note || '', coltivato_in: coltivato_in || null,
    }

    if (isNuova) {
      const { error } = await supabase.from('piante').insert({ id, ...riga, ultima_cura: {} })
      if (error) throw error
    } else {
      const { error } = await supabase.from('piante').update(riga).eq('id', id)
      if (error) throw error
    }

    store.piante = {
      ...store.piante,
      [id]: {
        specie, zona, sottozona: sottozona || null,
        varieta: riga.varieta, impianto: riga.impianto, impianto_circa: riga.impianto_circa,
        note: riga.note, coltivato_in: riga.coltivato_in,
        ultima_cura: isNuova ? {} : (store.piante?.[id]?.ultima_cura ?? {}),
      },
    }
  }

  async function eliminaPianta(id) {
    const { error } = await supabase.from('piante').delete().eq('id', id)
    if (error) throw error
    const nuove = { ...store.piante }
    delete nuove[id]
    store.piante = nuove
  }

  return { salvaPianta, eliminaPianta }
}
```

- [ ] **Step 2: Usa `usePianteApi` in `EditPiantaView.vue`**

In `src/views/EditPiantaView.vue`, sostituisci:

```js
import { useApi } from '@/composables/useApi'
```

con:

```js
import { usePianteApi } from '@/composables/usePianteApi'
```

Sostituisci:

```js
const { saveJSON } = useApi()
```

con:

```js
const pianteApi = usePianteApi()
```

Sostituisci:

```js
async function salva() {
  if (!form.value.specie || !form.value.zona || salvando.value) return
  salvando.value = true
  const id = isNuova.value ? `${form.value.specie}-${Date.now()}` : route.params.id
  try {
    const nuove = await saveJSON('piante.json', (correnti) => {
      const base = { ...(correnti ?? store.piante) }
      const piantaEsistente = isNuova.value ? {} : (base[id] || {})
      base[id] = {
        ...piantaEsistente,
        specie:    form.value.specie,
        zona:      form.value.zona,
        sottozona: form.value.sottozona || null,
        coltivato_in: form.value.coltivatoIn || null,
        varieta:   form.value.varieta  || '',
        impianto:  form.value.impianto || '',
        impianto_circa: form.value.impianto_circa || '',
        note:      form.value.note     || '',
        ultima_cura: piantaEsistente.ultima_cura || {},
      }
      return base
    })
    store.piante = nuove
    router.push(isNuova.value ? '/piante' : `/piante/${id}`)
  } finally {
    salvando.value = false
  }
}
```

con:

```js
async function salva() {
  if (!form.value.specie || !form.value.zona || salvando.value) return
  salvando.value = true
  const id = isNuova.value ? `${form.value.specie}-${Date.now()}` : route.params.id
  try {
    await pianteApi.salvaPianta({
      id,
      isNuova: isNuova.value,
      specie: form.value.specie,
      zona: form.value.zona,
      sottozona: form.value.sottozona || null,
      coltivato_in: form.value.coltivatoIn || null,
      varieta: form.value.varieta || '',
      impianto: form.value.impianto || '',
      impianto_circa: form.value.impianto_circa || '',
      note: form.value.note || '',
    })
    router.push(isNuova.value ? '/piante' : `/piante/${id}`)
  } finally {
    salvando.value = false
  }
}
```

- [ ] **Step 3: Usa `usePianteApi` in `PianteView.vue`**

In `src/views/PianteView.vue`, sostituisci:

```js
import { useApi } from '@/composables/useApi'
import { useGalleria } from '@/composables/useGalleria'
```

con:

```js
import { usePianteApi } from '@/composables/usePianteApi'
import { useGalleria } from '@/composables/useGalleria'
```

Sostituisci:

```js
const store      = useDatiStore()
const route      = useRoute()
const { saveJSON } = useApi()
const galleria   = useGalleria()
```

con:

```js
const store      = useDatiStore()
const route      = useRoute()
const pianteApi  = usePianteApi()
const galleria   = useGalleria()
```

Sostituisci:

```js
async function eliminaPianta() {
  if (!daEliminare.value) return
  eliminando.value = true
  const id = daEliminare.value.id
  try {
    await galleria.eliminaCartella(id)
    const nuove = await saveJSON('piante.json', (correnti) => {
      const base = { ...(correnti ?? store.piante) }
      delete base[id]
      return base
    })
    store.piante = nuove
    daEliminare.value = null
  } finally {
    eliminando.value = false
  }
}
```

con:

```js
async function eliminaPianta() {
  if (!daEliminare.value) return
  eliminando.value = true
  const id = daEliminare.value.id
  try {
    await galleria.eliminaCartella(id)
    await pianteApi.eliminaPianta(id)
    daEliminare.value = null
  } finally {
    eliminando.value = false
  }
}
```

- [ ] **Step 4: Usa `usePianteApi` per l'eliminazione in `PiantaView.vue`**

In `src/views/PiantaView.vue`, sostituisci:

```js
import { useApi } from '@/composables/useApi'
import { useGalleria } from '@/composables/useGalleria'
```

con:

```js
import { usePianteApi } from '@/composables/usePianteApi'
import { useGalleria } from '@/composables/useGalleria'
```

Sostituisci:

```js
const route  = useRoute()
const router = useRouter()
const store  = useDatiStore()
const { saveJSON } = useApi()
const galleria = useGalleria()
```

con:

```js
const route  = useRoute()
const router = useRouter()
const store  = useDatiStore()
const pianteApi = usePianteApi()
const galleria = useGalleria()
```

Sostituisci:

```js
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
```

con:

```js
async function eliminaPianta() {
  if (!pianta.value) return
  eliminando.value = true
  const id = pianta.value.id
  try {
    await galleria.eliminaCartella(id)
    await pianteApi.eliminaPianta(id)
    router.push('/piante')
  } finally {
    eliminando.value = false
  }
}
```

(La funzione `registraCura` in questo stesso file, che usa ancora `saveJSON`, viene sostituita nel Task 7 — lascia `useApi`/`saveJSON` importato per ora, sarà rimosso quando anche quella funzione passa a `usePianteApi`.)

- [ ] **Step 5: Verifica manuale**

Run: `npm run build`
Expected: build senza errori (in `PiantaView.vue` l'import `useApi` risulterà temporaneamente usato solo da `registraCura`, ancora presente fino al Task 7 — nessun errore di lint/build per questo).

Run: `npm run dev`

Apri `http://localhost:5173/#/piante/nuova`. Verifica:
- Creare una pianta nuova (specie, zona, sottozona, varietà, note), verificarne la comparsa in `/piante` e la scheda corretta in `/piante/:id`.
- Modificarla (cambiare zona e sottozona), verificare che la scheda rifletta il cambio.
- Eliminarla da `/piante` (icona nella riga) e da `/piante/:id` (pulsante "Elimina pianta"): sparisce in entrambi i casi, nessun errore in console.

- [ ] **Step 6: Commit**

```bash
git add src/composables/usePianteApi.js src/views/EditPiantaView.vue src/views/PianteView.vue src/views/PiantaView.vue
git commit -m "Sposta creazione/modifica/eliminazione piante su Supabase (Fase 5)"
```

---

### Task 7: Piante — registrazione cura (singola e bulk)

**Files:**
- Modify: `src/composables/usePianteApi.js`
- Modify: `src/components/AttivitaRiga.vue`
- Modify: `src/views/AttivitaView.vue`
- Modify: `src/views/PiantaView.vue`
- Test: verifica manuale

**Interfaces:**
- Consumes: `store.piante[id].ultima_cura` (Task 3), `usePianteApi()` (Task 6, estesa qui).
- Produces: `registraCura(id, tipo, data?) => Promise<void>`, `registraCuraMultipla(voci: Array<{piantaId, tipo}>, data?) => Promise<void>` aggiunte a `usePianteApi()`. Non consumate da altri task di questo piano.

- [ ] **Step 1: Aggiungi `registraCura` e `registraCuraMultipla` a `usePianteApi.js`**

In `src/composables/usePianteApi.js`, subito prima di `return { salvaPianta, eliminaPianta }`, aggiungi:

```js
  async function registraCura(id, tipo, data = oggi()) {
    const piantaEsistente = store.piante?.[id] ?? {}
    const ultima_cura = { ...(piantaEsistente.ultima_cura || {}), [tipo]: data }
    const { error } = await supabase.from('piante').update({ ultima_cura }).eq('id', id)
    if (error) throw error
    store.piante = { ...store.piante, [id]: { ...piantaEsistente, ultima_cura } }
  }

  // Raggruppa per pianta prima di scrivere: un gruppo può contenere più voci
  // per la stessa pianta (es. irrigazione E concimazione insieme), e ognuna
  // deve arrivare a un'unica riga jsonb finale — chiamare registraCura in
  // parallelo per la stessa pianta perderebbe una delle due (entrambe
  // leggerebbero lo stesso ultima_cura di partenza prima di scrivere).
  async function registraCuraMultipla(voci, data = oggi()) {
    const perPianta = new Map()
    for (const { piantaId, tipo } of voci) {
      if (!perPianta.has(piantaId)) perPianta.set(piantaId, { ...(store.piante?.[piantaId]?.ultima_cura ?? {}) })
      perPianta.get(piantaId)[tipo] = data
    }
    await Promise.all([...perPianta.entries()].map(async ([id, ultima_cura]) => {
      const { error } = await supabase.from('piante').update({ ultima_cura }).eq('id', id)
      if (error) throw error
      store.piante = { ...store.piante, [id]: { ...store.piante[id], ultima_cura } }
    }))
  }

```

Sostituisci:

```js
  return { salvaPianta, eliminaPianta }
```

con:

```js
  return { salvaPianta, eliminaPianta, registraCura, registraCuraMultipla }
```

- [ ] **Step 2: Usa `registraCura` in `AttivitaRiga.vue`**

In `src/components/AttivitaRiga.vue`, sostituisci:

```js
import { useApi } from '@/composables/useApi'
```

con:

```js
import { usePianteApi } from '@/composables/usePianteApi'
```

Sostituisci:

```js
const espansa = ref(false)
const store = useDatiStore()
const { saveJSON } = useApi()
```

con:

```js
const espansa = ref(false)
const store = useDatiStore()
const pianteApi = usePianteApi()
```

Sostituisci:

```js
const salvandoTipo = ref(null)
async function registraCuraTipo(tipo) {
  if (!pianta.value || salvandoTipo.value) return
  salvandoTipo.value = tipo
  const id = props.item.piantaId
  try {
    const nuove = await saveJSON('piante.json', (correnti) => {
      const base = { ...(correnti ?? store.piante) }
      const piantaEsistente = base[id] || {}
      base[id] = {
        ...piantaEsistente,
        ultima_cura: { ...(piantaEsistente.ultima_cura || {}), [tipo]: new Date().toISOString().split('T')[0] },
      }
      return base
    })
    store.piante = nuove
  } finally {
    salvandoTipo.value = null
  }
}
```

con:

```js
const salvandoTipo = ref(null)
async function registraCuraTipo(tipo) {
  if (!pianta.value || salvandoTipo.value) return
  salvandoTipo.value = tipo
  const id = props.item.piantaId
  try {
    await pianteApi.registraCura(id, tipo)
  } finally {
    salvandoTipo.value = null
  }
}
```

- [ ] **Step 3: Usa `registraCura`/`registraCuraMultipla` in `AttivitaView.vue`**

In `src/views/AttivitaView.vue`, aggiungi l'import (accanto agli altri, `useApi` resta perché ancora usato da `registraTappa` per `progetti.json`):

```js
import { usePianteApi } from '@/composables/usePianteApi'
```

Sostituisci:

```js
const store    = useDatiStore()
const { saveJSON } = useApi()
const salvando = ref(null)
```

con:

```js
const store    = useDatiStore()
const { saveJSON } = useApi()
const pianteApi = usePianteApi()
const salvando = ref(null)
```

Sostituisci:

```js
async function registra(item) {
  if (salvando.value || salvandoGruppo.value) return
  salvando.value = item.key
  try {
    const nuove = await saveJSON('piante.json', (correnti) => {
      const base = { ...(correnti ?? store.piante) }
      const piantaEsistente = base[item.piantaId] || {}
      base[item.piantaId] = {
        ...piantaEsistente,
        ultima_cura: {
          ...(piantaEsistente.ultima_cura || {}),
          [item.tipo]: new Date().toISOString().split('T')[0],
        }
      }
      return base
    })
    store.piante = nuove
  } finally {
    salvando.value = null
  }
}

async function registraGruppo(gruppo) {
  if (salvandoGruppo.value || salvando.value) return
  salvandoGruppo.value = gruppo.chiave
  try {
    const oggi = new Date().toISOString().split('T')[0]
    const nuove = await saveJSON('piante.json', (correnti) => {
      const base = { ...(correnti ?? store.piante) }
      for (const item of gruppo.items) {
        const piantaEsistente = base[item.piantaId] || {}
        base[item.piantaId] = {
          ...piantaEsistente,
          ultima_cura: { ...(piantaEsistente.ultima_cura || {}), [item.tipo]: oggi },
        }
      }
      return base
    })
    store.piante = nuove
  } finally {
    salvandoGruppo.value = null
  }
}
```

con:

```js
async function registra(item) {
  if (salvando.value || salvandoGruppo.value) return
  salvando.value = item.key
  try {
    await pianteApi.registraCura(item.piantaId, item.tipo)
  } finally {
    salvando.value = null
  }
}

async function registraGruppo(gruppo) {
  if (salvandoGruppo.value || salvando.value) return
  salvandoGruppo.value = gruppo.chiave
  try {
    await pianteApi.registraCuraMultipla(gruppo.items)
  } finally {
    salvandoGruppo.value = null
  }
}
```

- [ ] **Step 4: Usa `registraCura` in `PiantaView.vue`**

In `src/views/PiantaView.vue`, sostituisci:

```js
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
```

con:

```js
async function registraCura(tipo) {
  if (!pianta.value || salvando.value) return
  salvando.value = tipo
  const id = pianta.value.id
  try {
    await pianteApi.registraCura(id, tipo)
  } finally {
    salvando.value = null
  }
}
```

Rimuovi ora l'import ormai inutilizzato: sostituisci

```js
import { useApi } from '@/composables/useApi'
import { usePianteApi } from '@/composables/usePianteApi'
```

con:

```js
import { usePianteApi } from '@/composables/usePianteApi'
```

- [ ] **Step 5: Verifica manuale**

Run: `npm run build`
Expected: build senza errori.

Run: `npm run dev`

Apri `http://localhost:5173/#/piante/:id` di una pianta con almeno una cura configurata. Verifica:
- "✓ Fatto" su una cura aggiorna subito la data mostrata; ricarica la pagina (`F5`) e verifica che la data registrata sia persistita (letta di nuovo da Supabase).

Apri `http://localhost:5173/#/attivita`. Verifica:
- "✓ Fatto" su una singola riga funziona come prima.
- Espandi una riga (click sulla card) e usa "✓ Fatto" per un singolo tipo di cura nel dettaglio: funziona.
- Se ci sono almeno 2 attività della stessa zona/sottozona, usa "✓ Segna tutto fatto" sul gruppo: verifica che **tutte** le piante del gruppo risultino aggiornate dopo il refresh, incluso il caso in cui una stessa pianta compaia nel gruppo per due tipi di cura diversi (es. irrigazione e concimazione): entrambe le date devono risultare aggiornate, non solo una.

- [ ] **Step 6: Commit**

```bash
git add src/composables/usePianteApi.js src/components/AttivitaRiga.vue src/views/AttivitaView.vue src/views/PiantaView.vue
git commit -m "Sposta la registrazione delle cure (singola e bulk) su Supabase (Fase 5)"
```

---

### Task 8: Piante — rinomina specie a cascata

**Files:**
- Modify: `src/composables/usePianteApi.js`
- Modify: `src/components/SelettoreSpecie.vue`
- Test: verifica manuale

**Interfaces:**
- Consumes: `usePianteApi()` (Task 6-7, estesa qui).
- Produces: `rinominaSpecieInPiante(vecchioSlug, nuovoSlug) => Promise<void>` aggiunta a `usePianteApi()`. Ultimo task del piano che tocca `usePianteApi.js`.

- [ ] **Step 1: Aggiungi `rinominaSpecieInPiante` a `usePianteApi.js`**

In `src/composables/usePianteApi.js`, subito prima di `return { salvaPianta, eliminaPianta, registraCura, registraCuraMultipla }`, aggiungi:

```js
  async function rinominaSpecieInPiante(vecchioSlug, nuovoSlug) {
    const { error } = await supabase.from('piante').update({ specie: nuovoSlug }).eq('specie', vecchioSlug)
    if (error) throw error
    const nuove = { ...store.piante }
    for (const id of Object.keys(nuove)) {
      if (nuove[id].specie === vecchioSlug) nuove[id] = { ...nuove[id], specie: nuovoSlug }
    }
    store.piante = nuove
  }

```

Sostituisci:

```js
  return { salvaPianta, eliminaPianta, registraCura, registraCuraMultipla }
```

con:

```js
  return { salvaPianta, eliminaPianta, registraCura, registraCuraMultipla, rinominaSpecieInPiante }
```

- [ ] **Step 2: Usa `rinominaSpecieInPiante` in `SelettoreSpecie.vue`**

In `src/components/SelettoreSpecie.vue`, sostituisci l'import:

```js
import { useApi } from '@/composables/useApi'
```

con:

```js
import { usePianteApi } from '@/composables/usePianteApi'
```

Sostituisci:

```js
const store = useDatiStore()
const { saveJSON } = useApi()
const supabase = useSupabase()
```

con:

```js
const store = useDatiStore()
const pianteApi = usePianteApi()
const supabase = useSupabase()
```

Sostituisci:

```js
    if (chiaveOriginale && chiaveOriginale !== chiave) {
      const nuovePiante = await saveJSON('piante.json', (correnti) => {
        const base = { ...(correnti ?? store.piante) }
        for (const id of Object.keys(base)) {
          if (base[id].specie === chiaveOriginale) {
            base[id] = { ...base[id], specie: chiave }
          }
        }
        return base
      })
      store.piante = nuovePiante
      if (props.modelValue === chiaveOriginale) emit('update:modelValue', chiave)
    }
```

con:

```js
    if (chiaveOriginale && chiaveOriginale !== chiave) {
      await pianteApi.rinominaSpecieInPiante(chiaveOriginale, chiave)
      if (props.modelValue === chiaveOriginale) emit('update:modelValue', chiave)
    }
```

- [ ] **Step 3: Verifica manuale**

Run: `npm run build`
Expected: build senza errori.

Run: `npm run dev`

Apri `http://localhost:5173/#/piante/nuova`, apri il selettore specie, modifica una specie esistente **cambiandone il nome** (in modo che lo slug cambi) — usa una specie assegnata ad almeno una pianta di prova. Verifica:
- Il salvataggio va a buon fine.
- La pianta che referenziava la vecchia specie mostra ora la specie con il nuovo nome/slug (controlla `/piante/:id` di quella pianta).
- Nessun errore in console.

- [ ] **Step 4: Commit**

```bash
git add src/composables/usePianteApi.js src/components/SelettoreSpecie.vue
git commit -m "Sposta la rinomina specie a cascata sulle piante su Supabase (Fase 5)"
```

---

### Task 9: Offline — cache Supabase e pulizia al logout

**Files:**
- Modify: `vite.config.js`
- Modify: `src/composables/useAuth.js`
- Test: verifica manuale (build di produzione + rete disattivata)

**Interfaces:**
- Consumes: nessuna da task precedenti.
- Produces: nessuna interfaccia consumata da altri task (ultimo aspetto funzionale del piano).

- [ ] **Step 1: Aggiungi la regola di cache per il dominio REST Supabase**

In `vite.config.js`, sostituisci:

```js
      workbox: {
        // Dati del giardino: rete se disponibile, altrimenti l'ultima copia salvata
        // (così l'app resta consultabile in giardino senza campo/rete).
        runtimeCaching: [
          {
            urlPattern: /\/giardino\/data\/.*\.json$/,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'giardino-dati',
              networkTimeoutSeconds: 3,
              expiration: { maxEntries: 20, maxAgeSeconds: 60 * 60 * 24 * 30 },
            },
          },
```

con:

```js
      workbox: {
        // Dati del giardino: rete se disponibile, altrimenti l'ultima copia salvata
        // (così l'app resta consultabile in giardino senza campo/rete).
        runtimeCaching: [
          {
            urlPattern: /\/giardino\/data\/.*\.json$/,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'giardino-dati',
              networkTimeoutSeconds: 3,
              expiration: { maxEntries: 20, maxAgeSeconds: 60 * 60 * 24 * 30 },
            },
          },
          {
            // Zone/sottozone/piante (Fase 5) sono solo su Supabase, senza più
            // un fallback JSON statico: questa regola sostituisce quel
            // fallback per restare consultabili offline. La cache è per-URL,
            // non per-utente (il JWT viaggia nell'header, non nell'URL) —
            // svuotata al logout in useAuth.js per non mostrare offline i
            // dati dell'utente precedente su un device condiviso.
            urlPattern: /^https:\/\/ncuhhsvtjwcolhpdxbkt\.supabase\.co\/rest\/v1\/.*/,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'giardino-dati-supabase',
              networkTimeoutSeconds: 3,
              expiration: { maxEntries: 20, maxAgeSeconds: 60 * 60 * 24 * 30 },
            },
          },
```

- [ ] **Step 2: Svuota la cache Supabase al logout**

In `src/composables/useAuth.js`, sostituisci:

```js
supabase.auth.onAuthStateChange((evento, sessione) => {
  utente.value = sessione?.user ?? null
  if (evento === 'PASSWORD_RECOVERY') recuperoInCorso.value = true
})
```

con:

```js
supabase.auth.onAuthStateChange((evento, sessione) => {
  utente.value = sessione?.user ?? null
  if (evento === 'PASSWORD_RECOVERY') recuperoInCorso.value = true
  // La cache del service worker per le risposte Supabase (vite.config.js) è
  // per-URL, non per-utente: su un device condiviso, senza questa pulizia,
  // un secondo utente offline potrebbe vedere temporaneamente i dati
  // dell'utente precedente. `caches` non esiste in ambienti senza service
  // worker (es. alcuni contesti di test): controllo difensivo.
  if (evento === 'SIGNED_OUT' && typeof caches !== 'undefined') {
    caches.delete('giardino-dati-supabase')
  }
})
```

- [ ] **Step 3: Verifica manuale**

Run: `npm run build`
Expected: build senza errori.

Run: `npm run preview` (la cache offline di Workbox è attiva solo in build di produzione, non in `npm run dev`).

Apri l'app nel browser, effettua il login, naviga su `/piante` e `/zone` (così le risposte Supabase vengono cache-ate). Apri gli strumenti sviluppatore → Application → Service Workers, spunta "Offline" (o disattiva la rete). Ricarica `/piante`. Verifica:
- I dati mostrati sono l'ultima copia cache-ata, non una schermata di errore.

Riattiva la rete, poi effettua il logout. Verifica in Application → Cache Storage che la cache `giardino-dati-supabase` non sia più presente (o sia vuota).

- [ ] **Step 4: Commit**

```bash
git add vite.config.js src/composables/useAuth.js
git commit -m "Aggiunge cache offline per Supabase e pulizia al logout (Fase 5)"
```

---

### Task 10: Pulizia, documentazione e verifica finale

**Files:**
- Delete: `public/data/zone.json`, `public/data/sottozone.json`, `public/data/piante.json`
- Modify: `.claude/commands/elabora.md`
- Modify: `CLAUDE.md`
- Test: `execute_sql` (verifica RLS), verifica manuale

**Interfaces:**
- Consumes: tutto il lavoro dei Task 1-9 (verifica di chiusura).
- Produces: nessuna interfaccia consumata da altri task — ultimo task del piano.

- [ ] **Step 1: Elimina i JSON ormai non più letti da nessuno**

Verifica prima che non ci siano riferimenti residui (deve restituire solo righe in `.claude/commands/elabora.md`, sistemate allo Step 2):

Run: `grep -rn "piante\.json\|zone\.json\|sottozone\.json" src/ .claude/`

Expected: nessun risultato in `src/` (tutti i punti sono stati aggiornati nei Task 3-8); eventuali risultati in `.claude/commands/elabora.md` verranno risolti allo Step 2.

Poi:

```bash
git rm public/data/zone.json public/data/sottozone.json public/data/piante.json
```

- [ ] **Step 2: Aggiorna `.claude/commands/elabora.md`**

In `.claude/commands/elabora.md`, sostituisci:

```
   - Leggi `public/data/piante.json` per il contesto del giardino; per le specie, interroga la tabella `specie` su Supabase (MCP `execute_sql`, progetto `ncuhhsvtjwcolhpdxbkt`) per slug o nome — **non `public/data/specie.json`**, che è solo una copia di riserva offline e può essere disallineato (le scritture vanno tutte su Supabase dalla Fase 2)
```

con:

```
   - Interroga le tabelle `piante`, `zone` e `sottozone` su Supabase (MCP `execute_sql`, progetto `ncuhhsvtjwcolhpdxbkt`) per il contesto del giardino; per le specie, interroga allo stesso modo la tabella `specie` per slug o nome — **non `public/data/{piante,zone,sottozone,specie}.json`**, rimasti solo come copie storiche non più aggiornate (le scritture vanno tutte su Supabase: specie dalla Fase 2, zone/sottozone/piante dalla Fase 5). Essendo oggi l'unico utente, puoi interrogare senza filtro su `owner_id`; se in futuro ci fossero più utenti, filtra per l'account di chi ha creato la richiesta (`richieste-agente.json` non ha ancora un campo utente — vedi nota in `CLAUDE.md`)
```

Sostituisci:

```
1. Identifica la pianta/specie di cui parla il messaggio (per nome comune, nome scientifico, zona/sottozona menzionata) in `piante.json` e nella tabella `specie` su Supabase. Se il messaggio è ambiguo (più piante corrispondono, o nessuna), chiedi di specificare nella risposta invece di indovinare.
```

con:

```
1. Identifica la pianta/specie di cui parla il messaggio (per nome comune, nome scientifico, zona/sottozona menzionata) nelle tabelle `piante`/`zone`/`sottozone` e nella tabella `specie` su Supabase. Se il messaggio è ambiguo (più piante corrispondono, o nessuna), chiedi di specificare nella risposta invece di indovinare.
```

Sostituisci:

```
6. `zona`: deducila dal messaggio se è chiaramente indicata (nome zona/sottozona coerente con `zone.json`/`sottozone.json`, o un riferimento generico tipo "orto", "soggiorno"); altrimenti lascia quella già presente (o `null` per un progetto nuovo senza indicazioni).
```

con:

```
6. `zona`: deducila dal messaggio se è chiaramente indicata (nome zona/sottozona coerente con le tabelle `zone`/`sottozone` su Supabase, o un riferimento generico tipo "orto", "soggiorno"); altrimenti lascia quella già presente (o `null` per un progetto nuovo senza indicazioni).
```

- [ ] **Step 3: Aggiorna `CLAUDE.md` — tabella dati e sezione autenticazione**

In `CLAUDE.md`, sostituisci:

```
| File | Contenuto |
|------|-----------|
| `piante.json` | Piante con zona, sottozona, ultima_cura per tipo |
| `specie.json` | Profili di cura per specie (~8700 specie) con manutenzione stagionale — fallback offline, vedi sotto |
| `zone.json` | Metadati delle 6 zone (nome, tipo, esposizione, microclima) |
| `sottozone.json` | Sottozone indicizzate per chiave zona |
| `concimi.json` | Dispensa concimi posseduti, con NPK `{n, p, k}` — usata da `useConcimi.js` per il match con le esigenze della specie |
| `progetti.json` | Progetti del giardino con `tappe[]` (data, descrizione, esito) — schema in `useProgetti.js` |
| `richieste-agente.json` | Coda richieste AI (stato: in_attesa → completata/errore) |
| `settings.json` | Coordinate GPS per Open-Meteo |
```

con:

```
Piante, zone e sottozone sono invece tabelle Supabase (`piante`/`zone`/`sottozone`), con RLS per utente — vedi "Migrazione zone/sottozone/piante → Supabase" più sotto.

| File | Contenuto |
|------|-----------|
| `specie.json` | Profili di cura per specie (~8700 specie) con manutenzione stagionale — fallback offline, vedi sotto |
| `concimi.json` | Dispensa concimi posseduti, con NPK `{n, p, k}` — usata da `useConcimi.js` per il match con le esigenze della specie |
| `progetti.json` | Progetti del giardino con `tappe[]` (data, descrizione, esito) — schema in `useProgetti.js` |
| `richieste-agente.json` | Coda richieste AI (stato: in_attesa → completata/errore) |
| `settings.json` | Coordinate GPS per Open-Meteo |
```

Subito dopo la sezione che termina con:

```
Le migration schema/dati vivono in `supabase/migrations/` (es. `..._aggiunge_colonna_immagine.sql`, batch di popolamento `pfaf_bozza`/`immagini_hero`, import da fonti esterne — vedi `fonti/criterio-importazione.md`).
```

aggiungi una nuova sezione (prima di `### Autenticazione utente (Fase 4 migrazione Supabase, avviata)`):

```

### Migrazione zone/sottozone/piante → Supabase (Fase 5, completata)

Zone, sottozone e piante sono su Supabase (tabelle `zone`, `sottozone`, `piante`), con RLS reale per utente (`owner_id = auth.uid()`, colonna con default `auth.uid()` sulle nuove righe create dall'app) — a differenza di `specie`, qui le policy non sono aperte: ogni utente vede e scrive solo i propri dati. `piante.zona_id`/`sottozona_id` sono foreign key verso `zone`/`sottozone` (non più stringhe libere come nei vecchi JSON): rinominare una zona o sottozona non richiede più aggiornare le piante che la referenziano (prima gestito a mano in `SottozoneView.vue`). `piante.id` resta testo nello stesso formato di sempre (`slug-timestamp`) per compatibilità con la struttura cartelle della gallery foto (`docs/gallery/piante/{id-pianta}/`).

Lo store (`stores/dati.js → caricaTutto()`) ricostruisce comunque la stessa forma a oggetti keyed-by-nome usata da sempre da tutta l'app (`store.zone["Est"]`, `pianta.zona === "Est"`), risolvendo gli id via join lato client (`mappaZone`/`mappaSottozone`/`mappaPiante`) — le view non trattano mai zona/sottozona come id. Le scritture passano da `usePianteApi.js` (creazione/modifica/eliminazione pianta, registrazione cura, rinomina specie a cascata) o da chiamate dirette a Supabase nelle view di zone/sottozone (stesso pattern di `SelettoreSpecie.vue` per le specie): niente più riscrittura dell'intero file JSON con retry su conflitto SHA, ogni riga è indipendente.

Offline: la cache del service worker (Workbox, `vite.config.js`) copre anche il dominio REST di Supabase (`NetworkFirst`), sostituendo il vecchio fallback su file statici per queste tre entità. La cache viene svuotata al logout (`useAuth.js`) per evitare che un device condiviso mostri offline i dati dell'utente precedente.

Fuori scope di questa fase (restano su GitHub/JSON, senza scoping per utente): `progetti.json`, `concimi.json`, `settings.json`, `richieste-agente.json`.
```

Infine, sostituisci il paragrafo conclusivo della sezione Autenticazione:

```
**Importante**: per ora l'account **non controlla ancora nessun dato** — coesiste col token GitHub in `localStorage` (che resta l'unico meccanismo che sblocca le scritture) esattamente come da piano (Fase 4 = login obbligatorio per usare l'app, ma senza scoping dei dati; l'assegnazione dei dati per utente, RLS su `auth.uid()` per zone/piante/progetti/ecc., arriva con la Fase 5, non ancora iniziata).
```

con:

```
**Importante**: l'account ora controlla zone/sottozone/piante (Fase 5, completata — vedi sopra), ma non ancora progetti/concimi/settings/richieste-agente, rimasti su GitHub/JSON senza scoping per utente (round successivo). Il token GitHub in `localStorage` resta necessario per queste scritture non ancora migrate.
```

- [ ] **Step 4: Verifica RLS end-to-end**

Chiama `mcp__claude_ai_Supabase__execute_sql` con `project_id: "ncuhhsvtjwcolhpdxbkt"`:

```sql
select current_setting('request.jwt.claims', true) as jwt, count(*) from zone;
```

Expected: eseguito come ruolo con privilegi elevati (MCP), il conteggio ignora RLS (per verificare i dati). Per verificare che RLS blocchi davvero un accesso senza sessione, apri la Console SQL del progetto Supabase (dashboard, non MCP) e prova:

```sql
set role anon;
select count(*) from zone;
select count(*) from piante;
reset role;
```

Expected: `0` righe in entrambe le query (nessun `auth.uid()` nel contesto `anon` senza JWT, quindi `owner_id = auth.uid()` non è mai vero).

- [ ] **Step 5: Verifica manuale finale — giro completo**

Run: `npm run build && npm run dev`

Percorri l'intera app con l'utente esistente: `/`, `/zone`, `/zone/:zona/sottozone`, `/piante`, `/piante/:id`, `/attivita`. Verifica:
- Nessun dato mancante rispetto a prima della migrazione (stesso numero di zone/sottozone/piante visto in Task 2 Step 3/5).
- Nessun riferimento rotto a `saveJSON('piante.json'|'zone.json'|'sottozone.json', ...)` rimasto (`grep -rn "saveJSON.*\(piante\|zone\|sottozone\)\.json" src/` deve restituire zero risultati).
- Nessun errore in console durante la navigazione.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Rimuove i JSON zone/sottozone/piante ormai sostituiti da Supabase, aggiorna la documentazione (Fase 5)"
```

---

## Self-Review

**Copertura spec:**
- Schema tabelle + RLS → Task 1. ✓
- Migrazione dati esistenti (backfill a `owner_id` del tuo account) → Task 2. ✓
- Store che preserva la forma keyed-by-nome → Task 3. ✓
- Scritture zone (create/update/delete, blocco FK invece di orphaning silenzioso) → Task 4. ✓
- Scritture sottozone (rename senza più cascata manuale su piante, grazie a FK) → Task 5. ✓
- Scritture piante: crea/modifica/elimina → Task 6. ✓
- Scritture piante: registrazione cura singola e bulk (con la correzione della race condition sulla stessa pianta con più tipi nello stesso gruppo) → Task 7. ✓
- Scritture piante: rinomina specie a cascata → Task 8. ✓
- Offline: regola Workbox + pulizia cache al logout → Task 9. ✓
- Pulizia JSON, aggiornamento `elabora.md` e `CLAUDE.md`, verifica RLS finale → Task 10. ✓
- Fuori scope confermato (progetti/concimi/settings/richieste-agente restano su JSON) → documentato in Task 10 Step 3, nessun task li tocca. ✓

**Placeholder scan:** nessun TBD/TODO; ogni step ha codice completo, SQL completo, o comando+output atteso espliciti. Il contenuto della migration di backfill (Task 2) dipende dai dati correnti in `public/data/*.json` per costruzione — non è un placeholder, lo script che lo genera è interamente specificato e deterministico.

**Coerenza tipi/nomi:** `mappaZone`/`mappaSottozone`/`mappaPiante` (Task 3) usate identicamente in `caricaTutto()` (stesso task) e mai altrove — nessuna vista le chiama direttamente, coerente con l'obiettivo di preservare la forma esistente. `usePianteApi()` cresce incrementalmente nei Task 6-8 (`salvaPianta, eliminaPianta` → `+ registraCura, registraCuraMultipla` → `+ rinominaSpecieInPiante`): ogni task che lo estende mostra sia il blocco da aggiungere sia la riga `return` completa aggiornata, così l'ordine di esecuzione dei task non lascia il file in uno stato incoerente. `store.zone[nome].id`/`store.sottozone[nome][nome].id` (introdotti in Task 3) sono l'unico punto da cui Task 4-6 risolvono nome→id: nessuna vista tiene una propria copia di questa risoluzione. `error.code === '23503'` (violazione FK, Task 4) è il codice Postgres standard per `foreign_key_violation`, coerente con il vincolo `on delete restrict` creato in Task 1.

**Nota sull'ordine dei task:** Task 4 e 5 (zone/sottozone) precedono Task 6-8 (piante) perché `usePianteApi.salvaPianta` (Task 6) risolve `zona`/`sottozona` in id leggendo `store.zone`/`store.sottozone`, che devono già esporre `.id` (Task 3) — l'ordine Task 3 → 4 → 5 → 6 non è arbitrario.
