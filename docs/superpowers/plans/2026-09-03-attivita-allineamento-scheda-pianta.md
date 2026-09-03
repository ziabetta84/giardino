# Attività ↔ scheda pianta — allineamento + dossier nel foglio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** togliere da `AttivitaRiga.vue` l'accordion inline (che re-implementa a mano la scheda pianta) e far aprire il **dettaglio della pianta in un `FoglioLaterale`** — stesso pattern del selettore specie — con i contenuti sulle classi condivise di `PiantaView.vue` (`.care*` "Stato cure", `.feedlist`/`.feed*` "Concimi consigliati", `.kv` "Esigenze" con icone, `.notelist` "Note tecniche"). Estrarre in un composable le mappe icone/etichette cure ed esigenze oggi triplicate. Ristilizzare le righe della tab "Progetti" (oggi `.card` + `style` inline) a righe con filetto.

**Architecture:** presentazione + un'estrazione (`useCureVisual.js`) + un nuovo componente di contenuto (`DossierPianta.vue`). Un **solo** `<FoglioLaterale>` a livello di `AttivitaView` (non uno per riga — sarebbero decine di `<Teleport>` nascosti): `AttivitaRiga` emette `apri-dossier(item)` verso l'alto, `AttivitaGruppoZona` lo inoltra, `AttivitaView` tiene il foglio + `<DossierPianta>`. `AttivitaRiga` perde `espansa`/il trucco `grid-template-rows`/il chevron; tiene il bottone "✓ Fatto" sulla riga (azione rapida). Nessun cambio a calcolo cure/urgenze/tab/registrazioni. Si aggancia al selettore specie mergiato (`4e02e25`): `.care*` è già globale, l'icona `uovo` per il Calcio esiste, `FoglioLaterale.vue` esiste.

**Tech Stack:** Vue 3 `<script setup>` SFC, Vite, Pinia. Nessun test runner: verifica = `npm run build` exit 0 + controllo visivo.

**Spec:** `docs/superpowers/specs/2026-09-02-restyle-taccuino-design.md` + `PiantaView.vue` (sezioni "Stato cure" / "Concimi consigliati" / "Esigenze" / "Note tecniche") + `SelettoreSpecie.vue` (uso di `FoglioLaterale`) come riferimento vivo.

## Global Constraints

