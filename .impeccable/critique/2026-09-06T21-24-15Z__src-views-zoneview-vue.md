---
target: ZoneView
total_score: 21
max_score: 40
na_heuristics: 
p0_count: 2
p1_count: 1
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/ZoneView.vue"
target_fingerprint: "sha256:f7e8348cc173bf69e766e1cf8d91b826925caa21b3a7044b9c7c602605c8d985"
target_path: /Users/rob/Sites/localhost/giardino/src/views/ZoneView.vue
timestamp: 2026-09-06T21-24-15Z
slug: src-views-zoneview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Skeleton loading + save/delete spinners, ma nessuna conferma positiva dopo un salvataggio riuscito oltre alla chiusura del foglio |
| 2 | Match System / Real World | 3 | Vocabolario da giardino corretto (zona/sottozona/esposizione/microclima), indebolito da 45 glifi icona astratti senza appiglio nel mondo reale |
| 3 | User Control and Freedom | 3 | Annulla/Esc chiudono foglio e modale; ma un'eliminazione fallita non lascia un percorso di retry immediato |
| 4 | Consistency and Standards | 1 | Viola la Regola del Nome in Fraunces sul nome zona; non riusa il pattern `errore` di `ModalConferma` già usato in PianteView per lo stesso scenario |
| 5 | Error Prevention | 2 | Buon guard su nome duplicato prima del salvataggio, ma il caso più comune di blocco eliminazione (zona con piante) non è anticipato nel testo di conferma |
| 6 | Recognition Rather Than Recall | 1 | Selettore di 45 icone monocolore, 18px, senza etichette né raggruppamento, nonostante le categorie esistano già nel codice sorgente |
| 7 | Flexibility and Efficiency | 2 | Nessun riordino zone, nessuna azione bulk; una semplice rinomina ricarica l'intero store |
| 8 | Aesthetic and Minimalist Design | 3 | Composizione pulita e pattern a filetti corretto, ma stile inline duplicato invece di classi condivise |
| 9 | Error Recovery | 2 | Errore nome duplicato ben posizionato inline; errore di eliminazione bloccata isolato in un banner scollegato dalla riga/modale |
| 10 | Help and Documentation | 1 | Due icone hanno `title`/`aria-label`, i 45 pulsanti del selettore icone no |
| **Total** | | **21/40** | **Acceptable** |

## Design Specificity Verdict

**LLM assessment**: La schermata è costruita con il vocabolario proprio del prodotto, non con componenti generici — riusa il sistema di icone ad acquerello per dominio (`useIconeZona.js` → `IconDefs.vue`, silhouette piena + ellisse "-dark" clippata), il pattern a filetti `.destlist/.dest` invece di card impilate, il `FoglioLaterale`, e i ruoli colore sage/rosa/ghost esattamente come prescritto. Questo è un radicamento reale e verificabile — un'app CRUD generica non avrebbe questo sistema di icone né questo trattamento delle liste. Ma la vista viola la regola più codificata e non negoziabile del sistema proprio per il contenuto che quella regola protegge: il nome della zona (`.dest__n zname`, ZoneView.vue:30) usa DM Sans (`main.css:424`, `.dest__n` = `font:600 13.5px/1.2 var(--font-sans)`), non Fraunces. "La Regola del Nome in Fraunces" dice esplicitamente che ogni nome, a qualunque dimensione, deve essere Fraunces, mai DM Sans. Verdetto: specifica nei materiali, ma infrange la propria legge dove conta di più (i nomi propri) — una regressione silenziosa su una regola documentata, non un'assenza di identità.

**Deterministic scan**: `impeccable detect --json` su ZoneView.vue è uscito con **exit code 0** (nessun blocco), ma con **2 findings advisory**:
- `design-system-font-size` — riga 8: `font-size: 12px` fuori dalla scala tipografica di DESIGN.md.
- `design-system-radius` — riga 63: `border-radius: 10px` fuori dalla scala raggi di DESIGN.md (che va da 6px a 999px per step documentati; 10px non è uno step).

