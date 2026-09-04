# Zone edit nel foglio + × sulla hero del selettore specie — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Uniformare la modifica delle zone a quella delle sottozone (form in `FoglioLaterale` dentro `ZoneView`, non più pagina piena `EditZonaView`), e spostare la × di chiusura del foglio-dossier del selettore specie sopra la foto hero invece che nella barra sopra la foto.

**Architecture:** Due modifiche indipendenti. (1) `FoglioLaterale.vue` guadagna una prop booleana `senzaIntestazione` che sopprime l'intera barra header (titolo + ×); `SelettoreSpecie.vue` la usa e disegna una propria × in `position:absolute` dentro `.dossier`. (2) La logica insert/update/rename di `EditZonaView.vue` viene portata dentro `ZoneView.vue` sullo stesso schema di `SottozoneView.vue` (stato `mostraForm`/`modificaOriginale`, `apriNuovo`/`apriModifica`/`chiudiForm`/`salva`, scrittura diretta su Supabase, `store.aggiorna()` sul rename); `EditZonaView.vue` e le sue due route spariscono, insieme alla classe CSS `.zona-edit-wide` che serviva solo a quella pagina.

**Tech Stack:** Vue 3 `<script setup>` SFC, Vite, vue-router (`createWebHashHistory`), Supabase JS client, Pinia (`useDatiStore`). CSS custom properties in `src/assets/main.css`. Nessun runner di test.

**Spec:** nessuna spec formale — round bounded discusso e approvato in chat il 2026-09-04. Contesto: `docs/superpowers/plans/2026-09-03-foglio-laterale-rollout-esito.md` (rollout appena fatto a Progetti/Concimi/Sottozone; `ModalConferma` lasciato dialog centrato). `SottozoneView.vue` è il modello di riferimento per il Task 2.

## Global Constraints

- **Lingua:** testi UI, commenti e messaggi di commit in **italiano**.
- **Zorba** sempre nero `#141414` — non toccato qui, non introdurre regole che lo schiariscano.
- **Niente blocchi dark-mode** (`@media (prefers-color-scheme: dark)`, `:root[data-theme]`) — è Fase 3.
- **Verifica automatica = solo `npm run build` (exit 0).** Non esiste `npm test`. Nessun test da scrivere o cercare.
- **Palette invariata:** `--rose` · `--gold` · `--sage` · `--olive` · `--cream` e derivati. Font `--font-display` / `--font-sans`.
- **`FoglioLaterale` è condiviso da 5 viste** (SelettoreSpecie, AttivitaView, ProgettiView, ConcimiView, SottozoneView): la nuova prop deve essere puramente additiva, `default: false`, e non cambiare nulla per chi non la passa.
- **Il contratto `v-model` di `SelettoreSpecie` resta invariato** (`modelValue: String`, un solo `emit('update:modelValue', …)`): `EditPiantaView` e `AgenteView` non vanno toccati.
- **Commit:** messaggi in italiano, ognuno chiude con:
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
  ```
- **Branch:** `zone-nel-foglio` da `main`. Nessun commit diretto su `main`. Merge solo su ok esplicito di Rob.

---

## File Structure

| File | Modifica |
|------|----------|
| `src/components/FoglioLaterale.vue` | **Modifica** — nuova prop `senzaIntestazione: { type: Boolean, default: false }`; `v-if="!senzaIntestazione"` sul `<div class="foglio__hd">`. Nient'altro cambia (Esc, focus, `:inert`, scroll-lock, `.foglio__grab` restano). |
| `src/components/SelettoreSpecie.vue` | **Modifica** — `<FoglioLaterale v-model="dossierAperto" senza-intestazione>`; rimozione dello slot `#intestazione`; nuova `<button class="dossier-x">` in cima a `.dossier`; regola scoped `.dossier-x`. |
| `src/views/ZoneView.vue` | **Modifica** — import `MiniEditor`/`Spinner`/`FoglioLaterale`/`ICONE_ZONA`; stato `mostraForm`/`salvando`/`errore`/`modificaOriginale`/`form` + `apriNuovo`/`apriModifica`/`chiudiForm`/`salva`; "＋ Aggiungi" e la matita da `<RouterLink>` a `<button>`; blocco `<FoglioLaterale>` nuovo/modifica zona; rimozione della regola scoped morta `a.pill`. |
| `src/views/EditZonaView.vue` | **Elimina** — sostituita dal foglio in `ZoneView`. |
| `src/router/index.js` | **Modifica** — rimozione delle route `zona-nuova` (`/zone/nuova`) e `zona-modifica` (`/zone/:zona/modifica`). |
| `src/assets/main.css` | **Modifica** — rimozione del blocco `.zona-edit-wide` (commento incluso, righe ~168-177); aggiornamento del riferimento "EditZonaView" nel commento del selettore icona (riga ~156) → "ZoneView". |
| `src/composables/useIconeZona.js` | **Modifica** — commento riga 1: "EditZonaView, SottozoneView" → "ZoneView, SottozoneView". |
| `src/components/IconDefs.vue` | **Modifica** — commento riga ~219: "EditZonaView/SottozoneView" → "ZoneView/SottozoneView". |