- **Branch:** `attivita-allineamento` (da `main` @ `4e02e25`). Nessun merge/push su `main` senza richiesta esplicita di Rob.
- **Ambito file:** `src/composables/useCureVisual.js` (NUOVO); `src/components/DossierPianta.vue` (NUOVO); `src/assets/main.css` (globalizza `.care-act*` + `.feed-nb` se scoped in PiantaView); `src/views/PiantaView.vue` (usa il composable, perde `.care-act*` scoped); `src/components/AttivitaRiga.vue`; `src/components/AttivitaGruppoZona.vue`; `src/views/AttivitaView.vue`; `src/components/SelettoreSpecie.vue` (usa il composable per `iconaEsigenza`/`capitalizza`, solo se combacia senza rischi — Task 1). **Non toccare** `useCure.js`, `useConcimi.js`, `useProgetti.js`, `usePianteApi.js`, `raggruppaAttivita.js`, gli store, `FoglioLaterale.vue`.
- **Logica invariata:** in `AttivitaView` — tab (`tabAttiva`, `TIPI_TAB`, `conteggioTab`, `vuotaTab`, `daFareTab`/`inScadenzaTab`, `gruppi*`), `Transition`/`TransitionGroup` + stagger, i `computed` (`attivita`, `daFare`, `inScadenza`, `tappeProgetto`), `registra`/`registraGruppo`/`registraTappa`. In `AttivitaRiga` — le condizioni di `valutaCura`, `tipiCura`, `fabbisognoNpk`, `classificaConcimiPianta`, `contestoCura`, `registraCuraTipo`, `salvandoTipo`. Il calcolo cure/urgenze non si tocca; si sposta solo *dove* vive il rendering del pannello.
- **Contratti componente:** `AttivitaRiga` props (`item`, `variante`, `disabled`) invariate; **aggiunge** un emit `apri-dossier` (payload = `item`) oltre a `registra`. `AttivitaGruppoZona` inoltra `apri-dossier` (aggiunge a `defineEmits` + un `@apri-dossier="$emit('apri-dossier', $event)"`). `DossierPianta` props: `{ piantaId: String }`.
- **`FoglioLaterale`**: `v-model` è Boolean. In `AttivitaView` guidalo da uno stato "quale pianta" — `:model-value="!!dossierItem"` + `@update:model-value="v => { if (!v) dossierItem = null }"`. `:titolo` = nome specie dell'item. Il contenuto (`<DossierPianta>`) va sotto un `v-if="dossierItem"` così non dereferenzia null.
- **Nessuna regola nuova in `style="…"` inline.** Le `style`-string computed di `AttivitaRiga` (`cardStyle`, `iconStyle`, `labelStyle`) e i ternari inline della tab Progetti → classi (`main.css` se condivise, `<style scoped>` se locali) + `:class`. Micro-offset una-tantum (gap/margin/width per istanza) ammessi inline.
- **`calcio` = icona `uovo`** e tessera beige (`.care__ic--calcio`) ovunque — coerente con PiantaView post-merge.
- **Dark mode:** niente blocchi dark (Fase 3).
- **`prefers-reduced-motion`:** l'accordion sparisce (e con lui la sua gestione RM); `FoglioLaterale` ha già la sua. Non introdurre animazioni non protette.
- **Verifica:** `npm run build` exit 0. Poi `npm run dev` → `/attivita` (3 tab, gruppi per zona, tap riga → foglio con "Stato cure"/"Concimi"/"Esigenze"/"Note tecniche", "✓ Fatto" da riga e da foglio), `/piante/<id>` ("Stato cure" non regredito), `/piante/nuova` se Task 1 tocca SelettoreSpecie. Se il dev server non parte (OOM noto) dirlo, affidarsi a build + lettura.
- **Commit:** italiano, prefisso `allinea:`, con trailer:
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
  ```

---

### Task 1: `useCureVisual.js` — mappe condivise; globalizza `.care-act*` (+ `.feed-nb`)

**Files:**
- Create: `src/composables/useCureVisual.js`
- Modify: `src/assets/main.css`
- Modify: `src/views/PiantaView.vue`
- Modify: `src/components/SelettoreSpecie.vue`

**Interfaces:**
- Produce da `useCureVisual.js` (export nominati, costanti/funzioni pure — nessuna reattività):
  - `ICONE_CURA = { irrigazione:'goccia', concimazione:'concimazione', potatura:'potatura', calcio:'uovo' }`
  - `LABEL_CURA = { irrigazione:'Irrigazione', concimazione:'Concimazione', potatura:'Potatura', calcio:'Calcio' }`
  - `iconaCura(tipo)` → `ICONE_CURA[tipo] ?? 'foglia'`
  - `ICONE_ESIGENZA` = mappa esatta di `PiantaView.vue` (`sole/luce/esposizione→'sole'`, `terreno/suolo/substrato/ph→'foglia'`, `acqua/irrigazione/umidita/umidità→'goccia'`, `temperatura/clima→'caldo'`, `gelo→'gelo'`, `spazio/distanza→'pin'`, `potatura→'potatura'`, `concimazione→'concimazione'`)
  - `iconaEsigenza(chiave)` → `ICONE_ESIGENZA[String(chiave).toLowerCase()] ?? 'foglia'`
  - `capitalizza(s)` → `String(s).charAt(0).toUpperCase() + String(s).slice(1)`
- Produce in `main.css`: `.care-act`, `.care-act:disabled`, `.care-act--rose` (da PiantaView scoped, invariate); e `.feed-nb` **se** è scoped in PiantaView (verifica: `grep -n "feed-nb" src/views/PiantaView.vue src/assets/main.css` — se è solo in PiantaView scoped, spostala qui).

- [ ] **Step 1:** crea `useCureVisual.js` con gli export sopra (valori verbatim da `PiantaView.vue`, `ICONE_CURA.calcio` = `'uovo'`).
- [ ] **Step 2:** copia `.care-act` / `.care-act:disabled` / `.care-act--rose` (+ `.feed-nb` se serve) in coda a `main.css`, blocco commentato "condiviso (era scoped in PiantaView)".
- [ ] **Step 3:** `PiantaView.vue` — rimuovi le definizioni locali `ICONE_CURA`/`LABEL_CURA`/`iconaCura`/`ICONE_ESIGENZA`/`iconaEsigenza`/`capitalizza` e importale da `@/composables/useCureVisual`; rimuovi dal `<style scoped>` `.care-act*` (+ `.feed-nb` se spostata). `<template>` invariato.
- [ ] **Step 4:** `SelettoreSpecie.vue` — se `ICONA_ESIGENZA` locale + `capitalizza` combaciano con il composable, rimuovile e importa `iconaEsigenza`/`capitalizza`; aggiorna `esigenzeVoci` a `iconaEsigenza(chiave)`. Se diverge (chiave extra), **FERMATI e segnala**. Nient'altro.
- [ ] **Step 5:** `npm run build` → exit 0. Grep: nessuna definizione locale di quelle mappe in PiantaView/SelettoreSpecie (solo import); `.care-act` in `main.css`, non più nel `<style>` di PiantaView. Nessun blocco dark.
- [ ] **Step 6:** commit `allinea: useCureVisual.js (mappe icone/etichette cure+esigenze) + .care-act* globali`.

---

### Task 2: `DossierPianta.vue` — contenuto del foglio (classi condivise)

**Files:**
- Create: `src/components/DossierPianta.vue`

**Interfaces:**
- Props: `{ piantaId: { type: String, required: true } }`. Nessun emit (le registrazioni mutano lo store, reattivo).
- Consuma: `useDatiStore`, `usePianteApi` (`registraCura`), `valutaCura`/`stagione` (`useCure`), `classificaConcimiPerFabbisogno` (`useConcimi`), `useCureVisual` (`iconaCura`/`LABEL_CURA`/`iconaEsigenza`/`capitalizza`), `.slabel`/`.care*`/`.care-act*`/`.feedlist`/`.feed*`/`.prose`/`.feed-nb`/`.kv`/`.notelist` (globali), `<Icon>`, `<Spinner>`, `<RouterLink>`.
- Consumato da: `AttivitaView.vue` (Task 4), dentro il `<FoglioLaterale>`.

- [ ] **Step 1: `<script setup>`**

```js
import { ref, computed } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { usePianteApi } from '@/composables/usePianteApi'
import { valutaCura, stagione } from '@/composables/useCure'
import { classificaConcimiPerFabbisogno } from '@/composables/useConcimi'
import { iconaCura, LABEL_CURA, iconaEsigenza, capitalizza } from '@/composables/useCureVisual'
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const props = defineProps({ piantaId: { type: String, required: true } })
const store = useDatiStore()
const pianteApi = usePianteApi()

