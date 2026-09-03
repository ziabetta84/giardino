# Rollout FoglioLaterale + restyle ModalConferma + debiti SelettoreSpecie — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Portare le modali-form centrali rimaste (ProgettiView, ConcimiView, SottozoneView) sul pattern `FoglioLaterale` già in uso in `SelettoreSpecie`/`AttivitaView`, allineare `ModalConferma` allo stile taccuino, e chiudere due debiti minori dentro `SelettoreSpecie.vue`.

**Architecture:** Nessun componente nuovo. `FoglioLaterale.vue` esiste già (`Teleport`, `v-model` Boolean, chiusura velo/Esc/×, scroll-lock, focus, `:inert`, `prefers-reduced-motion`). Ogni view sostituisce il proprio blocco `<Teleport><div class="overlay"><div class="modal-box">…` con `<FoglioLaterale>`, sposta il titolo `<h3>` nella prop `:titolo`, e rimuove gli scoped `.overlay`/`.modal-box`. Due utility CSS condivise nuove (`.foglio-form`, `.foglio-actions`) forniscono padding e riga-azioni, perché `.foglio__body` è volutamente senza padding (in `SelettoreSpecie` l'hero è a tutta larghezza). `ModalConferma` resta un dialog centrato: solo ritocchi (raggio, font, Esc, animazione con opt-out). I debiti di `SelettoreSpecie` sono refactor interni al singolo file.

**Tech Stack:** Vue 3 `<script setup>` SFC, Vite 8, CSS custom properties in `src/assets/main.css`. Nessun runner di test nel repo.

**Spec:** nessuna spec formale — round bounded discusso e approvato in chat il 2026-09-03. Direzione: vedi `docs/superpowers/plans/2026-09-03-selettore-specie-redesign-esito.md` § "Follow-up minori / debito" (voce "Rollout del pattern `FoglioLaterale`") e `project_attivita_dossier_foglio.md`.

## Global Constraints

- **Lingua:** tutti i testi UI, i commenti e i messaggi di commit in **italiano**.
- **Zorba** (`<ZorbaLogo>` / gatto): sempre **nero** `#141414`, occhio verde `#7cc491`. Non toccato in questo round, ma non introdurre regole che lo schiariscano.
- **Niente blocchi dark-mode** (`@media (prefers-color-scheme: dark)`, `:root[data-theme]`): è Fase 3, fuori scope.
- **Verifica automatica = solo `npm run build` (exit 0).** Non esiste `npm test`. Ogni task termina con un build verde; la verifica visiva la fa Rob nel browser dopo il merge.
- **Palette invariata:** `--rose #cc6e6e` · `--gold #e0b84a` · `--sage #7a9e82` · `--olive #9aaa5a` · `--cream #faf7f2`. Font: `--font-display` (Fraunces), `--font-sans` (DM Sans).
- **Contratto `v-model` di `SelettoreSpecie` invariato** (`modelValue: String`, un solo `emit('update:modelValue', …)`): `EditPiantaView` e `AgenteView` non vanno toccati.
- **Commit:** messaggi in italiano, ognuno chiude con:
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
  ```
- **Branch:** `foglio-laterale-rollout` da `main`. Nessun commit diretto su `main`. Merge solo su ok esplicito di Rob a fine round.

---

## File Structure

| File | Responsabilità / modifica |
|------|---------------------------|
| `src/assets/main.css` | **Modifica** — aggiunge `.foglio-form` (padding contenuto) e `.foglio-actions` (riga pulsanti con filetto) accanto al blocco `.foglio*` (dopo la riga `@media (prefers-reduced-motion:reduce){ .foglio,.foglio-dim{transition:none} }`, attualmente riga ~668). |
| `src/views/ProgettiView.vue` | **Modifica** — modale "Nuovo progetto" → `<FoglioLaterale>`; nuova `chiudiForm()`; rimozione scoped `.overlay`/`.modal-box`. |
| `src/views/ConcimiView.vue` | **Modifica** — modale "Nuovo/Modifica concime" → `<FoglioLaterale>`; rimozione scoped `.overlay`/`.modal-box`; correzione commento stale (righe ~200-202). `ModalConferma` per l'eliminazione resta invariata. |
| `src/views/SottozoneView.vue` | **Modifica** — modale "Nuova/Modifica sottozona" → `<FoglioLaterale>`; rimozione scoped `.overlay`/`.modal-box`. `ModalConferma` per l'eliminazione resta invariata. |
| `src/components/ModalConferma.vue` | **Modifica** — raggio 20→22px, titolo su `var(--font-display)`, Esc-per-chiudere (focus sul box al mount), animazione fade+scale 150ms con `@media (prefers-reduced-motion: reduce)` che la annulla. |
| `src/components/SelettoreSpecie.vue` | **Modifica** — dropdown: markup di riga ripetuto 3× → un solo `v-for` su `gruppiDropdown`; `.sc-th` (miniatura 44px) passa da `hero.thumbUrl` (480px) a una miniatura 96px. |

Nessun file di test (il repo non ne ha).

---

### Task 1: Utility CSS `.foglio-form` / `.foglio-actions` + ProgettiView → FoglioLaterale

**Files:**
- Modify: `src/assets/main.css` (dopo la riga ~668, fine blocco `.foglio*`)
- Modify: `src/views/ProgettiView.vue`

**Interfaces:**
- Consuma: `FoglioLaterale.vue` (esistente) — props `{ modelValue: Boolean, titolo: String }`, emit `update:modelValue`; slot default = corpo scrollabile (`.foglio__body`, **senza padding**); prop `titolo` → renderizza `<h3>` in `.foglio__hd` con la × di chiusura.
- Produce: le classi globali `.foglio-form` e `.foglio-actions`, usate anche dai Task 2 e 3.

- [ ] **Step 1: Aggiungere le utility CSS**

In `src/assets/main.css`, subito dopo la riga:

```css
@media (prefers-reduced-motion:reduce){ .foglio,.foglio-dim{transition:none} }
```

inserire:

```css
/* Contenuto di un form dentro il foglio: .foglio__body è senza padding
   di proposito (in SelettoreSpecie l'hero è a tutta larghezza). */
.foglio-form { padding: 4px 16px 22px; }
.foglio-form > .field-label:first-child,
.foglio-form > label:first-child { margin-top: 0; }
.foglio-actions {
  display: flex; gap: 10px; justify-content: flex-end;
  margin-top: 18px; padding-top: 14px;
  border-top: 1px solid var(--cream-dark);
}
@media (min-width: 640px) { .foglio-form { padding: 4px 18px 24px; } }
```

- [ ] **Step 2: Verificare il build dopo la sola modifica CSS**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 3: ProgettiView — import e stato**

In `src/views/ProgettiView.vue`, sezione `<script setup>`:

Aggiungere l'import dopo `import Spinner from '@/components/Spinner.vue'`:

```js
import FoglioLaterale from '@/components/FoglioLaterale.vue'
```

Aggiungere una funzione di chiusura che azzera anche il form (subito dopo la dichiarazione `const form = ref({ titolo: '', descrizione: '', zona: '' })`):

```js
function chiudiForm() {
  mostraForm.value = false
  form.value = { titolo: '', descrizione: '', zona: '' }
}
```

- [ ] **Step 4: ProgettiView — sostituire la modale**

Sostituire l'intero blocco (dall'apertura `<!-- Form nuovo progetto -->` fino al `</Teleport>` incluso):

```html
    <!-- Form nuovo progetto -->
    <Teleport to="body">
      <div v-if="mostraForm" class="overlay" @click.self="mostraForm = false">
        <div class="modal-box">
          <h3 style="font-family:var(--font-display);font-size:16px;font-weight:600;margin-bottom:16px;">Nuovo progetto</h3>
          <input v-model="form.titolo" placeholder="Titolo" class="form-input" style="margin-bottom:10px;">
          <MiniEditor v-model="form.descrizione" placeholder="Descrizione (opzionale)" />
          <input v-model="form.zona" placeholder="Zona (opzionale)" class="form-input" style="margin:10px 0 16px;">
          <div style="display:flex;gap:10px;justify-content:flex-end;">
            <button class="btn btn-ghost" @click="mostraForm = false" style="min-height:40px;padding:8px 16px;">Annulla</button>
            <button class="btn btn-sage" @click="salvaProgetto" :disabled="!form.titolo.trim() || salvando"
              style="min-height:40px;padding:8px 16px;">
              <Spinner v-if="salvando" /><span v-else>Salva</span>
            </button>
          </div>
        </div>
      </div>
    </Teleport>
```

con:

```html
    <!-- Form nuovo progetto -->
    <FoglioLaterale
      :model-value="mostraForm"
      @update:model-value="v => { if (!v) chiudiForm() }"
      titolo="Nuovo progetto"
    >
      <div v-if="mostraForm" class="foglio-form">
        <input v-model="form.titolo" placeholder="Titolo" class="form-input" style="margin-bottom:10px;">
        <MiniEditor v-model="form.descrizione" placeholder="Descrizione (opzionale)" />
        <input v-model="form.zona" placeholder="Zona (opzionale)" class="form-input" style="margin:10px 0 0;">
        <div class="foglio-actions">
          <button class="btn btn-ghost" @click="chiudiForm" style="min-height:40px;padding:8px 16px;">Annulla</button>
          <button class="btn btn-sage" @click="salvaProgetto" :disabled="!form.titolo.trim() || salvando"
            style="min-height:40px;padding:8px 16px;">
            <Spinner v-if="salvando" /><span v-else>Salva</span>
          </button>
        </div>
      </div>
    </FoglioLaterale>
```

- [ ] **Step 5: ProgettiView — rimuovere gli scoped `.overlay`/`.modal-box`**

Nel blocco `<style scoped>` di `ProgettiView.vue`, rimuovere le regole `.overlay { … }` e `.modal-box { … }` (restano solo quelle, quindi lo `<style scoped>` diventa vuoto: rimuovere l'intero blocco `<style scoped> … </style>`).

- [ ] **Step 6: Verificare che `salvaProgetto` chiuda ancora correttamente**

Controllo di lettura: in `salvaProgetto()`, in caso di successo, le righe

```js
    mostraForm.value = false
    form.value = { titolo: '', descrizione: '', zona: '' }
```

restano valide (chiudono il foglio via `:model-value` e resettano il form). Non modificare `salvaProgetto`.

- [ ] **Step 7: Build**

Run: `npm run build`
Expected: exit 0, nessun warning nuovo su `ProgettiView.vue`.

- [ ] **Step 8: Commit**

```bash
git add src/assets/main.css src/views/ProgettiView.vue
git commit -m "$(cat <<'EOF'
FoglioLaterale: utility .foglio-form/.foglio-actions + ProgettiView

La modale "Nuovo progetto" passa dal box centrato al foglio laterale
(riuso di FoglioLaterale.vue). Rimossi gli scoped .overlay/.modal-box.
Nuove utility condivise per il padding del contenuto e la riga azioni,
dato che .foglio__body è senza padding di proposito.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
EOF
)"
```

---

### Task 2: ConcimiView → FoglioLaterale + commento stale

**Files:**
- Modify: `src/views/ConcimiView.vue`

**Interfaces:**
- Consuma: `FoglioLaterale.vue`; `.foglio-form`/`.foglio-actions` (Task 1).
- Produce: nulla per i task successivi.

- [ ] **Step 1: Import**

In `<script setup>` di `src/views/ConcimiView.vue`, dopo `import Spinner from '@/components/Spinner.vue'`:

```js
import FoglioLaterale from '@/components/FoglioLaterale.vue'
```

- [ ] **Step 2: Sostituire la modale nuovo/modifica**

Sostituire l'intero blocco `<!-- Modale nuovo/modifica -->` … `</Teleport>` con:

```html
    <!-- Foglio nuovo/modifica -->
    <FoglioLaterale
      :model-value="mostraForm"
      @update:model-value="v => { if (!v) chiudiForm() }"
      :titolo="modificaId ? 'Modifica concime' : 'Nuovo concime'"
    >
      <div v-if="mostraForm" class="foglio-form">
        <input v-model="form.nome" placeholder="Nome *" class="form-input" style="margin-bottom:10px;">
        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">NPK</label>
        <div style="display:flex;gap:8px;margin-bottom:16px;">
          <input v-model.number="form.n" type="number" min="0" placeholder="N" class="form-input" style="text-align:center;">
          <input v-model.number="form.p" type="number" min="0" placeholder="P" class="form-input" style="text-align:center;">
          <input v-model.number="form.k" type="number" min="0" placeholder="K" class="form-input" style="text-align:center;">
        </div>
        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Descrizione (opzionale)</label>
        <textarea v-model="form.descrizione" placeholder="Preparazione, dosi, tempo di macerazione…"
          rows="3" class="form-input" style="resize:vertical;font-family:inherit;margin-bottom:16px;"></textarea>
        <div style="display:flex;align-items:center;justify-content:space-between;gap:8px;">
          <span style="font-size:13px;color:var(--ink-mid);">Disponibile in dispensa</span>
          <button type="button" @click="form.disponibile = !form.disponibile"
            class="toggle-switch" :class="{ attivo: form.disponibile }"
            :aria-label="form.disponibile ? 'Segna come terminato' : 'Segna come disponibile'">
            <span class="toggle-switch-knob"></span>
          </button>
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