Nota di sintesi: la riga 63 flaggata dal detector per il raggio cade nella stessa area di template in cui l'Assessment A colloca il selettore di 45 icone (righe 63-69) — coerente con il fatto che quella porzione di UI non riusa i token di sistema (`{rounded.chip}`/`{rounded.tag}`) ma valori inline ad hoc, esattamente il problema di "stile inline duplicato" segnalato indipendentemente dalla review qualitativa. I due strumenti, lavorando in isolamento, hanno convertito sullo stesso punto debole da due angolazioni diverse.

**Visual overlays**: non disponibili in questa sessione — nessuno strumento di automazione browser (Playwright/Puppeteer/canvas nativo) è esposto; il live-server e l'iniezione di script sono stati saltati per la regola di fallback. Nessuna evidenza visiva a schermo per questo run.

## Overall Impression

ZoneView.vue è tecnicamente e strutturalmente uno dei membri più coerenti della famiglia di viste (icone di dominio corrette, pattern a filetti corretto, gestione ragionata del caso di eliminazione bloccata da FK) — ma è anche la vista che, tra quelle esaminate, si allontana di più dalla propria legge tipografica proprio sull'elemento che dovrebbe incarnarla (il nome della zona), e che concentra quasi tutto il carico cognitivo della schermata in un singolo selettore di icone sovradimensionato e inaccessibile. La singola opportunità più grande: il selettore di 45 icone è insieme il peggior problema di accessibilità, di riconoscimento e di carico cognitivo della vista — risolverlo (etichette + eventuale set curato) vale più di ogni altro intervento isolato.

## What's Working

- **Riuso corretto del linguaggio icone ad acquerello di dominio** — silhouette piena + ellisse "-dark" clippata al 40% (IconDefs.vue:234-237, richiamata via `store.iconaZona()` a ZoneView.vue:29), non un'icona outline generica.
- **Gestione reale del caso limite distruttivo**: il fallimento di eliminazione per FK-restrict viene intercettato, spiegato in italiano semplice, con un commento nel codice che lo contrappone esplicitamente al vecchio comportamento su JSON che orfanizzava le piante in silenzio (ZoneView.vue:254-266).
- **Applicazione corretta del pattern "liste con filetti"**: le zone sono righe hairline dentro `.destlist`, non incapsulate in card individuali (ZoneView.vue:26-43) — coerente con l'anti-pattern esplicitamente vietato dal sistema (doppia gerarchia di contenimento).

## Priority Issues

**[P0] Il nome della zona è in DM Sans, non in Fraunces**
- **Perché è importante**: viola direttamente la regola più netta e ripetuta del sistema ("mai DM Sans per i nomi, nemmeno a dimensioni piccole") — proprio sul contenuto che quella regola esiste per proteggere. Indebolisce l'identità "taccuino, non dashboard" nel punto in cui dovrebbe essere più forte.
- **Fix**: dare a `.zname` (o a una nuova variante `.dest__n--nome`) `font-family: var(--font-display)`, oppure smettere di condividere `.dest__n` tra etichette generiche di navigazione (tile Home) e nomi propri reali.
- **Dove**: ZoneView.vue:30, main.css:424.
- **Comando suggerito**: `/impeccable typeset`

**[P0] I 45 pulsanti del selettore icone non hanno nome accessibile**
- **Perché è importante**: per chi usa uno screen reader non è un degrado, è inutilizzabile — ogni pulsante annuncia solo "button", indistinguibile dagli altri 44 (violazione WCAG 4.1.2).
- **Fix**: aggiungere `:aria-label="nome"` (o un `title`, stesso pattern già usato due righe sopra per matita/elimina) a ogni pulsante icona.
- **Dove**: ZoneView.vue:64-68.
- **Comando suggerito**: `/impeccable audit`