const pianta = computed(() => store.piante?.[props.piantaId] ?? null)
const specie = computed(() => pianta.value ? (store.specie?.[pianta.value.specie] ?? null) : null)
const nomeSpecie = computed(() => specie.value?.nome ?? pianta.value?.specie ?? '')

const tipiCura = computed(() => {
  const base = ['irrigazione', 'concimazione']
  if (specie.value?.manutenzione?.calcio) base.push('calcio')
  return base
})
const contestoCura = computed(() => ({
  esterno: store.zone?.[pianta.value?.zona]?.tipo === 'esterno',
  meteo: store.meteo,
}))
const fabbisognoNpk = computed(() => specie.value?.manutenzione?.npk?.[stagione()] ?? null)
const classificaConcimiPianta = computed(() =>
  fabbisognoNpk.value ? classificaConcimiPerFabbisogno(fabbisognoNpk.value, store.concimi).slice(0, 3) : []
)

const salvandoTipo = ref(null)
async function registraCuraTipo(tipo) {
  if (!pianta.value || salvandoTipo.value) return
  salvandoTipo.value = tipo
  try { await pianteApi.registraCura(props.piantaId, tipo) }
  finally { salvandoTipo.value = null }
}
</script>
```
(Tutte queste erano dentro `AttivitaRiga.vue`; qui sono spostate senza cambi di logica.)

- [ ] **Step 2: `<template>`** — sezioni con le classi di PiantaView, verbatim dai blocchi reali:

```html
<div class="dossier-pianta">
  <p class="dossier-pianta__zona">
    <Icon :name="store.iconaZona(pianta.zona)" /> {{ pianta.zona }}<span v-if="pianta.sottozona"> · {{ pianta.sottozona }}</span>
    <span v-if="pianta.varieta"> — {{ pianta.varieta }}</span>
  </p>

  <div class="slabel">Stato cure</div>
  <div class="care">
    <div v-for="tipo in tipiCura" :key="tipo" class="care__row">
      <span class="care__ic" :class="`care__ic--${tipo}`"><Icon :name="iconaCura(tipo)" /></span>
      <span class="care__m">
        <span class="care__n">{{ LABEL_CURA[tipo] ?? tipo }}</span>
        <span class="care__d">{{ valutaCura(pianta, specie, tipo, contestoCura).label ?? 'Non configurata' }}</span>
      </span>
      <button class="care-act" type="button" @click="registraCuraTipo(tipo)" :disabled="salvandoTipo === tipo">
        <Spinner v-if="salvandoTipo === tipo" /><span v-else>Fatto</span>
      </button>
    </div>
  </div>

  <template v-if="fabbisognoNpk && classificaConcimiPianta.length">
    <div class="slabel">Concimi consigliati</div>
    <p class="prose feed-nb">Fabbisogno attuale: {{ fabbisognoNpk }}</p>
    <div class="feedlist">
      <div v-for="(c, i) in classificaConcimiPianta" :key="c.id" class="feed">
        <span class="feed__rank" :class="{ 'feed__rank--dim': i > 0 }">{{ i + 1 }}</span>
        <div class="feed__m"><div class="feed__n">{{ c.nome }}<span v-if="c.disponibile === false" class="feed__tag">terminato</span></div></div>
        <span class="feed__npk">{{ c.npk.n }}-{{ c.npk.p }}-{{ c.npk.k }}</span>
      </div>
    </div>
  </template>

  <template v-if="specie?.esigenze && Object.keys(specie.esigenze).length">
    <div class="slabel">Esigenze</div>
    <div class="kv">
      <div v-for="(val, chiave) in specie.esigenze" :key="chiave">
        <span class="k"><Icon :name="iconaEsigenza(chiave)" />{{ capitalizza(chiave) }}</span><span class="v">{{ val }}</span>
      </div>
    </div>
  </template>

  <template v-if="specie?.alert?.length">
    <div class="slabel">Note tecniche</div>
    <ul class="notelist"><li v-for="a in specie.alert" :key="a">{{ a }}</li></ul>
  </template>

  <template v-if="pianta.note">
    <div class="slabel">Note</div>
    <p class="prose">{{ pianta.note }}</p>
  </template>

  <RouterLink :to="`/piante/${piantaId}`" class="dossier-pianta__link">Apri la scheda completa →</RouterLink>
