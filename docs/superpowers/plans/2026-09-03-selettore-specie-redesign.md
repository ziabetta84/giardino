# Selettore specie — redesign (sola lettura + foglio) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** ridisegnare `src/components/SelettoreSpecie.vue`: **niente più creazione/modifica di specie dall'app** (con la multiutenza il catalogo `specie` è dato condiviso in sola lettura), e la scheda della specie scelta si apre in un **foglio** — dal basso su mobile, laterale da destra su desktop — con tutti i dati in sola lettura. Sostituisce il pass meccanico di "Batch 4". Mockup approvato: `docs/superpowers/specs/assets/2026-09-03-selettore-specie-mockup.html` (copiato in Task 1). Recupera anche l'**icona uovo per il Calcio**, persa dallo sprite (usata anche in Scheda Pianta).

**Architecture:** rimozione mirata di logica (il form 3-tab nuova/modifica specie, ~300 righe) — **approvata esplicitamente da Rob** — più restyle. Ricerca/selezione e letture da store/Supabase restano intatte, così come il contratto `v-model` verso i consumatori (`EditPiantaView.vue`, `AgenteView.vue`). Si globalizza il blocco "Stato cure" di `PiantaView.vue` (`.care*`) in `main.css` per riusarlo nel dossier, e si introduce un componente foglio riusabile (`FoglioLaterale.vue`), primo passo del pattern che sostituirà tutte le modali centrali dell'app (rollout = batch a parte, fuori scope).

**Tech Stack:** Vue 3 `<script setup>` SFC, Vite, Pinia. Nessun test runner: verifica = `npm run build` exit 0 + controllo visivo.

**Spec:** il mockup approvato + `docs/superpowers/specs/2026-09-02-restyle-taccuino-design.md` + le sezioni "La specie" e "Stato cure" di `PiantaView.vue` come riferimento vivo.

## Global Constraints

