# Restyle "Taccuino" — Fase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** portare la direzione visiva "Taccuino" nel codice per le fondamenta (token, tipografia, componenti globali, cornice) e per le due viste già disegnate — Home e Scheda pianta — più la modifica al modello attività (potatura fuori, calcio dentro).

**Architecture:** intervento di sola presentazione (template + CSS), tranne una modifica logica mirata in `useCure.js`. Si introduce un layer di **componenti globali** in `src/assets/main.css` (classi riusabili) che sostituiscono gli stili inline ripetuti; le view passano da `style="…"` inline a queste classi. Nessun cambio a dati, store, routing, API, Supabase. La **fonte visiva di verità** per Home e Scheda pianta è il mockup committato `docs/superpowers/specs/assets/2026-09-02-restyle-taccuino-mockup.html` (d'ora in poi: **il mockup**): i task ne portano CSS e markup adattando i nomi delle variabili CSS e ricablando i binding Vue.

**Tech Stack:** Vue 3 `<script setup>` SFC, Vite 8, Tailwind v4 (`@import "tailwindcss"` in `main.css`, usato pochissimo — il grosso è CSS custom properties), Pinia, vue-router (`createWebHashHistory`). Nessun test runner nel progetto: la verifica di ogni task è `npm run build` (exit 0) + controllo visivo con `npm run dev` (http://localhost:5173, hash routing).

**Spec:** `docs/superpowers/specs/2026-09-02-restyle-taccuino-design.md`

## Global Constraints

- **Branch:** tutto il lavoro su `restyle-taccuino` (già creato, contiene la spec). Nessun push/merge su `main` senza richiesta esplicita di Rob (il deploy GitHub Pages è automatico a ogni push su `main`).
- **Sola presentazione**, eccetto il modello attività: template + CSS. Non toccare `stores/dati.js`, i composable `*Api.js`, `useSupabase.js`, `router/index.js`, `vite.config.js`, le migration.
- **Nessuna nuova regola in `style="…"` inline.** Le regole nuove vivono in `src/assets/main.css` come classi, o in `<style scoped>` se davvero locali a una SFC. Gli inline esistenti si rimuovono man mano che si tocca una view; non è obbligatorio azzerarli tutti in Fase 1, ma i blocchi coperti da un componente globale sì.
- **Palette:** le 5 tinte-dominio riusano i valori esistenti `--rose/--sage/--olive/--gold/--acqua` + `-dark` (già in `main.css`). Si aggiungono per ciascuna `-bg` e `-ink` con i valori esatti della tabella §2 della spec. Neutri "carta" = `--cream/--cream-dark/--ink*` esistenti; si aggiunge `--carta-2`.
- **Dark mode:** in Fase 1 si predispone **solo** la struttura (tutti i valori chiari su `:root`, i componenti leggono i token, mai letterali). **Non** aggiungere blocchi `@media (prefers-color-scheme: dark)` né `:root[data-theme="dark"]` — valori scuri e toggle sono Fase 3.
- **Zorba sempre nero** (`#141414`) in ogni raffigurazione; classe `.is-zorba` per applicarlo. Unica eccezione: la filigrana `.specie-ghost` (tono carta tenue).
- **Modello attività:** i tipi con cadenza/urgenza sono `['irrigazione','concimazione','calcio']`. `potatura` non è mai valutata per urgenza né mostrata nei feed; resta un'azione registrabile nella scheda pianta.
- **Font:** `index.html` carica solo Fraunces + DM Sans + Caveat. Playfair Display e Lora escono. Le classi `.gradient-title`, `.title-display`, `.title-serif`, `.text-light`, `.title-settle`, l'effetto shine escono da `main.css` e dalle view.
- **Verifica per task:** `npm run build` deve uscire con codice 0; poi `npm run dev` e controllo visivo secondo la checklist del task. `prefers-reduced-motion`: nessuna animazione essenziale persa.
- **Commit frequenti:** un commit per task (o per step "commit" esplicito), messaggio in italiano, prefisso `restyle:`. Firma commit come da istruzioni di sessione.

---

### Task 1: Font — Fraunces / DM Sans / Caveat in `index.html`

**Files:**
- Modify: `index.html` (il `<link>` Google Fonts nel `<head>` e `<meta name="theme-color">`)

**Interfaces:**
- Produce: le famiglie `'Fraunces'`, `'DM Sans'`, `'Caveat'` disponibili globalmente; `'Playfair Display'` e `'Lora'` non più caricate.

- [ ] **Step 1: Sostituisci il `<link>` dei font**

In `index.html`, sostituisci la riga `<link href="https://fonts.googleapis.com/css2?family=Playfair+Display…Lora…DM+Sans…" rel="stylesheet" />` con:

```html
<link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@0,9..144,400;0,9..144,500;0,9..144,600;0,9..144,700;1,9..144,400;1,9..144,600&family=DM+Sans:wght@400;500;600;700&family=Caveat:wght@500;600&display=swap" rel="stylesheet" />
```

Lascia invariati i due `<link rel="preconnect">` sopra.

- [ ] **Step 2: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 3: Commit**

```bash
git add index.html
git commit -m "restyle: carica Fraunces/DM Sans/Caveat, rimuove Playfair e Lora"
```

---

### Task 2: Layer token in `main.css` (colore + carta)

**Files:**
- Modify: `src/assets/main.css` (blocco `:root`, righe ~3–39)

**Interfaces:**
- Produce: per ogni tinta `--<t>-bg` e `--<t>-ink` (`t` ∈ acqua/olive/rose/sage/gold); `--carta-2`. I task successivi li danno per esistenti.

- [ ] **Step 1: Aggiungi i token derivati**

Dentro `:root` in `src/assets/main.css`, subito dopo le definizioni esistenti delle tinte, aggiungi (valori esatti dalla spec §2):

```css
  /* Fondo-tinta (bande/chip) e testo-su-tinta (AA) per dominio — restyle "Taccuino" */
  --acqua-bg:  #e2edf3;  --acqua-ink: #2b566e;
  --olive-bg:  #ececd8;  --olive-ink: #545e2a;
  --rose-bg:   #f6e3e1;  --rose-ink:  #8a3f3a;
  --sage-bg:   #e4ede4;  --sage-ink:  #37543f;
  --gold-bg:   #f7ecd0;  --gold-ink:  #7a5a15;
  --carta-2:   #f4eede;
```

Non rimuovere nessun token esistente in questo task.

- [ ] **Step 2: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 3: Commit**

```bash
git add src/assets/main.css
git commit -m "restyle: token -bg/-ink per dominio + --carta-2"
```

---

### Task 3: Tipografia base + rimozione classi "AI" in `main.css`

**Files:**
- Modify: `src/assets/main.css` (blocco `body`, `--font-*`, blocchi `.title-*`, `.gradient-title*`, `.title-settle`, `@keyframes titleShine`, `@keyframes titleSettle`)

**Interfaces:**
- Produce: `--font-display` = Fraunces, `--font-sans` = DM Sans, nuova `--font-hand` = Caveat. Le classi `.title-display/.title-serif/.text-light/.gradient-title/.title-settle` non esistono più.

- [ ] **Step 1: Aggiorna le variabili font**

In `:root` di `main.css`, sostituisci le tre righe `--font-display/--font-serif/--font-sans` con:

```css
  --font-display: 'Fraunces', Georgia, 'Times New Roman', serif;
  --font-sans:    'DM Sans', system-ui, sans-serif;
  --font-hand:    'Caveat', 'Segoe Script', cursive;
```

(`--font-serif` esce.)

- [ ] **Step 2: Rimuovi le classi tipografiche "AI"**

In `main.css` elimina interamente: la riga `.title-display { … }`, `.title-serif { … }`, `.text-light { … }`, il blocco `.gradient-title { … }`, `.title-settle { … }`, `.gradient-title.title-settle { … }`, `@keyframes titleSettle`, `@keyframes titleShine`, e il blocco `@media (prefers-reduced-motion: reduce)` che le riguarda (quello con `.title-settle { animation: none; }`). Lascia gli altri `@keyframes` (shimmer, pageIn/pageOut, stagger).

- [ ] **Step 3: Cerca i riferimenti rimasti**

Run: `grep -rn "title-display\|gradient-title\|title-serif\|text-light\|title-settle" src/`
Expected: molti risultati nelle view (verranno ripuliti quando si tocca ogni view). **Non** modificarli ora tranne dove romperebbero il build. Il build non si rompe (sono classi CSS assenti → nessun errore), quindi lascia stare: annota che HomeView/PiantaView li perderanno nei Task 10–11 e le altre view in Fase 2.

- [ ] **Step 4: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 5: Commit**

```bash
git add src/assets/main.css
git commit -m "restyle: font display Fraunces + hand Caveat; rimuove classi gradient/shine/title-*"
```

---

### Task 4: Componenti globali — cornice (`.appbar`, `.bottomnav`, sidebar)

**Files:**
- Modify: `src/assets/main.css` (append di un nuovo blocco `/* ===== restyle: cornice ===== */`)

**Interfaces:**
- Produce le classi: `.appbar`, `.appbar__mark`, `.appbar__actions`, `.appbar__btn`; `.bottomnav`, `.bottomnav a`, `.bottomnav a.on`, `.bn-ic`; `.sidebar`, `.sidebar__mark`, `.sidebar a`, `.sidebar a.on`, `.sidebar__spacer`. Consumate da Task 12 (`App.vue`).

- [ ] **Step 1: Porta le regole della cornice dal mockup**

Dal mockup, blocco `<style>` righe **220–244** (`/* app chrome */`): copia `.appbar*`, `.bottomnav*`, `.bn-ic*` in `main.css`, con questi adattamenti:
- i colori del mockup usano già gli stessi nomi token dell'app (`--carta` → nel mockup è un alias; **nell'app usa `--cream`**). Sostituisci in queste regole: `var(--carta)` → `var(--cream)`, `var(--carta-2)` → `var(--carta-2)` (già aggiunta), `var(--inchiostro)` → `var(--ink)`, `var(--seppia)` → `var(--ink-mid)`, `var(--faint)` → `var(--ink-soft)`, `var(--linea)` → `var(--cream-dark)`.
- `.appbar` resta `position: sticky; top: 0`.
- `.bn-ic` mantiene l'override monocromatico **solo** in `.bottomnav a:not(.on) .bn-ic { --acqua: currentColor; … --gold-dark: currentColor; }` (10 variabili), come nel mockup righe 240–244.

- [ ] **Step 2: Aggiungi la sidebar desktop (nuova, non nel mockup)**

Appendi in `main.css`:

```css
  /* Sidebar sinistra, schermi larghi (sostituisce la NavBar orizzontale) */
  .sidebar { display: none; }
  @media (min-width: 640px) {
    .sidebar {
      display: flex; flex-direction: column; gap: 2px;
      position: fixed; top: 0; left: 0; bottom: 0; width: 200px; z-index: 50;
      padding: 18px 14px; background: var(--cream);
      border-right: 1px solid var(--cream-dark); overflow-y: auto;
    }
    .sidebar__mark {
      display: flex; align-items: center; gap: 8px; margin-bottom: 16px;
      font: 600 14px/1.15 var(--font-display); color: var(--ink);
    }
    .sidebar a {
      display: flex; align-items: center; gap: 10px;
      padding: 9px 10px; border-radius: 9px;
      font: 500 13px/1 var(--font-sans); color: var(--ink-soft);
      text-decoration: none;
    }
    .sidebar a svg { width: 17px; height: 17px; flex: none; }
    .sidebar a:not(.on) svg {
      --acqua: currentColor; --acqua-dark: currentColor;
      --olive: currentColor; --olive-dark: currentColor;
      --sage: currentColor; --sage-dark: currentColor;
      --rose: currentColor; --rose-dark: currentColor;
      --gold: currentColor; --gold-dark: currentColor;
    }
    .sidebar a.on {
      background: color-mix(in srgb, var(--acqua) 12%, transparent);
      color: var(--ink); font-weight: 600;
    }
    .sidebar__spacer { flex: 1; }
  }
```

- [ ] **Step 3: Build**

Run: `npm run build`
Expected: exit 0. (Nessuna view usa ancora queste classi — è solo CSS.)

- [ ] **Step 4: Commit**

```bash
git add src/assets/main.css
git commit -m "restyle: classi cornice (.appbar, .bottomnav, .sidebar)"
```

---

### Task 5: Componenti globali — liste con filetti

**Files:**
- Modify: `src/assets/main.css` (append)

**Interfaces:**
- Produce: `.slabel`; `.wxrow` (+ `__ic/__m/__t/__s/__chev`); `.zdice` (+ `__ic/__m/__t/__s/__chev`); `.tasklist`, `.task` (+ `__ic/__m/__n/__d`); `.seeall`; `.destlist`, `.dest` (+ `__ic/__n/__c`, `.dest__c.urg`, `__chev`); `.feedlist`, `.feed` (+ `__rank`, `__rank--dim`, `__m/__n/__d/__tag/__npk`); `.kv` (+ `.k`, `.v`); `.prose`; `.pill`. Consumate da Task 10 (Home) e 11 (Scheda pianta).

- [ ] **Step 1: Porta le regole dal mockup**

Dal mockup copia in `main.css`, con gli **stessi rinomini di variabili del Task 4 Step 1** (`--carta`→`--cream`, `--inchiostro`→`--ink`, `--seppia`→`--ink-mid`, `--faint`→`--ink-soft`, `--linea`→`--cream-dark`, `--carta-2`→`--carta-2`):
- righe **131–135**: `.slabel` (+ `.slabel::after`).
- righe **161–204** (`/* home body */`): `.wxrow*`, `.tasklist`, `.task*`, `.pill`, `.zdice*`. (Nel mockup `.zdice` sta in un blocco più sotto — righe ~150–160 dell'area "app chrome"/liste: cerca `.zdice {` e portalo qui.)
- `.seeall`, `.destlist`, `.dest*` (cerca `.seeall {` e `.destlist {` nel mockup, blocco righe ~186–205).
- `.feedlist`, `.feed*` (cerca `.feedlist {` nel mockup — è nel blocco "plant sheet", righe ~300–320).
- `.kv` e `.prose` (cerca `.kv {` e `.prose {` nel mockup, blocco "plant sheet").

Verifica che `.pill` non entri in conflitto con eventuali `.pill` già in `main.css`: **c'è già** un `.pill` (filtri) alle righe ~189–196 di `main.css`. Il `.pill` del mockup è più piccolo/ghost. **Decisione:** rinomina il `.pill` del mockup in `.pill-mini` per le azioni "Fatto"/"Registra" nelle liste, e lascia `.pill` esistente per i filtri. Aggiorna i riferimenti quando porti il markup nei Task 10–11.

- [ ] **Step 2: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 3: Commit**

```bash
git add src/assets/main.css
git commit -m "restyle: classi liste con filetti (.slabel, .wxrow, .zdice, .tasklist, .destlist, .feedlist, .kv, .prose, .pill-mini)"
```

---

### Task 6: Componenti globali — header foto scheda pianta + filigrana + Zorba utility

**Files:**
- Modify: `src/assets/main.css` (append)

**Interfaces:**
- Produce: `.phead-photo`, `.gtrack`, `.gslide`, `.gimg` (+ `--1/--2/--3` di esempio — vedi nota), `.phead-scrim`, `.pbtn` (+ `--back/--edit`), `.phead-cap`, `.pname` (+ `i`), `.pbino`, `.tag-inline`, `.chip` (+ `svg`), `.gdots` (+ `span`, `span.on`), `.gnote`; `.specie`, `.specie-ghost`, `.sg`; `.is-zorba`; `.zorba-mini`, `.zm-tail`, `.zm-eye`, `.zm-eye-p`. Consumate da Task 7 (ZorbaMini), 10, 11.

- [ ] **Step 1: Porta le regole dal mockup**

Dal mockup blocco "plant sheet" (righe **245–330**) copia `.phead-photo*`, `.gtrack*`, `.gslide`, `.gimg` (**senza** i `--1/--2/--3`, che erano segnaposto d'esempio: nell'app la `.gimg` sarà un `<img>` reale — vedi Task 11), `.phead-scrim`, `.pbtn*`, `.phead-cap`, `.pname*`, `.pbino`, `.tag-inline`, `.chip*`, `.gdots*`, `.gnote` (la `.gnote` d'esempio "esempio · 3 foto" **non** serve nell'app; porta comunque la classe, servirà per il conteggio foto reale). Applica i rinomini di variabili del Task 4.

Dal mockup righe **288–301** e **206–219**: copia `.specie`, `.specie-ghost`, `.sg`, `.is-zorba`, `.zorba-mini`, `.zm-tail`, `.zm-eye`, `.zm-eye-p`. Per `.specie-ghost .sg { fill: #6e5d44; }` e `.is-zorba { color: #141414; }`: **lascia i letterali** (sono i colori-Zorba, non token di palette). **Non** portare i blocchi `@media (prefers-color-scheme: dark)` / `:root[data-theme="dark"]` associati a `.specie-ghost`/`.is-zorba` (Fase 3).

- [ ] **Step 2: Riusa gli `@keyframes` di Zorba**

`.zm-tail`/`.zm-eye` nel mockup usano `@keyframes z-tail` e `z-blink`, definiti nel blocco "Zorba" del mockup righe **121–130**. Portali in `main.css` (vicino agli altri `@keyframes`), insieme a `z-breath` se il logo grande lo userà (Task 7).

- [ ] **Step 3: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 4: Commit**

```bash
git add src/assets/main.css
git commit -m "restyle: classi header foto scheda pianta, filigrana .specie, utility Zorba (.is-zorba, .zorba-mini)"
```

---

### Task 7: `ZorbaLogo.vue` — variante `mini` + animazione idle lenta

**Files:**
- Modify: `src/components/ZorbaLogo.vue`

**Interfaces:**
- Consuma: `.zorba-mini`, `.zm-tail`, `.zm-eye`, `.zm-eye-p`, `@keyframes z-tail/z-blink` (Task 6).
- Produce: `<ZorbaLogo mini />` renderizza il gatto ~21px con coda/occhio animati lentamente e **senza** l'animazione d'ingresso (draw-on del pattern). `<ZorbaLogo />` (default) invariato per boot/hero.

- [ ] **Step 1: Aggiungi la prop `mini`**

In `<script setup>` di `ZorbaLogo.vue`, aggiungi:

```js
const props = defineProps({ mini: { type: Boolean, default: false } })
```

- [ ] **Step 2: Rendi condizionale l'onMounted**

Avvolgi il corpo di `onMounted(() => { … })` in `if (props.mini) return` all'inizio (nella variante mini niente draw-on del pattern, niente `setTimeout` di blink/wag one-shot; l'animazione idle è puramente CSS).

- [ ] **Step 3: Classi condizionali sull'`<svg>` e sui gruppi**

Nel `<template>`, sull'`<svg>` root: `:class="mini ? 'zorba-mini' : 'zorba-logo'"`. Sui gruppi: `id="tail"` → aggiungi `:class="{ 'zm-tail': mini }"`; `id="eye"` → `:class="{ 'zm-eye': mini }"`; il `<path fill="#7cc491">` dentro `#eye` → aggiungi `:class="{ 'zm-eye-p': mini }"`. (Gli `id` restano per la variante default.)

- [ ] **Step 4: Nascondi il pattern dorato in mini**

Sul gruppo `id="pattern"`: `v-if="!mini"` (a 21px è invisibile e appesantisce).

- [ ] **Step 5: Verifica visiva**

Run: `npm run dev`. Apri http://localhost:5173/#/account (non autenticato mostra il form, ma il boot logo grande appare comunque all'avvio).
Expected: il logo grande d'avvio invariato (draw-on + wag + blink one-shot, poi fermo). Nessun errore in console.
Poi in un componente qualsiasi in dev, verifica `<ZorbaLogo mini />` (puoi metterlo temporaneamente in `App.vue` e rimuoverlo): gatto ~21px nero, occhio verde, coda che ondeggia lenta in loop, blink lento in loop. Con `prefers-reduced-motion: reduce` (DevTools → Rendering) le animazioni si fermano.

- [ ] **Step 6: Build + commit**

```bash
npm run build && git add src/components/ZorbaLogo.vue
git commit -m "restyle: ZorbaLogo variante mini (idle lento, no draw-on)"
```

---

### Task 8: Asset hero + classe `.hero` in `main.css`

**Files:**
- Create: `src/assets/hero-giardino.jpg` (copia di `docs/superpowers/specs/assets/2026-09-02-hero-giardino.jpg`)
- Modify: `src/assets/main.css` (append blocco `.hero`)

**Interfaces:**
- Produce: `.hero`, `.hero__scene`, `.hero__scene::after`, `.hero__grid`, `.hero__txt`, `.hero__z`, `.date`, `.greet`, `.stat` (+ `span`, `b`), `.leaf` (+ `--1/--2/--3`), `@keyframes leaf-fall`. Consumate da Task 10.

- [ ] **Step 1: Copia l'asset**

```bash
cp docs/superpowers/specs/assets/2026-09-02-hero-giardino.jpg src/assets/hero-giardino.jpg
```

- [ ] **Step 2: Porta le regole `.hero*` e `.leaf*` dal mockup**

Dal mockup blocco "hero" (righe **85–120**) copia in `main.css` con i rinomini di variabili del Task 4. Adatta `.hero__scene`:
- il mockup carica l'immagine via `<style id="garden-style">` con un data-URI. **Nell'app** usa invece: nel blocco `.hero__scene` **non** mettere `background-image` (Vite processa gli asset). L'immagine si aggancia dalla SFC HomeView con `:style` e `new URL('@/assets/hero-giardino.jpg', import.meta.url).href` (Task 10 Step 3). Lascia `.hero__scene` con solo `background-position/size/repeat` e il `::after`.
- **Non** portare i blocchi `@media (prefers-color-scheme: dark)` / `:root[data-theme="dark"]` di `.hero__scene` (Fase 3).
- Porta `.zorba` / `#z-tail` / `#z-eye` / `#z-body` / `@keyframes z-tail/z-blink/z-breath` del mockup (righe 121–130) **solo se non già portati nel Task 6 Step 2** — evita doppioni.

- [ ] **Step 3: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 4: Commit**

```bash
git add src/assets/hero-giardino.jpg src/assets/main.css
git commit -m "restyle: asset hero acquerello + classe .hero"
```

---

### Task 9: `useCure.js` — potatura fuori dalle urgenze, calcio dentro

**Files:**
- Modify: `src/composables/useCure.js`
- Modify: `src/views/AttivitaView.vue`, `src/components/AttivitaRiga.vue`, `src/components/PiantaRiga.vue` (solo se elencano i tipi esplicitamente)

**Interfaces:**
- Consuma: —
- Produce: `cureUrgentiPianta(pianta, specie, contesto?)` non considera più `potatura`; considera `calcio` quando `specie.manutenzione.calcio` esiste. `valutaCura(pianta, specie, 'potatura')` può restare chiamabile (per mostrare "ultima potatura: N gg fa" nella scheda) ma non produce mai `urgente: true`.

- [ ] **Step 1: Trova la lista canonica**

Run: `grep -n "irrigazione\|concimazione\|potatura\|calcio" src/composables/useCure.js`
Individua l'array dei tipi in `cureUrgentiPianta` (e ovunque `useCure.js` iteri i tipi per calcolare urgenze).

- [ ] **Step 2: Sostituisci la lista**

Dove `useCure.js` itera `['irrigazione','concimazione','potatura']` (o simile) per le **urgenze**, cambia in una funzione che parte da `['irrigazione','concimazione']` e aggiunge `'calcio'` se `specie?.manutenzione?.calcio`. `potatura` non entra. Aggiungi un commento:

```js
// La potatura non ha cadenza temporale: è un'etichetta testuale,
// registrabile per pianta ma mai valutata per urgenza né mostrata nei
// feed "attività". I tipi con cadenza sono irrigazione, concimazione e
// (per le specie che ne hanno beneficio documentato) calcio.
```

- [ ] **Step 3: Allinea i chiamanti che elencano i tipi**

In `AttivitaView.vue`, `AttivitaRiga.vue`, `PiantaRiga.vue`: `grep -n "potatura"` in ciascuno. Dove un array di tipi include `'potatura'` per costruire il feed/badge attività, rimuovilo e aggiungi `'calcio'` con la stessa condizione dello Step 2. **Non** toccare `PiantaView.vue` in questo task (Task 11).

- [ ] **Step 4: Verifica visiva**

Run: `npm run dev`. Autènticati. Vai su `/attivita` e `/` (Home).
Expected: nessuna voce "potatura" nei feed; se una pianta con `manutenzione.calcio` è in ritardo di calcio, compare. Nessun errore in console. `/piante` — il badge urgenza di `PiantaRiga` non si accende più per la sola potatura.

- [ ] **Step 5: Build + commit**

```bash
npm run build && git add src/composables/useCure.js src/views/AttivitaView.vue src/components/AttivitaRiga.vue src/components/PiantaRiga.vue
git commit -m "restyle: potatura fuori dai feed urgenze, calcio dentro"
```

---

### Task 10: `HomeView.vue` — riscrittura al target §9.1

**Files:**
- Modify: `src/views/HomeView.vue` (template + `<style scoped>`; lo `<script setup>` cambia solo per: rimuovere `daFareOggi` la potatura, aggiungere i conteggi mancanti per la `.destlist`)

**Interfaces:**
- Consuma: `.hero*`, `.leaf*`, `.wxrow*`, `.zdice*`, `.slabel`, `.tasklist/.task*`, `.pill-mini`, `.seeall`, `.destlist/.dest*` (Task 4–8); `<ZorbaLogo />` (grande, Task 7); icone via `<Icon name="…" />`.
- Produce: la Home renderizzata come il mockup "HOME" (righe 455–530), meno la cornice (Task 12).

- [ ] **Step 1: Rimuovi la potatura da `daFareOggi`**

Nel `<script setup>` di `HomeView.vue`, la funzione `daFareOggi` (oggi `~:149`) itera `['irrigazione','concimazione','potatura']`. Cambia in `['irrigazione','concimazione']` + `'calcio'` se `sp?.manutenzione?.calcio` (stesso criterio del Task 9). Il resto della logica invariato.

- [ ] **Step 2: Aggiungi i conteggi per la lista destinazioni**

`homeCards` esiste già con `numZone/numPiante/numConcimi/numUrgenti/daFareOggi.length`. Servono anche `numProgetti` (`store.progetti ? Object.keys(store.progetti).length : null`) e un conteggio foto gallery se disponibile a buon mercato — altrimenti ometti il numero gallery (la riga resta, senza conteggio). Trasforma `homeCards` nella forma usata dalla `.destlist`: `{ to, icona, label, count, urgent }` per Zone/Piante/Progetti/Concimi/Attività/Gallery.

- [ ] **Step 3: Riscrivi il `<template>`**

Sostituisci l'intero `<template>` con il markup del mockup "HOME" (righe **457–528**), adattando:
- l'`<svg class="hero__scene">` del mockup diventa `<div class="hero__scene" :style="sceneStyle"></div>` con, nello script: `const sceneStyle = { backgroundImage: \`url(${new URL('@/assets/hero-giardino.jpg', import.meta.url).href})\` }`.
- le `<span class="leaf …">` restano come nel mockup (usano `<Icon name="foglia" />` o `<use href="#i-foglia">` — nell'app usa `<Icon name="foglia" />`; per le foglie oro/rosa il mockup fa un override di `--olive`: replica con `:style` inline che ridefinisce `--olive`/`--olive-dark`, è un override di variabile, non una regola nuova).
- `<svg class="zorba" …>` (Zorba grande nell'angolo) → `<ZorbaLogo class="hero__z" />`. Assicurati che `.hero__z` (posizione assoluta bottom-right) sia nel CSS globale (Task 8) — se il mockup la definiva inline, spostala in `main.css`.
- la riga meteo `.wxrow`: `<RouterLink class="wxrow" to="/meteo">` con `<Icon :name="meteoOggi?.icona ?? 'meteo'" class="wxrow__ic" />`, temperature/descrizione da `meteoOggi`, chevron con `<Icon name="back" />` ruotato (o un carattere `→`).
- `.zdice`: `<RouterLink class="zdice" to="/agente">`, icona `<span class="zdice__ic is-zorba"><Icon name="gatto" /></span>`, testo "Zorba dice" + sottotitolo.
- `.tasklist`: `v-for` su `daFareOggi.slice(0,5)`; icona `<Icon :name="icona(a.tipo)" class="task__ic" />` (la funzione `icona()`/`tinta()` esistono già); nome specie in `.task__n` (Fraunces via CSS), `.task__d` con la label cura; `<button class="pill-mini">Fatto</button>` (non funzionale in questa fase — o wired a `registraCura` se già disponibile: vedi nota). `.seeall` con `<RouterLink to="/attivita">Vedi tutte le {{ daFareOggi.length }} attività →</RouterLink>` mostrata solo se `daFareOggi.length > 5`.
- `.destlist`: `v-for` su `homeCards` → `<RouterLink class="dest" :to="card.to">` con `<Icon :name="card.icona" class="dest__ic" />`, `.dest__n`, `.dest__c` (`:class="{ urg: card.urgent }"`), chevron.

Nota "Fatto": se registrare la cura da Home non è già supportato, il bottone `.pill-mini` in questa fase può essere puramente visivo (nessun `@click`) — la registrazione avviene dalla scheda pianta. Non introdurre nuova logica di scrittura in Fase 1.

- [ ] **Step 4: Pulisci lo `<style scoped>`**

Rimuovi da `<style scoped>` di `HomeView.vue` tutto ciò che riguardava `.app-logo`, `.dots`/`.dot`, `.meteo-icon-wrap`, `.zorba-icon-wrap`, `.card-grid`, `.card-item*`, `.attivita-icon` (sostituiti dai componenti globali). Lascia solo eventuali regole ancora locali e necessarie.

- [ ] **Step 5: Verifica visiva**

Run: `npm run dev`, autènticati, vai su `/`.
Expected (mobile ~390px e desktop):
- hero con l'acquerello di sfondo, velatura a sinistra, "Buongiorno" (o il saluto scelto) in Fraunces, data in Caveat, chip di stato; Zorba **nero** animato in basso a destra; 2–3 foglie che scendono lente.
- riga meteo con filetti sopra/sotto, niente riquadro.
- riga "Zorba dice" con gatto nero.
- "Da fare oggi": lista con filetti, icone colorate per tipo, **nessuna potatura**, max 5 + "Vedi tutte" se >5.
- "Il giardino": lista di destinazioni con icona + nome + conteggio ("3 da curare" in rosso) + freccia.
- Nessun titolo in gradiente/shine, nessuna griglia di quadrati, nessun logo grande centrato.
- Console pulita; `prefers-reduced-motion` ferma foglie e Zorba.

- [ ] **Step 6: Build + commit**

```bash
npm run build && git add src/views/HomeView.vue src/assets/main.css
git commit -m "restyle: HomeView al linguaggio Taccuino (hero acquerello, liste con filetti, Zorba nell'angolo)"
```

---

### Task 11: `PiantaView.vue` — riscrittura al target §9.2

**Files:**
- Modify: `src/views/PiantaView.vue`

**Interfaces:**
- Consuma: `.phead-photo/.gtrack/.gslide/.gimg/.phead-scrim/.pbtn*/.phead-cap/.pname/.pbino/.tag-inline/.chip/.gdots/.gnote` (Task 6), `.slabel`, `.pill-mini`, `.feedlist/.feed*`, `.kv`, `.prose`, `.specie/.specie-ghost/.sg`, `.is-zorba`, `<ZorbaLogo mini />` non serve qui (la filigrana è un `<svg>` statico — vedi Step 4).
- Produce: la scheda pianta come il mockup "SCHEDA PIANTA" (righe 579–…), meno la cornice (Task 12).

- [ ] **Step 1: Header foto con galleria**

Sostituisci l'attuale `.plant-hero` / header testuale con `.phead-photo` dal mockup (righe ~536–593), adattando:
- `<div class="gtrack">` contiene `v-for="f in fotoPianta"` → `<figure class="gslide"><img class="gimg" :src="f.thumbUrl" :alt="specie?.nome"></figure>`. Se `fotoPianta.length === 0`, usa `fotoHero` (immagine specie Wikimedia) come singola slide; se manca anche quella, **niente `.phead-photo`**: mostra un header testuale ridotto (nome + binomio + chip su `.cream`), come fallback.
- `.gdots`: `v-if="fotoPianta.length > 1"`, `v-for` su `fotoPianta`, `:class="{ on: i === indiceFotoCorrente }"`. Serve un `ref` `indiceFotoCorrente` aggiornato da un handler `@scroll` sul `.gtrack` (porta la logica JS dal mockup, righe ~640–650, adattata a `ref`).
- `.gnote`: `v-if="fotoPianta.length > 1"` → `{{ fotoPianta.length }} foto`.
- `.pbtn--back` → `<RouterLink class="pbtn pbtn--back" to="/piante">` con `<Icon name="back" />`. `.pbtn--edit` → `<RouterLink :to="\`/piante/${route.params.id}/modifica\`">` con `<Icon name="matita" />` + "Modifica".
- `.phead-cap`: `.chip` con `<Icon :name="store.iconaZona(pianta.zona)" />` + `{{ pianta.zona }}{{ pianta.sottozona ? ' · ' + pianta.sottozona : '' }}`; `.pname` = `{{ specie?.nome ?? pianta.specie }}` (con `<i>` sul nome cultivar se presente); `.pbino` = `{{ specie?.specie }}` + `<span class="tag-inline">{{ labelColtivatoIn(pianta.coltivato_in) }}</span>`.

- [ ] **Step 2: Alert cura + Stato cure**

- Blocco urgenze (`v-if="cureUrgenti.length"`): resta una `.card` (unico blocco "sollevato"), tinta olive, **solo icona a sinistra** (niente watermark di sfondo). Porta lo stile dal mockup `.jcard.cat-olive` righe ~136–160, rinominando in una classe locale es. `.alert-cura` o riusando `.card` + modificatori.
- "Stato cure" (`.slabel` + righe): `v-for="tipo in tipiCura"`. `tipiCura` oggi (`PiantaView` `~:391`) è `['irrigazione','concimazione','potatura']` + `calcio` condizionale. Cambia in: `['irrigazione','concimazione']` + `'calcio'` se `specie.manutenzione.calcio`, **poi sempre** `'potatura'` in coda. Per `potatura`: mostra la riga con icona + "Potatura" + "ultima: {{ giorniDaUltima }} giorni fa" (o "mai registrata"), **senza** stato di urgenza (`valutaCura(...).urgente` per potatura sarà sempre `false` dopo il Task 9, ma qui non chiamare nemmeno `valutaCura` per potatura: usa solo `pianta.ultima_cura?.potatura`). Il bottone "Fatto" (`.pill-mini`) resta e resta wired a `registraCura('potatura')` (già esiste).

- [ ] **Step 3: Concimi consigliati → `.feedlist`**

Sostituisci il blocco "Concimi consigliati" con il markup `.feedlist` del mockup (righe ~624–651), adattando:
- riga fabbisogno: `<p class="prose" style="…">Per il fabbisogno attuale: {{ fabbisognoNpk }}</p>` (o classe dedicata `.feed-fabbisogno`).
- `v-for="(c, i) in classificaConcimiPianta"` → `.feed` con `.feed__rank` (`i+1`, `:class="{ 'feed__rank--dim': i > 0 }"`), `.feed__n` = `c.nome` (+ `<span class="feed__tag" v-if="c.disponibile === false">terminato</span>`), `.feed__d` (opzionale: match), `.feed__npk` = `{{ c.npk.n }}-{{ c.npk.p }}-{{ c.npk.k }}`.

- [ ] **Step 4: Sezione "La specie" (ex "Coltivazione") + filigrana**

- Rinomina l'etichetta della sezione oggi chiamata "Coltivazione" in **"La specie"**.
- La sezione va dentro `<div class="specie">` con, come primo figlio, la filigrana: un `<svg class="specie-ghost" viewBox="0 0 512 512" aria-hidden="true">` che contiene **solo** i path body+tail di Zorba (copiali dal mockup righe ~666–667, i due `<path class="sg">`). È statico, non un componente. Per non duplicare i path lunghi in ogni futura view, va bene tenerli inline qui in Fase 1; un `<ZorbaSilhouette />` è un raffinamento opzionale.
- Contenuto di `.specie`: `.slabel "La specie"` · `<p class="prose">{{ specie?.descrizione }}</p>` (il campo `descrizione` naturalizzato; `v-if` se presente) · `<div class="kv">` con i dati botanici già mostrati oggi (famiglia, ecc. — riusa i `v-if` esistenti del blocco Coltivazione) · per annuali/biennali le righe semina/trapianto/raccolta/consociazioni (le stesse di oggi) restano dentro questa `.specie`.
- La `.kv` di "La specie" può usare 2 colonne se ci stanno (`.kv` + eventuale modificatore) — opzionale, non bloccante.

- [ ] **Step 5: Esigenze + resto**

- "Esigenze" (`specie.esigenze`): `.slabel` + `.kv` con icone (`<Icon name="sole" />` ecc.).
- "Alert specie" (`specie.alert`), "Note personali" (`pianta.note`): allinea a `.prose` / lista con `.slabel`, niente card decorative.
- **Rimuovi** la sezione "Foto" separata in fondo (le foto sono nell'header-galleria) e la relativa logica `luce`/`LightboxFoto` **solo se** non più raggiungibile — altrimenti aggancia il `LightboxFoto` al tap su una slide della galleria (`@click="luce = f"`), mantenendo il componente.
- Info impianto ("Messa a dimora: …"): riga semplice, `.kv` o `.prose`.
- "Elimina pianta": link `.delete` (porta la classe dal mockup) — apre `ModalConferma` come oggi.

- [ ] **Step 6: Pulisci `<style scoped>`**

Rimuovi da `PiantaView.vue` `<style scoped>` le regole ora coperte dai globali (`.plant-hero*`, `.plant-back/.plant-edit`, `.plant-hero-text/-title/-lat/-credit`, `.zone-chip`, `.cura-ic`). Lascia solo il davvero-locale.

- [ ] **Step 7: Verifica visiva**

Run: `npm run dev`, autènticati, apri una pianta **con foto** e una **senza foto**.
Expected:
- con foto: immagine grande in cima, se >1 si scorre in orizzontale con pallini; pulsanti tondi indietro/Modifica sopra; nome "Specie" + binomio **sovrapposti** in basso su velatura leggera (non blocco nero); chip zona · sottozona; tag "in terra".
- senza foto: header testuale ridotto pulito.
- alert cura (se presente): unica card, tinta olive, **solo** icona a sinistra.
- "Stato cure": irrigazione/concimazione (+ calcio se applicabile) con stato; **riga "Potatura" presente ma senza urgenza**, registrabile.
- "Concimi consigliati": lista piatta, rank 1 evidenziato, "terminato" in rosso se non disponibile, NPK a destra, riga fabbisogno in cima.
- "La specie": etichetta rinominata; paragrafo descrizione con **filigrana di Zorba** tenue in basso (nessuna cucitura visibile); dati botanici in `.kv`.
- "Esigenze" con icone.
- Nessun titolo gradiente; il "Fatto"/"Registra" delle cure funziona come prima.
- Console pulita.

- [ ] **Step 8: Build + commit**

```bash
npm run build && git add src/views/PiantaView.vue src/assets/main.css
git commit -m "restyle: PiantaView al linguaggio Taccuino (header foto+galleria, La specie + filigrana, concimi lista piatta)"
```

---

### Task 12: Cornice in `App.vue` — sidebar desktop, appbar + bottomnav mobile

**Files:**
- Modify: `src/App.vue`
- Modify: `src/components/BottomNav.vue`
- Modify: `src/components/NavBar.vue` (diventa la sidebar) **o** Create: `src/components/SideNav.vue` e dismetti `NavBar.vue`
- Modify: `src/components/StatusBar.vue` (l'accesso Account si sposta in appbar/sidebar; StatusBar resta per il banner update)

**Interfaces:**
- Consuma: `.appbar*`, `.bottomnav*`, `.bn-ic`, `.sidebar*`, `.is-zorba` (Task 4, 6); `<ZorbaLogo mini />` (Task 7); `<Icon>`.
- Produce: layout definitivo — `<640px`: `.appbar` sticky in alto (mini-Zorba + marchio + Account) e `.bottomnav` fissa in basso; `≥640px`: `.sidebar` fissa a sinistra, contenuto con `margin-left: 200px`, niente bottomnav, appbar ridotta o assente.

- [ ] **Step 1: SideNav (desktop)**

Rinomina/riscrivi `NavBar.vue` come sidebar (o crea `SideNav.vue`): root `<nav class="sidebar">`, `.sidebar__mark` con `<ZorbaLogo mini />` + "Il Giardino di Zorba", `v-for` sulle voci (le stesse 10 di oggi: Home/Meteo/Zone/Piante/Progetti/Concimi/Attività/Zorba dice/Gallery, poi `.sidebar__spacer`, poi Impostazioni + Account) come `<RouterLink class="sidebar" ... >` con `<Icon :name="…" />` + label; `router-link-active` → applica `.on`. Il gatto di "Zorba dice" con `.is-zorba`.

- [ ] **Step 2: BottomNav (mobile)**

Riscrivi `BottomNav.vue` con le classi `.bottomnav`/`.bn-ic` (Task 4). Voci: Home/Zone/Piante/Concimi/Attività/Zorba dice (le 6 di oggi). Icona voce attiva → **colore originale** (nessun override); inattive → monocromatiche (l'override `:not(.on)` è già nel CSS). Il gatto sempre `.is-zorba`.

- [ ] **Step 3: Appbar (mobile)**

Nuovo componente `AppBar.vue` (o markup diretto in `App.vue`): `<header class="appbar">` con `<span class="appbar__mark"><ZorbaLogo mini /> Il Giardino di Zorba</span>` e `<span class="appbar__actions"><RouterLink class="appbar__btn" to="/account"><Icon name="persona" /></RouterLink></span>`. **Niente** link agente.

- [ ] **Step 4: Comporre in `App.vue`**

Nel ramo "autenticato" di `App.vue`:
- `<SideNav />` (si mostra da sola solo ≥640px via CSS).
- `<AppBar />` (nasconderla ≥640px via media query nel CSS `.appbar { … }`: aggiungi `@media (min-width: 640px) { .appbar { display: none; } }` in `main.css`).
- `<main class="app-main">` con `margin-left: 200px` da ≥640px (aggiorna la regola `.app-main` o aggiungi media query); su mobile invariato con il padding-bottom per la bottomnav.
- `<BottomNav />` (già `display: none` ≥640px via il suo CSS).
- `<StatusBar />` resta, ma rimuovi da `StatusBar.vue` l'icona/menu Account (ora in appbar/sidebar); lascia il banner update PWA e l'eventuale confronto build.
- Il banner "token GitHub mancante" resta com'è.

- [ ] **Step 5: Verifica visiva**

Run: `npm run dev`, autènticati.
Expected:
- **Mobile** (DevTools ~390px): appbar in alto con mini-Zorba animato + marchio + icona Account; bottomnav in basso, voce attiva colorata, gatto nero; contenuto non finisce sotto le barre.
- **Desktop** (>640px): sidebar sinistra fissa con le voci in colonna, voce attiva evidenziata; niente bottomnav; niente appbar (o ridotta); contenuto centrato a destra della sidebar.
- Cambio rotta: la voce attiva si aggiorna in entrambe.
- Il boot logo grande all'avvio invariato.

- [ ] **Step 6: Build + commit**

```bash
npm run build && git add src/App.vue src/components/BottomNav.vue src/components/NavBar.vue src/components/SideNav.vue src/components/AppBar.vue src/components/StatusBar.vue src/assets/main.css
git commit -m "restyle: cornice — sidebar desktop, appbar+bottomnav mobile, Account fuori da StatusBar"
```

---

### Task 13: `PiantaRiga.vue` — allineamento a token e classi

**Files:**
- Modify: `src/components/PiantaRiga.vue`

**Interfaces:**
- Consuma: `.card` (ridimensionata), token `-bg/-ink`, `<Icon>`.
- Produce: la riga pianta resta una `.card` (oggetto con miniatura), con inline ridotti al minimo e colori dai token.

- [ ] **Step 1: Ripulisci gli inline**

Sposta gli stili inline ripetuti di `PiantaRiga.vue` in una classe locale `<style scoped>` (es. `.pianta-riga`, `.pianta-riga__thumb`, `.pianta-riga__nome`, `.pianta-riga__meta`, `.pianta-riga__urg`, `.pianta-riga__del`). Usa `--font-display` per il nome (era `title-serif`), `--ink-*` per i grigi, `--rose-tile`/`--olive-tile` per lo sfondo miniatura come oggi, `--rose-dark` per il testo urgenza. Rimuovi la classe `title-serif`/`text-light` (non esistono più).

- [ ] **Step 2: Verifica visiva**

Run: `npm run dev`, `/piante`.
Expected: righe pianta invariate nella sostanza (miniatura, nome in serif Fraunces, zona con icona, badge urgenza), nessun riferimento a classi rimosse, console pulita.

- [ ] **Step 3: Build + commit**

```bash
npm run build && git add src/components/PiantaRiga.vue
git commit -m "restyle: PiantaRiga — inline → classi scoped, colori da token"
```

---

### Task 14: Verifica integrale Fase 1

**Files:** nessuno (solo QA).

- [ ] **Step 1: Build pulito**

Run: `npm run build`
Expected: exit 0, nessun warning nuovo rilevante.

- [ ] **Step 2: Giro completo in `npm run dev`**

Autènticati e visita ogni rotta: `/`, `/meteo`, `/zone`, `/piante`, una pianta con foto, una senza, `/progetti`, `/concimi`, `/attivita`, `/agente`, `/gallery`, `/account`, `/impostazioni`.
Expected:
- Home e Scheda pianta: come nei Task 10–11.
- Le **altre** view: **non ancora ristilizzate** (Fase 2) ma **non rotte** — nessun crash, nessun layout scardinato dalla sidebar/appbar, testo leggibile (possono avere ancora i vecchi titoli in gradiente rimossi che ora appaiono come testo normale: accettabile in Fase 1).
- Cornice: sidebar su desktop, appbar+bottomnav su mobile, ovunque.
- `prefers-reduced-motion: reduce`: foglie e Zorba fermi; nessuna animazione essenziale persa.
- Console pulita su tutte le rotte.

- [ ] **Step 3: Nota di consegna**

Aggiorna la sezione "Stato" di `docs/superpowers/specs/2026-09-02-restyle-taccuino-design.md` (o un breve `docs/superpowers/plans/2026-09-02-restyle-taccuino-fase1-esito.md`) con: cosa è fatto, cosa resta (le view di Fase 2 elencate in §9.3), eventuali scostamenti dal piano.

- [ ] **Step 4: Commit finale**

```bash
git add -A && git commit -m "restyle: chiusura Fase 1 — nota di esito"
```

Il branch `restyle-taccuino` è pronto per la review di Rob; la merge su `main` (deploy) la decide lui.

---

## Self-Review

**Spec coverage:**
- §2 token → Task 2 ✓ · §3 tipografia → Task 1, 3 ✓ · §4 regole linguaggio → applicate in Task 5–6, 10–11 ✓ · §5 Zorba (nero, is-zorba, mini, filigrana) → Task 6, 7, 11 ✓ · §6 cornice (sidebar decisa) → Task 4, 12 ✓ · §7 hero → Task 8, 10 ✓ · §8 componenti globali → Task 4, 5, 6, 8 ✓ · §9.1 Home → Task 10 ✓ · §9.1 modello attività (potatura/calcio) → Task 9, 10, 11 ✓ · §9.2 Scheda pianta → Task 11 ✓ · §9.3 altre view → **Fase 2**, non in questo piano (per design) · §10 Fase 1 → tutti i task · §11 file toccati → coperti · §13 verifica → Task 14 ✓
- Gap noto e voluto: dark mode (Fase 3), view di Fase 2, stagionalità hero (Fase 4).

**Placeholder scan:** i task che "portano dal mockup" citano un file **committato** con numeri di riga e regole di adattamento esplicite (rinomini di variabili, binding Vue da ricablare) — non sono TODO vaghi. I bottoni "Fatto" in Home sono esplicitamente visivi in Fase 1 (nessuna logica di scrittura nuova). Nessun "gestire gli edge case" generico.

**Type/naming consistency:** `.pill` esistente vs `.pill-mini` nuovo → risolto in Task 5 Step 1 e usato coerentemente in Task 10–11. `--carta`/`--inchiostro`/`--seppia`/`--faint`/`--linea` del mockup → sempre rinominati a `--cream`/`--ink`/`--ink-mid`/`--ink-soft`/`--cream-dark` (regola fissata in Task 4 Step 1, richiamata nei Task 5, 6, 8). `<ZorbaLogo mini />` (prop `mini`, Task 7) usato in Task 12. Lista tipi cura `['irrigazione','concimazione','calcio']` (+ `potatura` solo come riga registrabile in PiantaView) coerente tra Task 9, 10, 11.
