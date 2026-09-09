# Registrazione automatica dell'irrigazione sospesa — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Quando l'irrigazione di una pianta è sospesa (pioggia prevista o programma automatico attivo) ma sarebbe comunque dovuta oggi secondo il proprio intervallo, l'app la registra da sola (`ultima_cura.irrigazione = oggi`) invece di limitarsi a nascondere il promemoria — al prossimo apertura dell'app, non con un processo server separato (deciso esplicitamente in chat: nessuna infrastruttura server-side in questa fase, possibile evoluzione futura quando l'app sarà aperta ad altri utenti che non la usano quotidianamente).

**Architecture:** Una nuova funzione pura in `useCure.js` (`irrigazioneDaRegistrareOggi`), separata da `valutaCura()` e senza alterarne il comportamento, riusa `pioggiaInArrivo()`/`parseGiorni()`/`stagione()` già esportate per decidere se una pianta è sospesa-ma-dovuta. `stores/dati.js → eseguiCaricamento()` la chiama una volta per sessione (stessa guardia di `caricaTutto()`), dopo che piante/specie/zone/programmi/meteo sono già caricati, e scrive `ultima_cura` per le piante risultate dovute — in un blocco try/catch proprio, che non deve mai trasformare un problema di rete isolato in un errore che nasconde dati già caricati con successo (stesso principio già applicato al caricamento del meteo nello stesso file).

**Tech Stack:** Vue 3 `<script setup>`/Pinia, Supabase JS client. Nessun runner di test in questo progetto.

**Spec:** nessuna spec formale — discusso in chat il 9 settembre 2026, dopo il merge della funzionalità "irrigazione automatica" (già su `main`). Decisione esplicita presa in chat: fase 1 lato client (questo piano); un'eventuale fase 2 lato server (Supabase Edge Function + `pg_cron`) resta un lavoro a parte, non anticipato qui.

## Global Constraints