- **Branch:** `restyle-taccuino-batch4` (HEAD `9498ce0`). Nessun merge/push su `main` senza richiesta esplicita di Rob (deploy automatico).
- **Ambito file:** `src/assets/main.css`; `src/components/IconDefs.vue`; `src/views/PiantaView.vue` (solo per: globalizzazione `.care*` + icona calcio — vedi Task 2); `src/components/FoglioLaterale.vue` (NUOVO); `src/components/SelettoreSpecie.vue`; `docs/superpowers/specs/assets/2026-09-03-selettore-specie-mockup.html` (copia). **NON toccare** `EditPiantaView.vue` / `AgenteView.vue` a meno che Task 4 Step 1 non trovi un `emit` diverso da `update:modelValue` con un listener nei genitori — in quel caso il piano si estende, minimamente.
- **Cosa si rimuove da `SelettoreSpecie.vue`** (deliberato): il `<Teleport>` con la modale nuova/modifica specie (tab Generale/Cure/Coltivazione); tutto lo stato e le funzioni che la servono (`mostraNuovaSpecie`, `nuovaSpecie`, `tabAttiva`, `salvandoSpecie`, `erroreSpecie`, `specieModificaOriginale`, `STAGIONI`, `STAGIONI_PILL`, `vasoVuoto`, `coltivazioneVuota`, `toggleStagione`, `manutenzioneVuota`, `manutenzioneOriginale`, `manutenzioneNumeroIniziale`, `estraiGiorniPuliti`, `generaManutenzione`, `slug`, `apriNuovaSpecie`, `apriModificaSpecie`, `chiudiNuovaSpecie`, `salvaNuovaSpecie`); l'import `usePianteApi` (`pianteApi` non serve più); la matita di modifica per riga nel dropdown; la riga "＋ Aggiungi nuova specie"; il bottone "Modifica" nella scheda.
- **Cosa NON si tocca in `SelettoreSpecie.vue`:** la ricerca (`specieQuery`, `dropdownAperto`, `specieFiltrate`, `ricercaInCorso`, `ricercaOffline`, `eseguiRicercaRemota`, `escapeIlike`, `watch(specieQuery,…)`, `onUnmounted`, `risolviEMergeCultivar`, `watch(() => props.modelValue,…)`), la selezione (`selezionaSpecie`, `chiudiDropdown`), il contratto `props.modelValue` / `emit('update:modelValue', …)`, gli import che servono (`useDatiStore`, `useSupabase`, `mappaSpecie`/`COLONNE_SPECIE`/`fondiEredita`, `urlMiniatura`, `parseGiorni`). Nessuna scrittura su `specie` da nessuna parte.
- **Sicurezza (fuori da questo piano):** togliere l'UI non chiude la RLS di scrittura aperta ("temporanea") su `specie` (CLAUDE.md). Migration a parte ora che c'è il login — annotata nella nota di esito, non implementata.
- **Nessuna regola nuova in `style="…"` inline** (binding `:style`/`:class` condizionali OK). Regole nuove → `main.css` (classi riusabili) o `<style scoped>`.
- **Dark mode:** niente blocchi `@media (prefers-color-scheme: dark)` / `[data-theme]` (Fase 3).
- **`prefers-reduced-motion`:** il foglio compare senza slide quando la media query è attiva.
- **Verifica:** `npm run build` exit 0. Poi `npm run dev` → `/piante/nuova`, `/agente` → "revisione specie", e `/piante/<id>` (per il calcio con icona uovo in "Stato cure"). Se il dev server non parte (OOM noto) dirlo e affidarsi a build + lettura.
- **Commit:** italiano, prefisso `redesign:` / `restyle:`, con trailer:
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
  ```

---

### Task 1: `main.css` — foglio riusabile + globalizzazione "Stato cure" (`.care*`); copia mockup

**Files:**
- Modify: `src/assets/main.css` (append)
- Create: `docs/superpowers/specs/assets/2026-09-03-selettore-specie-mockup.html` (copia di `/Users/rob/.claude/jobs/9f762bfd/tmp/selettore-specie-mockup.html`)

**Interfaces:**
- Produce:
  - `.foglio-dim` (+ `.open`), `.foglio` (+ `.open`), `.foglio__grab`, `.foglio__hd` (+ `h3`), `.foglio__x`, `.foglio__body` — foglio riusabile: bottom sheet < 640px, side sheet ≥ 640px. Consumate da Task 3.
  - `.care`, `.care__row`, `.care__ic` (+ `.care__ic--irrigazione|--concimazione|--calcio|--potatura|--npk`), `.care__m`, `.care__n`, `.care__d` (+ `.care__d--none`) — spostate dal `<style scoped>` di `PiantaView.vue` (che le perde in Task 2), con l'aggiunta della variante `--npk` e il ritocco beige di `--calcio`. Consumate da Task 3 e da `PiantaView.vue` (già le usa).

- [ ] **Step 1: Copia il mockup**

```bash
cp /Users/rob/.claude/jobs/9f762bfd/tmp/selettore-specie-mockup.html docs/superpowers/specs/assets/2026-09-03-selettore-specie-mockup.html
```

- [ ] **Step 2: `.foglio*` (in coda a `main.css`)**

Blocco `/* ===== foglio (bottom sheet mobile / side sheet desktop) — riusabile ===== */`:
```css
.foglio-dim{position:fixed;inset:0;z-index:300;background:rgba(30,22,10,.34);
  opacity:0;pointer-events:none;transition:opacity .22s ease}
.foglio-dim.open{opacity:1;pointer-events:auto}
.foglio{position:fixed;left:0;right:0;bottom:0;z-index:301;display:flex;flex-direction:column;
  background:var(--white);border-radius:22px 22px 0 0;max-height:92vh;
  box-shadow:0 -18px 50px -20px rgba(30,22,10,.5);
  transform:translateY(101%);transition:transform .26s ease}
.foglio.open{transform:translateY(0)}
.foglio__grab{width:38px;height:4px;border-radius:999px;background:var(--cream-dark);margin:9px auto 2px;flex:none}
.foglio__hd{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:6px 16px 12px;flex:none}
.foglio__hd h3{font:600 16px/1.15 var(--font-display);margin:0;color:var(--ink)}
.foglio__x{width:30px;height:30px;border-radius:50%;border:0;background:var(--cream-dark);color:var(--ink-mid);
  font-size:17px;line-height:1;cursor:pointer;flex:none}
