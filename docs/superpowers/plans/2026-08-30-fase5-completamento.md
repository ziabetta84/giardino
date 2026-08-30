# Completamento Fase 5 (progetti/tappe, settings, concimi) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** completare lo scope della issue #122 non affrontato nella prima parte della Fase 5: migrare `progetti`+`tappe`, `settings` e `concimi` da JSON/GitHub Contents API a tabelle Supabase multi-tenant con RLS reale, più `useZonaClimatica.js` e una view minimale per modificare `settings`.

**Architecture:** stesso pattern già validato in Fase 5 (zone/sottozone/piante): tabelle Supabase con RLS `owner_id = auth.uid()`, funzioni pure di mapping in `src/stores/dati.js` che ricostruiscono la stessa forma keyed-by-id/nome già usata dalle view, composable dedicato per dominio quando servono più punti di scrittura (`useProgettiApi.js`, `useSettingsApi.js`), scrittura diretta da Supabase nella view quando il punto di scrittura è uno solo (`ConcimiView.vue`).

**Tech Stack:** Vue 3 `<script setup>`, Pinia, `@supabase/supabase-js`, PostgreSQL/RLS, Node (`type: module` in `package.json`, quindi `import` ESM diretto anche in script eseguiti da riga di comando).

**Spec:** `docs/superpowers/specs/2026-08-30-fase5-completamento-design.md`

## Global Constraints

- RLS reale `owner_id = auth.uid()` (policy `for all using (...) with check (...)`, una sola policy per tabella) su `progetti`, `tappe`, `concimi`, `settings` — mai la policy "aperta" usata per `specie`.
- `owner_id` non va mai incluso nei payload di insert/update lato client: la colonna ha `default auth.uid()`, stesso pattern di `zone`/`sottozone`/`piante` in Fase 5.
- Progetto Supabase: `ncuhhsvtjwcolhpdxbkt` ("Il Giardino di Zorba"). Per il backfill, `owner_id` esplicito nelle INSERT: `fc227422-ece8-4dca-b706-956ec7ca9e6e` (stesso utente già usato nel backfill di Fase 5, confermato `select distinct owner_id from zone union select distinct owner_id from piante`).
- Migration SQL in `supabase/migrations/`, applicate con `mcp__claude_ai_Supabase__apply_migration` (project_id `ncuhhsvtjwcolhpdxbkt`), non solo scritte su disco.
- Script generatori o di verifica temporanei vanno scritti con percorso **relativo alla radice del repo** (es. `scripts/tmp-*.mjs`), mai un percorso assoluto legato alla sessione corrente (lezione della Fase 5: un percorso assoluto ha rotto la portabilità in worktree) — e cancellati (`rm`) prima del commit del task: solo il file di migration/il codice applicativo finale va committato, mai lo script usa-e-getta.
- Nessuna nuova regola Workbox da aggiungere in `vite.config.js`: la regola `NetworkFirst` su `https://ncuhhsvtjwcolhpdxbkt.supabase.co/rest/v1/.*` già presente da Fase 5 copre l'intero dominio REST, incluse le nuove tabelle.
- `cure_log` e lo script di importazione `coltivazione` sono chiusi come già soddisfatti dall'esistente (`piante.ultima_cura` jsonb, `piante.coltivato_in`) — nessun task di questo piano li tocca.

---

### Task 1: Schema Supabase per progetti/tappe/concimi/settings

**Files:**
- Create: `supabase/migrations/20260830040000_fase5_completamento_schema.sql`

**Interfaces:**
- Produce: tabelle `progetti`, `tappe`, `concimi`, `settings` su Supabase (project `ncuhhsvtjwcolhpdxbkt`), con le colonne esatte sotto — i task successivi le danno per esistenti.

- [ ] **Step 1: Scrivi la migration**

```sql
-- Completamento Fase 5: progetti/tappe, concimi, settings diventano
-- tabelle relazionali multi-tenant (prima JSON su GitHub, senza scoping
-- per utente). tappe è una tabella a parte, non un campo jsonb dentro
-- progetti: oggi esistono due percorsi di scrittura indipendenti sulle
-- tappe (ProgettoView riscrive l'intero form, AttivitaView aggiorna una
-- singola tappa per id da "registraTappa") — una riga per tappa rende
-- ogni scrittura atomica, senza il rischio di un UPDATE su un intero
-- campo jsonb che sovrascrive silenziosamente una modifica concorrente.

create table progetti (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  titolo text not null,
  descrizione text,
  zona text,
  stato text not null default 'aperto'
    check (stato in ('aperto','in_corso','completato','fallito','cancellato')),
  creato date not null default current_date
);

create table tappe (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  progetto_id uuid not null references progetti(id) on delete cascade,
  data date not null,
  descrizione text not null,
  esito text not null default 'atteso'
    check (esito in ('atteso','riuscito','fallito','saltato'))
);

create table concimi (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  nome text not null,
  npk jsonb not null default '{"n":0,"p":0,"k":0}'::jsonb,
  disponibile boolean not null default true,
  descrizione text
);

create table settings (
  owner_id uuid primary key references auth.users default auth.uid(),
  location jsonb,
  units jsonb not null default '{"temperature":"celsius","wind":"kmh","precipitation":"mm"}'::jsonb,
  meteo jsonb not null default '{"provider":"open-meteo","days":3}'::jsonb,
  ui jsonb not null default '{"theme":"auto"}'::jsonb,
  zona_climatica_id uuid references zone_climatiche(id)
);

alter table progetti enable row level security;
alter table tappe enable row level security;
alter table concimi enable row level security;
alter table settings enable row level security;

create policy "progetti: proprietario" on progetti for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "tappe: proprietario" on tappe for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "concimi: proprietario" on concimi for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "settings: proprietario" on settings for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
```

