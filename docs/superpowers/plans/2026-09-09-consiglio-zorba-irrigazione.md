# Il consiglio di Zorba per l'irrigazione — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nel Foglio "modifica programma" di `/impostazioni/irrigazione` (livelli pianta/zona/sottozona, mai giardino), mostrare un consiglio istantaneo — voce di Zorba — sull'intervallo di irrigazione giusto per le piante coperte da quel livello, calcolato dal catalogo specie già in memoria: un numero applicabile con un tap quando le esigenze delle piante coinvolte sono compatibili, un avviso che nomina le due specie agli estremi e consiglia di procedere pianta per pianta quando sono troppo diverse.

**Architecture:** Un nuovo composable puro (`useSuggerimentoIrrigazione.js`) che riusa `stagione()`/`parseGiorni()` già esportate da `useCure.js` per leggere `specie.manutenzione.irrigazione[stagione]` di ogni pianta coinvolta, calcola min/max degli intervalli e decide se restituire un numero singolo (vince la pianta più esigente) o un esito "divergente" quando lo scarto supera una soglia. `IrrigazioneView.vue` lo chiama in `apriModifica()` per pre-calcolare il consiglio del livello che si sta per modificare, e lo mostra nel Foglio prima del campo numerico esistente, con l'icona `ZorbaLogo mini` — stesso pattern già in uso in `AgenteView.vue` ("Zorba dice").

**Tech Stack:** Vue 3 `<script setup>` SFC, nessun nuovo store/tabella, nessuna chiamata di rete. Nessun runner di test in questo progetto.

**Spec:** nessuna spec formale — brief discusso e approvato in chat (comando `/impeccable shape`) il 9 settembre 2026, sullo stesso branch `irrigazione-automatica` dei due piani precedenti (`2026-09-08-irrigazione-automatica.md`, `2026-09-08-irrigazione-automatica-sottozone.md`).

## Global Constraints