.foglio__body{overflow-y:auto;flex:1;-webkit-overflow-scrolling:touch}
@media (min-width:640px){
  .foglio{left:auto;right:0;top:0;bottom:0;width:420px;max-width:92vw;max-height:none;
    border-radius:0;box-shadow:-18px 0 50px -22px rgba(30,22,10,.4);transform:translateX(101%)}
  .foglio.open{transform:translateX(0)}
  .foglio__grab{display:none}
  .foglio__hd{padding:16px 18px 12px}
}
@media (prefers-reduced-motion:reduce){ .foglio,.foglio-dim{transition:none} }
```

- [ ] **Step 3: Globalizza `.care*` da `PiantaView.vue`**

Apri `src/views/PiantaView.vue`, copia le regole `<style scoped>` per `.care`, `.care__row`, `.care__row + .care__row`, `.care__ic`, `.care__ic svg`, `.care__ic--irrigazione`, `.care__ic--concimazione`, `.care__ic--calcio`, `.care__ic--potatura`, `.care__m`, `.care__n`, `.care__d` e incollale in `main.css` in un blocco `/* ===== "Stato cure" / calendario cure — condiviso (era scoped in PiantaView) ===== */`. Poi:
- **`.care__ic--calcio`**: cambia da `background: var(--sage-bg); color: var(--sage-ink);` a `background: var(--carta-2); color: var(--ink-mid);` (tinta beige — richiesta di Rob, il calcio riceve anche l'icona uovo in Task 2).
- **Aggiungi** `.care__ic--npk { background: var(--sage-bg); color: var(--sage-ink); }` (riga "Fabbisogno NPK" — tinta salvia, coerente con l'icona `provetta` che è `var(--sage)`).
- **Aggiungi** `.care__d--none { color: var(--ink-faint); }` (valore assente per la stagione scelta).
Non spostare `.care-act` / `.care-act--rose` / `.care-act:disabled` (restano scoped in PiantaView — sono il bottone interattivo, non usato nel dossier di sola lettura).

- [ ] **Step 4: Build + self-review**

Run: `npm run build` → exit 0.
- `grep -nE "^\.foglio|^\.care\b|^\.care__" src/assets/main.css` → il blocco nuovo.
- `.foglio*` / `.care__ic--npk` / `.care__d--none` non pre-esistono in `main.css` (grep). Nessun `@media (prefers-color-scheme: dark)`. Nessun font letterale.
- Le regole `.care*` copiate corrispondono a quelle di PiantaView (Task 2 le toglierà da lì: se restano in entrambi i posti, il build passa comunque ma è un doppione — Task 2 lo risolve).

- [ ] **Step 5: Commit**

```bash
git add src/assets/main.css docs/superpowers/specs/assets/2026-09-03-selettore-specie-mockup.html
git commit -m "redesign: foglio riusabile (.foglio) + \"Stato cure\" globalizzato (.care*, +npk, calcio beige); mockup"
```

---

### Task 2: icona uovo per il Calcio + `PiantaView` usa `.care*` globali

**Files:**
- Modify: `src/components/IconDefs.vue`
- Modify: `src/views/PiantaView.vue`

**Interfaces:**
- Produce: `<Icon name="uovo" />` (nuovo simbolo `i-uovo` nello sprite). Consumato da `PiantaView.vue` (Task 2) e dal dossier (Task 3).

- [ ] **Step 1: `IconDefs.vue` — `<symbol id="i-uovo">` + `<clipPath id="clip-uovo">`**

Nel `<defs>`, accanto agli altri `clipPath`, aggiungi:
```html
<clipPath id="clip-uovo"><path d="M128,28 C96,28 68,92 68,148 a60,60 0 0 0 120,0 C188,92 160,28 128,28 Z"/></clipPath>
```
Accanto agli altri `<symbol>` (dopo `i-provetta`, che è il vicino tematico), aggiungi:
```html
<!-- Uovo: guscio d'uovo, per il Calcio (marciume apicale). -->
<symbol id="i-uovo" viewBox="0 0 256 256">
  <path fill="var(--uovo)" fill-rule="evenodd" d="M128,28 C96,28 68,92 68,148 a60,60 0 0 0 120,0 C188,92 160,28 128,28 Z"/>
  <g clip-path="url(#clip-uovo)"><ellipse cx="118" cy="176" rx="46" ry="40" fill="var(--uovo-dark)" opacity=".4"/></g>
</symbol>
```
In `src/assets/main.css`, nel blocco `:root`, aggiungi accanto agli altri token colore:
```css
  --uovo:      #cbb994;
  --uovo-dark: #a68f63;