Nessun file di test.

---

### Task 1: `FoglioLaterale` `senzaIntestazione` + × sulla hero in SelettoreSpecie

**Files:**
- Modify: `src/components/FoglioLaterale.vue`
- Modify: `src/components/SelettoreSpecie.vue`

**Interfaces:**
- Produce: prop `senzaIntestazione: Boolean` su `FoglioLaterale` (additiva, `default: false`). Nessun consumatore esistente la passa, quindi nessun altro file cambia.
- Consuma: nulla di nuovo.

- [ ] **Step 1: `FoglioLaterale` — prop**

In `src/components/FoglioLaterale.vue`, nel `defineProps`, aggiungere la terza prop:

```js
const props = defineProps({
  modelValue: { type: Boolean, default: false },
  titolo: { type: String, default: '' },
  senzaIntestazione: { type: Boolean, default: false },
})
```

- [ ] **Step 2: `FoglioLaterale` — nascondere la barra header**

Nel `<template>`, aggiungere `v-if="!senzaIntestazione"` al `<div class="foglio__hd">`:

```html
      <div v-if="!senzaIntestazione" class="foglio__hd">
        <slot name="intestazione"><h3 v-if="titolo">{{ titolo }}</h3><span v-else></span></slot>
        <button type="button" class="foglio__x" aria-label="Chiudi" @click="chiudi">×</button>
      </div>
```

Non toccare `.foglio__grab`, `.foglio__body`, lo script, o le classi.

- [ ] **Step 3: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 4: `SelettoreSpecie` — passare la prop e togliere lo slot**

In `src/components/SelettoreSpecie.vue`, sostituire:

```html
    <FoglioLaterale v-model="dossierAperto">
      <template #intestazione><span></span></template>
      <template v-if="specieSelezionata">
```

con:

```html
    <FoglioLaterale v-model="dossierAperto" senza-intestazione>
      <template v-if="specieSelezionata">
```

- [ ] **Step 5: `SelettoreSpecie` — × sopra la hero**

Sempre nel `<template>`, subito dopo `<div class="dossier">` (prima di `<div class="specie-ghost" …>`), inserire:

```html
      <div class="dossier">
        <button type="button" class="dossier-x" aria-label="Chiudi" @click="dossierAperto = false">×</button>
        <div class="specie-ghost" aria-hidden="true">
```

(cioè: aggiungere solo la riga `<button …>`, lasciando invariato tutto il resto del blocco).

- [ ] **Step 6: `SelettoreSpecie` — stile della ×**

Nel `<style scoped>`, subito dopo la regola `.dossier { … }` (che ha già `position: relative; overflow: hidden; isolation: isolate;`), aggiungere:

```css
/* Chiusura del foglio-dossier: sovrapposta in alto a destra sulla hero
   (foto .dh o intestazione senza foto .dh-np), non in una barra sopra. */
.dossier-x {
  position: absolute;
  top: 12px; right: 12px;
  z-index: 5;
  width: 30px; height: 30px;
  border: 0;
  border-radius: 50%;
  background: rgba(0,0,0,.34);
  color: #fdf8ee;
  font-size: 17px;
  line-height: 1;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}
```

(z-index 5 sta sopra `.dh-scrim`/`.dh-chip`/`.dh-cap`/`.dh-credit` che sono a z-index 3.)

- [ ] **Step 7: Build + verifica**

Run: `npm run build`
Expected: exit 0, nessun warning nuovo.

