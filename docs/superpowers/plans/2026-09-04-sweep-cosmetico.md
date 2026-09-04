# Sweep cosmetico: debiti minori sparsi — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chiudere 7 debiti minori annotati nelle note di esito dei round precedenti (A–G), tutti approvati esplicitamente da Rob dopo triage: catch-all route, cursore `.pill-mini`, focus/hover su `.dossier-x`, unificazione `.alert-cura`/`.alert-meteo` → `.alertbox`, `.chip` con base chiara + variante `--on-photo`, guardia null + tasto Spazio nel mini-grafico Meteo, hover del registro Meteo solo su dispositivi con puntatore.

**Architecture:** Nessuna nuova unità. Tre task: (1) un batch di 5 modifiche indipendenti a basso rischio (A, B, C, F, G) in un solo dispatch; (2) globalizza `.alert-cura`/`.alert-meteo` in `.alertbox` (+ modificatore `--rose`) in `main.css`, lasciando scoped solo le righe (`__row`) che hanno layout diverso tra i due consumatori; (3) rende `.chip` chiara di base con variante `.chip--on-photo`, eliminando due reimplementazioni scoped (`PiantaView.phead-text__chip`, `GalleryView.gpost__hd .chip`).

**Tech Stack:** Vue 3 `<script setup>` SFC, vue-router, CSS custom properties in `src/assets/main.css`. Nessun runner di test.

**Spec:** nessuna spec formale — triage approvato in chat il 2026-09-04 (lista A–G, con motivazione di cosa resta fuori: `.section-label` ancora usata da `PianteView`, vocabolario caroselli non duplicato, `@media(hover:hover)` non esteso a tutta l'app).

## Global Constraints

- **Lingua:** commenti e messaggi di commit in **italiano**.
- **Niente blocchi dark-mode** — Fase 3.
- **Verifica automatica = solo `npm run build` (exit 0).** Non esiste `npm test`.
- **Palette/font solo token.**
- **Nessun cambio di comportamento visibile oltre quanto descritto in ciascun task** — è un giro di pulizia, non un redesign: le modifiche a `.alertbox`/`.chip` devono produrre lo **stesso aspetto** di oggi nei punti che già esistono (PiantaView, MeteoView, GalleryView), non uno nuovo.
- **Commit:** messaggi in italiano, ognuno chiude con:
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
  ```
- **Branch:** `sweep-cosmetico` da `main`. Nessun commit diretto su `main`. Merge solo su ok esplicito di Rob.

---

## File Structure

| File | Modifica |
|------|----------|
| `src/router/index.js` | **Modifica** (Task 1) — catch-all route. |
| `src/assets/main.css` | **Modifica** (Task 1: `.pill-mini` cursore; Task 2: nuovo blocco `.alertbox*`; Task 3: `.chip*` riscritto). |
| `src/components/SelettoreSpecie.vue` | **Modifica** (Task 1) — `.dossier-x` hover/focus. |
| `src/components/MeteoGiorno.vue` | **Modifica** (Task 1) — guardia null in `chart`. |
| `src/views/MeteoView.vue` | **Modifica** (Task 1: tasto Spazio, `.day:hover`; Task 2: `.alert-meteo` → `.alertbox alertbox--rose`). |
| `src/components/AttivitaRiga.vue` | **Modifica** (Task 1) — tasto Spazio. |
| `src/views/ZoneView.vue` | **Modifica** (Task 1) — rimuove `cursor:pointer` ridondante da `.zrow__act .pill-mini`. |
| `src/views/SottozoneView.vue` | **Modifica** (Task 1) — rimuove `cursor:pointer` ridondante da `.dest .pill-mini`. |
| `src/views/PiantaView.vue` | **Modifica** (Task 2: `.alert-cura` → `.alertbox`; Task 3: `.chip`/`.chip--ic` al posto di `.phead-text__chip*`, rimozione delle regole scoped ora ridondanti). |
| `src/views/GalleryView.vue` | **Modifica** (Task 3) — `.gpost__hd .chip` ridotta al solo `flex:none`. |

Nessun file di test.

---

### Task 1: batch a basso rischio (A, B, C, F, G)

**Files:**
- Modify: `src/router/index.js`
- Modify: `src/assets/main.css`
- Modify: `src/components/SelettoreSpecie.vue`
- Modify: `src/components/MeteoGiorno.vue`
- Modify: `src/views/MeteoView.vue`
- Modify: `src/components/AttivitaRiga.vue`
- Modify: `src/views/ZoneView.vue`
- Modify: `src/views/SottozoneView.vue`

**Interfaces:** nessuna — sono ritocchi indipendenti, ognuno dentro un solo file (tranne il cursore `.pill-mini`, che tocca la regola globale + le due copie scoped che la ridefinivano).

- [ ] **Step A — catch-all route**

In `src/router/index.js`, nell'array `routes`, aggiungere come **ultima riga** (dopo `/impostazioni`, prima della `]` di chiusura):

```js
  { path: '/:pathMatch(.*)*',           name: 'not-found',      redirect: '/' },