```
(Beige guscio + accento più scuro, coerente con lo stile "acquerellato" delle altre icone. Se Rob lo vuole più chiaro/scuro è un ritocco di un token.)

- [ ] **Step 2: `PiantaView.vue` — usa l'uovo + le `.care*` globali**

- `const ICONE_CURA = { irrigazione: 'goccia', concimazione: 'concimazione', potatura: 'potatura', calcio: 'provetta' }` → `calcio: 'uovo'`.
- Nel `<style scoped>`: **rimuovi** le regole ora globali (Task 1 Step 3): `.care`, `.care__row`, `.care__row + .care__row`, `.care__ic`, `.care__ic svg`, `.care__ic--irrigazione`, `.care__ic--concimazione`, `.care__ic--calcio`, `.care__ic--potatura`, `.care__m`, `.care__n`, `.care__d`. **Tieni** `.care-act`, `.care-act--rose`, `.care-act:disabled` (restano scoped). Nessun cambio al `<template>` di PiantaView (le classi sono le stesse, ora servite da `main.css`).

- [ ] **Step 3: Build + verifica**

Run: `npm run build` (exit 0), poi `npm run dev` → `/piante/<id di una pianta con calcio>`.
Expected: la sezione "Stato cure" invariata nel layout, la riga **Calcio** ora con l'**icona uovo** su tessera beige; irrigazione/concimazione/potatura invariate; il bottone "✓ Fatto" (`.care-act`) funziona come prima.
- `grep -n "\.care__ic--calcio\|\.care__row\b" src/views/PiantaView.vue` → solo eventuali usi nel `<template>`, nessuna regola `<style>` rimasta.

- [ ] **Step 4: Commit**

```bash
git add src/components/IconDefs.vue src/views/PiantaView.vue src/assets/main.css
git commit -m "redesign: reintroduce l'icona uovo per il Calcio (i-uovo) + PiantaView usa le .care* globali"
```

---

### Task 3: `FoglioLaterale.vue` — componente foglio riusabile

**Files:**
- Create: `src/components/FoglioLaterale.vue`

**Interfaces:**
- Consuma: `.foglio-dim`, `.foglio`, `.foglio.open`, `.foglio__grab`, `.foglio__hd`, `.foglio__x`, `.foglio__body` (Task 1).
- Produce: componente con
  - props: `modelValue: Boolean`, `titolo: { type: String, default: '' }`.
  - emit: `update:modelValue` (a `false` alla chiusura).
  - slot: `default` (corpo). Slot `intestazione` opzionale (rimpiazza `h3` + area sinistra dell'header; la `×` resta sempre).
- Consumato da Task 4.

- [ ] **Step 1: Scrivi il componente**

```vue
<template>
  <Teleport to="body">
    <div class="foglio-dim" :class="{ open: modelValue }" @click="chiudi"></div>
    <div class="foglio" :class="{ open: modelValue }" role="dialog" aria-modal="true"
      tabindex="-1" ref="pannello" @keydown.esc="chiudi">
      <div class="foglio__grab" aria-hidden="true"></div>
      <div class="foglio__hd">
        <slot name="intestazione"><h3 v-if="titolo">{{ titolo }}</h3><span v-else></span></slot>
        <button type="button" class="foglio__x" aria-label="Chiudi" @click="chiudi">×</button>
      </div>
      <div class="foglio__body"><slot /></div>
    </div>
  </Teleport>
</template>

<script setup>
import { watch, nextTick, ref, onBeforeUnmount } from 'vue'

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  titolo: { type: String, default: '' },
})
const emit = defineEmits(['update:modelValue'])
const pannello = ref(null)

function chiudi() { emit('update:modelValue', false) }