- **Lingua:** testi/commenti/commit in italiano.
- **Nessun framework di test in questo repo.** Verifica automatica = `npm run build` (exit 0). Per la funzione pura, script Node usa-e-getta con import relativo, eseguito e cancellato.
- **`useCure.js` viene toccato per la prima volta in questa serie di lavori** (nei tre piani precedenti era esplicitamente protetto) — è un cambiamento intenzionale e nel perimetro di questo piano, non una deviazione.
- **`irrigazioneDaRegistrareOggi` non deve mai alterare `valutaCura()` né il suo output** — è una funzione parallela, sola lettura, usata solo dalla nuova logica di scrittura in `dati.js`. Le 6 viste che già chiamano `valutaCura()`/`cureUrgentiPianta()` non cambiano.
- **Mai per piante `coltivato_in === 'acqua'`** — stesso criterio già usato da `valutaCura()` per la sospensione da pioggia.
- **La registrazione automatica non deve mai bloccare il resto del caricamento dello store**: un fallimento di rete isolato su una singola scrittura resta contenuto in un proprio try/catch, non deve mai far comparire `store.errore` per piante/zone/specie già caricate con successo.
- **Nota operativa, non un vincolo di implementazione**: il progetto Supabase (`ncuhhsvtjwcolhpdxbkt`) è lo stesso in ogni branch — non esiste un database di test separato. Una volta mergiato, la prima apertura reale dell'app da parte di un utente reale scriverà `ultima_cura` per davvero sulle sue piante reali coperte da un programma automatico/dalla pioggia già dovute — è il comportamento voluto (il "recupero" di cui si è parlato), non un effetto collaterale da evitare.
- **Branch:** nuovo branch `irrigazione-automatica-registrazione` da `main` (il branch precedente è già mergiato ed eliminato). Nessun commit diretto su `main`.
- **Commit:** italiano, footer:
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
  ```

---

## File Structure

| File | Modifica |
|------|----------|
| `src/composables/useCure.js` | **Modifica** — nuova funzione esportata `irrigazioneDaRegistrareOggi(pianta, specie, contesto)`. |
| `src/stores/dati.js` | **Modifica** — nuovo passaggio in `eseguiCaricamento()`, dopo il caricamento del meteo, che chiama la funzione sopra per ogni pianta e scrive `ultima_cura` per quelle risultate dovute. |

Nessun file di test.

---

### Task 1: `irrigazioneDaRegistrareOggi` in `useCure.js`

**Files:**
- Modify: `src/composables/useCure.js`

**Interfaces:**
- Consuma: `pioggiaInArrivo()`, `parseGiorni()`, `stagione()` — già esportate nello stesso file, non toccarle.
- Produce: `irrigazioneDaRegistrareOggi(pianta, specie, contesto)` → `boolean`, dove `contesto = { programmaAutomatico, esterno, meteo }` (stessa forma già usata da `valutaCura`) — consumata da Task 2.

- [ ] **Step 1: Verificare il branch**

```bash
git branch --show-current
```

Expected: `irrigazione-automatica-registrazione` (nuovo branch da `main`, creato dal controller prima del dispatch).

- [ ] **Step 2: Aggiungere la funzione**

In `src/composables/useCure.js`, in fondo al file (dopo `cureUrgentiPianta`), aggiungere:

```js
// Se l'irrigazione di questa pianta è sospesa (dalla pioggia prevista o da
// un programma automatico attivo, vedi useIrrigazioneAuto.js) ma sarebbe
// comunque dovuta oggi secondo il proprio intervallo, l'app la registra da
// sola al posto del promemoria manuale: si fida che l'irrigazione avvenga
// per conto suo (pioggia reale, o un impianto/programma indipendente)
// invece di continuare a chiederla all'utente. Puramente di lettura, come
// valutaCura() — che resta l'unica fonte di verità per cosa mostrare in
// interfaccia: questa funzione non la chiama e non ne altera il risultato,
// serve solo a decidere se stores/dati.js deve scrivere ultima_cura.
export function irrigazioneDaRegistrareOggi(pianta, specie, contesto = {}) {
  if (pianta?.coltivato_in === 'acqua') return false

  const sospesaDaAutomatico = contesto.programmaAutomatico != null
  const sospesaDaPioggia = contesto.esterno && pioggiaInArrivo(contesto.meteo)
  if (!sospesaDaAutomatico && !sospesaDaPioggia) return false

  const intervallo = contesto.programmaAutomatico ?? parseGiorni(specie?.manutenzione?.irrigazione?.[stagione()])
  if (!intervallo) return false

  const ultimaStr = pianta?.ultima_cura?.irrigazione
  if (!ultimaStr) return true
  const trascorsi = Math.floor((new Date() - new Date(ultimaStr)) / 86400000)
  return trascorsi >= intervallo
}
```

- [ ] **Step 3: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 4: Verifica di lettura rapida (senza framework di test)**

Script Node temporaneo nella stessa cartella (`src/composables/verifica-registrazione-automatica.tmp.mjs`), import relativo, eseguito e poi cancellato:

```js
import assert from 'node:assert'
import { irrigazioneDaRegistrareOggi } from './useCure.js'

const oggi = new Date()
function giorniFa(n) {
  const d = new Date(oggi)
  d.setDate(d.getDate() - n)
  return d.toISOString().split('T')[0]
}
const specieConCadenza = { manutenzione: { irrigazione: { [(function () {
  const m = oggi.getMonth() + 1
  if ([3,4,5].includes(m)) return 'primavera'
  if ([6,7,8].includes(m)) return 'estate'
  if ([9,10,11].includes(m)) return 'autunno'
  return 'inverno'
})()]: 'ogni 5 giorni' } } }