Verifica di lettura:
- `grep -n "senza-intestazione\|#intestazione" src/components/SelettoreSpecie.vue` → deve comparire `senza-intestazione`, non più `#intestazione`.
- `grep -n "dossier-x" src/components/SelettoreSpecie.vue` → una riga nel template, una nel `<style>`.
- `defineEmits(['update:modelValue'])` e l'unico `emit('update:modelValue', s.key)` in `selezionaSpecie` intatti.
- In `FoglioLaterale.vue`, `grep -n "senzaIntestazione"` → una nel `defineProps`, una nel `v-if` del template.

- [ ] **Step 8: Commit**

```bash
git add src/components/FoglioLaterale.vue src/components/SelettoreSpecie.vue
git commit -m "$(cat <<'EOF'
FoglioLaterale: prop senzaIntestazione + × sulla hero nel selettore specie

FoglioLaterale accetta `senzaIntestazione` per non renderizzare la barra
header (titolo + ×); Esc/focus/inert/scroll-lock restano. SelettoreSpecie
la usa e disegna la propria × in absolute sopra la foto hero (o
l'intestazione senza foto), invece che in una barra prima della foto.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
EOF
)"
```

---

### Task 2: Zone edit → FoglioLaterale in ZoneView; ritiro EditZonaView

**Files:**
- Modify: `src/views/ZoneView.vue`
- Delete: `src/views/EditZonaView.vue`
- Modify: `src/router/index.js`
- Modify: `src/assets/main.css`
- Modify: `src/composables/useIconeZona.js`
- Modify: `src/components/IconDefs.vue`

**Interfaces:**
- Consuma: `FoglioLaterale.vue` (esistente); `.foglio-form`/`.foglio-actions` (classi globali già in `main.css`); `ICONE_ZONA` da `@/composables/useIconeZona`; `store.aggiorna()` (già usato da `SottozoneView`/`EditZonaView`).
- Modello: `src/views/SottozoneView.vue` (stessa forma di stato e di `<FoglioLaterale>`; leggilo prima di iniziare). Logica di salvataggio: portata da `src/views/EditZonaView.vue` (che stai eliminando).
- Produce: nulla per task successivi.

- [ ] **Step 1: ZoneView — import**

In `src/views/ZoneView.vue`, nel blocco `<script setup>`, aggiungere agli import esistenti:

```js
import { ICONE_ZONA } from '@/composables/useIconeZona'
import MiniEditor from '@/components/MiniEditor.vue'
import Spinner from '@/components/Spinner.vue'
import FoglioLaterale from '@/components/FoglioLaterale.vue'
```

- [ ] **Step 2: ZoneView — stato e funzioni del form**

Nel `<script setup>`, dopo le dichiarazioni esistenti (`daEliminare`/`eliminando`/`erroreEliminazione`) e prima di `eliminaZona`, aggiungere:

