# Attività ↔ scheda pianta — allineamento · Nota di esito

Branch: `attivita-allineamento` · `7909247`..`ee6ac96` (5 commit impl + 1 fix review). Subagent-driven: review per-task su Task 1 e 2; Task 3 e 4 controller-adjudicated (diff piccoli, verbatim del brief) e coperti dalla **review finale whole-branch su Opus** ("with fixes" — 1 Important, poi risolto). `npm run build` verde a ogni passo. **Non ancora mergiato** — decide Rob dopo il QA.

## Fatto

| Commit | Cosa |
|---|---|
| `7909247` | **`useCureVisual.js`** nuovo — `ICONE_CURA`/`LABEL_CURA`/`iconaCura` + `ICONE_ESIGENZA`/`iconaEsigenza`/`capitalizza` (prima triplicate in PiantaView, AttivitaRiga, SelettoreSpecie; `calcio` → `'uovo'`). `.care-act*` + `.feed-nb` da PiantaView scoped → `main.css`. PiantaView e SelettoreSpecie importano dal composable. |
| `64baee0` + `2747b24` | **`DossierPianta.vue`** nuovo — props `{ piantaId }`; rende "Stato cure" (con "Fatto" per tipo) / "Concimi consigliati" / "Esigenze" (icone acquerellate) / "Note tecniche" / "Note" / link, sulle classi condivise. Computeds portati 1:1 dal vecchio pannello accordion di `AttivitaRiga` (verificato verbatim dalla review finale). Contenuto sotto `<template v-if="pianta">`. |
| `965be3d` | **`AttivitaRiga.vue`** 182 → 46 righe — via l'accordion (`espansa`, `grid-template-rows`, chevron, `TINTE_CURA`, `cardStyle`/`iconStyle`/`labelStyle`); riga piatta; `@click` sul corpo → `emit('apri-dossier', item)`; "✓ Fatto" invariato (`@click.stop` → `emit('registra', item)`). |
| `03ae0de` | **`AttivitaGruppoZona`** inoltra `apri-dossier`. **`AttivitaView`** monta **un solo** `<FoglioLaterale :model-value="!!dossierItem" …>` con `<DossierPianta v-if="dossierItem">`, fratello di `<template v-else>` (fuori dal `<Transition>` — non si rimonta al cambio tab); `@apri-dossier="apriDossier"` su entrambi i gruppi. Righe tab "Progetti": da `.card` + ternari `style` a `.tappa-riga` con filetto. `.slabel` "Da fare"/"In scadenza" da `<p style="display:flex…">` a `<div class="slabel">`. |
| `ee6ac96` | **Fix review finale:** `.notelist`/`.notelist li` da PiantaView scoped → `main.css` (le usa anche il "Note tecniche" di DossierPianta — il piano le dava per globali ma non lo erano; renderizzava coi default del browser). `<p v-else>` in DossierPianta se la pianta è sparita dallo store. `role="button"`/`tabindex`/`@keydown.enter` sulla riga di AttivitaRiga (affordance da tastiera). |

## Da guardare nel QA browser — differenze visive **volute** (non bug)

- Il tap su una riga in "Attività" (tab Irrigazione/Concimi) ora apre un **foglio** (da destra su desktop, dal basso su mobile) invece dell'accordion inline. "✓ Fatto" sulla riga registra al volo **senza** aprire il foglio.
- Nel foglio, rispetto al vecchio pannello: il calcio ha l'**icona uovo** (era `provetta`); le tessere icona usano `--acqua-bg`/`--olive-bg`/`--carta-2` (erano `--*-tile`); i nomi cura vengono da `LABEL_CURA` (non più `{{ tipo }}` capitalizzato via CSS); lo stato "terminato" dei concimi è la pill testuale `.feed__tag` (non più l'icona `allerta`); le sezioni **zona**, **"Note tecniche"** e **"Note"** sono **nuove** (l'accordion non le aveva). "Esigenze" ora compare solo se ci sono davvero voci (prima poteva mostrare l'intestazione vuota).
- Tab "Progetti": righe con filetto (icona lampadina in tessera oro / rosa se urgente), non più card.
- `PiantaView → "Stato cure"`: identico a prima salvo il calcio con l'icona uovo su tessera beige (le `.care*`/`.notelist` ora arrivano da `main.css`).

## Follow-up minori / debito

- `DossierPianta.vue` è riusabile — candidato per un futuro "apri pianta al volo" da altre viste.
- `AttivitaView` skeleton resta `.card` (coerente con gli altri skeleton).
- `useCureVisual.js` non è un vero composable (costanti/funzioni pure), ma il nome è coerente col piano — nessuna azione.
- `ConcimiView.vue:201` ha un commento datato che cita `.care-act` "in PiantaView" (ora in `main.css`) — fuori scope, da sistemare in un passaggio futuro.
- Rollout di `FoglioLaterale` alle restanti modali centrali (ProgettiView/ConcimiView/SottozoneView/EditPianta/ModalConferma/dettaglio Meteo) — batch a parte.
- Migration per chiudere la RLS di scrittura su `specie` — round dedicato (dal redesign selettore specie).

## Fuori scope (round successivi)

- **Fase 3**: dark mode (interruttore in Impostazioni).
- **Fase 4**: velatura stagionale dell'hero.