**[P1] L'errore di eliminazione bloccata è scollegato dall'interazione**
- **Perché è importante**: `ModalConferma` supporta già una prop `errore` che tiene il dialogo aperto con il messaggio inline (usata correttamente in PianteView.vue:92-98), ma ZoneView chiude subito il modale (`daEliminare.value = null`, ZoneView.vue:262) e mostra il messaggio in un banner fisso in cima alla pagina (ZoneView.vue:8-10). Su una lista più lunga di uno schermo, chi ha cliccato elimina sulla sesta riga non vede alcun feedback a meno di risalire con lo scroll — l'azione distruttiva fallita sembra non aver fatto nulla.
- **Fix**: passare `:errore="erroreEliminazione"` a `ModalConferma` e non azzerare più `daEliminare` in caso di errore, rispecchiando esattamente il pattern di PianteView.
- **Dove**: ZoneView.vue:8-10, 254-266.
- **Comando suggerito**: `/impeccable clarify`

**[P2] `tipo` ed `esposizione` sono raccolti nel form ma mai mostrati nella lista**
- **Perché è importante**: la vista gemella SottozoneView.vue:23,29 mostra inline gli stessi campi sulle sottozone; qui l'utente compila "esterno/interno" ed esposizione cardinale e non li rivede più senza riaprire il foglio di modifica — un buco di architettura informativa reso evidente dal confronto con la schermata quasi identica.
- **Fix**: mostrare `tipo` come piccolo tag ed `esposizione` inline in `.zrow__desc`, stesso trattamento di SottozoneView.
- **Dove**: ZoneView.vue (vista di riga, confronto SottozoneView.vue:23,29).
- **Comando suggerito**: `/impeccable layout`

**[P2] Lo stato vuoto iniziale non ha una call-to-action inline**
- **Perché è importante**: poiché non si può creare una pianta senza una zona, questo è di fatto il primo vero schermo per ogni nuovo account multi-tenant — eppure è l'unico stato vuoto dell'app privo del pattern CTA-inline già usato altrove (PianteView.vue:80-85 include un pill "+ Aggiungi una pianta" dentro il blocco vuoto stesso).
- **Fix**: aggiungere lo stesso pill "+ Aggiungi una zona" dentro lo stato vuoto, che richiama `apriNuovo()`.
- **Dove**: ZoneView.vue:21-24.
- **Comando suggerito**: `/impeccable onboard`

## Cognitive Load

Checklist (8 voci): 3 pass / 5 fail.
- Fuoco singolo: **pass** — la lista ha un solo scopo, il foglio prende il controllo in modo modale.
- Chunking ≤4 per gruppo: **fail** — il selettore icone presenta 45 opzioni piatte senza raggruppamento visivo.
- Raggruppamento elementi correlati: **parziale** — i campi del form sono etichettati e separati, ma la griglia icone è una massa indifferenziata.
- Gerarchia visiva: **pass** — titolo, lista primaria, azioni secondarie attenuate si leggono in quell'ordine.
- Una decisione alla volta: **fail** — il foglio nuovo/modifica espone 6 decisioni concorrenti (nome, tipo, descrizione, microclima, icona, esposizione) senza sequenza, con solo "nome" marcato come obbligatorio.
- ≤4 opzioni visibili per punto di decisione: **fail** — il selettore icone (45) supera il budget di un ordine di grandezza.
- Carico di memoria di lavoro: **fail** — tutte le icone zona nella lista sono nella stessa tinta monocroma a 26px, il che rende difficile ricordare quale icona è stata scelta per quale zona.
- Divulgazione progressiva: **fail** — nessun collasso dei campi secondari (microclima, esposizione, icona) dietro un "altro" per il caso comune di nominare rapidamente una zona.

Verdetto: la lista in sé è calma e a basso carico; quasi tutto il peso cognitivo vive nel selettore icone, sproporzionato per un campo decorativo modificato di rado.

## Emotional Journey