```js
const mostraForm = ref(false)
const salvando   = ref(false)
const errore     = ref(null)
// Nome originale della zona in modifica (null quando se ne crea una nuova):
// store.zone è indicizzato per nome, serve per sapere quale chiave
// aggiornare/rinominare.
const modificaOriginale = ref(null)
const form = ref({ nome: '', tipo: 'esterno', descrizione: '', microclima: '', esposizione: [], icona: null })

function formVuoto() {
  return { nome: '', tipo: 'esterno', descrizione: '', microclima: '', esposizione: [], icona: null }
}

function apriNuovo() {
  modificaOriginale.value = null
  form.value = formVuoto()
  errore.value = null
  mostraForm.value = true
}

function apriModifica(z) {
  modificaOriginale.value = z.key
  form.value = {
    nome:        z.nome ?? z.key,
    tipo:        z.tipo ?? 'esterno',
    descrizione: z.descrizione ?? '',
    microclima:  z.microclima ?? '',
    esposizione: z.esposizione ? [...z.esposizione] : [],
    icona:       z.icona ?? null,
  }
  errore.value = null
  mostraForm.value = true
}

function chiudiForm() {
  mostraForm.value = false
  modificaOriginale.value = null
  form.value = formVuoto()
  errore.value = null
}

async function salva() {
  if (!form.value.nome.trim() || salvando.value) return
  const nomeOriginale = modificaOriginale.value
  const nomeNuovo = form.value.nome.trim()

  // Non sovrascrivere silenziosamente un'altra zona già esistente con lo
  // stesso nome (perderebbe criticita/manutenzione non gestiti da questo form).
  if (store.zone?.[nomeNuovo] && nomeNuovo !== nomeOriginale) {
    errore.value = 'Una zona con questo nome esiste già.'
    return
  }
  errore.value = null

  salvando.value = true
  try {
    const idOriginale = nomeOriginale ? (store.zone?.[nomeOriginale]?.id ?? null) : null
    const riga = {
      nome:        nomeNuovo,
      tipo:        form.value.tipo,
      descrizione: form.value.descrizione.trim() || '',
      microclima:  form.value.microclima.trim()  || '',
      esposizione: form.value.esposizione,
      icona:       form.value.icona,
    }

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

    const rinominata = nomeOriginale && nomeOriginale !== salvata.nome
    const nuoveZone = { ...store.zone }
    if (rinominata) delete nuoveZone[nomeOriginale]
    nuoveZone[salvata.nome] = {
      id: salvata.id, nome: salvata.nome, descrizione: salvata.descrizione,
      esposizione: salvata.esposizione, microclima: salvata.microclima,
      criticita: salvata.criticita, manutenzione: salvata.manutenzione, tipo: salvata.tipo,
      icona: salvata.icona,
    }
    store.zone = nuoveZone

    // Un rename lascia store.sottozone (indicizzato per nome zona) e
    // store.piante[*].zona sotto il vecchio nome: ricaricare tutto da
    // Supabase è più sicuro che rincollare a mano ogni chiave derivata.
    if (rinominata) await store.aggiorna()

    chiudiForm()
  } catch (e) {
    errore.value = e.message || 'Errore durante il salvataggio della zona.'
  } finally {
    salvando.value = false
  }
}
```

- [ ] **Step 3: ZoneView — pulsanti al posto dei link**

Nel `<template>`:

3a. Sostituire (riga ~5):
```html
      <RouterLink to="/zone/nuova" class="pill">＋ Aggiungi</RouterLink>
```
con:
```html
      <button type="button" @click="apriNuovo" class="pill">＋ Aggiungi</button>
```

3b. Sostituire (righe ~37-39):
```html
          <RouterLink :to="`/zone/${z.key}/modifica`" class="pill-mini" title="Modifica zona" aria-label="Modifica zona">
            <Icon name="matita" />
          </RouterLink>
```
con:
```html
          <button type="button" @click="apriModifica(z)" class="pill-mini" title="Modifica zona" aria-label="Modifica zona">
            <Icon name="matita" />
          </button>
```

- [ ] **Step 4: ZoneView — il foglio nuovo/modifica**

Nel `<template>`, come fratello di `<ModalConferma …>` (subito prima di esso), inserire:

```html
    <!-- Foglio nuova/modifica zona -->
    <FoglioLaterale
      :model-value="mostraForm"
      @update:model-value="v => { if (!v) chiudiForm() }"
      :titolo="modificaOriginale ? 'Modifica zona' : 'Nuova zona'"
    >
      <div v-if="mostraForm" class="foglio-form">
        <input v-model="form.nome" placeholder="Nome *" class="form-input" style="margin-bottom:10px;">
        <p v-if="errore" style="font-size:11px;color:var(--rose-dark);margin:0 0 10px;">{{ errore }}</p>
        <select v-model="form.tipo" class="form-input" style="margin-bottom:12px;">
          <option value="esterno">Esterno</option>
          <option value="interno">Interno</option>
        </select>
        <label class="field-label">Descrizione</label>
        <MiniEditor v-model="form.descrizione" placeholder="Descrizione breve della zona…" />
        <label class="field-label" style="margin-top:12px">Microclima</label>
        <MiniEditor v-model="form.microclima" placeholder="Caratteristiche di luce, temperatura, umidità…" />
        <label class="field-label" style="margin-top:12px">Icona</label>
        <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(30px,1fr));gap:0;max-height:140px;overflow-y:auto;padding:6px;border:1px solid var(--cream-dark);border-radius:10px;margin-top:6px;">
          <button type="button" v-for="nome in ICONE_ZONA" :key="nome" class="pill pill-icona"
            :class="{ active: form.icona === nome }"
            @click="form.icona = form.icona === nome ? null : nome">
            <Icon :name="`zona-${nome}`" style="width:18px;height:18px;vertical-align:middle;" />
          </button>
        </div>
        <label class="field-label" style="margin-top:12px">Esposizione</label>
        <div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:4px;">
          <label v-for="dir in ['nord','sud','est','ovest']" :key="dir"
            style="display:flex;align-items:center;gap:6px;font-size:13px;cursor:pointer;">
            <input type="checkbox" :value="dir" v-model="form.esposizione" style="accent-color:var(--sage);">
            {{ dir }}
          </label>
        </div>
        <div class="foglio-actions">
          <button class="btn btn-ghost" @click="chiudiForm" style="min-height:40px;padding:8px 16px;">Annulla</button>
          <button class="btn btn-sage" @click="salva" :disabled="!form.nome.trim() || salvando"
            style="min-height:40px;padding:8px 16px;">
            <Spinner v-if="salvando" /><span v-else>Salva</span>
          </button>
        </div>
      </div>
    </FoglioLaterale>
```

