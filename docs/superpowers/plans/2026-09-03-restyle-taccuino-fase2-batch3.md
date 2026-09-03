# Restyle "Taccuino" — Fase 2 Batch 3 (form e viste di servizio) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** portare al linguaggio "Taccuino" le 5 viste rimaste con i vecchi titoli gradient: **Meteo, Account, Impostazioni, EditZona, EditPianta**.

**Architecture:** intervento di sola presentazione (template + CSS). Il sistema di design è già completo in `src/assets/main.css` dopo Fase 1 e Fase 2 Batch 1+2 (mergiate su `main`, commit `4ca29ff`): `.page-title`/`.page-title__row`, `.slabel`, `.form-input`, `.btn*`, `.pill`/`.pill-icona`, `.card`, `.empty`, token tipografici e cromatici. Batch 3 aggiunge **due sole classi** condivise (`.field-label`, `.form-card` — oggi ripetute inline ~12 volte tra i due form di modifica) e riscrive i template delle 5 viste applicando le classi esistenti. Nessuna logica nuova. Fonte del linguaggio: le viste già fatte (`ProgettiView`, `SettingsView` sarà il modello per le pagine centrate, `PiantaView` per l'intestazione con back-link).

**Tech Stack:** Vue 3 `<script setup>` SFC, Vite 8, Pinia, vue-router. Nessun test runner: verifica per task = `npm run build` (exit 0) + controllo visivo con `npm run dev`.

**Spec:** `docs/superpowers/specs/2026-09-02-restyle-taccuino-design.md` (§4 regole del linguaggio, §9.3 principi per le viste dirette) + le viste di Batch 1+2 come riferimento vivo.

## Global Constraints

- **Branch:** tutto su `restyle-taccuino-batch3` (da creare da `main`). Nessun merge/push su `main` senza richiesta esplicita di Rob (deploy automatico).
- **Sola presentazione:** template + CSS. Non toccare `stores/`, i composable (`useMeteo`, `useAuth`, `useApi`, `useSettingsApi`, `usePianteApi`, `useSupabase`, `useIconeZona`), `router/`, `vite.config.js`, le migration. Nessun cambio a dati, rotte, API, form submission, validazione.
- **Nessuna nuova regola in `style="…"` inline.** Le regole nuove sono classi in `main.css` (le due condivise di Task 1) o `<style scoped>`. Quando un task tocca una vista, gli `style` inline coperti da una classe nuova/esistente vanno rimossi; gli `style` inline che restano devono essere solo layout una-tantum (gap, margin, max-width), mai un set riutilizzabile di proprietà tipografiche.
- **Classi rimosse in Fase 1** da eliminare da ogni vista di Batch 3: `title-display`, `gradient-title`, `title-settle`, `title-serif`, `text-light`, `section-label` (→ `.slabel`). `var(--font-serif)` → `var(--font-display)`.
- **Titolo pagina:** ogni `<h1>` diventa `<h1 class="page-title">` (classe globale già esistente). Se la vista ha un'azione a fianco del titolo usa `.page-title__row`; se ha un back-link sopra il titolo, tienilo com'è (testo piccolo `var(--ink-soft)`), non serve una classe.
- **Card:** i blocchi `<div class="card" style="padding:…">` dei form diventano `<div class="form-card">` (Task 1). La `.card` piena (radius 20px + ombra) resta solo dove è davvero un oggetto sollevato, non per raggruppare campi di un form.
- **Dark mode:** NIENTE blocchi `@media (prefers-color-scheme: dark)` / `:root[data-theme="dark"]` (è Fase 3).
- **Icone:** nessun glifo `plus` nello sprite — le azioni "aggiungi" usano il testo `＋`. Verifica ogni `<Icon name>` nuovo contro `src/components/IconDefs.vue`.
- **Verifica:** `npm run build` exit 0 è l'unica verifica automatica (niente test runner). Poi `npm run dev` per il controllo visivo; se il dev server non parte (OOM noto su questo repo, vedi memoria), dirlo e affidarsi a build + lettura ravvicinata.
- **Commit:** messaggio in italiano, prefisso `restyle:`, un commit per task, con trailer:
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
  ```

---

### Task 1: `main.css` — classi condivise `.field-label` e `.form-card`

**Files:**
- Modify: `src/assets/main.css` (append)

**Interfaces:**
- Produce: `.field-label` (etichetta di campo: uppercase, 11px, `var(--ink-soft)`, `display:block`, `margin-bottom:6px`) e `.form-card` (contenitore leggero per una sezione di form: fondo `var(--white)`, bordo `1px var(--cream-dark)`, `border-radius:14px`, `padding:16px`, niente ombra). Consumate da Task 2–4.

- [ ] **Step 1: Aggiungi il blocco**

In coda a `src/assets/main.css`, un blocco:
```css
/* ===== restyle Fase 2 Batch 3: form e viste di servizio ===== */
.field-label {
  display: block; margin-bottom: 6px;
  font: 600 11px/1.2 var(--font-sans);
  letter-spacing: .05em; text-transform: uppercase;
  color: var(--ink-soft);
}
.form-card {
  background: var(--white);
  border: 1px solid var(--cream-dark);
  border-radius: 14px;
  padding: 16px;
}
```
(La `.field-label` è la stessa regola oggi scoped in `AccountView.vue` — Task 3 la rimuoverà da lì. `.form-card` è la versione senza ombra di `.card` per raggruppare campi.)

- [ ] **Step 2: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 3: Self-review**

- `grep -n "field-label\|form-card" src/assets/main.css` → solo il blocco nuovo.
- Nessun `@media (prefers-color-scheme: dark)` aggiunto; nessun font letterale; nessuna collisione con selettori esistenti (`.field-label`/`.form-card` non pre-esistono in `main.css` — verifica con grep).

- [ ] **Step 4: Commit**

```bash
git add src/assets/main.css
git commit -m "restyle: classi condivise .field-label e .form-card (Batch 3)"
```

---

### Task 2: `MeteoView.vue` — titolo Fraunces + card leggere + `.slabel`

**Files:**
- Modify: `src/views/MeteoView.vue`

**Interfaces:**
- Consuma: `.page-title`, `.slabel`, `.card`/`.form-card`, `<Icon>`, token tipografici.
- Produce: la vista Meteo al linguaggio Taccuino, invariata nella logica (`useMeteo`, timer, overlay dettaglio).

- [ ] **Step 1: Riscrivi il `<template>`**

- `<h1 class="title-display gradient-title title-settle" style="…">Meteo</h1>` → `<h1 class="page-title">Meteo</h1>` (il `margin-bottom` va in uno scoped o resta come `style="margin-bottom:24px"` — margine una-tantum, ammesso).
- Le tre occorrenze di `class="section-label"` ("Adesso", "Oggi, ora per ora") → `class="slabel"` (rimuovi il `style="margin-bottom:…"` inline se `.slabel` ha già il suo margine; verifica in `main.css`).
- `class="title-display"` sul numero grande della temperatura ("{{ adessoMeteo.temp }}°" e nel box dettaglio "{{ tMax }}° / {{ tMin }}°") → rimuovi la classe, metti `font-family:var(--font-display)` (via una scoped `.meteo-temp` / `.meteo-temp--big`, non inline soup — sono 2 punti, una classe scoped va bene).
- Tutte le `class="text-light"` → rimuovi la classe (il colore `var(--ink-soft)`/`var(--ink-faint)` è già negli `style` inline accanto, quindi basta togliere `text-light`; se in qualche punto `text-light` era l'unico portatore di colore, aggiungi `color:var(--ink-soft)` a quello `style`).
- Il "meteo-hero" (`class="card meteo-hero hover-card"`): tienilo come `.card` (è un oggetto sollevato, cliccabile) ma valuta se alleggerire a `.form-card` + `hover-card`. **Decisione:** lascia `.card hover-card` (è la card "Adesso", il pezzo forte della pagina).
- I box "avvisi" e "ora per ora" (`class="card" style="padding:…"`): → `class="form-card"` (raggruppano info, non sono oggetti sollevati). Il box avvisi mantiene `border-color`/`background` rosa via `style` inline (stato, ammesso) o una scoped `.meteo-avvisi`.
- La griglia giorni (`.meteo-giorni-grid` di `.card hover-card`): lascia le card giorno come `.card hover-card` (sono tessere cliccabili) — invariate.
- Skeleton: invariato.

- [ ] **Step 2: `<style scoped>`**

- `.meteo-label { font-family: var(--font-serif); … }` → `var(--font-display)`.
- Aggiungi `.meteo-temp { font-family: var(--font-display); font-weight: 800; }` e usala sui due numeri temperatura (o due classi se le dimensioni differiscono — restano `style="font-size:…"` inline per la dimensione, ammesso).
- Se hai introdotto `.meteo-avvisi`, definiscila qui.

- [ ] **Step 3: Build + verifica**

Run: `npm run build` (exit 0), poi `npm run dev` → `/meteo`.
Expected: titolo Fraunces piatto; etichette sezione come `.slabel`; card dei giorni invariate e cliccabili; overlay dettaglio funziona (apri/chiudi, statistiche); nessun residuo `title-*`/`text-light`/`section-label`/`--font-serif`.

- [ ] **Step 4: Commit**

```bash
git add src/views/MeteoView.vue
git commit -m "restyle: MeteoView — titolo Fraunces, card leggere, .slabel"
```

---

### Task 3: `AccountView.vue` + `SettingsView.vue` — pagine di servizio al linguaggio

**Files:**
- Modify: `src/views/AccountView.vue`
- Modify: `src/views/SettingsView.vue`

**Interfaces:**
- Consuma: `.page-title`, `.slabel`, `.field-label` (Task 1), `.form-card` (Task 1), `.btn*`, `.pill`, `.form-input`, `<Icon>`, `<ZorbaLogo>`, `ModalConferma`, `Spinner`.
- Produce: Account (loggato + login/registrazione/recupero) e Impostazioni al linguaggio Taccuino, logica invariata (`useAuth`, `useApi`, `useSettingsApi`).

- [ ] **Step 1: `AccountView` — ramo loggato**

- `<h1 class="title-display gradient-title title-settle" style="…">Account</h1>` → `<h1 class="page-title">Account</h1>`.
- Le due `class="section-label"` ("Accesso effettuato", "Token GitHub") → `class="slabel"`.
- I due `<div class="card" style="padding:18px;…">` → `<div class="form-card">` (con i loro `margin-top` come `style` inline una-tantum, ammesso). **Nota:** questi due contengono azioni (Esci, gestione token) — se preferisci tenerli `.card` va bene, ma per coerenza con le altre pagine di servizio usa `.form-card`.
- La `RouterLink to="/impostazioni" class="card hover-card" style="…"`: → resta una riga cliccabile — usa `.card hover-card` (è una destinazione) oppure lo stile `.dest` (icona + testo + chevron) già globale. **Decisione:** `.card hover-card`, invariata (minimo intervento).
- `class="link-reset"` (scoped) resta.

- [ ] **Step 2: `AccountView` — ramo non loggato / recupero**

- `<h1 class="title-display gradient-title title-settle" style="font-size:1.6rem;…">` → `<h1 class="page-title" style="font-size:1.5rem">` (dimensione una-tantum per la variante centrata, ammessa) — il testo condizionale resta.
- `class="field-label"` (già scoped in questa vista): **sposta la definizione in `main.css` è Task 1** — qui rimuovi la regola scoped `.field-label { … }` e lascia solo l'uso della classe (ora globale).
- Le `pill tab-icona` (Accedi/Registrati) restano.
- Nessun altro cambio: form, `link-reset`, messaggi errore/successo invariati.

- [ ] **Step 3: `SettingsView`**

- `<h1 class="title-display gradient-title title-settle" style="…">Impostazioni</h1>` → `<h1 class="page-title">Impostazioni</h1>`.
- Le due `class="section-label"` ("Posizione", "Zona climatica") → `class="slabel"`.
- I due `<div class="card" style="padding:18px;margin-bottom:12px;">` → `<div class="form-card" style="margin-bottom:12px">`.
- Bottone "Salva" invariato (`btn btn-sage`, Spinner).

- [ ] **Step 4: Build + verifica**

Run: `npm run build` (exit 0), poi `npm run dev` → `/account` (loggato e, se puoi simularlo, sloggato) e `/impostazioni`.
Expected: titoli Fraunces; sezioni `.slabel`; `.field-label` uniformi (dalla classe globale, non più scoped); form e azioni (Esci, salva token, rimuovi token + `ModalConferma`, login/registrazione/recupero, salva impostazioni) tutte funzionanti; nessun residuo `title-*`/`section-label`; nessuna regola `.field-label` scoped rimasta in AccountView.

- [ ] **Step 5: Commit**

```bash
git add src/views/AccountView.vue src/views/SettingsView.vue
git commit -m "restyle: Account e Impostazioni — titoli Fraunces, .slabel, .field-label/.form-card condivise"
```

---

### Task 4: `EditZonaView.vue` + `EditPiantaView.vue` — form di modifica al linguaggio

**Files:**
- Modify: `src/views/EditZonaView.vue`
- Modify: `src/views/EditPiantaView.vue`

**Interfaces:**
- Consuma: `.page-title`, `.field-label` (Task 1), `.form-card` (Task 1), `.form-input`, `.btn*`, `.pill`/`.pill-icona`, `<Icon>`, `MiniEditor`, `Spinner`, `SelettoreSpecie`.
- Produce: i due form di modifica al linguaggio Taccuino, logica invariata (`useSupabase` per zona, `usePianteApi` per pianta, `useIconeZona`).

- [ ] **Step 1: `EditZonaView`**

- Back-link `← Zone` invariato (testo piccolo).
- `<h1 class="title-display gradient-title title-settle" style="…">{{ isNuova ? 'Nuova zona' : 'Modifica zona' }}</h1>` → `<h1 class="page-title">{{ … }}</h1>`.
- I tre `<div class="card" style="padding:16px;">` → `<div class="form-card">`.
- Ogni `<label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">` (compaiono ~5 volte, alcune con `margin:12px 0 6px`) → `<label class="field-label">` (per quelle con margine superiore diverso, aggiungi `style="margin-top:12px"` una-tantum).
- Griglia icone (`.pill.pill-icona`): invariata (le classi esistono già). Il `<div style="display:grid;…overflow-y:auto;…">` che la contiene: lascia lo `style` inline (layout una-tantum) o spostalo in una scoped `.icone-grid` — a tua scelta, non obbligatorio.
- Checkbox esposizione: invariati (label inline con `accent-color` — ok, è una proprietà singola di stato).
- Bottone salva: `btn btn-rose` invariato.

- [ ] **Step 2: `EditPiantaView`**

- Back-link invariato.
- `<h1 class="title-display gradient-title title-settle" style="…">{{ isNuova ? 'Nuova pianta' : 'Modifica pianta' }}</h1>` → `<h1 class="page-title">{{ … }}</h1>`.
- `<SelettoreSpecie>` invariato (è Batch 4, non si tocca qui).
- I tre `<div class="card" style="padding:16px;">` (Zona, Varietà e impianto, Note) → `<div class="form-card">`.
- Tutte le `<label style="font-size:11px;font-weight:600;color:var(--ink-soft);…">` (~8 occorrenze) → `<label class="field-label">`.
- I bottoni "Coltivata in" (`class="pill"` con `<Icon>`): invariati. Rimuovi solo `style="display:inline-flex;align-items:center;justify-content:center;padding:7px 16px;"` se `.pill` già li centra abbastanza — **verifica**: `.pill` non ha `display:inline-flex` di base, quindi tieni `style="display:inline-flex;align-items:center;justify-content:center"` (layout) ma il `padding:7px 16px` può restare; oppure lascia tutto com'è (nessun obbligo di toccarlo).
- `<textarea class="form-input" style="resize:vertical;font-family:inherit;">`: invariata.
- Bottone salva: `btn btn-rose` invariato.

- [ ] **Step 3: Build + verifica**

Run: `npm run build` (exit 0), poi `npm run dev` → `/zone/nuova`, `/zone/<key>/modifica`, `/piante/nuova`, `/piante/<id>/modifica`.
Expected: titoli Fraunces; `.field-label` uniformi da classe; sezioni `.form-card` (bordo leggero, no ombra); griglia icone zona funzionante; selettore specie invariato; salvataggio zona (insert/update + rename a cascata) e pianta (insert/update) funzionanti; nessun residuo `title-*`; nessuna `<label style="…uppercase…">` inline rimasta.

- [ ] **Step 4: Commit**

```bash
git add src/views/EditZonaView.vue src/views/EditPiantaView.vue
git commit -m "restyle: EditZona e EditPianta — titoli Fraunces, .field-label/.form-card, niente label inline ripetute"
```

---

### Task 5: Verifica integrale Batch 3 + nota di esito

**Files:** nessuno (QA) + nota di esito.

- [ ] **Step 1: Build pulito**

Run: `npm run build` → exit 0.

- [ ] **Step 2: `grep` di regressione**

```bash
grep -rn "title-display\|gradient-title\|title-settle\|title-serif\|text-light\|section-label\|--font-serif" src/views/MeteoView.vue src/views/AccountView.vue src/views/SettingsView.vue src/views/EditZonaView.vue src/views/EditPiantaView.vue
```
Expected: nessun risultato.

- [ ] **Step 3: Giro in `npm run dev`**

Visita `/meteo`, `/account`, `/impostazioni`, `/zone/nuova`, `/piante/nuova`. Nessun errore in console; nessuna regressione funzionale (form, modali, salvataggi, login).

- [ ] **Step 4: Nota di esito**

Scrivi `docs/superpowers/plans/2026-09-03-restyle-taccuino-fase2-batch3-esito.md`: cosa è fatto, cosa resta (Batch 4 SelettoreSpecie; Fase 3 dark mode), minori/scostamenti.

- [ ] **Step 5: Commit finale**

```bash
git add -A && git commit -m "restyle: chiusura Batch 3 — nota di esito"
```

---

## Self-Review

**Spec coverage:**
- Titolo pagina standard su tutte e 5 le viste → Task 2–4 (`.page-title`) ✓
- Meteo, Account, Impostazioni, EditZona, EditPianta (le 5 rimaste con titoli gradient, da esito Fase 2) → Task 2, 3, 4 ✓
- DRY delle label di campo ripetute inline → Task 1 (`.field-label` globale) + Task 3/4 ✓
- Card di form alleggerite → Task 1 (`.form-card`) + Task 2/3/4 ✓
- Nessun cambio dati/API/dark-mode → Global Constraints ✓
- Batch 4 (SelettoreSpecie), Fase 3 (dark mode) → **fuori scope**, nota di esito Task 5

**Placeholder scan:** ogni task elenca le occorrenze concrete da sostituire (numero di `section-label`, di `<label style>`), i nomi reali dei file e delle classi, le decisioni prese dove c'era una scelta (`.card` vs `.form-card` per il meteo-hero, `.card hover-card` per la riga Impostazioni in AccountView). Nessun "gestisci i casi limite" generico. Le logiche (form submit, `useAuth`, `useMeteo`, rename zona a cascata) sono esplicitamente "invariate".

**Type/naming consistency:** `.field-label` e `.form-card` coerenti tra Task 1 (definizione) e Task 3/4 (uso). `.slabel` (non `.section-label`) ovunque. `.page-title` (classe globale Fase 2, non ridefinita). `var(--font-display)` (non `--font-serif`) ovunque. Nessun nome di helper JS introdotto (Batch 3 non tocca `<script>`).