</div>
```
`<style scoped>`: `.dossier-pianta { padding: 4px 16px 24px; }` (dentro `.foglio__body` che ha già lo scroll); `.dossier-pianta__zona { display:flex; align-items:center; gap:6px; font:400 12px/1.4 var(--font-sans); color:var(--ink-soft); margin:0 0 6px; }` + `.dossier-pianta__zona svg { width:14px; height:14px; flex:none; }`; `.dossier-pianta .slabel:first-of-type { margin-top: 4px; }` (la prima "Stato cure" non deve avere i 22px pieni sopra); `.dossier-pianta__link { display:inline-block; margin-top:18px; font:600 12px/1 var(--font-sans); color:var(--sage-dark); text-decoration:none; }`.

- [ ] **Step 3:** `npm run build` → exit 0 (il componente non è ancora usato — verifica solo che compili; `DossierPianta` referenzia `props.piantaId` sempre valorizzato dal genitore sotto `v-if`).
- [ ] **Step 4:** self-review — nessun `<Icon name>` inventato; `.care-act`/`.feed-nb` sono globali (Task 1); `v-for` keyed.
- [ ] **Step 5:** commit `allinea: DossierPianta.vue — scheda pianta (stato cure/concimi/esigenze/note) per il foglio`.

---

### Task 3: `AttivitaRiga.vue` — via l'accordion, tap → `apri-dossier`

**Files:**
- Modify: `src/components/AttivitaRiga.vue`

**Interfaces:**
- Consuma: `useCureVisual` (`iconaCura`), `.care__ic--${tipo}` (globale, per la tessera testata), `<Icon>`, `<Spinner>`.
- Produce: riga piatta (niente accordion/chevron); `@click` sul corpo → `emit('apri-dossier', item)`; bottone "✓ Fatto" invariato (`@click.stop` → `emit('registra', item)`).

- [ ] **Step 1: `<script setup>` — dimagrisce**

- Rimuovi: `espansa` ref; `ICONE_CURA`, `TINTE_CURA`, `function icona`; `pianta`, `specie`, `tipiCura`, `contestoCura`, `fabbisognoNpk`, `classificaConcimiPianta`, `salvandoTipo`, `registraCuraTipo` (tutto migrato in `DossierPianta`); `cardStyle`, `iconStyle`, `labelStyle` (→ classi scoped, Step 3); gli import ora inutili (`usePianteApi`, `valutaCura`, `stagione`, `classificaConcimiPerFabbisogno`, `RouterLink`, `useDatiStore` se non più usato).
- Aggiungi: `import { iconaCura } from '@/composables/useCureVisual'`.
- `defineEmits(['registra'])` → `defineEmits(['registra', 'apri-dossier'])`.
- Il `item.suggerimento` (mostrato in testata) resta un dato del prop `item`, nessun computed serve.

- [ ] **Step 2: `<template>` — solo la testata, cliccabile**

```html
<div class="attivita-riga" :class="{ 'attivita-riga--urgente': variante === 'urgente' }"
  @click="$emit('apri-dossier', item)">
  <span class="care__ic" :class="`care__ic--${item.tipo}`"><Icon :name="iconaCura(item.tipo)" /></span>
  <div class="attivita-riga__m">
    <div class="attivita-riga__nome">{{ item.nomeSpecie }}</div>
    <div class="attivita-riga__label" :class="{ 'attivita-riga__label--urgente': variante === 'urgente' }">{{ item.label }}</div>
    <div v-if="item.tipo === 'concimazione' && item.suggerimento" class="attivita-riga__sugg">
      <Icon name="concimazione" /> Consigliato: {{ item.suggerimento.nome }} ({{ item.suggerimento.npk.n }}-{{ item.suggerimento.npk.p }}-{{ item.suggerimento.npk.k }})
      <Icon v-if="item.suggerimento.disponibile === false" name="allerta" class="attivita-riga__sugg-warn" aria-label="Terminato" />
    </div>
  </div>
  <button @click.stop="$emit('registra', item)" :disabled="disabled"
    :class="['btn', variante === 'urgente' ? 'btn-rose' : 'btn-ghost']"
    style="font-size:11px;padding:5px 10px;min-height:30px;flex-shrink:0;">
    <Spinner v-if="disabled" /><span v-else>✓ Fatto</span>
  </button>