- [ ] **Step 5: ZoneView — togliere la regola scoped morta**

Nel `<style scoped>`, rimuovere la riga:
```css
a.pill { display:inline-flex; align-items:center; text-decoration:none; }
```
(non c'è più nessun `<a class="pill">` in questa view: "＋ Aggiungi" è ora un `<button>`. Le regole `.zrow__act .pill-mini { … }` restano — valgono anche per il `<button class="pill-mini">` della matita e per il `<RouterLink class="pill-mini">` "Sottozone".)

- [ ] **Step 6: Build ZoneView**

Run: `npm run build`
Expected: exit 0. A questo punto ZoneView modifica le zone nel foglio; le route `/zone/nuova` e `/zone/:zona/modifica` esistono ancora ma non sono più linkate da nessuna parte.

- [ ] **Step 7: Rimuovere le route zona-nuova / zona-modifica**

In `src/router/index.js`, cancellare le due righe:
```js
  { path: '/zone/nuova',                name: 'zona-nuova',     component: () => import('@/views/EditZonaView.vue') },
  { path: '/zone/:zona/modifica',       name: 'zona-modifica',  component: () => import('@/views/EditZonaView.vue') },
```
Lasciare `/zone` e `/zone/:zona/sottozone`.

- [ ] **Step 8: Eliminare EditZonaView**

```bash
git rm src/views/EditZonaView.vue
```

- [ ] **Step 9: Rimuovere `.zona-edit-wide` da main.css**

In `src/assets/main.css`, rimuovere il blocco (commento + regole, righe ~168-177):
```css
/* EditZonaView: sfonda il max-width di .app-main su schermi larghi, così il
   form (in particolare la griglia icone) respira invece di allungarsi.
   Il vecchio `margin-left: calc((100% - 1040px) / 2)` diventava negativo
   (il contenitore è più stretto di 1040px) e spingeva il form sotto la
   sidebar fissa da 200px. `min()` limita la larghezza a quello che c'è
   davvero a destra della sidebar, senza margini negativi. */
.zona-edit-wide { width: 100%; }
@media (min-width: 1100px) {
  .zona-edit-wide { width: min(1040px, calc(100vw - 248px)); margin-left: 0; }
}
```

- [ ] **Step 10: Aggiornare i commenti stale che citano EditZonaView**

- `src/assets/main.css` (~riga 156): `/* Selettore icona zona/sottozona (EditZonaView, SottozoneView): pillole` → `/* Selettore icona zona/sottozona (ZoneView, SottozoneView): pillole`
- `src/composables/useIconeZona.js` (riga 1): `// Slug delle icone selezionabili per zona/sottozona (EditZonaView, SottozoneView).` → `// Slug delle icone selezionabili per zona/sottozona (ZoneView, SottozoneView).`
- `src/components/IconDefs.vue` (~riga 219): `<!-- Icone "tipo di zona": selezionabili in EditZonaView/SottozoneView,` → `<!-- Icone "tipo di zona": selezionabili in ZoneView/SottozoneView,`

- [ ] **Step 11: Build + verifica**

Run: `npm run build`
Expected: exit 0, nessun warning nuovo.

Verifica di lettura:
- `grep -rn "EditZonaView\|zona-nuova\|zona-modifica\|zona-edit-wide\|/zone/nuova\|/zone/.*/modifica" src/` → **nessun risultato**.
- `git status` → `src/views/EditZonaView.vue` eliminato.
- `grep -n "apriNuovo\|apriModifica\|mostraForm" src/views/ZoneView.vue` → presenti nel template e nello script.

- [ ] **Step 12: Commit**

```bash
git add src/views/ZoneView.vue src/router/index.js src/assets/main.css src/composables/useIconeZona.js src/components/IconDefs.vue
git commit -m "$(cat <<'EOF'
Zone: modifica nel foglio laterale, come le sottozone

La logica insert/update/rename di EditZonaView passa dentro ZoneView sullo
stesso schema di SottozoneView (FoglioLaterale, stato mostraForm/
modificaOriginale, scrittura diretta su Supabase, store.aggiorna() sul
rename). "＋ Aggiungi" e la matita diventano pulsanti. Eliminati
EditZonaView.vue, le route zona-nuova/zona-modifica e la classe
.zona-edit-wide che serviva solo a quella pagina.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
EOF
)"
```

---

## Note di verifica per il QA nel browser (dopo il merge)

- **ZoneView**: "＋ Aggiungi" apre il foglio "Nuova zona"; la matita su una riga apre "Modifica zona" con i campi popolati; `Esc` / velo / × chiudono e resettano; "Salva" chiude su successo e la lista si aggiorna; rinominare una zona con piante/sottozone non lascia riferimenti al vecchio nome (rebuild via `store.aggiorna()`); il messaggio di errore "Una zona con questo nome esiste già." compare se si riusa un nome.
- Nessuna rotta rotta: non ci sono più link a `/zone/nuova` o `/zone/:zona/modifica`; digitare a mano quegli URL ora cade nella (eventuale) 404/redirect del router — comportamento accettabile, sono URL interni mai esposti.
- **SelettoreSpecie**: scegliendo una specie, il foglio si apre senza barra header; la × è in alto a destra sopra la foto (o sopra l'intestazione senza-foto) e chiude il foglio; `Esc` e click sul velo chiudono ancora.
- Griglia icona: la stessa in ZoneView e SottozoneView (scroll `max-height:140px` dentro `.foglio__body`).

## Fuori scope

- **MeteoView redesign** (registro verticale, `useMeteo` a 7 giorni, mini-grafico orario, dettaglio nel foglio) — round dedicato con mockup.
- **Migration RLS `specie`** — round dedicato.
- **Fase 3** dark mode (`--uovo`/`--font-serif` ecc.), **Fase 4** velatura hero. `useCureVisual.js` naming.
- Le `<label>` inline di `SottozoneView` (stile vecchio, non `.field-label`) — non toccate qui, il Task 2 usa `.field-label` in `ZoneView` perché la logica arriva da `EditZonaView` che già le usava.

## Self-review

- **Copertura spec:** (1) prop `senzaIntestazione` + × sulla hero → Task 1. (2) zone edit nel foglio come le sottozone → Task 2 Step 1-6; ritiro `EditZonaView` + route + `.zona-edit-wide` + commenti → Task 2 Step 7-10.
- **Placeholder:** nessuno — ogni step ha il codice completo.
- **Coerenza tipi/nomi:** `senzaIntestazione` (camelCase prop) ↔ `senza-intestazione` (kebab nel template consumatore) — corretto per Vue. `modificaOriginale` in `ZoneView` tiene `z.key` (la chiave di `store.zone`, cioè il nome), coerente con l'uso in `apriModifica`/`salva`. `form` ha le stesse 6 chiavi in `formVuoto`, `apriNuovo`, `apriModifica`, `chiudiForm`. `riga` per Supabase ha le 6 colonne che `EditZonaView` già scriveva (`nome`/`tipo`/`descrizione`/`microclima`/`esposizione`/`icona`); l'oggetto messo in `store.zone[...]` ha la forma che `EditZonaView` usava (con `id`/`criticita`/`manutenzione` da `salvata`).
- **Ordine:** Task 1 e Task 2 sono indipendenti (file disgiunti a parte nessuna sovrapposizione). Task 1 prima solo per convenzione (più piccolo). Dentro Task 2 gli step sono sequenziali: prima ZoneView funziona col foglio (Step 1-6), poi si rimuove il vecchio percorso (Step 7-10) — così un build fallito a metà lascia comunque un'app navigabile.
