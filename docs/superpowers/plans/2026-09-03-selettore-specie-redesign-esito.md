# Selettore specie — redesign · Nota di esito

Branch: `restyle-taccuino-batch4` · redesign in `c9ff5e2`..`6f92ca7` (4 commit impl + piano). Subagent-driven: 4 task + review per task (Task 1/3 controller-adjudicated, Task 2/4 review completa). `npm run build` verde a ogni task e sul branch. `grep` di regressione su `SelettoreSpecie.vue` → nessun residuo della modale. **Non ancora mergiato** — decide Rob dopo il QA nel browser.

> La history del branch contiene anche il vecchio pass meccanico "Batch 4" (`e3fc562`, poi la sua nota di esito rimossa in `9498ce0`): quelle 12 label passate a `.field-label` erano nella modale che il redesign **elimina**, quindi sono inerti. Innocuo, resta nella history.

## Fatto

| Commit | Cosa |
|---|---|
| `c9ff5e2` | `main.css`: classi **`.foglio*`** (foglio riusabile — bottom sheet <640px, laterale ≥640px, `prefers-reduced-motion`); blocco **`.care*` globalizzato** (era scoped in PiantaView) con `.care__ic--calcio` beige (`--carta-2`/`--ink-mid`), nuovo `.care__ic--npk` (`--sage-bg`/`--sage-ink`), `.care__d--none`. Copia del mockup nel repo. |
| `d05f9cc` | **Icona uovo per il Calcio** — `<symbol id="i-uovo">` + `clip-uovo` in `IconDefs.vue`, token `--uovo`/`--uovo-dark` (beige). `PiantaView` usa `ICONE_CURA.calcio: 'uovo'` e le `.care*` globali (rimosse dal suo `<style scoped>`, resta solo `.care-act*`). |
| `e46fae3` | **`FoglioLaterale.vue`** nuovo — componente foglio generico: `v-model`, `Teleport`, chiusura velo/Esc/×, scroll-lock del body, focus sul pannello, `#intestazione` slot opzionale. Nessuno `<style>` (classi globali). |
| `6f92ca7` | **`SelettoreSpecie.vue`** ridisegnato (+464/−717): **rimossa** tutta la modale nuova/modifica specie (3 tab) + il suo stato/handler/`usePianteApi`; dropdown raggruppato ("Nel tuo giardino" / "Nel catalogo") con miniatura per riga, niente matite, footer "Chiedi a Zorba a `/agente`"; card compatta post-scelta ("Vedi scheda completa" + "Cambia"); **dossier in sola lettura** dentro `<FoglioLaterale>` — descrizione, esigenze (`.kv` + icone acquerellate reali `sole`/`goccia`/`foglia`), **calendario cure** (pill stagioni + righe stile "Stato cure": icona colorata + valore per la stagione scelta; calcio con uovo su tessera beige; "Non prevista in questa stagione" quando vuoto), coltivazione, note tecniche con "+N altre". Filigrana `.specie-ghost`. Contratto `v-model` invariato → `EditPiantaView`/`AgenteView` non toccati. |
| `b0d5a7b` | **Fix review finale (Opus):** il `<FoglioLaterale>` ora è sempre montato (con `v-if="specieSelezionata"` interno) — prima si montava già "aperto" alla PRIMA scelta e non partivano scroll-lock / focus / Esc / slide. `FoglioLaterale`: `:inert` da chiuso (fuori dal tab-order/albero a11y) + ripristino del focus alla chiusura + `onMounted` che gestisce il mount-già-aperto. **Raggruppamento "Nel tuo giardino" per possesso reale** (`store.piante`, non più `stato_verifica`) + hint del dropdown riportato onesto. Minori: `.np-badge` col colore dello stato (`.badge-mini` cv/bz), `url()` quotato+escaped per gli URL Wikimedia esterni, `.foglio*` z-index 320/321 (non più in pari con `.agente-storico-menu`), `overscroll-behavior:contain`, guard su `hero.fontePagina`. |

## Da guardare nel QA browser

- **Foglio**: si apre alla scelta di una specie — da destra su desktop, dal basso su mobile; Esc / click sul velo / × chiudono; con *riduci animazioni* niente slide.
- **Dossier**: filigrana Zorba dentro il foglio; blocco hero foto (crop / velatura); pill stagioni che cambiano i valori delle righe cure; icona uovo del Calcio su tessera beige; "Non prevista in questa stagione".
- **`PiantaView` → "Stato cure"**: il Calcio ora con l'icona uovo su tessera beige (le `.care*` ora arrivano da `main.css`, il layout deve essere identico a prima).
- **Ricerca**: gruppi + miniature, footer "Chiedi a Zorba"; ricerca remota / offline / vuoto invariati; "Cambia" riapre la tendina.
- `EditPiantaView` salva la pianta; `AgenteView` invia "revisione specie".

## Sicurezza — da fare a parte (NON in questo giro)

Togliere l'UI di modifica specie **non chiude** la RLS di scrittura aperta ("temporanea") sulla tabella `specie` (vedi CLAUDE.md: "Da sostituire con policy basate su `auth.uid()` quando verrà implementato un vero login"). Ora il login c'è: serve una **migration** che restringa le policy di `INSERT`/`UPDATE` su `specie` (es. solo service-role / un ruolo curatore), lasciando la lettura pubblica. Round dedicato.

## Follow-up minori / debito

- **Rollout del pattern `FoglioLaterale`** alle altre modali centrali dell'app (ProgettiView, ConcimiView, SottozoneView, EditPianta, `ModalConferma`, dettaglio Meteo) — batch a parte.
- `SelettoreSpecie`: il markup di riga del dropdown è ripetuto 3× (gruppo posseduto / catalogo / lista piatta) — accorpabile in un `v-for` su un array `groups`.
- `.sc-th` (miniatura 44px nella card compatta) usa `hero.thumbUrl` (480px) — passare a `urlMiniatura(url, 96)`.
- `statoBadge` mostra "verificata" in minuscolo — capitalizzare o rendere una `.chip` come cultivar/bozza.
- `--uovo`/`--uovo-dark` senza override dark-mode (come le altre icone che in dark passano a `currentColor`) — da rivedere in Fase 3.
- Hint del dropdown a campo vuoto: riscritto (non solo restilizzato) per coerenza col label di gruppo "Nel tuo giardino".

## Fuori scope (round successivi)

- **Fase 3**: dark mode (interruttore in Impostazioni; `SettingsView` salva già `ui.theme`).
- **Fase 4**: velatura stagionale dell'hero della Home.