</div>
```
(Niente più `.attivita-riga-testata` / chevron / `.attivita-riga-dettagli-wrap`. Il click sul corpo apre il foglio; `@click.stop` sul bottone tiene separata l'azione rapida.)

- [ ] **Step 3: `<style scoped>` — riscritto**

```css
.attivita-riga { display:flex; align-items:center; gap:12px; padding:12px 2px; cursor:pointer; }
.attivita-riga + .attivita-riga { border-top:1px solid var(--cream-dark); }
.attivita-riga--urgente { padding:12px; background:var(--rose-pale); border-radius:10px; }
.attivita-riga .care__ic { width:40px; height:40px; }   /* la classe globale è 34px */
.attivita-riga__m { flex:1; min-width:0; }
.attivita-riga__nome { font:600 13px/1.25 var(--font-display); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.attivita-riga__label { font:400 11px/1.4 var(--font-sans); color:var(--ink-mid); margin-top:2px; }
.attivita-riga__label--urgente { color:var(--rose-dark); }
.attivita-riga__sugg { display:flex; align-items:center; gap:4px; font:400 11px/1.4 var(--font-sans); color:var(--sage-dark); margin-top:2px; }
.attivita-riga__sugg svg { width:12px; height:12px; flex:none; }
.attivita-riga__sugg-warn { color:var(--rose); }
```
Rimuovi tutte le vecchie regole `.attivita-riga-testata` / `-chevron` / `-dettagli*` e il blocco `@media (prefers-reduced-motion)` associato all'accordion (non c'è più nulla da proteggere qui).

- [ ] **Step 4:** `npm run build` → exit 0.
- [ ] **Step 5:** self-review — `grep -n "espansa\|TINTE_CURA\|cardStyle\|iconStyle\|labelStyle\|attivita-riga-dettagli\|grid-template-rows" src/components/AttivitaRiga.vue` → niente; `defineEmits` = `['registra','apri-dossier']`; `disabled`/`variante`/`item` props intatti; nessun import inutilizzato.
- [ ] **Step 6:** commit `allinea: AttivitaRiga — via l'accordion, tap sulla riga apre il dossier nel foglio`.

---

### Task 4: `AttivitaView.vue` + `AttivitaGruppoZona.vue` — foglio unico + righe tab Progetti

**Files:**
- Modify: `src/components/AttivitaGruppoZona.vue`
- Modify: `src/views/AttivitaView.vue`

- [ ] **Step 1: `AttivitaGruppoZona.vue` — inoltra `apri-dossier`**

- `defineEmits(['registra', 'registraGruppo'])` → aggiungi `'apri-dossier'`.
- Sul `<AttivitaRiga>`: aggiungi `@apri-dossier="$emit('apri-dossier', $event)"`.
- Nient'altro.

- [ ] **Step 2: `AttivitaView.vue` — il `<FoglioLaterale>` unico**

- `<script setup>`: `import FoglioLaterale from '@/components/FoglioLaterale.vue'` + `import DossierPianta from '@/components/DossierPianta.vue'`. `const dossierItem = ref(null)`. `function apriDossier(item) { dossierItem.value = item }`.
- Passa `@apri-dossier="apriDossier"` a **ogni** `<AttivitaGruppoZona>` (i due `v-for`, "Da fare" e "In scadenza").
- In fondo al `<template>` (dentro il `<div>` radice, fuori dal `<Transition>`):
  ```html
  <FoglioLaterale
    :model-value="!!dossierItem"
    @update:model-value="v => { if (!v) dossierItem = null }"
    :titolo="dossierItem?.nomeSpecie ?? ''"
  >
    <DossierPianta v-if="dossierItem" :pianta-id="dossierItem.piantaId" />
  </FoglioLaterale>
  ```
- `registra` / `registraGruppo` / `registraTappa` / gli `import` esistenti / i `computed` — invariati.

- [ ] **Step 3: `AttivitaView.vue` — righe tab "Progetti"**

Sostituisci il blocco `<template v-else-if="tappeProgetto.length">` (righe ~82-102) — le `<div v-for … class="card" :style="ternario">` — con:
```html
<template v-else-if="tappeProgetto.length">
  <div class="tappa-lista">
    <div v-for="t in tappeProgetto" :key="`${t.progettoId}-${t.indice}`"
      class="tappa-riga" :class="{ 'tappa-riga--urgente': t.urgente }">
      <span class="tappa-riga__ic" :class="{ 'tappa-riga__ic--urgente': t.urgente }"><Icon name="lampadina" /></span>
      <div class="tappa-riga__m">
        <RouterLink :to="`/progetti/${t.progettoId}`" class="tappa-riga__t">{{ t.progettoTitolo }}</RouterLink>
        <div class="tappa-riga__d" :class="{ 'tappa-riga__d--urgente': t.urgente }">
          {{ t.tappa.descrizione }} — {{ t.urgente ? `scaduta ${Math.abs(t.giorni)} gg fa` : `tra ${t.giorni} gg` }}
        </div>
      </div>
      <button @click="registraTappa(t)" :disabled="salvandoTappa === `${t.progettoId}-${t.indice}`"
        :class="['btn', t.urgente ? 'btn-rose' : 'btn-ghost']" style="font-size:11px;padding:5px 10px;min-height:30px;flex-shrink:0;">
        <Spinner v-if="salvandoTappa === `${t.progettoId}-${t.indice}`" /><span v-else>✓ Fatto</span>
      </button>
    </div>
  </div>
</template>
```
`<style scoped>` (aggiunge a quello esistente):
```css
.tappa-lista { display:flex; flex-direction:column; margin-bottom:24px; }
.tappa-riga { display:flex; align-items:center; gap:12px; padding:12px 2px; }
.tappa-riga + .tappa-riga { border-top:1px solid var(--cream-dark); }
.tappa-riga--urgente { padding:12px; background:var(--rose-pale); border-radius:10px; }
.tappa-riga__ic { flex:none; width:40px; height:40px; border-radius:12px; display:flex; align-items:center; justify-content:center;
  background:var(--gold-bg); color:var(--gold-ink); }
.tappa-riga__ic--urgente { background:var(--rose-bg); color:var(--rose-ink); }
.tappa-riga__ic svg { width:18px; height:18px; }
.tappa-riga__m { flex:1; min-width:0; }
.tappa-riga__t { display:block; font:600 13px/1.25 var(--font-display); color:var(--ink); text-decoration:none;
  white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.tappa-riga__d { font:400 11px/1.4 var(--font-sans); color:var(--ink-soft); margin-top:2px; }
.tappa-riga__d--urgente { color:var(--rose-dark); }
```

- [ ] **Step 4: `AttivitaView.vue` — `.slabel` "Da fare" / "In scadenza"**

`<p class="slabel" style="display:flex;align-items:center;gap:6px;"><Icon …/>Da fare</p>` → `<div class="slabel"><Icon name="campanella" style="width:12px;height:12px;flex-shrink:0;" />Da fare</div>` (togli `display:flex` inline — `.slabel` è già flex). Idem per "In scadenza (entro 3 giorni)". Skeleton (`.card`): **lascialo** (coerente con gli altri skeleton dell'app).

- [ ] **Step 5:** `npm run build` → exit 0, poi `npm run dev` → `/attivita`.
Expected: tab Irrigazione/Concimi — tap su una riga apre il **foglio** (da destra su desktop, dal basso su mobile) con "Stato cure"/"Concimi"/"Esigenze"/"Note tecniche" della pianta; "✓ Fatto" sulla riga registra al volo (senza aprire il foglio); il "Fatto" dentro il foglio registra la singola cura; Esc/velo/× chiudono. Tab Progetti — righe con filetto (icona lampadina in tessera oro/rosa), titolo Fraunces linkato, "✓ Fatto" funziona; niente card. `.slabel` senza `style` inline ridondante.
- [ ] **Step 6:** commit `allinea: AttivitaView — foglio unico per il dossier pianta + righe tab Progetti con filetto`.

---

### Task 5: Verifica integrale + nota di esito

- [ ] **Step 1: Build + grep**

```bash
npm run build   # exit 0
grep -rn "TINTE_CURA\|-tile)\|cardStyle\|iconStyle\|labelStyle\|attivita-riga-dettagli\|espansa" src/components/AttivitaRiga.vue   # → niente
grep -rn "ICONE_CURA\s*=\|ICONE_ESIGENZA\s*=\|function capitalizza" src/views/PiantaView.vue src/components/AttivitaRiga.vue src/components/DossierPianta.vue src/components/SelettoreSpecie.vue   # → niente (solo import)
grep -n 'class="card"' src/views/AttivitaView.vue   # → solo lo skeleton
```

- [ ] **Step 2: Giro in `npm run dev`**

`/attivita` (3 tab; gruppi per zona; tap riga → foglio; "✓ Fatto" da riga e da foglio; tab Progetti), `/piante/<id>` ("Stato cure" invariato — icona uovo calcio, `.care-act`), `/piante/nuova` (SelettoreSpecie — Esigenze con icone se Task 1 l'ha toccato). Nessun errore console; registrazioni cure singole/bulk e tappe funzionanti; un solo `<FoglioLaterale>` nel DOM (non uno per riga).

- [ ] **Step 3: Nota di esito**

`docs/superpowers/plans/2026-09-03-attivita-allineamento-scheda-pianta-esito.md`: cosa è fatto; `DossierPianta.vue` riusabile (candidato anche per un futuro "apri pianta al volo" da altre viste); scostamenti; minori (skeleton `.card`; urgent-row `rose-pale`+radius tenuto come cue — filetto puro è 1 riga se Rob lo preferisce); il rollout di `FoglioLaterale` alle modali centrali (ProgettiView/ConcimiView/SottozoneView/EditPianta/ModalConferma/dettaglio Meteo) resta un batch a parte.

- [ ] **Step 4:** commit finale `allinea: chiusura Attività ↔ scheda pianta — nota di esito`.

---

## Self-Review

**Spec coverage:**
- Duplicazione mappe icone/etichette (PiantaView + AttivitaRiga + SelettoreSpecie) → Task 1 (`useCureVisual.js`) ✓
- `.care-act*` solo scoped in PiantaView → Task 1 (globale) ✓
- AttivitaRiga re-implementa la scheda pianta a mano → Task 2 (`DossierPianta.vue` con `.care*`/`.feed*`/`.kv`/`.notelist`) + Task 3 (accordion rimosso) ✓
- Rob: "tap-riga apre la vera scheda pianta nel `FoglioLaterale`" (fuori scope approvato) → Task 3 (emit `apri-dossier`) + Task 4 (foglio unico in AttivitaView) ✓
- "Esigenze" senza icone / manca "Note tecniche" → Task 2 (icone + `.notelist`) ✓
- `style`-string computed di AttivitaRiga → Task 3 (classi scoped + `:class`) ✓
- Tab Progetti = `.card` + ternari inline → Task 4 (`.tappa-riga` con filetto) ✓
- `.slabel` con `display:flex` inline ridondante → Task 4 Step 4 ✓
- Nessun cambio a dati/API/logica cure/tab/registrazioni → Global Constraints ✓
- Rollout `FoglioLaterale` alle modali centrali → fuori scope, nota di esito Task 5

**Placeholder scan:** ogni task dà il markup di sostituzione verbatim (dai blocchi reali di PiantaView), i simboli esatti da rimuovere/migrare, le classi scoped nuove con le regole complete, gli export del composable con i valori, e le eccezioni (`.feed-nb` da globalizzare se scoped; SelettoreSpecie `ICONA_ESIGENZA` — fermati se diverge; skeleton `.card` lasciato apposta; `FoglioLaterale` `v-model` Boolean guidato da `!!dossierItem`). Nessun "gestisci i casi limite" generico. Logica (`valutaCura`, `tipiCura`, `classificaConcimiPianta`, tab, registrazioni) esplicitamente non-toccata, solo spostata in `DossierPianta`.

**Type/naming consistency:** `useCureVisual` export (`ICONE_CURA`/`LABEL_CURA`/`iconaCura`/`ICONE_ESIGENZA`/`iconaEsigenza`/`capitalizza`) coerenti Task 1↔2↔3↔(PiantaView/SelettoreSpecie). `apri-dossier` coerente: emesso da `AttivitaRiga` (Task 3), inoltrato da `AttivitaGruppoZona` (Task 4 Step 1), gestito da `AttivitaView.apriDossier` (Task 4 Step 2). `dossierItem` (ref, `{ nomeSpecie, piantaId, … }` = un `item` di `attivita`) coerente Task 4. `DossierPianta` prop `piantaId` coerente Task 2↔4. `.tappa-riga*` (scoped AttivitaView) e `.attivita-riga--urgente`/`.attivita-riga__*` (scoped AttivitaRiga) nuove, coerenti nei rispettivi task. `.care__ic--${tipo}` (globale) usata da DossierPianta e dalla testata di AttivitaRiga con lo stesso significato.