// programma automatico attivo, dovuta (mai registrata prima) -> true
assert.strictEqual(
  irrigazioneDaRegistrareOggi({ ultima_cura: {} }, null, { programmaAutomatico: 3 }),
  true
)
// programma automatico attivo, NON ancora dovuta (registrata ieri, ogni 3 giorni) -> false
assert.strictEqual(
  irrigazioneDaRegistrareOggi({ ultima_cura: { irrigazione: giorniFa(1) } }, null, { programmaAutomatico: 3 }),
  false
)
// programma automatico attivo, dovuta (registrata 3 giorni fa, ogni 3 giorni) -> true
assert.strictEqual(
  irrigazioneDaRegistrareOggi({ ultima_cura: { irrigazione: giorniFa(3) } }, null, { programmaAutomatico: 3 }),
  true
)
// nessuna sospensione (né pioggia né automatico) -> sempre false, anche se scaduta da tempo
assert.strictEqual(
  irrigazioneDaRegistrareOggi({ ultima_cura: { irrigazione: giorniFa(30) } }, specieConCadenza, {}),
  false
)
// pioggia in arrivo, esterna, dovuta secondo la specie (mai registrata) -> true
assert.strictEqual(
  irrigazioneDaRegistrareOggi({ ultima_cura: {} }, specieConCadenza, { esterno: true, meteo: [{ pioggia: 10 }, { pioggia: 0 }] }),
  true
)
// pioggia in arrivo ma NON esterna -> false (la sospensione da pioggia vale solo all'aperto)
assert.strictEqual(
  irrigazioneDaRegistrareOggi({ ultima_cura: {} }, specieConCadenza, { esterno: false, meteo: [{ pioggia: 10 }, { pioggia: 0 }] }),
  false
)
// pianta in acqua -> sempre false anche con automatico attivo e mai registrata
assert.strictEqual(
  irrigazioneDaRegistrareOggi({ coltivato_in: 'acqua', ultima_cura: {} }, null, { programmaAutomatico: 1 }),
  false
)
// automatico attivo ma senza intervallo utilizzabile (0/null) -> false
assert.strictEqual(
  irrigazioneDaRegistrareOggi({ ultima_cura: {} }, null, { programmaAutomatico: null, esterno: false }),
  false
)

console.log('OK')
```

Run: `node src/composables/verifica-registrazione-automatica.tmp.mjs`
Expected: stampa `OK`. Poi cancella il file (`rm src/composables/verifica-registrazione-automatica.tmp.mjs`) — non va committato.

- [ ] **Step 5: Commit**

```bash
git add src/composables/useCure.js
git commit -m "$(cat <<'EOF'
useCure: aggiunge irrigazioneDaRegistrareOggi per la registrazione automatica

Funzione pura e separata da valutaCura() (che resta invariata): decide se
un'irrigazione sospesa da pioggia o da un programma automatico sarebbe
comunque dovuta oggi — usata dal prossimo commit per scrivere ultima_cura
da soli invece di continuare a mostrare il promemoria manuale.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```

---

### Task 2: Registrazione automatica in `stores/dati.js`

**Files:**
- Modify: `src/stores/dati.js`

**Interfaces:**
- Consuma: `irrigazioneDaRegistrareOggi` (Task 1); `programmaIrrigazioneEffettivo` da `@/composables/useIrrigazioneAuto` (esistente, già usato altrove nell'app, non toccarlo); `store.piante`/`store.specie`/`store.zone`/`store.programmiIrrigazione`/`store.meteo` (già tutti popolati a questo punto di `eseguiCaricamento()`).
- Produce: nessuna interfaccia nuova per altri task — chiude la funzionalità.

- [ ] **Step 1: Import**

In `src/stores/dati.js`, in cima al file, aggiungere agli import esistenti:

```js
import { irrigazioneDaRegistrareOggi } from '@/composables/useCure'
import { programmaIrrigazioneEffettivo } from '@/composables/useIrrigazioneAuto'
```

- [ ] **Step 2: Il nuovo passaggio, dopo il caricamento del meteo**

In `eseguiCaricamento()`, subito dopo la riga esistente `meteo.value = giorni.value` (l'ultima istruzione prima del `catch` esterno), aggiungere:

```js
      meteo.value = giorni.value

      // Irrigazione sospesa (pioggia prevista o programma automatico) ma
      // comunque dovuta oggi: la registriamo da soli invece di continuare a
      // segnalarla come cura da fare — l'utente ha già delegato quella
      // decisione scegliendo un programma automatico, o la pioggia la copre
      // di fatto. Gira una sola volta per sessione (stessa guardia di
      // caricaTutto()), dopo che piante/specie/zone/programmi/meteo sono
      // tutti pronti. Try/catch proprio: un fallimento di rete isolato qui
      // non deve trasformarsi in un errore che nasconde dati già caricati
      // con successo (stesso principio già applicato al meteo qui sopra).
      try {
        const daRegistrare = []
        for (const [id, p] of Object.entries(piante.value)) {
          const sp = specie.value?.[p.specie] ?? null
          const programmaAutomatico = programmaIrrigazioneEffettivo(id, p.zona, p.sottozona, programmiIrrigazione.value)?.ogniGiorni ?? null
          const esterno = zone.value?.[p.zona]?.tipo === 'esterno'
          if (irrigazioneDaRegistrareOggi(p, sp, { programmaAutomatico, esterno, meteo: meteo.value })) {
            daRegistrare.push(id)
          }
        }
        if (daRegistrare.length) {
          const oggiStr = new Date().toISOString().split('T')[0]
          await Promise.all(daRegistrare.map(async id => {
            const ultima_cura = { ...(piante.value[id].ultima_cura ?? {}), irrigazione: oggiStr }
            const { error } = await supabase.from('piante').update({ ultima_cura }).eq('id', id)
            if (error) throw error
            piante.value = { ...piante.value, [id]: { ...piante.value[id], ultima_cura } }
          }))
        }
      } catch (e) {
        console.error('Registrazione automatica irrigazione fallita:', e)
      }