L'arrivo sulla lista è quieto e coerente col brand — nessuna urgenza, righe hairline, niente che compete per l'attenzione, in linea con l'atmosfera "fine giornata in giardino". Ma la vista è emotivamente piatta più che calda: a differenza della Home, non c'è alcun tocco di Zorba, nessun momento disegnato a mano — accettabile per una superficie CRUD in modalità Operate, ma significa che la vista non accumula nulla per il lato "picco" della regola picco-fine. La vera valle è l'eliminazione di una zona che contiene ancora piante: il dialogo di conferma sottostima il rischio reale (avvisa delle sottozone collegate, non del blocco più probabile per piante presenti), l'azione fallisce, e la spiegazione appare come un piccolo paragrafo in cima alla pagina mentre il modale è già sparito — per chi ha scrollato per raggiungere la zona da eliminare, la risoluzione di un'azione distruttiva stressante è di fatto invisibile. Un momento ad alto rischio che finisce con un sussurro, esattamente dove servirebbe più rassicurazione — ed è risolvibile con un meccanismo già presente e inutilizzato in `ModalConferma` (prop `errore`).

## Persona Red Flags

**Jordan (primo utilizzo)**: atterra su una lista Zone vuota senza CTA nello stato vuoto (deve individuare il piccolo pill in intestazione — vedi P2); aprendo il foglio "nuova zona" vede cinque campi senza indizi obbligatorio/opzionale a parte l'asterisco su Nome, quindi deve indovinare se tipo/descrizione/microclima/esposizione/icona contano prima di salvare; il testo di avviso dell'eliminazione ("verranno eliminate anche le sottozone collegate") è gergo confuso per chi non ha ancora creato una sottozona.

**Sam (dipendente da accessibilità)**: il selettore icone è un muro invalicabile — 45 pulsanti senza nome (P0 sopra); il banner di errore eliminazione non ha `aria-live`, quindi chi usa uno screen reader e conferma un'eliminazione bloccata non riceve alcun feedback vocale che sia successo qualcosa, dato che il dialogo su cui era focalizzato semplicemente scompare.

**Riley (stress tester)**: rinominare "Est" in "est" (solo maiuscole/minuscole) supera il guard anti-duplicato di ZoneView.vue:178 perché il controllo è un lookup case-sensitive su chiave oggetto, producendo silenziosamente due zone quasi identiche; una navigazione rapida su due tab mentre si rinomina in una potrebbe lasciare l'altra a eliminare con una chiave zona ormai obsoleta (nessuna sincronizzazione realtime nello store).

## Minor Observations

- "N piante" resta sempre plurale anche per 1 ("1 piante" è agrammaticale in italiano) — ZoneView.vue:31; lo stesso bug è duplicato in SottozoneView.vue:24, quindi è sistemico.
- L'azione di eliminazione usa un glifo "×" nudo (ZoneView.vue:40) accanto a un'icona ad acquerello "matita" corretta (riga 38) nella stessa riga di azioni — una scelta di iconografia incoerente in un'unica riga.
- `descrizioneZona()` (ZoneView.vue:238-240) mostra `descrizione` OPPURE `microclima`, mai entrambi — se una zona ha entrambi compilati, il microclima diventa permanentemente invisibile fuori dal foglio di modifica.
- Uso pesante di attributi `style=` inline nel template (righe 63, 71-77, 79-84) dove esistono già classi condivise in main.css — un odore di manutenibilità/coerenza, confermato indipendentemente dal detector (riga 63, raggio fuori scala).

## Questions to Consider

- Se la regola Fraunces-per-i-nomi è non negoziabile ovunque altrove, perché l'unica classe condivisa `.dest__n` serve sia etichette anonime di tile di navigazione (Home) sia nomi propri reali (Zone/Sottozona) — ed è questa confusione la causa radice da correggere una volta per tutte a livello di sistema, invece che rattoppare la sola ZoneView?
- Dato che `ModalConferma` ha già una prop `errore` costruita e usata correttamente in PianteView, il banner in cima alla pagina di ZoneView (e SottozoneView) è stata una divergenza intenzionale, o le due schermate semplicemente non hanno ricevuto il promemoria che esiste già un pattern migliore nel codebase?
- Un selettore di 45 icone, monocolore e senza etichette, sta davvero rendendo il suo valore come campo "decorativo", o l'app (e Sam, e Jordan) sarebbero meglio serviti da un set curato molto più piccolo di default, con le 45 icone complete dietro una divulgazione "altre icone"?