(Rispetto all'originale: rimosso l'`<h3>` — ora è `:titolo`; rimosso il `margin-bottom:16px` sull'ultima riga toggle perché `.foglio-actions` porta il proprio `margin-top`.)

- [ ] **Step 3: `chiudiForm` deve resettare il form**

`chiudiForm()` oggi fa solo `mostraForm.value = false`. Il reset avviene in `apriNuovo`/`apriModifica` alla riapertura, quindi va bene così — **non modificare** `chiudiForm`. (La chiusura via velo/Esc chiama `chiudiForm` tramite l'handler `@update:model-value`.)

- [ ] **Step 4: Rimuovere gli scoped `.overlay`/`.modal-box`**

Nel `<style scoped>`, rimuovere **solo** le regole `.overlay { … }` e `.modal-box { … }`. Lasciare intatte `.feedlist .feed--tap`, `.feedlist .feed__del`, `.toggle-switch*` (il toggle è ancora usato nel foglio e nella riga elenco).

- [ ] **Step 5: Correggere il commento stale**

Nel `<style scoped>`, sostituire il commento sopra `.feedlist .feed--tap`:

```css
/* Riga concime: tap sull'intera riga apre la modale di modifica.
   Override parent-qualificato (come .care-act in PiantaView): non ridefinisce
   .feed globale, aggiunge solo il cursore per la riga interattiva. */
```

con:

```css
/* Riga concime: tap sull'intera riga apre il foglio di modifica.
   Override parent-qualificato: non ridefinisce la .feed globale,
   aggiunge solo il cursore per la riga interattiva. */
```

- [ ] **Step 6: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 7: Commit**

```bash
git add src/views/ConcimiView.vue
git commit -m "$(cat <<'EOF'
FoglioLaterale: ConcimiView

La modale nuovo/modifica concime passa al foglio laterale. ModalConferma
per l'eliminazione resta invariata. Aggiornato il commento stale che
citava .care-act "in PiantaView" (ora classe globale).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
EOF
)"
```

---

### Task 3: SottozoneView → FoglioLaterale

**Files:**
- Modify: `src/views/SottozoneView.vue`

**Interfaces:**
- Consuma: `FoglioLaterale.vue`; `.foglio-form`/`.foglio-actions` (Task 1).
- Produce: nulla per i task successivi.

- [ ] **Step 1: Import**

In `<script setup>` di `src/views/SottozoneView.vue`, dopo `import Spinner from '@/components/Spinner.vue'`:

```js
import FoglioLaterale from '@/components/FoglioLaterale.vue'
```

- [ ] **Step 2: Sostituire la modale nuova/modifica**

Sostituire l'intero blocco `<!-- Form nuova/modifica sottozona -->` … `</Teleport>` con:

```html
    <!-- Foglio nuova/modifica sottozona -->
    <FoglioLaterale
      :model-value="mostraForm"
      @update:model-value="v => { if (!v) chiudiForm() }"
      :titolo="modificaOriginale ? 'Modifica sottozona' : 'Nuova sottozona'"
    >
      <div v-if="mostraForm" class="foglio-form">
        <input v-model="form.nome" placeholder="Nome *" class="form-input" style="margin-bottom:10px;">
        <MiniEditor v-model="form.descrizione" placeholder="Descrizione (opzionale)" />
        <p v-if="errore" style="font-size:11px;color:var(--rose-dark);margin:6px 0 0;">{{ errore }}</p>
        <select v-model="form.tipo" class="form-input" style="margin:10px 0;">
          <option value="esterno">Esterno</option>
          <option value="interno">Interno</option>
        </select>
        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Icona</label>
        <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(30px,1fr));gap:0;max-height:140px;overflow-y:auto;padding:6px;border:1px solid var(--cream-dark);border-radius:10px;margin-bottom:16px;">
          <button type="button" v-for="nome in ICONE_ZONA" :key="nome" class="pill pill-icona"
            :class="{ active: form.icona === nome }"
            @click="form.icona = form.icona === nome ? null : nome">
            <Icon :name="`zona-${nome}`" style="width:18px;height:18px;vertical-align:middle;" />
          </button>
        </div>
        <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Esposizione</label>
        <div style="display:flex;gap:8px;flex-wrap:wrap;">
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

(Rispetto all'originale: rimosso l'`<h3>`; rimosso il `margin-bottom:16px` sull'ultimo blocco esposizione — subentra `.foglio-actions`.)

- [ ] **Step 3: Non toccare `chiudiForm`**

`chiudiForm()` in `SottozoneView` già resetta `form`, `modificaOriginale`, `errore`. Va bene così: l'handler `@update:model-value` lo richiama su chiusura via velo/Esc/×.

- [ ] **Step 4: Rimuovere gli scoped `.overlay`/`.modal-box`**

Nel `<style scoped>` rimuovere **solo** `.overlay { … }` e `.modal-box { … }`. Lasciare `.szrow*`, `.dest .pill-mini*`, `.szt`.

- [ ] **Step 5: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 6: Commit**

```bash
git add src/views/SottozoneView.vue
git commit -m "$(cat <<'EOF'
FoglioLaterale: SottozoneView

La modale nuova/modifica sottozona passa al foglio laterale. La griglia
icone e i checkbox esposizione restano identici, dentro .foglio-form.
ModalConferma per l'eliminazione resta invariata.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
EOF
)"
```

---

### Task 4: Restyle ModalConferma

**Files:**
- Modify: `src/components/ModalConferma.vue`

**Interfaces:**
- Consuma: nulla di nuovo.
- Produce: nessun cambio di API — props `{ aperto, titolo, messaggio, caricamento }` ed emit `{ conferma, annulla }` invariati. I chiamanti (`ZoneView`, `SottozoneView`, `ConcimiView`) non vanno toccati.

- [ ] **Step 1: Template — box focusabile + Esc**

Sostituire il `<template>` con:

```html
<template>
  <Teleport to="body">
    <div v-if="aperto" class="overlay" @click.self="$emit('annulla')">
      <div class="modal-box" role="alertdialog" aria-modal="true" tabindex="-1"
        ref="box" @keydown.esc="$emit('annulla')">
        <h3 class="mc-titolo">{{ titolo }}</h3>
        <p style="font-size:13px;color:var(--ink-soft);line-height:1.5;">{{ messaggio }}</p>
        <div style="display:flex;gap:10px;margin-top:20px;justify-content:flex-end;">
          <button class="btn btn-ghost" style="min-height:40px;padding:8px 18px;" @click="$emit('annulla')">Annulla</button>
          <button class="btn" style="min-height:40px;padding:8px 18px;background:var(--rose);color:white;" @click="$emit('conferma')" :disabled="caricamento">
            <Spinner v-if="caricamento" />{{ caricamento ? 'Eliminazione…' : 'Elimina' }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
```

- [ ] **Step 2: Script — focus sul box all'apertura**

Sostituire il `<script setup>` con:

```js
<script setup>
import { ref, watch, nextTick } from 'vue'
import Spinner from './Spinner.vue'

const props = defineProps({
  aperto:     { type: Boolean, default: false },
  titolo:     { type: String,  default: 'Conferma eliminazione' },
  messaggio:  { type: String,  default: 'Questa azione non può essere annullata.' },
  caricamento:{ type: Boolean, default: false },
})
defineEmits(['conferma', 'annulla'])

const box = ref(null)
watch(() => props.aperto, (v) => {
  if (v) nextTick(() => box.value?.focus())
})
</script>
```

- [ ] **Step 3: Style — raggio, font titolo, animazione con opt-out**

Sostituire il `<style scoped>` con:

```css
<style scoped>
.overlay {
  position: fixed; inset: 0; z-index: 400;
  background: rgba(42,34,24,0.4);
  display: flex; align-items: center; justify-content: center;
  padding: 16px;
}
.modal-box {
  background: var(--white);
  border-radius: 22px;
  padding: 24px;
  width: 100%; max-width: 360px;
  box-shadow: 0 20px 60px rgba(42,34,24,0.2);
  animation: mc-in 150ms ease;
}
.mc-titolo {
  font: 600 16px/1.2 var(--font-display);
  color: var(--ink);
  margin: 0 0 8px;
}
@keyframes mc-in {
  from { opacity: 0; transform: translateY(8px) scale(.98); }
  to   { opacity: 1; transform: none; }
}
@media (prefers-reduced-motion: reduce) {
  .modal-box { animation: none; }
}
</style>
```

- [ ] **Step 4: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 5: Verifica di lettura dei chiamanti**

`grep -n "ModalConferma" src/views/*.vue` → confermare che `ZoneView`, `SottozoneView`, `ConcimiView` passano gli stessi prop/handler di prima (nessuna modifica necessaria: l'API è invariata).

- [ ] **Step 6: Commit**

```bash
git add src/components/ModalConferma.vue
git commit -m "$(cat <<'EOF'
ModalConferma: allineamento allo stile taccuino

Resta un dialog centrato (le conferme distruttive sono una categoria UX
a parte). Ritocchi: raggio 22px, titolo su --font-display, Esc per
annullare (focus sul box all'apertura), fade+scale 150ms annullata da
prefers-reduced-motion. API dei prop/emit invariata.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
EOF
)"
```

---

### Task 5: Debiti SelettoreSpecie — dropdown DRY + miniatura scheda

**Files:**
- Modify: `src/components/SelettoreSpecie.vue`

**Interfaces:**
- Consuma: `urlMiniatura(url, larghezza)` da `@/composables/useWikimedia` (già importato).
- Produce: nessun cambio di API pubblica del componente.

- [ ] **Step 1: Nuovo computed `gruppiDropdown`**

In `<script setup>`, subito dopo la riga:

```js
const mostraGruppi    = computed(() => speciePossedute.value.length > 0 && specieCatalogo.value.length > 0)
```

aggiungere:

```js
// Righe della tendina, raggruppate o piatte, con un'unica forma per il
// template (prima il markup di riga era ripetuto 3 volte).
const gruppiDropdown = computed(() =>
  mostraGruppi.value
    ? [
        { label: 'Nel tuo giardino', voci: speciePossedute.value },
        { label: 'Nel catalogo',     voci: specieCatalogo.value },
      ]
    : [{ label: null, voci: specieFiltrate.value }]
)
```

- [ ] **Step 2: Template — sostituire i 3 blocchi con un solo `v-for`**

Nel `<template>`, sostituire l'intero blocco da `<template v-if="mostraGruppi">` fino al `</template>` che chiude il ramo `v-else` (righe 15–62 del file attuale: i due `v-for` dentro `mostraGruppi` + il `v-for` piatto nel `v-else`) con:

```html
      <template v-for="g in gruppiDropdown" :key="g.label ?? '_flat'">
        <div v-if="g.label" class="dd-group"><div class="slabel">{{ g.label }}</div></div>
        <div v-for="s in g.voci" :key="s.key" class="dd-row" @mousedown.prevent="selezionaSpecie(s)">
          <span class="dd-thumb" :class="{ leaf: !s.immagine?.url }"
            :style="s.immagine?.url ? { backgroundImage: bgUrl(urlMiniatura(s.immagine.url, 96)) } : null">
            <Icon v-if="!s.immagine?.url" name="foglia" />
          </span>
          <span class="dd-m">
            <span class="dd-name">
              {{ s.nome }}
              <span v-if="s.cultivarDi" class="badge-mini cv">cultivar</span>
              <span v-else-if="!s.verificata" class="badge-mini bz">bozza</span>
            </span>
            <span v-if="s.nomeScientifico" class="dd-sci">{{ s.nomeScientifico }}</span>
          </span>
        </div>
      </template>
```

Le righe successive (`<p v-if="ricercaInCorso" …>` ecc. e il `<RouterLink to="/agente" …>`) restano invariate.

- [ ] **Step 3: `hero` computed — aggiungere `miniUrl`**

Nel computed `hero`, sostituire:

```js
const hero = computed(() => {
  const img = specieSelezionata.value?.immagine
  return img?.url
    ? { thumbUrl: urlMiniatura(img.url, 480), attribuzione: img.attribuzione, fontePagina: img.fonte_pagina }
    : null
})
```

con:

```js
const hero = computed(() => {
  const img = specieSelezionata.value?.immagine
  return img?.url
    ? { thumbUrl: urlMiniatura(img.url, 480), miniUrl: urlMiniatura(img.url, 96), attribuzione: img.attribuzione, fontePagina: img.fonte_pagina }
    : null
})
```

- [ ] **Step 4: `.sc-th` — usare la miniatura 96px**

Nel `<template>`, sostituire:

```html
      <span class="sc-th" :style="hero ? { backgroundImage: bgUrl(hero.thumbUrl) } : null"></span>
```

con:

```html
      <span class="sc-th" :style="hero ? { backgroundImage: bgUrl(hero.miniUrl) } : null"></span>
```

- [ ] **Step 5: Build**

Run: `npm run build`
Expected: exit 0, nessun warning nuovo.

- [ ] **Step 6: Verifica di lettura — nessun uso residuo**

- `grep -n "mostraGruppi" src/components/SelettoreSpecie.vue` → deve comparire solo nella dichiarazione del `computed` e dentro `gruppiDropdown` (non più nel template).
- `grep -n "hero.thumbUrl" src/components/SelettoreSpecie.vue` → resta solo negli usi dell'hero grande (`.dh`, `.dh-np` no; `.dh` sì: `:style="{ backgroundImage: bgUrl(hero.thumbUrl) }"` e il credit). Non deve comparire più su `.sc-th`.
- Il contratto `v-model` è intatto: `defineEmits(['update:modelValue'])` e un solo `emit('update:modelValue', …)` in `selezionaSpecie`.

- [ ] **Step 7: Commit**

```bash
git add src/components/SelettoreSpecie.vue
git commit -m "$(cat <<'EOF'
SelettoreSpecie: dropdown DRY + miniatura scheda a 96px

Il markup di riga della tendina era ripetuto 3 volte (posseduta /
catalogo / lista piatta): ora un solo v-for su gruppiDropdown. La
miniatura 44px della card compatta usava l'URL a 480px dell'hero:
passa a una miniatura dedicata a 96px.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
EOF
)"
```

---

## Note di verifica per il QA nel browser (dopo il merge)

- **ProgettiView / ConcimiView / SottozoneView**: "＋ Aggiungi" apre il foglio (da destra su desktop ≥640px, dal basso su mobile); `Esc` / click sul velo / × chiudono e resettano il form; "Salva" chiude su successo; in modifica (Concimi/Sottozone) il titolo del foglio dice "Modifica …"; con *riduci animazioni* niente slide.
- **SottozoneView**: la griglia icone scrolla dentro il suo riquadro `max-height:140px`; i pulsanti Annulla/Salva sono in fondo al contenuto scrollabile del foglio (form corti, accettabile — nessun footer fisso).
- **ModalConferma**: eliminando una zona/sottozona/concime compare il dialog centrato col nuovo raggio; `Esc` annulla; il focus va sul box.
- **SelettoreSpecie**: tendina con gruppi + miniature invariata all'occhio; card compatta post-scelta con miniatura più nitida (meno banda passante); "Vedi scheda completa" apre il foglio dossier; "Cambia" riapre la tendina.

## Fuori scope (round successivi)

- **Redesign MeteoView** in stile taccuino (registro verticale, barra escursione min–max, dettaglio giorno nel `FoglioLaterale`) + estensione di `useMeteo` alle ore di tutti i 7 giorni con mini-grafico orario nel foglio. Round dedicato, con mockup.
- **Sicurezza**: migration per restringere le policy RLS di `INSERT`/`UPDATE` sulla tabella `specie` (lettura pubblica, scrittura solo curatore/service-role). Round dedicato — vedi `2026-09-03-selettore-specie-redesign-esito.md` § Sicurezza.
- **`useCureVisual.js`**: naming improprio (non è un vero composable) — rinominare tocca 3 import per zero guadagno funzionale, eventualmente in Fase 3.
- **Fase 3**: dark mode. **Fase 4**: velatura stagionale dell'hero della Home.

## Self-review

- **Copertura**: i 3 form-modali della lista → Task 1/2/3; `ModalConferma` → Task 4; i due debiti `SelettoreSpecie` (dropdown 3×, `.sc-th` 480px) → Task 5; commento stale `ConcimiView` → Task 2 Step 5. "EditPianta" era in lista per errore (è una pagina piena, usa solo `SelettoreSpecie`): escluso, come concordato. Il debito "badge `statoBadge` minuscolo" è stato verificato in fase di analisi: `.dh-chip` e `.badge-mini` hanno già `text-transform: uppercase`, quindi rende maiuscolo — nessun intervento.
- **Placeholder**: nessuno — ogni step ha il codice completo.
- **Coerenza tipi/nomi**: `gruppiDropdown` (Task 5) restituisce `[{ label, voci }]`; il template itera `g.label`/`g.voci`. `hero` guadagna `miniUrl` (Task 5 Step 3) usato in Task 5 Step 4. `.foglio-form`/`.foglio-actions` definite in Task 1 e usate identiche in Task 2/3. Nomi di stato per view: `mostraForm` (tutte e 3), `chiudiForm` (Concimi/Sottozone esistente; Progetti creato in Task 1 Step 3), `modificaId` (Concimi), `modificaOriginale` (Sottozone).
- **Ordine**: Task 1 prima (definisce le utility CSS che 2 e 3 consumano). Task 4 e 5 indipendenti, eseguibili in qualsiasi ordine dopo l'1.