- **Lingua:** testi UI, commenti e messaggi di commit in italiano.
- **Nessun framework di test in questo repo.** Verifica automatica = solo `npm run build` (exit 0). Per la funzione pura, uno script Node usa-e-getta con import relativo, eseguito e poi cancellato (stesso pattern dei due piani precedenti).
- **Mai per il livello giardino.** Il consiglio esiste solo per pianta/zona/sottozona — un giardino intero è quasi sempre troppo eterogeneo per un numero unico, ed è esplicitamente fuori perimetro (deciso nel brief).
- **Nessuna chiamata all'agente AI/coda `richieste-agente.json`.** Il consiglio è calcolato all'istante dai dati già in `store.specie`, non passa da `/elabora`.
- **Nessun nuovo "battito" su `ZorbaLogo.vue`.** La Regola dei Due Battiti di DESIGN.md copre solo due momenti già definiti (ridisegno scena raro, conferma cura frequente); questo è un terzo tipo di momento (un'informazione disponibile, non un evento raro né una conferma) e resta un'icona statica — non aggiungere `reagisci()`/`confermaCura()` né una nuova animazione.
- **Niente Caveat.** Il testo del consiglio resta in DM Sans (corpo), come tutto il resto dell'app — Caveat è riservato a data/didascalia.
- **Non toccare `useCure.js`, `useIrrigazioneAuto.js`, `useIrrigazioneApi.js`.** Il consiglio è solo informativo al momento della scelta: non cambia come la cascata viene salvata o valutata altrove nell'app.
- **Le piante "coperte" da un livello, per il calcolo del consiglio, sono tutte le piante fisicamente in quella zona/sottozona/pianta — a prescindere da eventuali override più specifici già impostati su una di loro.** Il consiglio descrive cosa c'è in quel punto del giardino, non ricalcola la cascata reale (quella resta compito di `useIrrigazioneAuto.js`, non toccato qui). Decisione presa in fase di piano per tenere lo scope semplice; non è la stessa cosa della "cascata effettiva" mostrata altrove nell'albero.
- **Branch:** `irrigazione-automatica` (stesso dei piani precedenti, non ancora mergiato). Nessun commit diretto su `main`.
- **Commit:** italiano, footer:
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
  ```

---

## File Structure

| File | Modifica |
|------|----------|
| `src/composables/useSuggerimentoIrrigazione.js` | **Crea** — funzione pura `suggerimentoIrrigazione(piante, specie)` + costante `SOGLIA_DIVERGENZA_IRRIGAZIONE`. |
| `src/views/IrrigazioneView.vue` | **Modifica** — calcolo del consiglio in `apriModifica()`, nuovo blocco nel Foglio con `ZorbaLogo mini`, bottone "Usa questo", CSS scoped. |

Nessun file di test.

---

### Task 1: `useSuggerimentoIrrigazione.js`

**Files:**
- Create: `src/composables/useSuggerimentoIrrigazione.js`

**Interfaces:**
- Consuma: `stagione()`, `parseGiorni()` da `@/composables/useCure.js` (già esportate, non toccarle).
- Produce: `suggerimentoIrrigazione(piante, specie)` → `{ tipo: 'numero', ogniGiorni } | { tipo: 'divergente', piuEsigente, minGiorni, menoEsigente, maxGiorni } | null`, e la costante `SOGLIA_DIVERGENZA_IRRIGAZIONE` — consumate da Task 2.

- [ ] **Step 1: Verificare il branch**

```bash
git branch --show-current
```

Expected: `irrigazione-automatica`. Non creare un nuovo branch.

- [ ] **Step 2: Scrivere il composable**

Crea `src/composables/useSuggerimentoIrrigazione.js`:

```js
import { stagione, parseGiorni } from '@/composables/useCure'

// Sopra questa soglia (intervallo più lungo ≥ N volte il più breve tra le
// specie coinvolte), un unico numero per l'intera zona/sottozona finirebbe
// per sotto-irrigare la pianta più esigente o sovra-irrigare quella meno
// esigente in modo eccessivo: meglio consigliare un programma per pianta.
export const SOGLIA_DIVERGENZA_IRRIGAZIONE = 3

// Consiglio di Zorba per il livello pianta/zona/sottozona (mai giardino:
// un intero giardino è quasi sempre troppo eterogeneo per un numero solo,
// vedi IrrigazioneView.vue). `piante` è l'elenco delle piante fisicamente
// coperte dal livello in esame (per una pianta, un array di una sola);
// `specie` è store.specie. Ritorna null quando non c'è abbastanza dato
// per un consiglio (nessuna pianta, o nessuna con manutenzione.irrigazione
// documentata per la stagione corrente).
export function suggerimentoIrrigazione(piante, specie) {
  const stagCorrente = stagione()
  const voci = piante
    .map(p => {
      const sp = specie?.[p.specie]
      const intervallo = parseGiorni(sp?.manutenzione?.irrigazione?.[stagCorrente])
      return intervallo ? { nomeSpecie: sp?.nome ?? p.specie, intervallo } : null
    })
    .filter(Boolean)

  if (!voci.length) return null

  const intervalli = voci.map(v => v.intervallo)
  const min = Math.min(...intervalli)
  const max = Math.max(...intervalli)

  if (voci.length > 1 && max >= min * SOGLIA_DIVERGENZA_IRRIGAZIONE) {
    return {
      tipo: 'divergente',
      piuEsigente: voci.find(v => v.intervallo === min).nomeSpecie,
      minGiorni: min,
      menoEsigente: voci.find(v => v.intervallo === max).nomeSpecie,
      maxGiorni: max,
    }
  }

  return { tipo: 'numero', ogniGiorni: min }
}
```

- [ ] **Step 3: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 4: Verifica di lettura rapida (senza framework di test)**

Il file non ha dipendenze esterne al progetto (solo `useCure.js`, anch'esso senza import): verificalo con uno script Node usa-e-getta **nella stessa cartella** (`src/composables/verifica-suggerimento.tmp.mjs`), import relativo, eseguito e poi cancellato — non va committato.

**Importante**: `stagione()` legge la data reale di oggi — non dare per scontato che la stagione corrente sia "estate". Costruisci i dati di prova con `stagione()` stessa, così lo script funziona in qualunque giorno venga eseguito:

```js
import assert from 'node:assert'
import { stagione } from './useCure.js'
import { suggerimentoIrrigazione } from './useSuggerimentoIrrigazione.js'

const s = stagione()
const specie = {
  rosmarino: { nome: 'Rosmarino', manutenzione: { irrigazione: { [s]: 'ogni 20 giorni' } } },
  felce:     { nome: 'Felce',     manutenzione: { irrigazione: { [s]: 'ogni 2 giorni' } } },
  basilico:  { nome: 'Basilico',  manutenzione: { irrigazione: { [s]: 'ogni 3 giorni' } } },
}

// singola pianta: il suo stesso intervallo
assert.deepStrictEqual(
  suggerimentoIrrigazione([{ specie: 'rosmarino' }], specie),
  { tipo: 'numero', ogniGiorni: 20 }
)

// due piante con bisogni vicini (2 vs 3, sotto la soglia 3x): vince la più esigente
assert.deepStrictEqual(
  suggerimentoIrrigazione([{ specie: 'felce' }, { specie: 'basilico' }], specie),
  { tipo: 'numero', ogniGiorni: 2 }
)

// due piante con bisogni troppo diversi (2 vs 20, sopra la soglia 3x): divergenza
assert.deepStrictEqual(
  suggerimentoIrrigazione([{ specie: 'rosmarino' }, { specie: 'felce' }], specie),
  { tipo: 'divergente', piuEsigente: 'Felce', minGiorni: 2, menoEsigente: 'Rosmarino', maxGiorni: 20 }
)

// nessuna pianta, o nessuna con dato utilizzabile
assert.strictEqual(suggerimentoIrrigazione([], specie), null)
assert.strictEqual(suggerimentoIrrigazione([{ specie: 'sconosciuta' }], specie), null)

console.log('OK')
```

Run: `node src/composables/verifica-suggerimento.tmp.mjs`
Expected: stampa `OK`. Poi cancella il file (`rm src/composables/verifica-suggerimento.tmp.mjs`) — non va committato.

- [ ] **Step 5: Commit**

```bash
git add src/composables/useSuggerimentoIrrigazione.js
git commit -m "$(cat <<'EOF'
Aggiunge il consiglio di Zorba per l'irrigazione (calcolo puro)

suggerimentoIrrigazione() legge manutenzione.irrigazione delle specie
coinvolte per la stagione corrente (stesso dato già usato da useCure.js)
e restituisce un numero quando le esigenze sono compatibili, o un avviso
di divergenza (le due specie agli estremi) quando sono troppo diverse
per un programma comune — mai per il livello giardino, gestito nel
prossimo commit da IrrigazioneView.vue.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```

---

### Task 2: Integrazione in `IrrigazioneView.vue`

**Files:**
- Modify: `src/views/IrrigazioneView.vue`

**Interfaces:**
- Consuma: `suggerimentoIrrigazione(piante, specie)` e `SOGLIA_DIVERGENZA_IRRIGAZIONE` (non necessaria qui, solo importata se serve) da `@/composables/useSuggerimentoIrrigazione` (Task 1); `ZorbaLogo` (`@/components/ZorbaLogo.vue`, esistente, prop booleana `mini`).
- Produce: nessuna interfaccia nuova per altri task — chiude la funzionalità.

- [ ] **Step 1: Import**

In `src/views/IrrigazioneView.vue`, nel blocco `<script setup>`, aggiungere agli import esistenti:

```js
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import { suggerimentoIrrigazione } from '@/composables/useSuggerimentoIrrigazione'
```

- [ ] **Step 2: Stato e calcolo del consiglio**

Nello stesso blocco, dopo la dichiarazione esistente `const errore = ref(null)`, aggiungere:

```js
const suggerimento = ref(null)

// Le piante fisicamente coperte da questo livello, a prescindere da un
// eventuale override più specifico già impostato su una di loro — il
// consiglio descrive cosa c'è in quel punto del giardino, non ricalcola
// la cascata reale (quella resta compito di useIrrigazioneAuto.js).
function pianteCoperte(target) {
  if (target.pianta) {
    const p = piante.value.find(pp => pp.id === target.pianta)
    return p ? [p] : []
  }
  if (target.sottozona) return pianteDellaZona(target.zona, target.sottozona)
  return piante.value.filter(p => p.zona === target.zona)
}
```

- [ ] **Step 3: Calcolare il consiglio quando si apre il Foglio**

Sostituire la funzione esistente:

```js
function apriModifica(target, titolo, valoreAttuale) {
  targetForm.value = target
  titoloForm.value = titolo
  giorniForm.value = valoreAttuale ?? null
  errore.value = null
  mostraForm.value = true
}
```

con:

```js
function apriModifica(target, titolo, valoreAttuale) {
  targetForm.value = target
  titoloForm.value = titolo
  giorniForm.value = valoreAttuale ?? null
  errore.value = null
  suggerimento.value = target === 'giardino' ? null : suggerimentoIrrigazione(pianteCoperte(target), store.specie)
  mostraForm.value = true
}
```

(Il livello giardino non chiama mai `apriModifica` con un target diverso da `'giardino'`, ma il controllo esplicito documenta il vincolo invece di lasciarlo implicito nel comportamento di `pianteCoperte`.)

- [ ] **Step 4: Azzerare il consiglio alla chiusura del Foglio**

Sostituire:

```js
function chiudiForm() {
  mostraForm.value = false
  targetForm.value = null
}
```

con:

```js
function chiudiForm() {
  mostraForm.value = false
  targetForm.value = null
  suggerimento.value = null
}
```

- [ ] **Step 5: Template — il blocco del consiglio nel Foglio**

Nel `<template>`, dentro `<FoglioLaterale>`, subito dopo `<div v-if="mostraForm" class="foglio-form">` e prima di `<label class="field-label" for="irr-giorni">Ogni quanti giorni</label>`, inserire:

```html
        <div v-if="suggerimento" class="irr-suggerimento">
          <ZorbaLogo mini />
          <p v-if="suggerimento.tipo === 'numero'">
            Zorba consiglia: ogni {{ suggerimento.ogniGiorni }} giorni.
            <button v-if="giorniForm !== suggerimento.ogniGiorni" type="button" class="link-reset" @click="giorniForm = suggerimento.ogniGiorni">Usa questo</button>
          </p>
          <p v-else>
            Zorba nota una differenza: <strong>{{ suggerimento.piuEsigente }}</strong> ha bisogno di acqua ogni {{ suggerimento.minGiorni }} giorni, ma <strong>{{ suggerimento.menoEsigente }}</strong> regge fino a ogni {{ suggerimento.maxGiorni }} — troppo diverse per un programma comune. Conviene impostarle una per una.
          </p>
        </div>
```

(cioè: il blocco `<div class="foglio-form">` diventa, nell'ordine, il nuovo blocco `.irr-suggerimento`, poi l'etichetta e l'input già esistenti, invariati.)

- [ ] **Step 6: CSS scoped**

Nel blocco `<style scoped>` esistente, aggiungere (in coda, dopo le regole già presenti):

```css
.irr-suggerimento { display:flex; align-items:flex-start; gap:8px; margin-bottom:12px; }
.irr-suggerimento p { margin:0; font-size:12.5px; line-height:1.5; color:var(--ink-mid); }
.irr-suggerimento .link-reset {
  background: none; border: none; padding: 0; margin-left: 4px;
  font-size: 12.5px; color: var(--sage-dark); text-decoration: underline;
  cursor: pointer;
}
.irr-suggerimento .link-reset:hover { color: var(--sage); }
```

Nota per il reviewer: `.link-reset` qui è locale a questo file (stesso nome usato in `AccountView.vue`, ma quel file lo definisce nel proprio `<style scoped>` — non è una classe globale condivisa, quindi va ridefinita qui). Il colore `--sage-dark`/`--sage` (non `--ink-soft` come in `AccountView.vue`) è deliberato: "Usa questo" è un'azione affermativa (applica un valore), non una rinuncia come "Annulla" — coerente con la Regola dei Colori di DESIGN.md (Verde Salvia = azione affermativa).

- [ ] **Step 7: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 8: Verifica manuale nel browser**

Con `npm run dev` avviato e sessione autenticata, su `/impostazioni/irrigazione`:

1. Apri "modifica programma" per una singola pianta la cui specie ha `manutenzione.irrigazione` documentata per la stagione corrente → il blocco di Zorba mostra "Zorba consiglia: ogni N giorni" con lo stesso numero della scheda specie di quella pianta; "Usa questo" compila il campo sottostante.
2. Apri "modifica programma" per una zona/sottozona con piante dai bisogni simili → un solo numero (il più esigente tra quelli coinvolti).
3. Apri "modifica programma" per una zona/sottozona che include sia una pianta a bassissimo fabbisogno (es. una succulenta) sia una ad alto fabbisogno → il blocco mostra l'avviso di divergenza, nomina le due specie agli estremi, nessun bottone "Usa questo".
4. Apri "modifica programma" per **Tutto il giardino** → nessun blocco di Zorba (fuori perimetro per questa funzionalità).
5. Chiudi il Foglio e riaprilo su un target diverso → il consiglio si aggiorna (non resta quello del target precedente).
6. Se nessuna pianta coinvolta ha `manutenzione.irrigazione` per la stagione corrente → nessun blocco (assenza silenziosa, non un errore).

- [ ] **Step 9: Commit**

```bash
git add src/views/IrrigazioneView.vue
git commit -m "$(cat <<'EOF'
IrrigazioneView: mostra il consiglio di Zorba nel Foglio di modifica

Calcolato all'apertura del Foglio per pianta/zona/sottozona (mai per il
giardino), con ZorbaLogo mini — stesso pattern di "Zorba dice" in
AgenteView.vue. Un numero applicabile con un tap quando le piante
coperte hanno bisogni compatibili, un avviso che nomina le due specie
agli estremi quando sono troppo diverse per un programma comune.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```