```

Non toccare il resto del file (la guardia `router.beforeEach` non va modificata: un URL morto non autenticato finisce comunque su `/account` come ogni altra rotta protetta, redirect route → guardia → redirect finale, in quest'ordine).

- [ ] **Step B — cursore `.pill-mini`**

In `src/assets/main.css`, la regola (riga ~358):

```css
.pill-mini { flex:none; font:600 10.5px/1 var(--font-sans); padding:6px 12px;
  border-radius:999px; border:1px solid var(--cream-dark); background:transparent; color:var(--ink-mid); cursor:default; }
```

diventa (solo `cursor:default` → `cursor:pointer`, nient'altro):

```css
.pill-mini { flex:none; font:600 10.5px/1 var(--font-sans); padding:6px 12px;
  border-radius:999px; border:1px solid var(--cream-dark); background:transparent; color:var(--ink-mid); cursor:pointer; }
```

(Verificato: le 6 istanze di `.pill-mini` nel repo sono tutte `<button>` o `<RouterLink>`, nessuna statica — sicuro cambiarla nella base.)

In `src/views/ZoneView.vue`, la regola scoped:

```css
.zrow__act .pill-mini { cursor:pointer; text-decoration:none; display:inline-flex; align-items:center; gap:4px; }
```

diventa (tolto `cursor:pointer;`, ora ridondante):

```css
.zrow__act .pill-mini { text-decoration:none; display:inline-flex; align-items:center; gap:4px; }
```

In `src/views/SottozoneView.vue`, la regola scoped:

```css
.dest .pill-mini { cursor:pointer; display:inline-flex; align-items:center; gap:4px; }
```

diventa:

```css
.dest .pill-mini { display:inline-flex; align-items:center; gap:4px; }
```

- [ ] **Step C — `.dossier-x` hover/focus**

In `src/components/SelettoreSpecie.vue`, subito dopo la regola `.dossier-x--np { background: var(--cream-dark); color: var(--ink-mid); }`, aggiungere:

```css
.dossier-x:hover { opacity: .85; }
.dossier-x:focus-visible { outline: 2px solid currentColor; outline-offset: 2px; }
```

(`currentColor` risolve da solo al colore giusto per entrambe le varianti: `#fdf8ee` sopra la foto, `var(--ink-mid)` su `.dossier-x--np`.)

- [ ] **Step F1 — `MeteoGiorno.vue`: guardia null nel mini-grafico**

Nel `<script setup>` di `src/components/MeteoGiorno.vue`, la funzione `chart` computed va da:

```js
const chart = computed(() => {
  const ore = props.giorno?.ore ?? []
  if (ore.length < 2) return null
  const W = 320, H = 92, pad = 6, bandaUmido = 34
  const temps = ore.map(o => o.temp)
  const tMin = Math.min(...temps)
  const tMax = Math.max(...temps)
  const tSpan = (tMax - tMin) || 1
  const base = H - pad              // pavimento della banda umido
  const bandaTop = base - bandaUmido
  const x = i => pad + (i / (ore.length - 1)) * (W - 2 * pad)
  const yTemp = t => pad + (1 - (t - tMin) / tSpan) * (bandaTop - pad)
  const yPerc = p => base - (Math.max(0, Math.min(100, p ?? 0)) / 100) * bandaUmido
  const nx = i => x(i).toFixed(1)

  const tempPoints = ore.map((o, i) => `${nx(i)},${yTemp(o.temp).toFixed(1)}`).join(' ')
  // Probabilità di pioggia come area continua: pavimento → profilo → pavimento.
  const rainArea = `M${nx(0)},${base} `
    + ore.map((o, i) => `L${nx(i)},${yPerc(o.pioggiaProb).toFixed(1)}`).join(' ')
    + ` L${nx(ore.length - 1)},${base} Z`
  // Umidità dell'aria come linea, solo se tutte le ore hanno il dato.
  const conUmid = ore.every(o => o.umidita != null)
  const umidPoints = conUmid
    ? ore.map((o, i) => `${nx(i)},${yPerc(o.umidita).toFixed(1)}`).join(' ')
    : null

  return {
    W, H, base,
    bandX: pad.toFixed(1), bandY: bandaTop.toFixed(1),
    bandW: (W - 2 * pad).toFixed(1), bandH: bandaUmido.toFixed(1),
    x0: nx(0), xN: nx(ore.length - 1),
    tempPoints, rainArea, umidPoints,
    first: { x: nx(0), y: yTemp(ore[0].temp).toFixed(1) },
    last: { x: nx(ore.length - 1), y: yTemp(ore[ore.length - 1].temp).toFixed(1) },
  }
})
```