- [ ] **Step 2: Applica la migration**

Usa `mcp__claude_ai_Supabase__apply_migration` con `project_id: "ncuhhsvtjwcolhpdxbkt"`, `name: "fase5_completamento_schema"`, `query`: il contenuto SQL sopra.

- [ ] **Step 3: Verifica**

Usa `mcp__claude_ai_Supabase__list_tables` (project_id `ncuhhsvtjwcolhpdxbkt`, schemas `["public"]`, verbose `true`) e controlla che `progetti`, `tappe`, `concimi`, `settings` compaiano con `rls_enabled: true` e le colonne elencate sopra.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260830040000_fase5_completamento_schema.sql
git commit -m "Aggiunge schema Supabase per progetti/tappe/concimi/settings (Fase 5 completamento)"
```

---

### Task 2: `useZonaClimatica.js`

**Files:**
- Create: `src/composables/useZonaClimatica.js`

**Interfaces:**
- Produce: `calcolaCodiceZonaClimatica({ lat, lon, altitude })` → uno degli 8 `codice` di `zone_climatiche` (`nord`, `nord-montana`, `centro`, `centro-montana`, `sud`, `sud-montana`, `insulare`, `insulare-montana`) o `null` se `lat`/`lon` mancanti. Il Task 3 (backfill) e il futuro `useSettingsApi.js` (Task 7) lo importano.

- [ ] **Step 1: Scrivi il composable**

```js
// Euristica dichiaratamente approssimativa (coerente con stato_verifica
// bozza/verificato già presente sulle righe di zone_climatiche stessa):
// fasce di latitudine per nord/centro/sud continentali, bounding box
// grezzo per Sicilia/Sardegna, soglia di altitudine per le varianti
// "-montana". Non è geolocalizzazione precisa, è un punto di partenza
// sempre modificabile a mano (vedi SettingsView.vue).
const SOGLIA_MONTANA_M = 600

const SARDEGNA = { latMin: 38.8, latMax: 41.3, lonMin: 8.0, lonMax: 9.8 }
const SICILIA  = { latMin: 36.6, latMax: 38.3, lonMin: 12.4, lonMax: 15.7 }

function inBox(lat, lon, box) {
  return lat >= box.latMin && lat <= box.latMax && lon >= box.lonMin && lon <= box.lonMax
}

export function calcolaCodiceZonaClimatica({ lat, lon, altitude = 0 } = {}) {
  if (lat == null || lon == null) return null
  const montana = (altitude ?? 0) >= SOGLIA_MONTANA_M

  if (inBox(lat, lon, SARDEGNA) || inBox(lat, lon, SICILIA)) {
    return montana ? 'insulare-montana' : 'insulare'
  }
  if (lat >= 44.5) return montana ? 'nord-montana' : 'nord'
  if (lat >= 41.5) return montana ? 'centro-montana' : 'centro'
  return montana ? 'sud-montana' : 'sud'
}

export function useZonaClimatica() {
  return { calcolaCodiceZonaClimatica }
}
```

- [ ] **Step 2: Verifica con uno script Node temporaneo**

Crea `scripts/tmp-test-zona-climatica.mjs` (percorso relativo alla radice del repo):

```js
import { calcolaCodiceZonaClimatica } from '../src/composables/useZonaClimatica.js'
import assert from 'node:assert'

// Fano (PU): centro, bassa quota
assert.strictEqual(calcolaCodiceZonaClimatica({ lat: 43.8309591, lon: 12.98603, altitude: 50 }), 'centro')
// Cagliari: insulare
assert.strictEqual(calcolaCodiceZonaClimatica({ lat: 39.2238, lon: 9.1217, altitude: 10 }), 'insulare')
// Cortina d'Ampezzo: nord-montana (lat >= 44.5, alta quota)
assert.strictEqual(calcolaCodiceZonaClimatica({ lat: 46.5369, lon: 12.1357, altitude: 1224 }), 'nord-montana')
// Bari: sud
assert.strictEqual(calcolaCodiceZonaClimatica({ lat: 41.1171, lon: 16.8719, altitude: 5 }), 'sud')
// Coordinate mancanti
assert.strictEqual(calcolaCodiceZonaClimatica({ lat: null, lon: 12 }), null)

