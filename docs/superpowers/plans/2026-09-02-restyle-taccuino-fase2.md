# Restyle "Taccuino" — Fase 2 (Batch 1+2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** portare il linguaggio "Taccuino" nelle viste **Progetti, Progetto, Galleria, Zorba dice** (disegnate nel mockup Fase 2) e **Zone, Sottozone, Concimi, Attività** (restyle diretto), più una classe di titolo di pagina condivisa. Le restanti viste (Meteo, Account, Impostazioni, form di modifica, SelettoreSpecie) sono di un piano successivo.

**Architecture:** intervento di sola presentazione (template + CSS). Fase 1 ha già in `src/assets/main.css` i token e le classi di base (`.slabel`, `.pill` / `.pill-mini`, `.tasklist/.task`, `.destlist/.dest`, `.feedlist/.feed`, `.kv`, `.prose`, `.card`, cornice, `.is-zorba`). Fase 2 aggiunge poche classi nuove (`.page-title`; timeline progetto `.path*`/`.step*`; drawer storico agente `.hstore*`; feed galleria `.gpost*`; lista progetti `.prow`/`.st`; form agente `.reqchip`/`.reqbox`/`.answer`) e riscrive i template delle 8 viste. Una sola aggiunta di logica leggera: lo **scrub** della timeline tappe (scroll → `--draw`), in JS vanilla dentro `ProgettoView.vue`. Fonte visiva di verità: `docs/superpowers/specs/assets/2026-09-02-restyle-taccuino-fase2-mockup.html`.