a (aggiunta solo la gestione di `temp` nullo: `tMin`/`tMax` calcolati solo sulle ore con dato, `tempPoints` salta le ore senza dato — lascia un vuoto nella linea invece di un punto spurio a 0°C — `first`/`last` usano il primo/ultimo punto con dato; `x(i)` resta sull'indice originale, quindi pioggia/umidità restano allineate):

```js
const chart = computed(() => {
  const ore = props.giorno?.ore ?? []
  if (ore.length < 2) return null
  const W = 320, H = 92, pad = 6, bandaUmido = 34
  // Solo le ore con temperatura nota entrano nel range/nella linea: Math.round(null)
  // sarebbe 0, un punto spurio che trascinerebbe giù tMin. In pratica Open-Meteo
  // non restituisce mai null qui, ma teniamolo esplicito.
  const puntiTemp = ore.map((o, i) => (o.temp != null ? { i, t: o.temp } : null)).filter(Boolean)
  if (puntiTemp.length < 2) return null
  const temps = puntiTemp.map(p => p.t)
  const tMin = Math.min(...temps)
  const tMax = Math.max(...temps)
  const tSpan = (tMax - tMin) || 1
  const base = H - pad              // pavimento della banda umido
  const bandaTop = base - bandaUmido
  const x = i => pad + (i / (ore.length - 1)) * (W - 2 * pad)
  const yTemp = t => pad + (1 - (t - tMin) / tSpan) * (bandaTop - pad)
  const yPerc = p => base - (Math.max(0, Math.min(100, p ?? 0)) / 100) * bandaUmido
  const nx = i => x(i).toFixed(1)

  // Le ore senza temperatura lasciano un vuoto nella linea (indice invariato,
  // per restare allineate a pioggia/umidità che usano tutte le 24 ore).
  const tempPoints = puntiTemp.map(({ i, t }) => `${nx(i)},${yTemp(t).toFixed(1)}`).join(' ')
  // Probabilità di pioggia come area continua: pavimento → profilo → pavimento.
  const rainArea = `M${nx(0)},${base} `
    + ore.map((o, i) => `L${nx(i)},${yPerc(o.pioggiaProb).toFixed(1)}`).join(' ')
    + ` L${nx(ore.length - 1)},${base} Z`
  // Umidità dell'aria come linea, solo se tutte le ore hanno il dato.
  const conUmid = ore.every(o => o.umidita != null)
  const umidPoints = conUmid
    ? ore.map((o, i) => `${nx(i)},${yPerc(o.umidita).toFixed(1)}`).join(' ')
    : null

  const primo = puntiTemp[0]
  const ultimo = puntiTemp[puntiTemp.length - 1]
  return {
    W, H, base,
    bandX: pad.toFixed(1), bandY: bandaTop.toFixed(1),
    bandW: (W - 2 * pad).toFixed(1), bandH: bandaUmido.toFixed(1),
    x0: nx(0), xN: nx(ore.length - 1),
    tempPoints, rainArea, umidPoints,
    first: { x: nx(primo.i), y: yTemp(primo.t).toFixed(1) },
    last: { x: nx(ultimo.i), y: yTemp(ultimo.t).toFixed(1) },
  }
})
```

Non toccare il `<template>` né il `<style>` di questo file.

- [ ] **Step F2 — tasto Spazio su `role="button"`**

In `src/views/MeteoView.vue`, riga ~25-26:

```html
        <div class="adesso" role="button" tabindex="0"
          @click="apriDettaglio(giorni[0])" @keydown.enter="apriDettaglio(giorni[0])">
```

diventa:

```html
        <div class="adesso" role="button" tabindex="0"
          @click="apriDettaglio(giorni[0])" @keydown.enter="apriDettaglio(giorni[0])" @keydown.space.prevent="apriDettaglio(giorni[0])">
```

Riga ~65-66:

```html
          <div v-for="g in giorniSuccessivi" :key="g.data" class="day" role="button" tabindex="0"
            @click="apriDettaglio(g)" @keydown.enter="apriDettaglio(g)">
```

diventa:

```html
          <div v-for="g in giorniSuccessivi" :key="g.data" class="day" role="button" tabindex="0"
            @click="apriDettaglio(g)" @keydown.enter="apriDettaglio(g)" @keydown.space.prevent="apriDettaglio(g)">
```

In `src/components/AttivitaRiga.vue`, righe 3-4:

```html
    role="button" tabindex="0"
    @click="$emit('apri-dossier', item)" @keydown.enter="$emit('apri-dossier', item)">
```

diventa:

```html
    role="button" tabindex="0"
    @click="$emit('apri-dossier', item)" @keydown.enter="$emit('apri-dossier', item)" @keydown.space.prevent="$emit('apri-dossier', item)">
```

- [ ] **Step G — `.day:hover` solo con puntatore**

In `src/views/MeteoView.vue`, la regola:

```css
.day:hover { background: var(--white); }
```

diventa:

```css
@media (hover: hover) { .day:hover { background: var(--white); } }
```

- [ ] **Step finale: build + verifica**

Run: `npm run build`
Expected: exit 0, nessun warning nuovo.

Verifica di lettura:
- `grep -n "pathMatch" src/router/index.js` → la riga aggiunta.
- `grep -n "cursor:default" src/assets/main.css` → **nessun risultato** su `.pill-mini` (potrebbero comparire altri usi legittimi altrove: controllare che non riguardino `.pill-mini`).
- `grep -n "dossier-x:hover\|dossier-x:focus-visible" src/components/SelettoreSpecie.vue` → 2 righe.
- `grep -n "keydown.space" src/views/MeteoView.vue src/components/AttivitaRiga.vue` → 3 occorrenze totali.
- `grep -n "hover: hover" src/views/MeteoView.vue` → 1 riga.

- [ ] **Step: Commit**

```bash
git add src/router/index.js src/assets/main.css src/components/SelettoreSpecie.vue src/components/MeteoGiorno.vue src/views/MeteoView.vue src/components/AttivitaRiga.vue src/views/ZoneView.vue src/views/SottozoneView.vue
git commit -m "$(cat <<'EOF'
sweep: catch-all route, cursore pill-mini, focus dossier-x, guardie Meteo

- router: catch-all -> redirect a / (i vecchi /zone/nuova ecc. non danno
  più pagina bianca)
- .pill-mini: cursore pointer nella base (era default, ridefinito
  scoped in ZoneView/SottozoneView, mancante nel bottone "Fatto" di Home)
- .dossier-x: :hover/:focus-visible (currentColor, vale per entrambe le
  varianti)
- MeteoGiorno: il mini-grafico non pianta più un punto a 0° se un'ora
  non ha temperatura (Math.round(null) altrimenti darebbe 0)
- role="button" (Adesso/registro Meteo, AttivitaRiga): anche Spazio,
  non solo Invio
- MeteoView: .day:hover solo sotto @media(hover:hover), non resta
  appiccicato dopo un tap su touch

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
EOF
)"
```

---

### Task 2: unificare `.alert-cura` / `.alert-meteo` → `.alertbox`

**Files:**
- Modify: `src/assets/main.css`
- Modify: `src/views/PiantaView.vue`
- Modify: `src/views/MeteoView.vue`

**Interfaces:**
- Produce: classi globali `.alertbox`, `.alertbox__ic`, `.alertbox__ic svg`, `.alertbox__main`, `.alertbox__title`, `.alertbox__rows`, `.alertbox--rose` (+ le due varianti annidate `--rose .alertbox__ic` / `--rose .alertbox__title`).
- Consuma: `--olive`/`--olive-ink`/`--rose`/`--rose-ink`/`--cream` (già in `main.css`).
- Restano scoped, perché il contenuto della riga è diverso tra i due consumatori: `.alert-cura__row` in PiantaView (`<span>` + bottone, `justify-content:space-between`), `.alert-meteo__row`/`.alert-meteo__row svg` in MeteoView (icona + testo, allineati a sinistra).

- [ ] **Step 1: aggiungere `.alertbox*` a `main.css`**

Aggiungere in fondo a `src/assets/main.css`:

```css

/* ===== Blocco avviso — icona in tessera + titolo + righe, tinta per dominio =====
   Base olive (PiantaView "Da curare subito"); .alertbox--rose per gli avvisi
   meteo. Il contenuto della riga (.__row) resta scoped nel consumatore: il
   layout differisce (label+bottone vs icona+testo). */
.alertbox { display:flex; gap:12px; align-items:flex-start; padding:14px 15px; margin:16px 0 0;
  background:var(--olive-bg); border:1px solid color-mix(in srgb, var(--olive) 28%, transparent);
  border-radius:16px; box-shadow:none; }
.alertbox__ic { flex:none; width:36px; height:36px; border-radius:11px;
  display:flex; align-items:center; justify-content:center;
  background:color-mix(in srgb, var(--olive) 16%, var(--cream)); color:var(--olive-ink); }
.alertbox__ic svg { width:20px; height:20px; }
.alertbox__main { flex:1; min-width:0; }
.alertbox__title { font:600 14px/1.25 var(--font-display); color:var(--olive-ink); }
.alertbox__rows { display:flex; flex-direction:column; gap:8px; margin-top:8px; }
.alertbox--rose { background:var(--rose-bg); border-color:color-mix(in srgb, var(--rose) 28%, transparent); }
.alertbox--rose .alertbox__ic { background:color-mix(in srgb, var(--rose) 16%, var(--cream)); color:var(--rose-ink); }
.alertbox--rose .alertbox__title { color:var(--rose-ink); }
```

- [ ] **Step 2: `PiantaView.vue` — usare `.alertbox`**

Nel `<template>`, il blocco (riga ~68-72):

```html
      <div v-if="cureUrgenti.length" class="card alert-cura">
        <span class="alert-cura__ic"><Icon name="campanella" /></span>
        <div class="alert-cura__main">
          <div class="alert-cura__title">Da curare subito</div>
          <div class="alert-cura__rows">
```

diventa (solo le 4 classi condivise, `alert-cura__row` **resta invariato** — non è condivisa):

```html
      <div v-if="cureUrgenti.length" class="card alertbox">
        <span class="alertbox__ic"><Icon name="campanella" /></span>
        <div class="alertbox__main">
          <div class="alertbox__title">Da curare subito</div>
          <div class="alertbox__rows">
```

Nel `<style scoped>`, il blocco (righe ~440-462):

```css
/* Alert cura: unico blocco sollevato, tinta olive, sola icona a sinistra.
   Sobrio come nel mockup: niente ombra, bordo tenue, icona tinta (non bianca). */
.alert-cura {
  display: flex; gap: 12px; align-items: flex-start;
  padding: 14px 15px; margin: 16px 0 0;
  background: var(--olive-bg);
  border: 1px solid color-mix(in srgb, var(--olive) 28%, transparent);
  border-radius: 16px; box-shadow: none;
}
.alert-cura__ic {
  flex: none; width: 36px; height: 36px; border-radius: 11px;
  display: flex; align-items: center; justify-content: center;
  background: color-mix(in srgb, var(--olive) 16%, var(--cream)); color: var(--olive-ink);
}
.alert-cura__ic svg { width: 20px; height: 20px; }
.alert-cura__main { flex: 1; min-width: 0; }
.alert-cura__title { font: 600 14px/1.25 var(--font-display); color: var(--olive-ink); }
.alert-cura__rows { display: flex; flex-direction: column; gap: 8px; margin-top: 8px; }
.alert-cura__row {
  display: flex; align-items: center; justify-content: space-between; gap: 10px;
  font: 400 12.5px/1.4 var(--font-sans); color: var(--olive-ink);
}
```

diventa (via tutto tranne la riga, che resta — ora è l'unica cosa scoped qui):

```css
/* Alert cura: .alertbox* ora globale in main.css. .alert-cura__row resta
   scoped qui: la riga (label + bottone) ha un layout diverso da quella
   degli avvisi meteo. */
.alert-cura__row {
  display: flex; align-items: center; justify-content: space-between; gap: 10px;
  font: 400 12.5px/1.4 var(--font-sans); color: var(--olive-ink);
}
```

- [ ] **Step 3: `MeteoView.vue` — usare `.alertbox alertbox--rose`**

Nel `<template>`, il blocco (righe ~50-54):

```html
      <div v-if="avvisi.length" class="alert-meteo">
        <span class="alert-meteo__ic"><Icon name="allerta" /></span>
        <div class="alert-meteo__main">
          <div class="alert-meteo__title">Occhio a questi giorni</div>
          <div class="alert-meteo__rows">
```

diventa (di nuovo, `alert-meteo__row` **resta invariato**):

```html
      <div v-if="avvisi.length" class="alertbox alertbox--rose">
        <span class="alertbox__ic"><Icon name="allerta" /></span>
        <div class="alertbox__main">
          <div class="alertbox__title">Occhio a questi giorni</div>
          <div class="alertbox__rows">
```

Nel `<style scoped>`, il blocco (righe ~191-201):

```css
/* Blocco avvisi — stessa struttura di .alert-cura in PiantaView, tinta rosa */
.alert-meteo { display: flex; gap: 12px; align-items: flex-start; padding: 14px 15px; margin: 22px 0 2px;
  background: var(--rose-bg); border: 1px solid color-mix(in srgb, var(--rose) 28%, transparent); border-radius: 16px; }
.alert-meteo__ic { flex: none; width: 36px; height: 36px; border-radius: 11px; display: flex; align-items: center; justify-content: center;
  background: color-mix(in srgb, var(--rose) 16%, var(--cream)); color: var(--rose-ink); }
.alert-meteo__ic svg { width: 20px; height: 20px; }
.alert-meteo__main { flex: 1; min-width: 0; }
.alert-meteo__title { font: 600 14px/1.25 var(--font-display); color: var(--rose-ink); }
.alert-meteo__rows { display: flex; flex-direction: column; gap: 8px; margin-top: 8px; }
.alert-meteo__row { display: flex; align-items: center; gap: 8px; font: 400 12.5px/1.4 var(--font-sans); color: var(--rose-ink); }
.alert-meteo__row svg { width: 15px; height: 15px; flex: none; }
```

diventa (via tutto tranne la riga — che resta, con **`margin: 22px 0 2px`** portato su un `.alertbox` locale, dato che `.alertbox` globale ha `margin: 16px 0 0`: qui va preservato lo spazio verticale specifico di MeteoView):

```css
/* Blocco avvisi: .alertbox*/.alertbox--rose ora globali in main.css.
   .alert-meteo__row resta scoped qui: riga icona+testo, diversa da quella
   di PiantaView. Margine locale: qui il blocco sta dopo il nastro orario,
   non subito sotto un titolo come in PiantaView. */
.alertbox.alertbox--rose { margin: 22px 0 2px; }
.alert-meteo__row { display: flex; align-items: center; gap: 8px; font: 400 12.5px/1.4 var(--font-sans); color: var(--rose-ink); }
.alert-meteo__row svg { width: 15px; height: 15px; flex: none; }
```

- [ ] **Step 4: build + verifica**

Run: `npm run build`
Expected: exit 0.

Verifica di lettura:
- `grep -n "alert-cura\b\|alert-meteo\b" src/views/PiantaView.vue src/views/MeteoView.vue` → nel `<template>` non deve comparire più `alert-cura`/`alert-meteo` come classe del contenitore/ic/main/title/rows; deve restare solo `alert-cura__row` (PiantaView) e `alert-meteo__row` (MeteoView).
- `grep -n "alertbox" src/assets/main.css` → il nuovo blocco.

- [ ] **Step 5: Commit**

```bash
git add src/assets/main.css src/views/PiantaView.vue src/views/MeteoView.vue
git commit -m "$(cat <<'EOF'
Unifica .alert-cura/.alert-meteo in .alertbox globale

Le due classi erano ~9 regole quasi identiche duplicate (olive in
PiantaView, copia rosa in MeteoView). Ora .alertbox/.alertbox--rose in
main.css; resta scoped solo la riga (.__row), che ha layout diverso nei
due consumatori (label+bottone vs icona+testo). Nessun cambio visivo.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
EOF
)"
```

---

### Task 3: `.chip` — base chiara + variante `--on-photo`

**Files:**
- Modify: `src/assets/main.css`
- Modify: `src/views/PiantaView.vue`
- Modify: `src/views/GalleryView.vue`

**Interfaces:**
- Produce: `.chip` (ora chiara di base), `.chip svg`, `.chip--ic`, `.chip--on-photo` globali in `main.css`.
- Consuma: `--cream-dark`/`--ink-mid` (base chiara, come le usava già `.phead-text__chip` in PiantaView e l'override scoped di GalleryView).

**Contesto:** oggi `.chip` (globale) è cablata per stare **sopra una foto** (testo/icona chiari, sfondo scuro semitrasparente). Due consumatori la ridefiniscono per stare su **sfondo chiaro**: `PiantaView.vue` ha una classe scoped separata quasi identica (`.phead-text__chip`, stessa forma, colori chiari) invece di riusare `.chip`; `GalleryView.vue` la riusa ma la ridefinisce scoped (`.gpost__hd .chip { background:var(--cream-dark); color:var(--ink-mid); --acqua:currentColor; --acqua-dark:currentColor; }`). Si inverte: `.chip` diventa chiara di base, la variante `--on-photo` copre il caso attuale (header foto di PiantaView).

- [ ] **Step 1: riscrivere `.chip*` in `main.css`**

La regola attuale (righe ~385-395):

```css
.chip { display:inline-flex; align-items:center; gap:5px; font:700 9.5px/1 var(--font-sans);
  letter-spacing:.05em; text-transform:uppercase; background:rgba(253,248,238,.22); color:#fdf8ee;
  padding:4px 9px; border-radius:999px; --acqua:#fdf8ee; --acqua-dark:#fdf8ee; }
.chip svg { width:11px; height:11px; }
```

(e, qualche riga sotto, `.chip--ic { padding:4px 7px; }` — quella resta invariata) diventa:

```css
.chip { display:inline-flex; align-items:center; gap:5px; font:700 9.5px/1 var(--font-sans);
  letter-spacing:.05em; text-transform:uppercase; background:var(--cream-dark); color:var(--ink-mid);
  padding:4px 9px; border-radius:999px; }
.chip svg { width:11px; height:11px; }
.chip--on-photo { background:rgba(253,248,238,.22); color:#fdf8ee; --acqua:#fdf8ee; --acqua-dark:#fdf8ee; }
```

`.chip--ic { padding:4px 7px; }` resta dov'è, invariata.

- [ ] **Step 2: `PiantaView.vue` — header con foto usa `.chip--on-photo`**

Nel `<template>`, righe ~40-41 (dentro `.phead-cap`, l'header **con** foto):

```html
            <span class="chip"><Icon :name="pianta.sottozona ? store.iconaSottozona(pianta.zona, pianta.sottozona) : store.iconaZona(pianta.zona)" />{{ pianta.zona }}{{ pianta.sottozona ? ' · ' + pianta.sottozona : '' }}</span>
            <span v-if="pianta.coltivato_in" class="chip chip--ic" :title="labelColtivatoIn(pianta.coltivato_in)" :aria-label="labelColtivatoIn(pianta.coltivato_in)"><Icon :name="iconaColtivatoIn(pianta.coltivato_in)" /></span>
```

diventa:

```html
            <span class="chip chip--on-photo"><Icon :name="pianta.sottozona ? store.iconaSottozona(pianta.zona, pianta.sottozona) : store.iconaZona(pianta.zona)" />{{ pianta.zona }}{{ pianta.sottozona ? ' · ' + pianta.sottozona : '' }}</span>
            <span v-if="pianta.coltivato_in" class="chip chip--ic chip--on-photo" :title="labelColtivatoIn(pianta.coltivato_in)" :aria-label="labelColtivatoIn(pianta.coltivato_in)"><Icon :name="iconaColtivatoIn(pianta.coltivato_in)" /></span>
```

- [ ] **Step 3: `PiantaView.vue` — header senza foto usa `.chip` (elimina il duplicato)**

Nel `<template>`, righe ~57-58 (dentro `.phead-text`, l'header **senza** foto):

```html
              <span class="phead-text__chip"><Icon :name="pianta.sottozona ? store.iconaSottozona(pianta.zona, pianta.sottozona) : store.iconaZona(pianta.zona)" />{{ pianta.zona }}{{ pianta.sottozona ? ' · ' + pianta.sottozona : '' }}</span>
              <span v-if="pianta.coltivato_in" class="phead-text__chip phead-text__chip--ic" :title="labelColtivatoIn(pianta.coltivato_in)" :aria-label="labelColtivatoIn(pianta.coltivato_in)"><Icon :name="iconaColtivatoIn(pianta.coltivato_in)" /></span>
```

diventa:

```html
              <span class="chip"><Icon :name="pianta.sottozona ? store.iconaSottozona(pianta.zona, pianta.sottozona) : store.iconaZona(pianta.zona)" />{{ pianta.zona }}{{ pianta.sottozona ? ' · ' + pianta.sottozona : '' }}</span>
              <span v-if="pianta.coltivato_in" class="chip chip--ic" :title="labelColtivatoIn(pianta.coltivato_in)" :aria-label="labelColtivatoIn(pianta.coltivato_in)"><Icon :name="iconaColtivatoIn(pianta.coltivato_in)" /></span>
```

Nel `<style scoped>`, rimuovere le tre regole ora ridondanti (righe ~414-420, 431):

```css
.phead-text__chip {
  display: inline-flex; align-items: center; gap: 5px;
  font: 700 9.5px/1 var(--font-sans); letter-spacing: .05em; text-transform: uppercase;
  color: var(--ink-mid); background: var(--cream-dark);
  padding: 4px 9px; border-radius: 999px;
}
.phead-text__chip svg { width: 11px; height: 11px; }
```

e

```css
.phead-text__chip--ic { padding: 4px 7px; }
```

**Non toccare** `.phead-text__chips { display: flex; gap: 6px; flex-wrap: wrap; }` (è il contenitore, non la singola chip: resta).

- [ ] **Step 4: `GalleryView.vue` — l'override diventa solo layout**

Nel `<style scoped>`, la regola (righe ~311-320):

```css
/* Chip zona nell'intestazione: la `.chip` globale è tarata sulle foto
   (testo e icona chiari su scrim scuro). Qui vive su fondo chiaro e non
   deve comprimersi quando il nome zona è lungo (`flex:none`). */
.gpost__hd .chip {
  flex: none;
  background: var(--cream-dark);
  color: var(--ink-mid);
  --acqua: currentColor;
  --acqua-dark: currentColor;
}
```

diventa (la `.chip` globale è ormai chiara di base: qui serve solo evitare che si comprima):

```css
/* Chip zona nell'intestazione: la .chip globale è già chiara di base;
   qui serve solo evitare che si comprima quando il nome zona è lungo. */
.gpost__hd .chip {
  flex: none;
}
```

- [ ] **Step 5: build + verifica**

Run: `npm run build`
Expected: exit 0.

Verifica di lettura:
- `grep -n "phead-text__chip" src/views/PiantaView.vue` → **nessun risultato** tranne `.phead-text__chips` (il contenitore, con la "s" finale).
- `grep -n "chip--on-photo" src/views/PiantaView.vue` → 2 righe nel template.
- `grep -n "\-\-acqua: currentColor" src/views/GalleryView.vue` → **nessun risultato**.

- [ ] **Step 6: Commit**

```bash
git add src/assets/main.css src/views/PiantaView.vue src/views/GalleryView.vue
git commit -m "$(cat <<'EOF'
.chip: base chiara + variante --on-photo, via due reimplementazioni

.chip globale era cablata per stare sopra una foto; PiantaView aveva una
.phead-text__chip scoped quasi identica per il caso a sfondo chiaro, e
GalleryView la ridefiniva scoped per lo stesso motivo. Ora .chip è chiara
di base, .chip--on-photo copre il caso foto (PiantaView, header con
foto). Nessun cambio visivo nei tre punti che già la usano.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
EOF
)"
```

---

## Note di verifica per il QA nel browser (dopo il merge)

- **Scheda pianta**: header con foto — i chip zona/vaso restano chiari sopra lo scrim scuro (`--on-photo`), invariati a vista. Header senza foto — i chip restano com'erano (ora è la `.chip` condivisa, stesso aspetto). Blocco "Da curare subito" — invariato.
- **Meteo**: blocco "Occhio a questi giorni" — invariato (ora `.alertbox--rose`). Righe del registro: hover solo con mouse/trackpad, non appiccicato dopo un tap. `.adesso` e le righe si aprono anche con Spazio, non solo Invio/click.
- **Galleria**: chip zona nell'intestazione dei post — invariata.
- **Selettore specie**: la × sul foglio-dossier ha un feedback al passaggio del mouse e un contorno visibile da tastiera.
- **Zone/Sottozone/Home**: i pulsanti-pillola (Sottozone, matita, ×, "Fatto") mostrano il cursore a manina.
- **URL ritirati**: `#/zone/nuova` (o qualunque path inesistente) porta alla Home invece che a una pagina vuota.

## Fuori scope (confermato in triage)

- `.section-label` — ancora usata da `PianteView` (2 volte), convertirla a `.slabel` è una scelta di design.
- Vocabolario caroselli (`.gtrack`/`.gslide` vs `.gpost`) — non è duplicazione, sono concetti diversi.
- `@media (hover:hover)` esteso a tutti i `:hover` dell'app — troppo largo per un giro cosmetico, fatto solo su `.day` (finding esplicito del round Meteo).

## Self-review

- **Copertura**: A→Task 1 Step A, B→Step B, C→Step C, F→Step F1/F2, G→Step G, D→Task 2, E→Task 3.
- **Placeholder**: nessuno — ogni step ha il codice completo, prima e dopo.
- **Coerenza**: `.alertbox`/`.alertbox--rose` (Task 2) e `.chip`/`.chip--on-photo` (Task 3) non si sovrappongono nello stesso file oltre a `main.css` (append in fondo in entrambi i casi, blocchi distinti). Task 1 non tocca `main.css` nello stesso punto di Task 2/3 (`.pill-mini` è una riga esistente diversa). Nessuna dipendenza tra i 3 task — ordine ininfluente, eseguibili in sequenza qualunque essa sia.