// Blocca lo scroll del body mentre il foglio è aperto e sposta il focus sul
// pannello (per Esc / lettori di schermo). Nessun focus-trap completo:
// coerente con le modali esistenti dell'app.
watch(() => props.modelValue, async (aperto) => {
  document.body.style.overflow = aperto ? 'hidden' : ''
  if (aperto) { await nextTick(); pannello.value?.focus() }
})
onBeforeUnmount(() => { document.body.style.overflow = '' })
</script>
```
Il ripristino di `body.overflow` allo smontaggio evita che un unmount con foglio aperto lasci il body bloccato.

`.foglio`/`.foglio-dim` restano montati (Teleport) e si animano via `.open` + `transform`; `pointer-events:none` sul dim chiuso.

- [ ] **Step 2: Build**

Run: `npm run build` → exit 0 (non ancora usato: verifica solo la compilazione — attenzione al refuso `onBeforeUnmount`).

- [ ] **Step 3: Self-review**

- `import` con `onBeforeUnmount` corretto; nessun import inutilizzato.
- `Teleport to="body"`; `role="dialog"`/`aria-modal`; `aria-label` sulla `×`.
- `document.body.style.overflow` ripristinato a `''` (non `'auto'`) sia alla chiusura sia allo smontaggio.
- Nessuno `<style>` (classi globali).

- [ ] **Step 4: Commit**

```bash
git add src/components/FoglioLaterale.vue
git commit -m "redesign: FoglioLaterale.vue — foglio riusabile (bottom sheet mobile / laterale desktop)"
```

---

### Task 4: `SelettoreSpecie.vue` — sola lettura + dossier nel foglio

**Files:**
- Modify: `src/components/SelettoreSpecie.vue`

**Interfaces:**
- Consuma: `FoglioLaterale` (Task 3), `.slabel`/`.kv`/`.prose`/`.specie-ghost`/`.care*` (Task 1)/`.field-label`, `<Icon>`, `<Spinner>`, `<RouterLink>`, token. Contratto invariato: `props.modelValue` (slug), `emit('update:modelValue', slug)`.

- [ ] **Step 1: Verifica il contratto verso i genitori**

`grep -n "SelettoreSpecie" src/views/*.vue` → `EditPiantaView.vue` e `AgenteView.vue` usano SOLO `v-model` (nessun `@evento` ascoltato). `grep -n "defineEmits" src/components/SelettoreSpecie.vue` → resta `['update:modelValue']`. Se trovi un emit aggiuntivo con listener in un genitore, FERMATI e segnala.

- [ ] **Step 2: Rimuovi la modale nuova/modifica specie**

- `<template>`: elimina l'intero `<Teleport to="body"> … </Teleport>` con `.modal-box` e le tre `<template v-if="tabAttiva === …">`.
- `<script setup>`: elimina tutto l'elenco in "Cosa si rimuove" (Global Constraints) — da `const mostraNuovaSpecie` a `salvaNuovaSpecie`, più `function slug`, più l'import `usePianteApi` + `const pianteApi = usePianteApi()`.
- **Mantieni** l'import `parseGiorni` da `@/composables/useCure` (serve al calendario cure, Step 5).
- `<style scoped>`: elimina `.overlay`, `.modal-box`, `.campo-label`, `.campo-hint`, `.manutenzione-grid`, `.stagione-header`, `.tipo-label`, `.manutenzione-grid input`, `.specie-nuova` e ogni regola usata solo da modale / riga "aggiungi specie".
- `npm run build` deve passare qui.

- [ ] **Step 3: Dropdown — raggruppato, con miniatura, senza matite**

- In `specieFiltrate` (computed): aggiungi `immagine: s.immagine ?? null` al `.map(...)`.
- Ogni riga `.specie-opzione-riga`:
  - rimuovi il `<button class="icon-btn" @mousedown.prevent="apriModificaSpecie(s)">`.
  - a sinistra una miniatura `.dd-thumb`: `:style="s.immagine?.url ? { backgroundImage: \`url(${urlMiniatura(s.immagine.url, 96)})\` } : null"`; senza immagine, fondo tinta + `<Icon name="foglia" />` placeholder.
  - nome `.dd-name` (`var(--font-display)`), binomio `.dd-sci` (italico piccolo), badge cultivar/bozza come oggi (piccoli).
- Raggruppa in due liste con un `.slabel` ciascuna: "Nel tuo giardino" (`s.verificata` come proxy, o un flag "posseduta" se comodo) e "Nel catalogo" (il resto). Se la seconda è vuota (campo vuoto → solo verificate) mostra solo il primo gruppo senza `.slabel`.
- Footer: al posto della riga `.specie-nuova`,
  `<RouterLink to="/agente" class="dd-foot">Non la trovi? <span>Chiedi a Zorba di aggiungerla →</span></RouterLink>`.
- `ricercaInCorso` / `ricercaOffline` / "nessuna specie trovata" / hint a campo vuoto: restano, restilizzati a `var(--ink-faint)` in un piccolo `<p>` scoped (`.dd-nota`).

- [ ] **Step 4: Card compatta post-scelta + apertura foglio**

- Sostituisci `<div v-if="specieSelezionata && !dropdownAperto" class="scheda-specie"> … </div>` con:
  ```html
  <div v-if="specieSelezionata && !dropdownAperto" class="scheda-chosen">
    <span class="sc-th" :style="hero ? { backgroundImage: `url(${hero.thumbUrl})` } : null"></span>
    <span class="sc-m">
      <span class="sc-nm">{{ specieSelezionata.nome }}</span>
      <span v-if="specieSelezionata.specie" class="sc-sci">{{ specieSelezionata.specie }}</span>
      <span class="sc-acts">
        <button type="button" @click="dossierAperto = true">Vedi scheda completa</button>
        <button type="button" class="alt" @click="apriRicerca">Cambia</button>
      </span>
    </span>
  </div>
  ```
- `const dossierAperto = ref(false)`.
- `apriRicerca()` = `dropdownAperto.value = true` (+ focus sull'input se la logica esiste già).
- In `selezionaSpecie(s)`: dopo `emit`/`dropdownAperto=false`, aggiungi `dossierAperto.value = true` (apertura automatica alla prima scelta — richiesta di Rob).
- `<style scoped>` per `.scheda-chosen`/`.sc-th`/`.sc-m`/`.sc-nm`/`.sc-sci`/`.sc-acts` (dal mockup, classe `.chosen`).

- [ ] **Step 5: Dossier nel `<FoglioLaterale>`**

Dopo la card compatta:
```html
<FoglioLaterale v-model="dossierAperto">
  <template #intestazione><span></span></template>
  <div class="specie-ghost" aria-hidden="true"><!-- stesso <svg> di PiantaView "La specie" --></div>

  <!-- hero: se hero → blocco foto con nome/binomio sovrapposti (stile .phead-cap:
       scrim + .pname/.pbino); altrimenti intestazione testuale (nome + binomio +
       badge stato) -->

  <div class="dossier-body">
    <div class="slabel">La specie</div>
    <p v-if="specieSelezionata.descrizione" class="prose">{{ specieSelezionata.descrizione }}</p>
    <p v-else class="prose dossier-vuoto">Nessuna descrizione per questa specie.</p>

    <template v-if="esigenzeVoci.length">
      <div class="slabel">Esigenze</div>
      <div class="kv">
        <div v-for="e in esigenzeVoci" :key="e.chiave">
          <span class="k"><Icon :name="e.icona" />{{ capitalizza(e.chiave) }}</span><span class="v">{{ e.valore }}</span>
        </div>
      </div>
    </template>

    <template v-if="cureRighe.length">
      <div class="slabel">Calendario cure</div>
      <div class="dossier-stagioni">
        <button v-for="s in STAGIONI_CAL" :key="s.val" type="button" class="pill"
          :class="{ active: stagioneCal === s.val }" @click="stagioneCal = s.val">{{ s.label }}</button>
      </div>
      <div class="care">
        <div v-for="r in cureRighe" :key="r.tipo" class="care__row">
          <span class="care__ic" :class="`care__ic--${r.tipo}`"><Icon :name="r.icona" /></span>
          <span class="care__m">
            <span class="care__n">{{ r.label }}</span>
            <span class="care__d" :class="{ 'care__d--none': !r.valore }">{{ r.valore || 'Non prevista in questa stagione' }}</span>
          </span>
        </div>
      </div>
    </template>

    <template v-if="coltivazioneVoci.length">
      <div class="slabel">Coltivazione</div>
      <div class="kv"><div v-for="c in coltivazioneVoci" :key="c.k"><span class="k">{{ c.k }}</span><span class="v">{{ c.v }}</span></div></div>
    </template>

    <template v-if="alertList.length">
      <div class="slabel">Note tecniche</div>
      <ul class="notelist"><li v-for="a in alertVisibili" :key="a">{{ a }}</li></ul>
      <button v-if="alertExtra > 0" type="button" class="dossier-more" @click="alertTuttiAperti = !alertTuttiAperti">
        {{ alertTuttiAperti ? 'Mostra meno' : `+ ${alertExtra} altre` }}
      </button>
    </template>
  </div>
</FoglioLaterale>
```

Script — nuovi (sola lettura, dal record `specieSelezionata`):
- `capitalizza(s)` — `s.charAt(0).toUpperCase() + s.slice(1)` (come in PiantaView).
- **Icone esigenze** — allinea a PiantaView: `ICONA_ESIGENZA = { sole:'sole', luce:'sole', esposizione:'sole', acqua:'goccia', irrigazione:'goccia', umidita:'goccia', 'umidità':'goccia', terreno:'foglia', suolo:'foglia', substrato:'foglia', ph:'foglia', temperatura:'caldo', clima:'caldo', gelo:'gelo', spazio:'pin', distanza:'pin', potatura:'potatura', concimazione:'concimazione' }`, fallback `'foglia'`. Aggiorna `esigenzeVoci` per usarlo (oggi ha `{ luce:'sole', acqua:'goccia', terreno:'terra' }` — `terra` va cambiato in `foglia`, come PiantaView).
- `STAGIONI_CAL = [{val:'primavera',label:'Primavera'},{val:'estate',label:'Estate'},{val:'autunno',label:'Autunno'},{val:'inverno',label:'Inverno'}]`.
- `stagioneCal` — `ref(stagioneCorrente())` dove `stagioneCorrente()` mappa il mese corrente a una delle 4 stagioni (riusa la logica di `useCure` se esporta un helper; altrimenti: mesi 3-5 primavera, 6-8 estate, 9-11 autunno, 12/1-2 inverno).
- `cureRighe` — array `{ tipo, label, icona, valore }` per i tipi presenti in `specieSelezionata.manutenzione`, nell'ordine `irrigazione, concimazione, calcio, potatura, npk`, ma **solo** se quel tipo ha almeno una stagione non vuota. Etichette: "Irrigazione"/"Concimazione"/"Calcio"/"Potatura"/"Fabbisogno NPK". Icone: `goccia`/`concimazione`/`uovo`/`potatura`/`provetta`. `valore` = valore per `stagioneCal`:
  - irrigazione/concimazione/calcio: `manutenzione[tipo][stagioneCal]`; se `parseGiorni(v)` dà un numero → `Ogni ${n} giorni` (`Ogni giorno` per `1`); altrimenti il testo grezzo; vuoto → `''` (mostra "Non prevista in questa stagione", classe `--none`).
  - potatura: `manutenzione.potatura[stagioneCal]` testo grezzo; vuoto → `''`.
  - npk: `manutenzione.npk[stagioneCal]` (stringa `n-p-k`); vuoto → `''`.
- `coltivazioneVoci` — array `{ k, v }` dalle chiavi presenti di `specieSelezionata.coltivazione`, stesse etichette di PiantaView ("Famiglia", "Germinazione"+" gg", "Al trapianto"+" gg dalla semina", "Prima raccolta"+" gg dal trapianto", "Finestra semina", "Finestra trapianto", "Resistenza al gelo", "Spaziatura"+" cm", "Si abbina a" ← `consociazioni_favorevoli.join(', ')`, "Evitare vicino a" ← `consociazioni_sfavorevoli.join(', ')`). Aggiungi le voci vaso **se** il record le espone (nomi reali da verificare sul record: `vaso` / `vaso_*` / `adatta_vaso`…); se non ci sono, ometti e annota nel report.

`<style scoped>` — aggiungi: `.dossier-body` (padding 16px 16px 26px), `.dossier-vuoto` (italic, `--ink-faint`), `.dossier-stagioni` (flex, gap 6px, `.pill` a `padding:6px 12px;font-size:11px`, `margin:-2px 0 12px`), `.dossier-more` (come l'attuale `.scheda-alert-toggle`), `.notelist`/`.notelist li` (dal mockup: `li` con bullet rosa). Il blocco hero foto (`.dh*` del mockup) o il fallback testuale (nome+binomio+badge). Elimina gli scoped `.scheda-*` non più usati (`.scheda-specie`, `.scheda-hero*`, `.scheda-testa`, `.scheda-modifica`, `.scheda-descrizione`, `.scheda-esigenze`, `.scheda-alert*`, `.scheda-nome`, `.scheda-sci`, `.scheda-badge`, `.scheda-vuota`) — riusa quelli che combaciano rinominandoli `.dossier-*` o `.dh-*`.

- [ ] **Step 6: Build + verifica**

Run: `npm run build` (exit 0), poi `npm run dev` → `/piante/nuova` e `/agente` (revisione specie).
Expected:
- ricerca: si digita → tendina con gruppi + miniatura, niente matite, footer "Chiedi a Zorba"; remota/offline/vuoto invariati.
- alla scelta: tendina chiusa, card compatta + il foglio si apre (da destra su desktop, dal basso su mobile); Esc / velo / × chiudono; con *riduci animazioni* niente slide.
- dossier: descrizione, esigenze con icone acquerellate reali (`sole`/`goccia`/`foglia`), **calendario cure** = pill stagioni + righe stile "Stato cure" (icona colorata + valore per la stagione scelta; calcio con icona uovo su tessera beige; "Non prevista in questa stagione" quando vuoto), coltivazione, note tecniche con "+N altre".
- "Cambia" riapre la tendina. Nessun modo di creare/modificare una specie.
- `EditPiantaView` salva la pianta come prima; `AgenteView` invia "revisione specie" come prima.

- [ ] **Step 7: Commit**

```bash
git add src/components/SelettoreSpecie.vue
git commit -m "redesign: SelettoreSpecie — sola lettura, dossier nel foglio, calendario cure con pill stagioni"
```

---

### Task 5: Verifica integrale + nota di esito

**Files:** nessuno (QA) + nota di esito.

- [ ] **Step 1: Build + grep**

```bash
npm run build   # exit 0
grep -nE "apriNuovaSpecie|apriModificaSpecie|salvaNuovaSpecie|nuovaSpecie|usePianteApi|mostraNuovaSpecie|tabAttiva" src/components/SelettoreSpecie.vue   # → niente
grep -rn "SelettoreSpecie" src/views/*.vue   # → solo v-model
grep -nE "font-serif|title-serif|title-display|gradient-title|section-label" src/components/SelettoreSpecie.vue   # → niente
grep -n "i-uovo\|clip-uovo" src/components/IconDefs.vue   # → presenti
```

- [ ] **Step 2: Giro in `npm run dev`**

`/piante/nuova`, `/piante/<id>/modifica`, `/piante/<id>` (Stato cure → Calcio con uovo), `/agente` (revisione specie). Nessun errore console. Ricerca / scelta / foglio (mobile + desktop, Esc/velo/×, reduced-motion) / card compatta / "Cambia" / salvataggio pianta / invio richiesta agente / "Stato cure" in PiantaView — tutto a posto. Nessun percorso per creare/modificare specie.

- [ ] **Step 3: Nota di esito**

`docs/superpowers/plans/2026-09-03-selettore-specie-redesign-esito.md`: cosa è fatto; **RLS `specie` da chiudere con una migration a parte** (evidenziato); rollout di `FoglioLaterale` alle altre modali (ProgettiView, ConcimiView, SottozoneView, EditPianta, ModalConferma, dettaglio Meteo) = batch successivo; follow-up minori (precompilare il tipo richiesta nel link "Chiedi a Zorba"; unificare `.dossier-*`/`.dh-*` con "La specie" di PiantaView se restano doppioni; `--uovo`/`--uovo-dark` da ritoccare se la tinta non convince); Fase 3 dark mode; Fase 4 hero stagionale.

- [ ] **Step 4: Commit finale**

```bash
git add -A && git commit -m "redesign: chiusura selettore specie — nota di esito"
```

---

## Self-Review

**Spec coverage (mockup approvato + feedback di Rob):**
- Niente creazione/modifica specie dall'app → Task 4 Step 2 ✓
- Ricerca invariata, dropdown raggruppato con miniatura, footer "Chiedi a Zorba" → Task 4 Step 3 ✓
- Scheda specie nel foglio (bottom mobile / laterale desktop), apertura automatica alla scelta, `prefers-reduced-motion` → Task 1 (`.foglio*`) + Task 3 (`FoglioLaterale`) + Task 4 Step 4–5 ✓
- Esigenze con le icone acquerellate reali (`sole`/`goccia`/`foglia`) → Task 4 Step 5 (`ICONA_ESIGENZA` allineato a PiantaView) ✓
- Calendario cure = layout "Stato cure" + pill stagioni cliccabili (fabbisogno per periodo) → Task 1 (globalizza `.care*`) + Task 4 Step 5 (`STAGIONI_CAL`, `stagioneCal`, `cureRighe`) ✓
- Icona uovo per il Calcio, riaggiunta e usata anche in PiantaView; tessera beige → Task 2 (`i-uovo`, `ICONE_CURA.calcio`, `.care__ic--calcio`) ✓
- Card compatta post-scelta ("Vedi scheda completa" + "Cambia") → Task 4 Step 4 ✓
- RLS `specie` → fuori scope, evidenziata Task 5 Step 3
- Rollout `FoglioLaterale` alle altre modali → fuori scope, batch successivo (Task 5 Step 3)

**Placeholder scan:** ogni task elenca i simboli esatti da rimuovere/aggiungere (dalla lettura del file), i computed nuovi con forma di ritorno e formattazione per tipo, gli helper (`capitalizza`, `stagioneCorrente`), le etichette `.kv` verbatim da PiantaView, l'ordine e le icone delle righe cure, il path SVG dell'uovo per intero, i due token `--uovo`. Le eccezioni sono esplicitate (voci vaso se il record non le espone → ometti + annota; refuso `onBeforeUnmount` da correggere). Il comportamento di ricerca è "invariato" e elencato tra i non-tocchi. `FoglioLaterale` è dato per intero.

**Type/naming consistency:** `dossierAperto` (ref) coerente Task 4 Step 4↔5. `FoglioLaterale` `modelValue`/`update:modelValue` coerente Task 3↔4. `.foglio*` / `.care*` / `.care__ic--npk` / `.care__d--none` coerenti Task 1 (def) ↔ Task 2/4 (uso). `stagioneCal` / `STAGIONI_CAL` / `cureRighe` coerenti dentro Task 4 Step 5. `i-uovo` coerente Task 2 (def) ↔ Task 4 Step 5 (`icona: 'uovo'`). `emit(['update:modelValue'])` di SelettoreSpecie invariato (Task 4 Step 1 lo verifica). `ICONE_CURA.calcio` (PiantaView, Task 2) e `cureRighe[calcio].icona` (SelettoreSpecie, Task 4) entrambi `'uovo'`.