console.log('OK: tutti i casi passano')
```

Esegui: `node scripts/tmp-test-zona-climatica.mjs` — atteso: `OK: tutti i casi passano`. Poi `rm scripts/tmp-test-zona-climatica.mjs` (script usa-e-getta, non va committato).

- [ ] **Step 3: Commit**

```bash
git add src/composables/useZonaClimatica.js
git commit -m "Aggiunge useZonaClimatica.js: euristica lat/lon/altitudine -> codice zona_climatiche"
```

---

### Task 3: Backfill dati esistenti

**Files:**
- Create: `supabase/migrations/20260830050000_fase5_completamento_backfill.sql` (generato da script temporaneo, non committato)

**Interfaces:**
- Consuma: `calcolaCodiceZonaClimatica` da `src/composables/useZonaClimatica.js` (Task 2); tabelle `progetti`/`tappe`/`concimi`/`settings` (Task 1).
- Produce: righe reali su Supabase — il Task 4 (store) le legge per verificare il mapping.

- [ ] **Step 1: Scrivi lo script generatore**

Crea `scripts/tmp-genera-backfill-completamento.mjs` (percorso relativo alla radice del repo, dati letti da `public/data/*.json` — ancora presenti a questo punto del piano, cancellati solo nel Task 9):

```js
import fs from 'node:fs'
import crypto from 'node:crypto'
import { calcolaCodiceZonaClimatica } from '../src/composables/useZonaClimatica.js'

const OWNER_ID = 'fc227422-ece8-4dca-b706-956ec7ca9e6e'

function str(v) {
  if (v === null || v === undefined || v === '') return 'null'
  return `'${String(v).replace(/'/g, "''")}'`
}
function json(v) {
  return `'${JSON.stringify(v).replace(/'/g, "''")}'::jsonb`
}

const progetti = JSON.parse(fs.readFileSync('public/data/progetti.json', 'utf8'))
const concimi  = JSON.parse(fs.readFileSync('public/data/concimi.json', 'utf8'))
const settings = JSON.parse(fs.readFileSync('public/data/settings.json', 'utf8'))

const progettiRighe = []
const tappeRighe = []
for (const p of Object.values(progetti)) {
  const id = crypto.randomUUID()
  progettiRighe.push(`  (${str(id)}, ${str(OWNER_ID)}, ${str(p.titolo)}, ${str(p.descrizione)}, ${str(p.zona)}, ${str(p.stato)}, ${str(p.creato)})`)
  for (const t of (p.tappe || [])) {
    tappeRighe.push(`  (${str(crypto.randomUUID())}, ${str(OWNER_ID)}, ${str(id)}, ${str(t.data)}, ${str(t.descrizione)}, ${str(t.esito || 'atteso')})`)
  }
}

const concimiRighe = Object.values(concimi).map(c =>
  `  (${str(crypto.randomUUID())}, ${str(OWNER_ID)}, ${str(c.nome)}, ${json(c.npk)}, ${c.disponibile !== false}, ${str(c.descrizione || null)})`
)

const codiceZona = calcolaCodiceZonaClimatica(settings.location)

let sql = `-- Backfill dati esistenti (generato da scripts/tmp-genera-backfill-completamento.mjs,
-- non committato — vedi supabase/migrations/20260830040000 per lo schema).

insert into progetti (id, owner_id, titolo, descrizione, zona, stato, creato) values
${progettiRighe.join(',\n')};

insert into tappe (id, owner_id, progetto_id, data, descrizione, esito) values
${tappeRighe.join(',\n')};

insert into concimi (id, owner_id, nome, npk, disponibile, descrizione) values
${concimiRighe.join(',\n')};

insert into settings (owner_id, location, units, meteo, ui, zona_climatica_id) values (
  ${str(OWNER_ID)},
  ${json(settings.location)},
  ${json(settings.units)},
  ${json(settings.meteo)},
  ${json(settings.ui)},
  ${codiceZona ? `(select id from zone_climatiche where codice = ${str(codiceZona)})` : 'null'}
);
`

fs.writeFileSync('supabase/migrations/20260830050000_fase5_completamento_backfill.sql', sql)
console.log(`Generati: ${progettiRighe.length} progetti, ${tappeRighe.length} tappe, ${concimiRighe.length} concimi, zona climatica: ${codiceZona}`)
```

Esegui: `node scripts/tmp-genera-backfill-completamento.mjs` — atteso: `Generati: 5 progetti, 40 tappe, 12 concimi, zona climatica: centro`.

- [ ] **Step 2: Applica la migration generata**

Leggi il contenuto di `supabase/migrations/20260830050000_fase5_completamento_backfill.sql` e applicalo con `mcp__claude_ai_Supabase__apply_migration` (project_id `ncuhhsvtjwcolhpdxbkt`, name `fase5_completamento_backfill`).

- [ ] **Step 3: Verifica riga per riga**

Con `mcp__claude_ai_Supabase__execute_sql` (project_id `ncuhhsvtjwcolhpdxbkt`):

```sql
select
  (select count(*) from progetti) as progetti,
  (select count(*) from tappe) as tappe,
  (select count(*) from concimi) as concimi,
  (select count(*) from settings) as settings;
```

Atteso: `progetti=5, tappe=40, concimi=12, settings=1`. Poi:

```sql
select s.zona_climatica_id, z.codice from settings s left join zone_climatiche z on z.id = s.zona_climatica_id;
```

Atteso: `codice = 'centro'`.

- [ ] **Step 4: Pulisci e committa**

```bash
rm scripts/tmp-genera-backfill-completamento.mjs
git add supabase/migrations/20260830050000_fase5_completamento_backfill.sql
git commit -m "Backfill progetti/tappe/concimi/settings esistenti su Supabase (Fase 5 completamento)"
```

---

### Task 4: Store — mapping e caricamento

**Files:**
- Modify: `src/stores/dati.js`

**Interfaces:**
- Consuma: tabelle popolate dal Task 3.
- Produce: `mappaProgetti(righeProgetti, righeTappe)`, `mappaConcimi(righeConcimi)`, `mappaSettings(rigaSettings)` esportate (i Task 5-8 le riusano/estendono nei composable API); `store.progetti`, `store.concimi`, `store.settings` con la stessa forma di prima.

- [ ] **Step 1: Aggiungi le funzioni pure di mapping**

In `src/stores/dati.js`, dopo `mappaPiante` (circa riga 202), aggiungi:

```js
// progetti/tappe (completamento Fase 5): stesso pattern di mappaZone/
// mappaSottozone — righe piatte da Supabase, ricostruite nella forma
// keyed-by-id con tappe annidate che le view già conoscono.
export function mappaProgetti(righeProgetti, righeTappe) {
  const tappePerProgetto = {}
  for (const t of righeTappe) {
    (tappePerProgetto[t.progetto_id] ??= []).push({
      id: t.id, data: t.data, descrizione: t.descrizione, esito: t.esito,
    })
  }
  for (const lista of Object.values(tappePerProgetto)) {
    lista.sort((a, b) => (a.data || '').localeCompare(b.data || ''))
  }
  return Object.fromEntries(righeProgetti.map(p => [p.id, {
    titolo: p.titolo, descrizione: p.descrizione, zona: p.zona,
    stato: p.stato, creato: p.creato,
    tappe: tappePerProgetto[p.id] ?? [],
  }]))
}

export function mappaConcimi(righeConcimi) {
  return Object.fromEntries(righeConcimi.map(c => [c.id, {
    nome: c.nome, npk: c.npk, disponibile: c.disponibile, descrizione: c.descrizione,
  }]))
}

export function mappaSettings(rigaSettings) {
  if (!rigaSettings) return null
  return {
    location: rigaSettings.location, units: rigaSettings.units,
    meteo: rigaSettings.meteo, ui: rigaSettings.ui,
    zona_climatica_id: rigaSettings.zona_climatica_id,
  }
}
```

- [ ] **Step 2: Sostituisci il caricamento JSON con query Supabase in `caricaTutto()`**

Nel blocco `Promise.all` di `caricaTutto()` (circa righe 228-237), sostituisci:

```js
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
```

con:

```js
      const [righeZone, righeSottozone, righePiante, richiesteData, righeProgetti, righeTappe, righeSettings, righeConcimi] =
        await Promise.all([
          query(supabase.from('zone').select('*')),
          query(supabase.from('sottozone').select('*')),
          query(supabase.from('piante').select('*')),
          caricaJSON('richieste-agente.json'),
          query(supabase.from('progetti').select('*')),
          query(supabase.from('tappe').select('*')),
          query(supabase.from('settings').select('*')),
          query(supabase.from('concimi').select('*')),
        ])
```

Poi sostituisci le tre righe:

```js
      progetti.value  = progettiData
      settings.value  = settingsData
      concimi.value   = concimiData
```

con:

```js
      progetti.value  = mappaProgetti(righeProgetti, righeTappe)
      concimi.value   = mappaConcimi(righeConcimi)
      settings.value  = mappaSettings(righeSettings[0] ?? null)
```

- [ ] **Step 3: Verifica**

```bash
npm run build
```

Atteso: build senza errori. Poi, con `mcp__claude_ai_Supabase__execute_sql` (già usato nei task precedenti), confronta il conteggio `select count(*) from progetti` con quello che ti aspetti dopo aver riletto `store.progetti` in dev (`npm run dev`, apri `/progetti` nel browser — dovresti vedere gli stessi 5 progetti di prima, incluse le tappe cliccando su uno).

- [ ] **Step 4: Commit**

```bash
git add src/stores/dati.js
git commit -m "Store: legge progetti/tappe/concimi/settings da Supabase invece che da JSON"
```

---

### Task 5: `useProgettiApi.js`

**Files:**
- Create: `src/composables/useProgettiApi.js`

**Interfaces:**
- Consuma: `useDatiStore` (forma `store.progetti[id] = { titolo, descrizione, zona, stato, creato, tappe: [{id, data, descrizione, esito}] }`, prodotta dal Task 4).
- Produce: `salvaProgetto(id, dati, isNuova)`, `eliminaProgetto(id)`, `registraTappa(tappaId, esito)` — il Task 6 li usa da `ProgettiView.vue`/`ProgettoView.vue`/`AttivitaView.vue`.

- [ ] **Step 1: Scrivi il composable**

```js
// CRUD progetti/tappe su Supabase (completamento Fase 5). registraTappa
// aggiorna una singola riga tappe per id: a differenza di salvaProgetto
// (che riconcilia l'intero form), è pensato per essere sicuro sotto
// scritture concorrenti — vedi la spec per il motivo della tabella tappe
// separata invece di un campo jsonb su progetti.

import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'

export function useProgettiApi() {
  const store = useDatiStore()
  const supabase = useSupabase()

  // dati.tappe: array locale (form) con { id?, data, descrizione, esito }.
  // Tappe senza id sono nuove (insert); quelle con id il cui contenuto è
  // cambiato rispetto allo snapshot originale vengono aggiornate; quelle
  // presenti nello snapshot ma assenti dall'array locale vengono eliminate.
  async function salvaProgetto(id, dati, isNuova = false) {
    const riga = {
      titolo: dati.titolo, descrizione: dati.descrizione || null,
      zona: dati.zona || null, stato: dati.stato, creato: dati.creato,
    }

    let progettoId = id
    if (isNuova) {
      const { data, error } = await supabase.from('progetti').insert(riga).select().single()
      if (error) throw error
      progettoId = data.id
    } else {
      const { error } = await supabase.from('progetti').update(riga).eq('id', id)
      if (error) throw error
    }

    const originali = new Map((store.progetti?.[id]?.tappe ?? []).map(t => [t.id, t]))
    const localiConId = new Set((dati.tappe ?? []).filter(t => t.id).map(t => t.id))

    for (const [tappaId] of originali) {
      if (!localiConId.has(tappaId)) {
        const { error } = await supabase.from('tappe').delete().eq('id', tappaId)
        if (error) throw error
      }
    }

    const tappeFinali = []
    for (const t of (dati.tappe ?? [])) {
      const rigaTappa = { data: t.data, descrizione: t.descrizione.trim(), esito: t.esito || 'atteso' }
      if (t.id) {
        const originale = originali.get(t.id)
        const cambiata = !originale || originale.data !== rigaTappa.data
          || originale.descrizione !== rigaTappa.descrizione || originale.esito !== rigaTappa.esito
        if (cambiata) {
          const { error } = await supabase.from('tappe').update(rigaTappa).eq('id', t.id)
          if (error) throw error
        }
        tappeFinali.push({ id: t.id, ...rigaTappa })
      } else {
        const { data, error } = await supabase.from('tappe')
          .insert({ ...rigaTappa, progetto_id: progettoId }).select().single()
        if (error) throw error
        tappeFinali.push({ id: data.id, ...rigaTappa })
      }
    }
    tappeFinali.sort((a, b) => (a.data || '').localeCompare(b.data || ''))

    store.progetti = {
      ...store.progetti,
      [progettoId]: { ...riga, tappe: tappeFinali },
    }
    return progettoId
  }

  async function eliminaProgetto(id) {
    const { error } = await supabase.from('progetti').delete().eq('id', id)
    if (error) throw error
    const nuovi = { ...store.progetti }
    delete nuovi[id]
    store.progetti = nuovi
  }

  // Aggiorna una singola tappa per id — atomico, nessuna race con salvaProgetto.
  async function registraTappa(tappaId, esito = 'riuscito') {
    const { error } = await supabase.from('tappe').update({ esito }).eq('id', tappaId)
    if (error) throw error
    const nuovi = { ...store.progetti }
    for (const pid of Object.keys(nuovi)) {
      const tappe = nuovi[pid].tappe
      const i = tappe.findIndex(t => t.id === tappaId)
      if (i !== -1) {
        nuovi[pid] = { ...nuovi[pid], tappe: tappe.map((t, idx) => idx === i ? { ...t, esito } : t) }
        break
      }
    }
    store.progetti = nuovi
  }

  return { salvaProgetto, eliminaProgetto, registraTappa }
}
```

- [ ] **Step 2: Verifica**

```bash
npm run build
```

Atteso: nessun errore (il composable non è ancora importato da nessuna view, quindi il build verifica solo la sintassi).

- [ ] **Step 3: Commit**

```bash
git add src/composables/useProgettiApi.js
git commit -m "Aggiunge useProgettiApi.js: CRUD progetti/tappe su Supabase"
```

---

### Task 6: Collega progetti/tappe alle view

**Files:**
- Modify: `src/views/ProgettiView.vue`
- Modify: `src/views/ProgettoView.vue`
- Modify: `src/views/AttivitaView.vue`

**Interfaces:**
- Consuma: `useProgettiApi()` (Task 5).

- [ ] **Step 1: `ProgettiView.vue` — creazione nuovo progetto**

Sostituisci l'import `useApi` con `useProgettiApi`:

```js
import { useProgettiApi } from '@/composables/useProgettiApi'
```

al posto di

```js
import { useApi } from '@/composables/useApi'
```

e sostituisci

```js
const { saveJSON } = useApi()
```

con

```js
const progettiApi = useProgettiApi()
```

Sostituisci l'intera funzione `salvaProgetto`:

```js
async function salvaProgetto() {
  if (!form.value.titolo.trim() || salvando.value) return
  salvando.value = true
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
  } finally {
    salvando.value = false
  }
}
```

- [ ] **Step 2: `ProgettoView.vue` — form completo + eliminazione**

Sostituisci l'import e il const:

```js
import { useProgettiApi } from '@/composables/useProgettiApi'
```

al posto di `useApi`, e

```js
const progettiApi = useProgettiApi()
```

al posto di `const { saveJSON } = useApi()`.

Sostituisci `salva()`:

```js
async function salva() {
  if (!form.value.titolo.trim() || salvando.value) return
  salvando.value = true
  errore.value = null
  const id = route.params.id
  try {
    await progettiApi.salvaProgetto(id, {
      titolo: form.value.titolo.trim(),
      descrizione: form.value.descrizione.trim() || null,
      zona: form.value.zona.trim() || null,
      stato: form.value.stato,
      creato: form.value.creato,
      tappe: form.value.tappe.filter(t => t.data && t.descrizione.trim()),
    }, false)
  } catch (e) {
    errore.value = e.message
  } finally {
    salvando.value = false
  }
}
```

Sostituisci `eliminaProgetto()`:

```js
async function eliminaProgetto() {
  eliminando.value = true
  const id = route.params.id
  try {
    await progettiApi.eliminaProgetto(id)
    router.push('/progetti')
  } finally {
    eliminando.value = false
  }
}
```

- [ ] **Step 3: `AttivitaView.vue` — segna tappa come riuscita**

Sostituisci `registraTappa`:

```js
async function registraTappa(t) {
  const chiave = `${t.progettoId}-${t.indice}`
  if (salvandoTappa.value) return
  salvandoTappa.value = chiave
  try {
    await progettiApi.registraTappa(t.tappa.id, 'riuscito')
  } finally {
    salvandoTappa.value = null
  }
}
```

Nota: `t.tappa` è già disponibile nell'oggetto costruito da `tappeAttese()` (`src/composables/useProgetti.js`), che include `id` da quando `mappaProgetti` (Task 4) lo aggiunge a ogni tappa — nessuna modifica necessaria a `useProgetti.js`.

Aggiungi l'import e il const in cima allo script, accanto agli altri composable già presenti (`pianteApi`):

```js
import { useProgettiApi } from '@/composables/useProgettiApi'
```

```js
const progettiApi = useProgettiApi()
```

Rimuovi l'import di `useApi`/`saveJSON` **solo se** non è più usato per nient'altro nel file (verifica con `grep -n "useApi\|saveJSON" src/views/AttivitaView.vue` prima di toglierlo: se resta un uso legittimo per un'altra risorsa ancora su JSON, lascialo).

- [ ] **Step 4: Verifica manuale**

```bash
npm run dev
```

Apri `/progetti`, crea un progetto nuovo, aprilo, aggiungi/modifica/elimina una tappa, salva, elimina il progetto. Apri `/attivita` e segna una tappa "in scadenza" come fatta. Nessun errore in console.

- [ ] **Step 5: Commit**

```bash
git add src/views/ProgettiView.vue src/views/ProgettoView.vue src/views/AttivitaView.vue
git commit -m "Collega ProgettiView/ProgettoView/AttivitaView a useProgettiApi (Supabase)"
```

---

### Task 7: `useSettingsApi.js` + `SettingsView.vue`

**Files:**
- Create: `src/composables/useSettingsApi.js`
- Create: `src/views/SettingsView.vue`
- Modify: `src/router/index.js`
- Modify: `src/views/AccountView.vue`

**Interfaces:**
- Consuma: `calcolaCodiceZonaClimatica` (Task 2), `useDatiStore` (`store.settings`, Task 4).

- [ ] **Step 1: `useSettingsApi.js`**

```js
import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'
import { calcolaCodiceZonaClimatica } from '@/composables/useZonaClimatica'

export function useSettingsApi() {
  const store = useDatiStore()
  const supabase = useSupabase()

  // zona_climatica_id: calcolato solo se ancora mai impostato (null) —
  // una volta valorizzato (auto o a mano) non viene più ricalcolato, anche
  // se location cambia, per non sovrascrivere una correzione manuale.
  async function salvaSettings(dati) {
    const riga = { location: dati.location, units: dati.units, meteo: dati.meteo, ui: dati.ui }

    if (!store.settings?.zona_climatica_id && dati.location) {
      const codice = calcolaCodiceZonaClimatica(dati.location)
      if (codice) {
        const { data: zc } = await supabase.from('zone_climatiche').select('id').eq('codice', codice).single()
        if (zc) riga.zona_climatica_id = zc.id
      }
    } else if ('zona_climatica_id' in dati) {
      riga.zona_climatica_id = dati.zona_climatica_id
    }

    const { data, error } = await supabase.from('settings').upsert(riga, { onConflict: 'owner_id' }).select().single()
    if (error) throw error
    store.settings = {
      location: data.location, units: data.units, meteo: data.meteo,
      ui: data.ui, zona_climatica_id: data.zona_climatica_id,
    }
  }

  return { salvaSettings }
}
```

- [ ] **Step 2: `SettingsView.vue`**

```vue
<template>
  <div style="max-width:420px;margin:0 auto;">
    <h1 class="title-display gradient-title title-settle" style="font-size:1.9rem;font-weight:800;margin-bottom:16px;">Impostazioni</h1>

    <div class="card" style="padding:18px;margin-bottom:12px;">
      <p class="section-label" style="margin-bottom:10px;">Posizione</p>
      <div style="display:flex;gap:8px;margin-bottom:10px;">
        <input v-model.number="form.lat" type="number" step="0.0001" placeholder="Latitudine" class="form-input">
        <input v-model.number="form.lon" type="number" step="0.0001" placeholder="Longitudine" class="form-input">
      </div>
      <input v-model.number="form.altitude" type="number" placeholder="Altitudine (m)" class="form-input">
    </div>

    <div class="card" style="padding:18px;margin-bottom:12px;">
      <p class="section-label" style="margin-bottom:10px;">Zona climatica</p>
      <select v-model="form.zona_climatica_id" class="form-input">
        <option :value="null">Non impostata</option>
        <option v-for="z in zoneClimatiche" :key="z.id" :value="z.id">{{ z.nome }}</option>
      </select>
    </div>

    <p v-if="errore" style="font-size:12px;color:var(--rose-dark);margin-bottom:10px;">{{ errore }}</p>

    <button @click="salva" :disabled="salvando" class="btn btn-sage" style="width:100%;min-height:44px;">
      <Spinner v-if="salvando" />{{ salvando ? 'Salvataggio…' : 'Salva' }}
    </button>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useSettingsApi } from '@/composables/useSettingsApi'
import { useSupabase } from '@/composables/useSupabase'
import Spinner from '@/components/Spinner.vue'

const store = useDatiStore()
const settingsApi = useSettingsApi()
const supabase = useSupabase()

const salvando = ref(false)
const errore = ref(null)
const zoneClimatiche = ref([])
const form = ref({ lat: null, lon: null, altitude: null, zona_climatica_id: null })

onMounted(async () => {
  await store.caricaTutto()
  const s = store.settings
  form.value = {
    lat: s?.location?.lat ?? null,
    lon: s?.location?.lon ?? null,
    altitude: s?.location?.altitude ?? null,
    zona_climatica_id: s?.zona_climatica_id ?? null,
  }
  const { data } = await supabase.from('zone_climatiche').select('id, nome').order('nome')
  zoneClimatiche.value = data ?? []
})

async function salva() {
  if (salvando.value) return
  salvando.value = true
  errore.value = null
  try {
    await settingsApi.salvaSettings({
      location: { lat: form.value.lat, lon: form.value.lon, altitude: form.value.altitude },
      units: store.settings?.units ?? { temperature: 'celsius', wind: 'kmh', precipitation: 'mm' },
      meteo: store.settings?.meteo ?? { provider: 'open-meteo', days: 3 },
      ui: store.settings?.ui ?? { theme: 'auto' },
      zona_climatica_id: form.value.zona_climatica_id,
    })
  } catch (e) {
    errore.value = e.message || 'Errore durante il salvataggio.'
  } finally {
    salvando.value = false
  }
}
</script>
```

- [ ] **Step 3: Route**

In `src/router/index.js`, aggiungi dopo la riga `/account`:

```js
  { path: '/impostazioni',              name: 'impostazioni',   component: () => import('@/views/SettingsView.vue') },
```

- [ ] **Step 4: Link da `AccountView.vue`**

Dopo il blocco `<div class="card" ...>` del token GitHub (dopo la sua chiusura `</div>`, prima di `<ModalConferma`), aggiungi:

```html
    <RouterLink to="/impostazioni" class="card hover-card" style="display:flex;align-items:center;justify-content:space-between;padding:16px;margin-top:16px;text-decoration:none;color:inherit;">
      <span style="font-size:14px;font-weight:600;">Impostazioni giardino</span>
      <Icon name="freccia-destra" style="width:14px;height:14px;flex-shrink:0;color:var(--ink-faint);" />
    </RouterLink>
```

Se l'icona `freccia-destra` non esiste in `IconDefs.vue`, usa `pin` al suo posto (già usata altrove in `ProgettiView.vue`) — verifica con `grep -n "freccia-destra\|name=\"pin\"" src/components/IconDefs.vue`.

- [ ] **Step 5: Verifica manuale**

```bash
npm run dev
```

Vai su `/account` → "Impostazioni giardino" → `/impostazioni`. Verifica che i campi siano precompilati con i dati esistenti (lat/lon di Fano, zona climatica "Toscana, Marche, Lazio"), modifica un campo, salva, ricarica la pagina e verifica che il valore sia persistito.

- [ ] **Step 6: Commit**

```bash
git add src/composables/useSettingsApi.js src/views/SettingsView.vue src/router/index.js src/views/AccountView.vue
git commit -m "Aggiunge SettingsView.vue e useSettingsApi.js (settings su Supabase)"
```

---

### Task 8: `concimi` su Supabase

**Files:**
- Modify: `src/views/ConcimiView.vue`

**Interfaces:**
- Consuma: `store.concimi` (Task 4, forma `{ nome, npk, disponibile, descrizione }` keyed by uuid).

- [ ] **Step 1: Sostituisci le tre scritture**

Sostituisci l'import:

```js
import { useSupabase } from '@/composables/useSupabase'
```

al posto di `useApi`, e

```js
const supabase = useSupabase()
```

al posto di `const { saveJSON } = useApi()`.

Sostituisci `salva()`:

```js
async function salva() {
  const nome = form.value.nome.trim()
  if (!nome || salvando.value) return
  salvando.value = true
  const riga = {
    nome,
    npk: { n: form.value.n || 0, p: form.value.p || 0, k: form.value.k || 0 },
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
  } finally {
    salvando.value = false
  }
}
```

Sostituisci `toggleDisponibile()`:

```js
async function toggleDisponibile(c) {
  if (salvandoDisponibile.value) return
  salvandoDisponibile.value = c.id
  const disponibile = c.disponibile === false
  try {
    const { error } = await supabase.from('concimi').update({ disponibile }).eq('id', c.id)
    if (error) throw error
    store.concimi = { ...store.concimi, [c.id]: { ...store.concimi[c.id], disponibile } }
  } finally {
    salvandoDisponibile.value = null
  }
}
```

Sostituisci `eliminaConcime()`:

```js
async function eliminaConcime() {
  if (!daEliminare.value) return
  eliminando.value = true
  const id = daEliminare.value
  try {
    const { error } = await supabase.from('concimi').delete().eq('id', id)
    if (error) throw error
    const nuovi = { ...store.concimi }
    delete nuovi[id]
    store.concimi = nuovi
    daEliminare.value = null
  } finally {
    eliminando.value = false
  }
}
```

- [ ] **Step 2: Verifica manuale**

```bash
npm run dev
```

Apri `/concimi`: crea un concime, modificalo, cambia il toggle "disponibile", eliminalo. Nessun errore in console.

- [ ] **Step 3: Commit**

```bash
git add src/views/ConcimiView.vue
git commit -m "Collega ConcimiView a Supabase invece che a concimi.json"
```

---

### Task 9: Pulizia — rimuove i JSON residui, aggiorna la documentazione

**Files:**
- Delete: `public/data/progetti.json`
- Delete: `public/data/settings.json`
- Delete: `public/data/concimi.json`
- Modify: `CLAUDE.md`
- Modify: `.claude/commands/elabora.md`

**Interfaces:**
- Nessuna — task di sola pulizia/documentazione, nessun consumer a valle.

- [ ] **Step 1: Rimuovi i JSON**

```bash
git rm public/data/progetti.json public/data/settings.json public/data/concimi.json
```

- [ ] **Step 2: Verifica che nulla li referenzi più**

```bash
grep -rn "progetti.json\|settings.json\|concimi.json" src/ .claude/commands/elabora.md
```

Atteso: nessun risultato (a parte eventuali menzioni storiche/commenti in CLAUDE.md, che aggiorni al passo successivo).

- [ ] **Step 3: Aggiorna `CLAUDE.md`**

Nella tabella dei file `public/data/`, rimuovi le righe `progetti.json`, `concimi.json`, `settings.json` (restano solo `specie.json` come fallback offline e `richieste-agente.json`).

Nella sezione "Migrazione zone/sottozone/piante → Supabase (Fase 5, completata)", aggiungi in coda un nuovo paragrafo:

```markdown
### Completamento Fase 5: progetti/tappe, settings, concimi → Supabase

Anche `progetti`, `tappe`, `settings` e `concimi` sono ora tabelle Supabase con RLS reale per utente (`owner_id = auth.uid()`), stesso pattern di zone/sottozone/piante. `tappe` è una tabella a sé (non un campo jsonb dentro `progetti`): `ProgettoView.vue` riconcilia l'intero form (insert/update/delete mirati per tappa, via `useProgettiApi.js`), mentre `AttivitaView.vue` aggiorna una singola tappa per id (`registraTappa`) — un campo jsonb condiviso tra questi due percorsi di scrittura avrebbe perso silenziosamente le modifiche concorrenti, una tabella con una riga per tappa lo evita per costruzione.

`settings` è una riga singola per utente (`owner_id` è la chiave primaria). `zona_climatica_id` viene calcolato una sola volta, al primo salvataggio con il campo ancora vuoto, da `useZonaClimatica.js` (euristica su lat/lon/altitudine, mai più ricalcolato dopo per non sovrascrivere una scelta manuale) — modificabile a mano dalla nuova pagina `/impostazioni` (linkata da `/account`).

`cure_log` come tabella a parte e uno script di importazione per `coltivazione` erano nello scope originale della issue #122 ma sono stati chiusi come già soddisfatti: `piante.ultima_cura` (jsonb, solo l'ultima cura per tipo) copre l'unico uso reale oggi (calcolo urgenze), e `piante.coltivato_in` (vaso/terra/acqua) è lo stesso campo già descritto con un altro nome.

`richieste-agente.json` resta l'unico dato ancora su GitHub/JSON senza scoping per utente — legato al comando `/elabora`, eseguito manualmente, va ridiscusso a parte in un round futuro.
```

- [ ] **Step 4: Aggiorna `.claude/commands/elabora.md`**

Cerca i riferimenti a `progetti.json`/`settings.json`/`concimi.json` (es. nella descrizione del tipo `pianifica_progetto`, che oggi dice "crea/aggiorna anche `progetti.json`") e sostituiscili con la tabella Supabase corrispondente, seguendo lo stesso schema già usato quando `revisione_specie` fu aggiornato per scrivere su Supabase invece che su `specie.json` in Fase 5 (Task 10 del piano precedente).

- [ ] **Step 5: Verifica finale**

```bash
npm run build
```

Atteso: build senza errori.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Rimuove progetti/settings/concimi.json, aggiorna CLAUDE.md ed elabora.md"
```