```

- [ ] **Step 3: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 4: Verifica manuale nel browser**

Con `npm run dev` avviato e sessione autenticata (nota: questo scrive per davvero su Supabase, non c'è un database di test separato — vedi Global Constraints):

1. Scegli una pianta esterna con una specie che ha `manutenzione.irrigazione` per la stagione corrente, senza programma automatico attivo. Impostane `ultima_cura.irrigazione` a una data abbastanza vecchia da risultare scaduta (via scheda pianta, o direttamente su Supabase per il test). Se secondo `/meteo` è prevista pioggia sufficiente (`SOGLIA_PIOGGIA_MM`), ricarica l'app: la pianta deve ora avere `ultima_cura.irrigazione` aggiornata a oggi, e la sua riga in Home/Attività non deve più comparire come urgente (comportamento visibile identico a prima — cambia solo cosa succede sotto).
2. Scegli una pianta coperta da un programma automatico (pianta/zona/sottozona) il cui intervallo risulti già scaduto rispetto a `ultima_cura.irrigazione`. Ricarica l'app: `ultima_cura.irrigazione` deve aggiornarsi a oggi.
3. Scegli una pianta coperta da un programma automatico ma NON ancora dovuta (es. `ultima_cura.irrigazione` di ieri, programma "ogni 5 giorni"). Ricarica l'app: `ultima_cura.irrigazione` NON deve cambiare.
4. Verifica che una pianta senza pioggia in arrivo e senza programma automatico continui a comportarsi esattamente come prima di questo piano (nessuna scrittura automatica, il promemoria manuale resta l'unico modo per registrarla).
5. Verifica che il caricamento dello store non si rompa se una delle scritture fallisse (difficile da simulare direttamente; almeno conferma a lettura di codice che il try/catch è posizionato correttamente attorno al solo blocco nuovo, non attorno a tutto `eseguiCaricamento()`).

- [ ] **Step 5: Commit**

```bash
git add src/stores/dati.js
git commit -m "$(cat <<'EOF'
Store: registra da sola l'irrigazione sospesa ma dovuta

Al caricamento, dopo meteo e programmi: per ogni pianta la cui
irrigazione è sospesa da pioggia prevista o da un programma automatico
ma sarebbe comunque dovuta oggi, scrive ultima_cura.irrigazione invece
di lasciare solo il promemoria manuale. Try/catch proprio, non blocca il
resto del caricamento in caso di fallimento di rete isolato.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01DufXBNju4XxaesDYnfWBC9
EOF
)"
```
