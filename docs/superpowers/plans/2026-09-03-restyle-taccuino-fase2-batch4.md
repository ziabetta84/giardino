# Restyle "Taccuino" — Fase 2 Batch 4 (SelettoreSpecie) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** allineare `src/components/SelettoreSpecie.vue` al linguaggio "Taccuino" — l'ultimo componente con stile proprio non allineato. Chiude l'arco "restyle di tutte le viste/componenti".

**Architecture:** sola presentazione (template + `<style scoped>`). Il sistema di design è completo in `src/assets/main.css` dopo Batch 1–3 (mergiati su `main`, ultimo `4bcb772`): `.field-label` (etichetta di campo uppercase), `.form-card` (già sull'outer del componente), `.form-input`, `.pill`, `.btn*`, token. Nessuna classe nuova in `main.css`. Una sola classe scoped nuova (`.campo-hint`, per 9 paragrafi di aiuto ripetuti inline).

**Tech Stack:** Vue 3 `<script setup>` SFC. Nessun test runner: verifica = `npm run build` exit 0 + controllo visivo.

**Spec:** `docs/superpowers/specs/2026-09-02-restyle-taccuino-design.md` + i componenti/viste di Batch 1–3 come riferimento vivo.

## Global Constraints

- **Branch:** `restyle-taccuino-batch4` (da `main`). Nessun merge/push senza richiesta esplicita di Rob (deploy automatico).
- **Sola presentazione:** template + `<style scoped>`. `<script setup>` **byte-identical**. Non toccare `useDatiStore`, `usePianteApi`, `useSupabase`, `mappaSpecie`/`COLONNE_SPECIE`/`fondiEredita`, `parseGiorni`, `urlMiniatura`, né la logica del combobox/ricerca remota/modale (tab, salvataggio specie, `emit('update:modelValue')`).
- **`--font-serif` NON esiste più** (rimosso in Fase 1). Le 3 occorrenze in questo file (`<h3>` modale riga ~76, `.scheda-nome` ~957, `.scheda-descrizione` ~985) sono un bug latente → `var(--font-display)`.
- **Nessuna nuova regola in `style="…"` inline.** Le 12 `<label style="font-size:11px;font-weight:600;…text-transform:uppercase;…">` (intestazioni di sezione nella modale) → `class="field-label"`. Dove una di queste ha anche `margin:12px 0 2px` o `display:flex` (label Potatura con icona), tieni quell'offset come `style` una-tantum sopra la classe. Le 9 `<p style="font-size:11px;color:var(--ink-faint);margin:…">` (testi di aiuto) → `class="campo-hint"` (scoped, nuova).
- **Non toccare:** `.campo-label` (19 usi — è l'etichetta fine dei sotto-campi, già tokenizzata, NON è il target); il combobox `.specie-dropdown`/`.specie-opzione*`; `.manutenzione-grid`; il `.modal-box` (ha `box-shadow` — è una modale, elevazione corretta, come le altre modali dell'app); i `.badge` inline mini per cultivar/bozza (stato, 2-3 usi — lasciare).
- **Dark mode:** niente blocchi `@media (prefers-color-scheme: dark)` / `[data-theme]` (Fase 3).
- **Verifica:** `npm run build` exit 0. Poi `npm run dev` → apri "Modifica pianta" (`/piante/nuova`) e "Zorba dice" → richiesta "revisione specie" (i due punti d'uso del componente); se il dev server non parte (OOM noto) dirlo e affidarsi a build + lettura ravvicinata.
- **Commit:** italiano, prefisso `restyle:`, con trailer:
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
  ```

---

### Task 1: `SelettoreSpecie.vue` — allineamento al linguaggio

**Files:**
- Modify: `src/components/SelettoreSpecie.vue`

**Interfaces:**
- Consuma: `.field-label`, `.form-card` (già presente), `.form-input`, `.pill`, `.btn*`, `<Icon>`, `Spinner`, `Teleport` — tutte esistenti.
- Produce: il componente al linguaggio Taccuino, invariato nella logica.

- [ ] **Step 1: `<style scoped>` — token dei font**

- `.scheda-nome` (~riga 957): `font-family: var(--font-serif)` → `var(--font-display)`.
- `.scheda-descrizione` (~riga 985): `font-family: var(--font-serif)` → `var(--font-display)`.
- Aggiungi la classe nuova:
  ```css
  .campo-hint {
    margin: 0 0 8px;
    font: 400 11px/1.5 var(--font-sans);
    color: var(--ink-faint);
  }
  ```
  (I margini reali variano: alcuni hint hanno `margin:0 0 6px`, `0 0 8px`, `6px 0 0`. Usa `.campo-hint` con `margin:0 0 8px` come default e, dove serve un margine diverso — es. il hint sotto la griglia manutenzione con `margin:6px 0 0` — tieni un `style="margin:6px 0 0"` una-tantum sopra la classe.)

- [ ] **Step 2: `<template>` — `<h3>` modale**

`<h3 style="font-family:var(--font-serif);font-size:16px;font-weight:600;margin-bottom:12px;">` (~riga 76) → `<h3 style="font-family:var(--font-display);font-size:16px;font-weight:600;margin-bottom:12px;">`.

- [ ] **Step 3: `<template>` — le 12 label uppercase inline → `.field-label`**

Sostituisci ogni `<label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">` (e le varianti con `margin-bottom:2px` / `margin:12px 0 2px`) con `<label class="field-label">`.
- Per quelle che avevano un margine superiore (`margin:12px 0 2px`): `<label class="field-label" style="margin-top:12px">`.
- La label "Potatura (opzionale)" ha `display:flex;align-items:center;gap:5px;margin:12px 0 2px` + un `<Icon>` figlio: `<label class="field-label" style="display:flex;align-items:center;gap:5px;margin-top:12px">` (mantiene icona + testo in linea; `.field-label` è `display:block`, l'override inline `display:flex` vince).
Le label diventano 12 `class="field-label"`; nessuna `<label style="…uppercase…">` inline deve restare (il grep di Task 2 lo verifica).

- [ ] **Step 4: `<template>` — le 9 `<p>` di aiuto → `.campo-hint`**

Ogni `<p style="font-size:11px;color:var(--ink-faint);margin:0 0 6px;">` / `margin:0 0 8px;` / `margin:6px 0 0;` / `margin:0 0 12px;` → `<p class="campo-hint">` (con `style="margin:…"` una-tantum solo dove il margine differisce dal default `0 0 8px`).

- [ ] **Step 5: Build + verifica**

Run: `npm run build` (exit 0), poi `npm run dev` → `/piante/nuova` (il componente in EditPiantaView) e `/agente` → tipo richiesta "revisione specie" (il componente in AgenteView).
Expected: combobox e dropdown invariati (ricerca, opzioni, "Aggiungi nuova specie"); scheda di sola lettura invariata nella struttura, testo in `var(--font-display)`; modale nuova/modifica specie con le 3 tab funzionanti, label di sezione uniformi (`.field-label`), testi di aiuto uniformi (`.campo-hint`); salvataggio specie (insert/update) funzionante; nessun `--font-serif` nel file; nessuna `<label style="…uppercase…">` inline.

- [ ] **Step 6: Commit**

```bash
git add src/components/SelettoreSpecie.vue
git commit -m "restyle: SelettoreSpecie — token font, label di sezione a .field-label, hint a .campo-hint"
```

---

### Task 2: Verifica + nota di esito

**Files:** nessuno (QA) + nota di esito.

- [ ] **Step 1: Build + grep di regressione**

```bash
npm run build   # exit 0
grep -nE "font-serif|title-serif|title-display|gradient-title|title-settle|text-light|section-label" src/components/SelettoreSpecie.vue
grep -n 'font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase' src/components/SelettoreSpecie.vue
```
Expected: primo grep → niente; secondo grep → niente.

- [ ] **Step 2: Giro in `npm run dev`**

`/piante/nuova`, `/piante/<id>/modifica`, `/agente` (revisione specie). Nessun errore console; combobox, dropdown, scheda, modale 3-tab, salvataggio specie tutti invariati.

- [ ] **Step 3: Nota di esito**

`docs/superpowers/plans/2026-09-03-restyle-taccuino-fase2-batch4-esito.md`: cosa è fatto; cosa resta (Fase 3 dark mode; Fase 4 hero stagionale; debito CSS raccolto nelle note precedenti — `.chip` base-chiara, `pill-mini` cursor globale, `.section-label` morta da rimuovere, `.scheda-*` di SelettoreSpecie ancora implementazione parallela di "La specie" di PiantaView, non unificata).

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "restyle: chiusura Batch 4 — nota di esito"
```

---

## Self-Review

**Spec coverage:**
- SelettoreSpecie al linguaggio (ultimo componente non allineato) → Task 1 ✓
- Bug `--font-serif` (token inesistente) → Task 1 Step 1–2 ✓
- DRY label di sezione + hint → Task 1 Step 3–4 (`.field-label` globale + `.campo-hint` scoped) ✓
- Logica invariata (`<script setup>` byte-identical) → Global Constraints ✓
- Fase 3 / Fase 4 → fuori scope, nota di esito Task 2

**Placeholder scan:** Task 1 dà i conteggi reali (12 label, 9 hint, 3 `--font-serif`), le righe approssimative, e le eccezioni esplicite (label Potatura con icona, hint con margine non-standard). Nessun "gestisci i casi limite". `.campo-label` (19 usi) esplicitamente escluso dal target.

**Type/naming consistency:** `.field-label` (globale, Batch 3) e `.campo-hint` (scoped, nuova qui) coerenti tra gli step. `var(--font-display)` (non `--font-serif`). Nessun helper JS introdotto (Batch 4 non tocca `<script>`).