**Tech Stack:** Vue 3 `<script setup>` SFC, Vite 8, Tailwind v4 (usato pochissimo), Pinia, vue-router (`createWebHashHistory`). Nessun test runner: verifica per task = `npm run build` (exit 0) + controllo visivo con `npm run dev` (http://localhost:5173, hash routing).

**Spec:** `docs/superpowers/specs/2026-09-02-restyle-taccuino-design.md` (§4 regole del linguaggio, §9.3 principi per le altre viste)

## Global Constraints

- **Branch:** tutto su `restyle-taccuino-fase2` (già creato, contiene il mockup Fase 2). Nessun push/merge su `main` senza richiesta esplicita (deploy automatico).
- **Sola presentazione**: template + CSS. Non toccare `stores/dati.js`, i composable `*Api.js` / `useCure.js` / `useProgetti.js` / `useConcimi.js`, `router/index.js`, `vite.config.js`, le migration. Nessun cambio a dati/rotte/API.
- **Nessuna nuova regola in `style="…"` inline.** Le regole nuove sono classi in `src/assets/main.css` (o `<style scoped>` se davvero locali a una SFC). Quando un task tocca una view, i blocchi inline coperti da una classe nuova/esistente vanno rimossi.
- **Classi rimosse in Fase 1** (`.title-display`, `.title-serif`, `.text-light`, `.gradient-title`, `.title-settle`) — ogni view di Fase 2 le rimuove dal proprio template, sostituendo: titolo pagina → `.page-title` (nuova, Task 1); sottotitoli/testi → token diretti (`var(--font-display)` / `var(--ink-*)`).
- **`.section-label`** esiste ancora (globale, Fase 1 l'ha rimappata a `var(--font-display)`). Le view di Fase 2 che la usano la sostituiscono con `.slabel` dove ha senso (etichetta di sezione), altrimenti la lasciano.
- **Rename variabili** quando si porta CSS dal mockup Fase 2 (`…-fase2-mockup.html`): `--carta`→`--cream`; `--carta-2` resta; `--inchiostro`→`--ink`; `--seppia`→`--ink-mid`; `--faint`→`--ink-soft`; `--linea`→`--cream-dark`. `--acqua/--olive/--rose/--sage/--gold` + `-bg`/`-ink` esistono già (Fase 1).
- **Font**: mai letterali di font stack — `'Fraunces', …`→`var(--font-display)`, `'DM Sans', …`→`var(--font-sans)`, `'Caveat', …`→`var(--font-hand)`.
- **Dark mode**: NIENTE blocchi `@media (prefers-color-scheme: dark)` né `:root[data-theme="dark"]` (Fase 3). Eccezione: i letterali dei colori-Zorba (`#141414`, `#7cc491`) e i colori dell'overlay-foto (`#fdf8ee`, `rgba(20,15,8,…)`) sono ammessi.
- **Zorba sempre nero** (`.is-zorba` sull'icona `gatto`); il mini-Zorba nella `.appbar` è già gestito da Fase 1.
- **`.pill`** (filtri, esiste) resta; azioni brevi di lista usano `.pill-mini` (esiste). Se serve un bottone azione con `cursor:pointer` (non decorativo), usa `<style scoped>` locale come fatto in Fase 1 (`.care-act`).
- **Nessun test runner**: verifica = `npm run build` exit 0 + controllo visivo `npm run dev`. L'assenza di test unitari è una condizione del progetto, non un difetto del task.
- **Commit**: messaggio in italiano, prefisso `restyle:`, un commit per task, con trailer:
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
  ```
- **`prefers-reduced-motion`**: lo scrub della timeline (Task 3) deve mostrare lo stato finale (traccia disegnata, pallini visibili) senza animazione quando la media query è attiva.

---

### Task 1: Classi nuove in `main.css` (page-title + timeline + drawer agente + feed galleria + lista progetti + form agente)

**Files:**
- Modify: `src/assets/main.css` (append)

**Interfaces:**
- Produce: `.page-title` (+ `.page-title__row` per il layout titolo+azione); timeline `.path` (+ `--draw`), `.path__svg`, `.path__base`, `.path__trail`, `.step`, `.step__dot` (+ `--g/--s/--r/--f`, `.in`), `.step__head/__date/__esito` (+ `--g/--s/--r/--f`), `.step__desc`, `.pgoal` (+ `.pnode`, `.in`), `.path__add`; drawer `.hstore` (+ `.open`), `.hstore__hd`, `.hstore__new`, `.hstore__list`, `.hitem` (+ `.on`, `__ic/__m/__t/__d`), `.adot`, `.hback` (+ `.open`), `.htoggle`; feed `.gpost` (+ `__hd/__name/__n`), `.chip` già esiste da Fase 1 — verificare, se manca aggiungerla; form agente `.reqchips`, `.reqchip` (+ `.on`), `.reqbox` (+ `textarea`, `.reqbar`), `.reqsend`, `.answer` (+ `__hd/__body`); lista progetti `.prow` (+ `__m/__t/__d/__meta`), `.st` (+ `--n/--g/--s/--r`). Consumate dai Task 2–9.

- [ ] **Step 1: Porta le classi dal mockup Fase 2**

Apri `docs/superpowers/specs/assets/2026-09-02-restyle-taccuino-fase2-mockup.html`. Nel suo `<style>` trovi (con `grep`): `.ptitle`, `.pill--go`, `.row`/`.row__*`, `.st`/`.st--*`, `.path*`/`.step*`/`.pgoal`, `.gpost*`, `.chip`, `.hstore*`/`.hitem*`/`.hback`/`.htoggle`, `.reqchip*`/`.reqbox*`/`.reqsend`/`.answer*`, `.empty`, `.btn`/`.btn--*`, `.pfiller`. Porta in `src/assets/main.css` un blocco `/* ===== restyle Fase 2 ===== */` con:

- `.ptitle` → **rinominala `.page-title__row`**; il suo `h2` diventa `.page-title` (`font: 600 26px/1.05 var(--font-display); letter-spacing:-0.01em; color: var(--ink);`). Aggiungi `.page-title__row { display:flex; align-items:center; justify-content:space-between; gap:12px; margin:2px 0 18px; }`.
- `.row` → **rinominala `.prow`** (evita collisione con eventuali `.row` generiche); porta `.prow`, `.prow + .prow`, `.prow__m/__t/__d/__meta` (+ `span`, `svg`), `.prow__chev`. `.row__t` usa `var(--font-display)`.
- `.st`, `.st--n/--g/--s/--r` (chip di stato progetto) — invariate, applica i rename.
- `.empty` (+ `svg`, `p`, `p b`) — stato vuoto generico.
- Timeline: `.path` (con `--draw:0`), `.path__svg`, `.path__base`, `.path__trail` (con `stroke-dashoffset:calc(100 - var(--draw)*100)`), `.step`, `.step__dot` (+ `--g/--s/--r/--f`, `.in`, `transition`), `.step__head`, `.step__date` (`var(--font-display)`), `.step__esito` (+ `--g/--s/--r/--f`), `.step__desc`, `.pgoal` (+ `.pgoal .pnode`, `.pgoal .pnode.in`), `.path__add` (+ `button`, `svg`). **NON** portare `.pfiller` (era solo per lo scroll del mockup) né `.tvar` (selettore forma rimosso). Aggiungi la media query:
  ```css
  @media (prefers-reduced-motion:reduce){
    .path { --draw:1 !important; }
    .step__dot, .pgoal .pnode { transform:scale(1) !important; transition:none !important; }
  }
  ```
- Drawer agente: `.hstore` (+ `.open`), `.hstore__hd` (+ `b`), `.hstore__new` (+ `svg`), `.hstore__list`, `.hitem` (+ `.on`, `+ .hitem`, `__ic` + `svg`, `__m`, `__t`, `__d`), `.adot`, `.hback` (+ `.open`), `.htoggle` (+ `svg`). **Adatta il posizionamento**: nel mockup `.hstore` è `position:absolute` dentro il `.device`; nell'app diventa `position:fixed` (vedi Task 5 per i valori esatti — qui porta la classe base con `position:fixed; left:0; top:0; bottom:0; z-index:70; transform:translateX(-102%)` e `.hstore.open{transform:translateX(0)}`), `.hback` `position:fixed; inset:0; z-index:65`.
- Feed galleria: `.gpost` (+ `__hd`, `__name`, `__n`). `.chip` — se **non** è già in `main.css` da Fase 1, portala (con l'override `--acqua:#fdf8ee` per l'icona su foto). `.gtrack`/`.gslide`/`.gimg`/`.gdots` esistono già da Fase 1 (Task 6) — riusale, non duplicare; se il mockup ha valori diversi, allinea il mockup all'esistente, non viceversa.
- Form agente: `.reqchips`, `.reqchip` (+ `.on`), `.reqbox` (+ `textarea`, `textarea::placeholder`, `.reqbar` + `.ph` + `svg`), `.reqsend`, `.answer` (+ `__hd` + `svg`, `__body` + `p`).
- `.btn`/`.btn--save`/`.btn--del` del mockup (azioni progetto): **rinominale** in `.pbtn-save` / `.pbtn-del` per non collidere con la `.btn` globale esistente dell'app (che ha già `.btn-rose/.btn-sage/.btn-ghost`). Oppure riusa la `.btn` globale + modificatori esistenti nel Task 3 e non portare queste. **Scelta:** riusa `.btn` globale esistente nel Task 3; **non** portare `.btn--*` dal mockup.

Applica **tutti** i rename di variabile e di font-stack del blocco Global Constraints.

- [ ] **Step 2: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 3: Self-review**

- `grep -n "var(--carta)\|var(--inchiostro)\|var(--seppia)\|var(--faint)\|var(--linea)" src/assets/main.css` → zero occorrenze **nel blocco aggiunto** (il resto del file non si tocca).
- `grep -n "'Fraunces'\|'DM Sans'\|'Caveat'" src/assets/main.css` → solo le 3 righe `:root` dei token.
- Nessun `@keyframes` duplicato; nessun `@media (prefers-color-scheme: dark)` aggiunto.
- Nessun selettore in collisione con quelli esistenti di `main.css` (`.chip`, `.btn`, `.row`, `.step` — verifica che non pre-esistano; se `.step`/`.row` pre-esistono, i nomi Fase 2 vanno prefissati).

- [ ] **Step 4: Commit**

```bash
git add src/assets/main.css
git commit -m "restyle: classi Fase 2 (.page-title, timeline .path, drawer .hstore, feed .gpost, lista .prow)"
```

---

### Task 2: `ProgettiView.vue` — lista con `.page-title` e chip di stato

**Files:**
- Modify: `src/views/ProgettiView.vue`

**Interfaces:**
- Consuma: `.page-title__row`, `.page-title`, `.pill` (azione "Aggiungi"), `.prow` + sub-parti, `.st` + `--n/--g/--s/--r`, `.empty`, `<Icon>`.
- Produce: la vista Progetti come il mockup Fase 2 schermo "Progetti".

- [ ] **Step 1: Riscrivi il `<template>`**

- Intestazione: `<div class="page-title__row"><h1 class="page-title">Progetti</h1><button class="pill" @click="mostraForm = true"><Icon name="lampadina"/> Aggiungi</button></div>` (o l'icona `＋` come testo se non c'è un glifo `plus` nello sprite — verifica `IconDefs.vue`; se manca, testo "＋ Aggiungi" senza `<Icon>`).
- Lista: `v-for="p in progetti"` → `<RouterLink class="prow" :to="\`/progetti/${p.id}\`">` con `.prow__m` (`.prow__t` = `p.titolo`, `.prow__d` = `descrizioneBreve(p)`), `.prow__meta` (zona con `<Icon :name="store.iconaZona(p.zona)"/>` + `p.zona`; scadenza con `<Icon name="bandiera"/>` + `formatData(scadenzaCalcolata(p))`), e un `<span class="st" :class="classeStato(p.stato)">{{ labelStato(p.stato) }}</span>`.
- `classeStato(stato)`: mappa `aperto→'st--n'`, `in_corso→'st--g'`, `completato→'st--s'`, `fallito→'st--r'`, `cancellato→'st--n'`. Sostituisce `badgeStato`/`STILI_STATO` (rimuovi lo stile inline, tieni `LABEL_STATO`/`labelStato`).
- **`formatData`**: cambia in giorno + mese per esteso, anno solo se ≠ anno corrente:
  ```js
  function formatData(d){
    if(!d) return ''
    var dt = new Date(d), ora = new Date()
    var s = dt.toLocaleDateString('it-IT', { day:'numeric', month:'long' })
    return dt.getFullYear() !== ora.getFullYear() ? s + ' ' + dt.getFullYear() : s
  }
  ```
- Stato vuoto: `<div class="empty"><Icon name="lampadina"/><p><b>Nessun progetto ancora</b>Pianifica interventi, trapianti o lavori in giardino</p></div>`.
- Skeleton: tieni, alleggerisci a righe con filetto se banale (non obbligatorio).
- La modale "Nuovo progetto" (`Teleport`) resta funzionalmente identica; sostituisci `class="title-serif"` / `font-family:var(--font-serif)` nell'`<h3>` con `var(--font-display)`; `class="btn btn-sage"` ecc. restano.

- [ ] **Step 2: Pulisci `<script setup>` e `<style scoped>`**

Rimuovi `STILI_STATO`/`badgeStato` (non più usati). Lo `<style scoped>` `.overlay`/`.modal-box` resta.

- [ ] **Step 3: Build + verifica**

Run: `npm run build` (exit 0), poi `npm run dev` → `/progetti`.
Expected: titolo Fraunces piatto; lista con filetti, chip di stato colorati; niente card arrotondate per riga; scadenza col mese per esteso; la modale "Aggiungi" funziona come prima.

- [ ] **Step 4: Commit**

```bash
git add src/views/ProgettiView.vue
git commit -m "restyle: ProgettiView — lista con filetti, chip di stato, titolo Fraunces"
```

---

### Task 3: `ProgettoView.vue` — intestazione + timeline tappe che si disegna sullo scroll

**Files:**
- Modify: `src/views/ProgettoView.vue`

**Interfaces:**
- Consuma: `.path` (+ `--draw`), `.path__svg/__base/__trail`, `.step` (+ `__dot--g/--s/--r/--f`, `.in`, `__head/__date/__esito--*/__desc`), `.pgoal` (+ `.pnode`), `.path__add`, `.slabel`, `.prose`, `.st`, `.btn` globale, `<Icon>`.
- Produce: la scheda progetto come il mockup Fase 2 schermo "Progetto" (linea dritta), con scrub della traccia legato allo scroll di `window`.

- [ ] **Step 1: Intestazione**

Sostituisci il blocco "Dati principali" (la `.card` con gli input inline) con:
- back link `<RouterLink to="/progetti">← Progetti</RouterLink>` (stile `.prow__chev`-ish o testo semplice a `var(--ink-soft)`).
- `<h1 class="page-title" style="font-size:24px">` legato a `form.titolo` **come heading**, con un piccolo affordance di modifica: mantieni gli input di modifica ma spostali sotto un toggle "Modifica dati" **oppure** (più semplice, come oggi) tieni gli input inline ma restilizzati con `.form-input` (esiste). **Decisione:** tieni la modalità inline attuale (input `.form-input` per titolo/zona, `<select>` per stato, `MiniEditor` per descrizione), solo restilizzata: l'`<input>` titolo usa `font:600 20px/1.2 var(--font-display)`; niente `class="title-serif"`; niente `.card` wrapper (metti gli input in un contenitore semplice con `gap`); lo `<span class="badge">` dello stato → `<span class="st" :class="classeStato(form.stato)">`.
- riga meta: "creato il {{ formatData(form.creato) }}" e "Scadenza (dall'ultima tappa): {{ formatData(scadenza) }}" con `<Icon name="bandiera"/>`, in `var(--ink-soft)` piccolo. `formatData` come nel Task 2 (giorno + mese per esteso).

- [ ] **Step 2: Timeline `.path`**

Sostituisci il blocco Tappe (la `.card` con `.tl`) con la struttura del mockup Fase 2 "Progetto":
```html
<div class="slabel">Tappe</div>
<div class="path" ref="pathEl">
  <svg class="path__svg" viewBox="0 0 20 600" preserveAspectRatio="none" aria-hidden="true">
    <defs>
      <linearGradient id="trailGrad" x1="0" y1="0" x2="0" y2="1">
        <!-- stop generati da uno computed: per ogni tappa una banda del colore del suo esito -->
      </linearGradient>
    </defs>
    <path class="path__base"  d="M 10 4 L 10 596"/>
    <path class="path__trail" pathLength="100" d="M 10 4 L 10 596"/>
  </svg>
  <div class="path__add"><button type="button" @click="apriInserimento(0)"><Icon name="…plus…"/> Aggiungi tappa</button></div>
  <template v-for="(t, i) in form.tappe" :key="i">
    <div class="step">
      <span class="step__dot" :class="classeEsitoDot(t.esito)"></span>
      <div class="step__head"><span class="step__date">{{ formatData(t.data) }}</span><span class="step__esito" :class="classeEsito(t.esito)">{{ labelEsito(t.esito) }}</span></div>
      <p class="step__desc" @click="tappaApertaIndex = i">{{ t.descrizione }}</p>
      <!-- form inline di modifica tappa: come oggi (tappaApertaIndex === i), restilizzato con .form-input -->
    </div>
    <div class="path__add"><button type="button" @click="apriInserimento(i + 1)"><Icon name="…plus…"/></button></div>
  </template>
  <div class="pgoal"><span class="pnode"></span><Icon name="bandiera"/> Scadenza · {{ formatData(scadenza) }}</div>
</div>
```
- `classeEsitoDot`: `atteso→'step__dot--g'`, `riuscito→'step__dot--s'`, `fallito→'step__dot--r'`, `saltato→'step__dot--f'`. `classeEsito` idem con `step__esito--*`. Sostituiscono `coloreEsito`/`COLORE_ESITO` (rimuovi lo stile inline con i colori; tieni `LABEL_ESITO`/`labelEsito`).
- **Gradiente per esito**: un `computed` `gradientStops` che, date le tappe ordinate, produce le coppie di `<stop>` (per ogni tappa `i` su `n`: due stop a offset `i/n*100%` e `(i+1)/n*100%` con lo `stop-color` `var(--gold|sage|rose|faint)` in base a `esito`). Renderli con `v-for` dentro `<linearGradient>`. Se `form.tappe` è vuoto, un solo stop `var(--cream-dark)`.
- I mini-form inline (inserimento tappa, modifica tappa aperta) restano funzionalmente identici (`nuovaTappaInserimento`, `confermaInserimento`, `rimuoviTappa`, `tappaApertaIndex`, `inserimentoIndex`) — solo restilizzati con `.form-input` e senza i vecchi stili `.tl-*` inline. Rimuovi le classi `.tl-*` dallo `<style scoped>`.

- [ ] **Step 3: Scrub JS**

In `<script setup>`:
```js
import { ref, onMounted, onBeforeUnmount, nextTick } from 'vue'
const pathEl = ref(null)
let scrollHandler = null
function updateTrail(){
  const el = pathEl.value; if(!el) return
  if (matchMedia('(prefers-reduced-motion: reduce)').matches){
    el.style.setProperty('--draw', 1)
    el.querySelectorAll('.step__dot, .pgoal .pnode').forEach(d => d.classList.add('in'))
    return
  }
  const pr = el.getBoundingClientRect()
  const vh = window.innerHeight
  let frac = (vh * 0.82 - pr.top) / (pr.height + vh * 0.5)
  frac = Math.max(0, Math.min(1, frac))
  el.style.setProperty('--draw', frac.toFixed(4))
  el.querySelectorAll('.step__dot, .pgoal .pnode').forEach(d => {
    const dr = d.getBoundingClientRect()
    const df = ((dr.top + dr.height/2) - pr.top) / (pr.height || 1)
    d.classList.toggle('in', frac >= df - 0.02)
  })
}
onMounted(async () => {
  await nextTick()
  scrollHandler = () => requestAnimationFrame(updateTrail)
  window.addEventListener('scroll', scrollHandler, { passive: true })
  window.addEventListener('resize', scrollHandler)
  updateTrail()
})
onBeforeUnmount(() => {
  if (scrollHandler){ window.removeEventListener('scroll', scrollHandler); window.removeEventListener('resize', scrollHandler) }
})
```
E richiama `updateTrail()` (via `nextTick`) dopo ogni modifica alle tappe (aggiunta/rimozione) così i pallini nuovi si agganciano.

- [ ] **Step 4: Azioni + pulizia**

- In fondo: `<div style="display:flex;gap:10px">` con `<button class="btn" style="color:var(--rose-dark);background:transparent;border-color:var(--rose-light)">Elimina progetto</button>` (come oggi) e `<button class="btn btn-sage" style="flex:1">Salva modifiche</button>` — riusa la `.btn` globale, NON `.btn--*` del mockup.
- `<style scoped>`: rimuovi tutte le `.tl-*`. Aggiungi solo eventuali regole locali indispensabili.

- [ ] **Step 5: Build + verifica**

Run: `npm run build` (exit 0), poi `npm run dev` → apri un progetto con ≥2 tappe.
Expected: intestazione Fraunces; la **traccia si disegna man mano che scrolli** la pagina, colore per esito (oro atteso / salvia riuscito / rosa fallito / grigio saltato); i **pallini compaiono** quando lo scroll li raggiunge; nodo "Scadenza" in fondo; il "+" tra le tappe apre il mini-form come prima; salva/elimina funzionano. Con *riduci animazioni* tutto già disegnato.

- [ ] **Step 6: Commit**

```bash
git add src/views/ProgettoView.vue
git commit -m "restyle: ProgettoView — intestazione Fraunces + timeline tappe che si disegna sullo scroll"
```

---

### Task 4: `GalleryView.vue` — `.page-title` + feed `.gpost`

**Files:**
- Modify: `src/views/GalleryView.vue`

**Interfaces:**
- Consuma: `.page-title__row/.page-title`, `.pill`, `.gpost` (+ `__hd/__name/__n`), `.chip`, `.gtrack/.gslide/.gimg` (Fase 1), `.gdots` (Fase 1), `.empty`, `<Icon>`, `ModalConferma`, `LightboxFoto` se presente (verifica: la gallery usa un lightbox proprio? oggi apre le foto con menù contestuale/long-press per eliminare — **NON cambiare quella logica**).
- Produce: la Galleria come il mockup Fase 2 schermo "Galleria".

- [ ] **Step 1: Riscrivi il `<template>`**

- Intestazione `.page-title__row` + `.pill` "Aggiungi" (apre `mostraFormUpload`).
- Feed: `v-for="g in gruppi"` → `<article class="gpost">`:
  - `.gpost__hd`: `.gpost__name` (link a `/piante/${g.piantaId}` col nome specie; per `g.isGenerale` testo "Foto generiche" senza link) + `<span class="chip" v-if="g.zona"><Icon :name="store.iconaZona(g.zona)"/> {{ g.zona }}</span>` + `<span class="gpost__n">{{ g.foto.length }} foto</span>`.
  - carosello: `<div class="gtrack" @scroll="…">` con `v-for="f in g.foto"` → `<div class="gslide">` contenente `<img class="gimg" :src="f.thumbUrl">` e l'overlay `.gov` (data `f.dataBreve`; zona/sottozona con `<Icon :name="g.sottozona ? store.iconaSottozona(g.zona,g.sottozona) : store.iconaZona(g.zona)"/>`; icona `coltivato_in` con `iconaColtivatoIn(g.coltivatoIn)` e `:title`). **Mantieni** gli handler `@contextmenu` / `@touchstart` per l'eliminazione foto e `onScrollCarosello`.
  - `.gdots` (v-if `g.foto.length > 1`) sincronizzati come oggi (`slideAttiva[g.piantaId]`).
- Stato vuoto: `.empty` con `<Icon name="cornice"/>`.
- La modale upload (bottom-sheet) resta funzionalmente identica; sostituisci `class="title-serif"` → `var(--font-display)`, `font-family:var(--font-serif)` → `var(--font-display)`; `class="text-light"` → rimuovi (token diretti).
- Rimuovi le classi rimosse dal template; sposta gli stili inline ripetuti dell'`article`/header in `.gpost*` (già in main.css).

- [ ] **Step 2: `<style scoped>`**

`.post`/`.carosello`/`.slide`/`.overlay` locali: rinomina/allinea a `.gpost`/`.gtrack`/`.gslide`/`.gov` globali dove combaciano; tieni scoped solo il davvero-locale (es. i valori del carosello se diversi).

- [ ] **Step 3: Build + verifica**

Run: `npm run build` (exit 0), poi `npm run dev` → `/gallery`.
Expected: titolo Fraunces; feed di post per pianta con nome + chip zona + conteggio; carosello foto che scorre con pallini; overlay con data/zona/coltivato_in; long-press/tasto destro per eliminare una foto funziona ancora; la modale "Aggiungi" funziona.

- [ ] **Step 4: Commit**

```bash
git add src/views/GalleryView.vue
git commit -m "restyle: GalleryView — titolo Fraunces + feed .gpost, carosello allineato alla scheda pianta"
```

---

### Task 5: `AgenteView.vue` — storico come drawer a sinistra + form richiesta + risposta

**Files:**
- Modify: `src/views/AgenteView.vue`

**Interfaces:**
- Consuma: `.hstore` (+ `.open`, `__hd/__new/__list`), `.hitem` (+ `.on`, `__ic/__m/__t/__d`), `.adot`, `.hback` (+ `.open`), `.htoggle`, `.slabel`, `.reqchips/.reqchip/.reqbox/.reqsend`, `.answer` (+ `__hd/__body`), `.prose`, `<Icon>`, `<ZorbaLogo>`, `Teleport`.
- Produce: la vista "Zorba dice" come il mockup Fase 2 schermo "Zorba dice" (storico drawer sinistro, aperto/chiuso via `.htoggle`).

- [ ] **Step 1: Storico → `.hstore` drawer**

L'attuale `<aside class="agente-sidebar" :class="{ aperta: sidebarAperta }">` diventa `<aside class="hstore" :class="{ open: sidebarAperta }" id="hstore">`:
- `.hstore__hd`: `<b>Storico</b>` + `<button class="hstore__new" @click="nuovaRichiesta">＋ Nuova</button>` (era `btn btn-sage`).
- `.hstore__list`: `v-for="r in richieste"` → `<a class="hitem" :class="{ on: r.id === richiestaSelezionataId }" @click="selezionaRichiesta(r.id)">` con `.hitem__ic` (`<Icon :name="infoTipo(r.tipo).icon" />`), `.hitem__m` (`.hitem__t` = `titoloRichiesta(r)`, `.hitem__d` = `formatData(r.creata)`), e `<span class="adot" v-if="r.stato === 'in_attesa'">`. Mantieni il menù kebab (`⋮` → elimina) come oggi (`toggleMenu`, il `Teleport` del menù resta).
- `<div class="hback" :class="{ open: sidebarAperta }" @click="sidebarAperta = false">` sostituisce `.agente-backdrop`.
- Il toggle per aprire: `<button class="htoggle" @click="sidebarAperta = true"><Icon name="lista"/> Storico</button>` in cima al contenuto (sostituisce `.agente-storico-toggle`).
- Rimuovi/riadatta lo `<style scoped>` `.agente-sidebar`/`.agente-backdrop`/`.agente-storico-*` — porta a `main.css` (Task 1) le parti condivise; tieni scoped solo il locale.

- [ ] **Step 2: Intestazione + form richiesta**

- Header locale: il `.htoggle` (sopra) + `<h1>` con `<ZorbaLogo style="width:30px;height:30px" />` + "Zorba dice" (`var(--font-display)`, ~23px; niente `class="title-display gradient-title"`). Sottotitolo "Elaborato da Claude Code · risposta entro pochi minuti" in `var(--ink-soft)`.
- Blocco "Nuova richiesta" (quando `!richiestaSelezionata`): `.slabel` "Nuova richiesta"; i tipi come `.reqchips` con `.reqchip` (+ `.on` sul selezionato) — sostituiscono le `.pill tab-icona` attuali; `.reqbox` con `<textarea>` (il campo messaggio) + `.reqbar` con "Aggiungi foto" (`.ph` + `<Icon name="fotocamera"/>`, mantieni la logica di selezione foto esistente coi due bottoni libreria/fotocamera) e `<button class="reqsend" @click="invia">Invia</button>`. Il banner "Token GitHub richiesto" resta (restilizzato a `.slabel`/`.prose`, niente `.card` decorativa se possibile o card leggera).

- [ ] **Step 3: Risposta**

Quando `richiestaSelezionata` ha una risposta: `.answer` con `.answer__hd` (`<Icon name="…"/>` + "Risposta · {{ infoTipo(r.tipo).label }} · {{ formatData(r.risposta?.completata ?? r.creata) }}") e `.answer__body` che rende `r.risposta.messaggio`. **Attenzione**: se il messaggio è testo con a capo, rendilo come paragrafi (`white-space: pre-wrap` sul `.answer__body` o split su `\n\n`), mantenendo l'eventuale markdown-lite già gestito oggi (verifica come `AgenteView` rende oggi la risposta e conserva quel comportamento).

- [ ] **Step 4: Build + verifica**

Run: `npm run build` (exit 0), poi `npm run dev` → `/agente`, autenticato.
Expected: pulsante "Storico" apre un **drawer da sinistra** con la lista conversazioni (scrollabile), voce attiva evidenziata, puntino su quelle in attesa, "＋ Nuova" in alto; il velo scuro chiude; i chip del tipo di richiesta, la textarea e "Invia" funzionano come prima; la risposta si legge come prosa con intestazione. Il menù "elimina" su una conversazione funziona ancora.

- [ ] **Step 5: Commit**

```bash
git add src/views/AgenteView.vue src/assets/main.css
git commit -m "restyle: AgenteView — storico come drawer a sinistra, form richiesta e risposta al linguaggio Taccuino"
```

---

### Task 6: `ZoneView.vue` + `SottozoneView.vue` — griglia card → lista di destinazioni

**Files:**
- Modify: `src/views/ZoneView.vue`
- Modify: `src/views/SottozoneView.vue`

**Interfaces:**
- Consuma: `.page-title__row/.page-title`, `.pill`, `.dest`/`.destlist` (Fase 1) **o** `.prow` (Task 1) — scegli `.dest` (icona + nome + stato + chevron, già fatto per la Home). `<Icon>`, `ModalConferma`.
- Produce: Zone e Sottozone come liste di destinazioni.

- [ ] **Step 1: `ZoneView` template**

- `.page-title__row` "Zone" + `.pill` "Aggiungi" (link a `/zone/nuova`).
- Lista: `v-for="z in zoneList"` → una riga `.dest` (o `.prow`) come `<RouterLink :to="\`/piante?zona=${z.key}\`">` con `<Icon :name="z.icona ? \`zona-${z.icona}\` : 'pin'" class="dest__ic"/>`, nome zona (`.dest__n`, `text-transform:capitalize` via classe o inline var — usa una scoped `.zname{text-transform:capitalize}`), conteggio piante (`.dest__c` = `{{ contaPiante(z.key) }} piante`), chevron. Le azioni secondarie (Sottozone, Modifica, Elimina) → un gruppetto compatto a destra: due `<RouterLink class="pill-mini">` ("Sottozone", icona matita) + un `<button class="pill-mini">` elimina (rosa). **Non** perdere nessuna azione presente oggi.
- Stato vuoto: `.empty` con `<Icon name="pin"/>`.
- Skeleton: tieni, semplifica se banale.
- Rimuovi `.zone-grid`, `.zone-card-actions` scoped e le classi rimosse.

- [ ] **Step 2: `SottozoneView` template**

Stessa logica: `.page-title__row` (titolo = nome zona + "· Sottozone" o simile, come oggi), `.pill` aggiungi, lista `.dest`/`.prow` di sottozone con icona sottozona (`store.iconaSottozona(zona, sz)`), conteggio piante, azioni modifica/elimina come `.pill-mini`. Il selettore icona nel form di modifica sottozona è un'altra vista (`EditZonaView`/inline) — non in scope qui se non già in `SottozoneView`; se `SottozoneView` contiene un form inline, restilizzalo minimamente (token) senza ristrutturare.

- [ ] **Step 3: Build + verifica**

Run: `npm run build` (exit 0), poi `npm run dev` → `/zone` e `/zone/<key>/sottozone`.
Expected: titolo Fraunces; liste di destinazioni con icona acquerellata + nome + conteggio + chevron; tutte le azioni (piante, sottozone, modifica, elimina) raggiungibili; `ModalConferma` elimina funziona; niente griglia di card.

- [ ] **Step 4: Commit**

```bash
git add src/views/ZoneView.vue src/views/SottozoneView.vue
git commit -m "restyle: Zone e Sottozone — liste di destinazioni al posto della griglia di card"
```

---

### Task 7: `ConcimiView.vue` — lista `.feedlist` con NPK e toggle disponibilità

**Files:**
- Modify: `src/views/ConcimiView.vue`

**Interfaces:**
- Consuma: `.page-title__row/.page-title`, `.pill`, `.feedlist`/`.feed` (Fase 1: `__rank`, `__m`, `__n`, `__d`, `__tag`, `__npk`), `.empty`, `<Icon>`, `Spinner`, `ModalConferma`.
- Produce: Concimi come lista piatta con NPK e stato "terminato".

- [ ] **Step 1: Riscrivi il `<template>`**

- `.page-title__row` "Concimi" + `.pill` "Aggiungi" (`apriNuovo`).
- Lista: `v-for="c in concimi"` → `<div class="feed" @click="apriModifica(c)">` (niente `.feed__rank` qui — i concimi non sono classificati in questa vista; oppure ometti `__rank` e usa solo `.feed__m` + `.feed__npk`). `.feed__n` = `c.nome` + `<span class="feed__tag" v-if="c.disponibile === false">terminato</span>`; `.feed__d` = `descrizioneBreve(c)` se presente; `.feed__npk` = `{{ c.npk.n }}-{{ c.npk.p }}-{{ c.npk.k }}`. A destra il **toggle** `.toggle-switch` (mantienilo, è già una classe scoped funzionante) + il bottone elimina (`.pill-mini` o `×`). Riga con `opacity:.7` quando `c.disponibile === false` (tienilo, è un `:style` condizionale = ammesso).
- Stato vuoto: `.empty` con `<Icon name="provetta"/>`.
- La modale nuovo/modifica resta identica; `font-family:var(--font-serif)` → `var(--font-display)`; classi rimosse → token.
- `<style scoped>` `.toggle-switch*`, `.overlay`, `.modal-box` restano.

- [ ] **Step 2: Build + verifica**

Run: `npm run build` (exit 0), poi `npm run dev` → `/concimi`.
Expected: titolo Fraunces; lista piatta con nome + NPK + "terminato" (rosso) quando finito; toggle disponibilità funziona; tap sulla riga apre la modale di modifica; "Aggiungi" ed elimina funzionano.

- [ ] **Step 3: Commit**

```bash
git add src/views/ConcimiView.vue
git commit -m "restyle: ConcimiView — lista piatta con NPK e stato terminato"
```

---

### Task 8: `AttivitaView.vue` + `AttivitaGruppoZona.vue` + `AttivitaRiga.vue` — allineamento al linguaggio

**Files:**
- Modify: `src/views/AttivitaView.vue`
- Modify: `src/components/AttivitaGruppoZona.vue`
- Modify: `src/components/AttivitaRiga.vue`

**Interfaces:**
- Consuma: `.page-title` (+ eventuale sottotitolo data in `var(--font-hand)` come l'hero Home, o `var(--font-display)` corsivo), `.slabel`, `.pill` (le tab), `.tasklist/.task` (Fase 1) per le righe, `<Icon>`, `Spinner`.
- Produce: Attività al linguaggio Taccuino, **senza ristrutturare** la logica di tab / raggruppamento / espansione.

- [ ] **Step 1: `AttivitaView`**

- `<h1 class="page-title">Attività</h1>` + sotto la data (`dataOggi`) in `var(--ink-soft)` corsivo `var(--font-display)` (era `class="title-serif" italic`).
- Le tab restano `<button class="pill tab-icona" :class="{ active }">` — la `.pill` esiste, `.tab-icona` è scoped, tienila; il badge conteggio → `.badge badge-warn` esiste, o un piccolo `.st--r`.
- `.section-label` "Da fare" / "In ordine" → `.slabel`.
- Lo stato "Tutto in ordine!" → `.empty` o una riga `.prose`.
- Non cambiare `Transition`/`TransitionGroup`, i `computed` dei conteggi, la logica tab.

- [ ] **Step 2: `AttivitaGruppoZona`**

Restilizza l'header di gruppo (nome zona + conteggio + "Segna tutto fatto") a token/`.slabel`-ish; il bottone resta `btn btn-rose`/`btn-ghost`. Nessun cambio logico.

- [ ] **Step 3: `AttivitaRiga`**

**Non ristrutturare** l'espansione/collasso né la registrazione per tipo. Solo:
- `class="card attivita-riga"` → alleggerisci: usa `.task`-style (riga con filetto, icona acquerellata a sinistra col colore del tipo, nome in `var(--font-display)`, label in `var(--ink-mid)`), niente `.card` piena. Se serve un contenitore, una scoped `.attivita-riga` senza radius/ombra.
- `class="title-serif"` / `class="section-label"` → `var(--font-display)` / `.slabel`.
- i blocchi interni "Stato cure" / "Concimi consigliati" già presenti nel pannello espanso → allinea a `.kv`/`.feedlist` dove combaciano, altrimenti token diretti.
- il bottone "✓ Fatto" resta (`btn btn-rose`/`btn-sage` o `.care-act` scoped se serve `cursor:pointer`).

- [ ] **Step 4: Build + verifica**

Run: `npm run build` (exit 0), poi `npm run dev` → `/attivita`, autenticato.
Expected: titolo Fraunces + data; le tab funzionano; i gruppi per zona e l'espansione delle righe funzionano come prima; "✓ Fatto" e "Segna tutto fatto" registrano; niente card pesanti, righe con filetti.

- [ ] **Step 5: Commit**

```bash
git add src/views/AttivitaView.vue src/components/AttivitaGruppoZona.vue src/components/AttivitaRiga.vue
git commit -m "restyle: Attività — titolo Fraunces, tab e righe al linguaggio Taccuino (logica invariata)"
```

---

### Task 9: Verifica integrale Fase 2 (Batch 1+2)

**Files:** nessuno (QA) + nota di esito.

- [ ] **Step 1: Build pulito**

Run: `npm run build` → exit 0, nessun warning nuovo rilevante.

- [ ] **Step 2: Giro in `npm run dev`**

Autenticato, visita: `/progetti`, un progetto (`/progetti/<id>`), `/gallery`, `/agente`, `/zone`, `/zone/<key>/sottozone`, `/concimi`, `/attivita`. E ricontrolla `/` e una scheda pianta (non devono essere regredite).
Expected:
- Ogni vista di Batch 1+2 nel linguaggio Taccuino: titolo Fraunces piatto, liste con filetti, colore nelle icone, card solo dove serve.
- ProgettoView: la traccia si disegna sullo scroll, colore per esito, pallini in sequenza; `prefers-reduced-motion` → tutto statico.
- AgenteView: drawer storico da sinistra, scrollabile.
- Le viste **non** ancora ristilizzate (Meteo, Account, Impostazioni, EditPianta, EditZona, SelettoreSpecie): **non rotte**, titoli in gradiente ora resi come testo — atteso, Batch 3/4.
- Nessun errore in console su nessuna rotta. Nessuna regressione funzionale (form, modali, registrazioni, eliminazioni).

- [ ] **Step 3: Nota di esito**

Scrivi `docs/superpowers/plans/2026-09-02-restyle-taccuino-fase2-esito.md`: cosa è fatto (Batch 1+2), cosa resta (Batch 3: Meteo/Account/Impostazioni/EditPianta/EditZona; Batch 4: SelettoreSpecie), minori rinviati, scostamenti dal piano.

- [ ] **Step 4: Commit finale**

```bash
git add -A && git commit -m "restyle: chiusura Fase 2 Batch 1+2 — nota di esito"
```

Il branch `restyle-taccuino-fase2` è pronto per la review di Rob; la merge su `main` la decide lui.

---

## Self-Review

**Spec coverage:**
- Titolo pagina standard (§ deciso in kickoff) → Task 1 (`.page-title`) + applicato in Task 2–8 ✓
- Progetti/Progetto/Galleria/Zorba dice (mockup Fase 2 approvato) → Task 2, 3, 4, 5 ✓
- Timeline "linea dritta che si disegna sullo scroll, colore per esito" (deciso con Rob) → Task 1 (classi) + Task 3 (markup + scrub JS) ✓
- Zorba dice storico "a sinistra, per molte conversazioni" (deciso con Rob) → Task 1 (`.hstore`) + Task 5 ✓
- §9.3 principi altre viste (liste, `.slabel`, pill, card solo dove serve) → Zone/Sottozone (Task 6), Concimi (Task 7), Attività (Task 8) ✓
- Batch 3 (Meteo/Account/Impostazioni/Edit*) e Batch 4 (SelettoreSpecie) → **fuori da questo piano**, per design (nota di esito Task 9)
- Nessun cambio dati/API/dark-mode → Global Constraints ✓

**Placeholder scan:** i task "portano dal mockup Fase 2" citano un file committato con regole di adattamento esplicite (rename variabili/font, rinomina classi in collisione `.row→.prow`/`.btn--*` scartate). Lo scrub JS di Task 3 è dato per intero. Il gradiente-per-esito è specificato come `computed` di `<stop>`. Nessun "gestire gli edge case" generico. Le modali/logiche esistenti sono esplicitamente "restano identiche".

**Type/naming consistency:** `.page-title` / `.page-title__row` coerenti tra Task 1 e 2–8. Classi mockup rinominate per evitare collisione con l'app: `.row`→`.prow`, `.btn--save/--del`→si riusa `.btn` globale. `--carta/--inchiostro/--seppia/--faint/--linea`→`--cream/--ink/--ink-mid/--ink-soft/--cream-dark` (regola in Global Constraints, richiamata in ogni task che tocca CSS). `classeStato` (Progetti/Progetto) e `classeEsito`/`classeEsitoDot` (Progetto) sostituiscono coerentemente `badgeStato`/`coloreEsito`. `.gtrack/.gslide/.gimg/.gdots` riusate da Fase 1, non ridefinite (Task 1 Step 1 + Task 4).
