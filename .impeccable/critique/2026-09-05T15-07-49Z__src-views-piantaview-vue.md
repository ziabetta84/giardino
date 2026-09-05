---
target: Scheda pianta (src/views/PiantaView.vue)
total_score: 29
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 0
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/PiantaView.vue"
target_fingerprint: "sha256:a8b1421731ffe3b1c80a0a237a5c25cd24d60b6f83a9e895dd544626a064d796"
target_path: /Users/rob/Sites/localhost/giardino/src/views/PiantaView.vue
timestamp: 2026-09-05T15-07-49Z
slug: src-views-piantaview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Euristica | Punteggio | Nodo specifico |
|---|-----------|-------|-----------------|
| 1 | Visibilità dello stato del sistema | 3 | Spinner + messaggi d'errore per tutti e tre i flussi; manca `aria-live` sui nuovi messaggi |
| 2 | Corrispondenza sistema/mondo reale | 4 | Terminologia orticola naturale, ordine informativo coerente |
| 3 | Controllo e libertà dell'utente | 3 | Esc, click-fuori, Annulla sempre disponibili anche dopo un errore |
| 4 | Coerenza e standard | 2 | Risolto internamente, ma ora tre pattern diversi convivono a livello app per "eliminazione fallita" (nessuno in ConcimiView/GalleryView, banner-pagina in ZoneView/SottozoneView, messaggio-nel-modale qui) |
| 5 | Prevenzione errori | 3 | Conferma dinamica pluralizzata, bottoni disabilitati durante il salvataggio |
| 6 | Riconoscimento anziché ricordo | 4 | I 4 nuovi sottogruppi eliminano il muro di dati precedente |
| 7 | Flessibilità ed efficienza d'uso | 2 | Nessuna azione bulk, nessuna scorciatoia oltre l'attivazione da tastiera appena aggiunta |
| 8 | Estetica e design minimalista | 4 | Rimozione duplicazione + raggruppamento kv rinforzano direttamente questo asse |
| 9 | Aiutare a riconoscere/recuperare errori | 3 | Messaggi vicini al controllo fallito, stato preservato per retry immediato; nessun `aria-live` |
| 10 | Aiuto e documentazione | 1 | Nessun aiuto contestuale su NPK/consociazioni, invariato |
| **Totale** | | **29/40** | **Buono** (miglioramento da 25/40) |

## Design Specificity Verdict

Confermato ancorato a DESIGN.md: watermark Zorba al 7% dietro "La specie", pallini colorati per dominio di cura, credito Wikimedia con licenza, `.care-act--rose` riusato come pattern canonico invece di una seconda implementazione. I fix hanno rinforzato la specificità riusando token esistenti (`.field-label`, `.btn/.btn-rose/.btn-ghost`) invece di introdurre pattern generici da SaaS.

Scansione deterministica: pulita, 0 anti-pattern reali su 5 file (solo 4 advisory di micro-drift tokenizzazione già note dal run precedente). Nessuna regressione sui 5 altri consumer di `ModalConferma` (nessuno passa `:errore`, retrocompatibile). Verificato via lettura diretta del codice attuale: tutti e 6 i fix confermati implementati correttamente, con due effetti collaterali emersi solo ora (vedi Priority Issues).

## Overall Impression

I 6 fix hanno funzionato: la duplicazione dell'azione cura è sparita, i salvataggi/eliminazioni non falliscono più in silenzio, la galleria è raggiungibile da tastiera, il bottone distruttivo rispetta lo standard, il colore urgenza è sempre corretto, "La specie" non è più un muro di dati. Il punteggio sale da 25 a 29/40. Restano problemi di secondo ordine, tipici di un fix locale ben fatto che non si è propagato al resto dell'app: la gestione errori appena introdotta qui non è ancora lo standard applicato ovunque, il focus da tastiera sulla galleria rischia di essere invisibile per via dell'`overflow:hidden` del contenitore, e il contrasto di `--rose-dark` come testo (usato ora in 3 punti nuovi) è sotto la soglia AA in light mode.

## What's Working

- `.care-act--rose` applicato per-riga (PiantaView.vue:82): implementazione pulita del pattern canonico, zero duplicazione di stato.
- `messaggioEliminaPianta`: copy dinamica pluralizzata che cita le foto coinvolte — prevenzione errori concreta.
- Sottogruppi di "La specie" (Identità/Tempistiche/Semina e spaziatura/Consociazioni): riuso intelligente di `.field-label` esistente, soluzione chirurgica al sovraccarico.
- `try/catch/finally` verificato corretto end-to-end nei tre flussi (errore impostato solo in catch, sempre pulito in finally, nessuno stato bloccato).

## Priority Issues

**[P2] Contrasto AA non rispettato per `--rose-dark` come testo in light mode.**
`.care__d--urgente`, `.care__d--err`, `.mc-errore`, `.care-act--rose` usano tutti `--rose-dark` (#b85f5f) su sfondo chiaro (`--cream`/`--white`): contrasto calcolato 4.06–4.34:1, sotto la soglia AA 4.5:1 per testo normale (nessuna di queste dimensioni, 10.5-12px, qualifica come "testo grande"). Dark mode è a posto (8.6:1+). Non è una regressione isolata (`.badge-warn` ha lo stesso limite preesistente), ma i fix hanno esteso lo stesso pattern sotto-soglia a 3 nuovi punti.
Fix: scurire leggermente `--rose-dark` in light mode, o riservare il testo colorato a dimensioni ≥14px/bold.

**[P2] Indicatore di focus da tastiera probabilmente invisibile in galleria.**
`.gslide` non ha alcuno stile `:focus-visible` dedicato, e il contenitore `.phead-photo{overflow:hidden}` rischia di tagliare l'anello di focus di default del browser (la figure riempie esattamente il contenitore, nessun margine). L'attivazione da tastiera funziona (verificato), ma potrebbe non essere mai visibile quale foto sia a fuoco.
Fix: `box-shadow` interno o `outline-offset` negativo su `.gslide:focus-visible` che resti dentro il clip.

**[P2] Gestione errori di eliminazione incoerente a livello di app.**
Il pattern appena introdotto qui (errore nel modale, che resta aperto) non è ancora applicato a `ConcimiView.vue`/`GalleryView.vue` (stesso bug `try/finally` senza `catch` mai corretto) né a `ZoneView.vue`/`SottozoneView.vue` (terzo pattern: banner in pagina, modale chiuso). Un utente oggi ha 4 esperienze diverse in caso di fallimento a seconda di cosa sta eliminando.
Fix: propagare il pattern `errore` di `ModalConferma` a `ConcimiView`/`GalleryView`; valutare se migrare anche `ZoneView`/`SottozoneView`.

**[P3] `.care-act` può scendere sotto i 44px di larghezza nello stato di caricamento.**
`.care-act` garantisce solo `min-height: 44px`, nessun `min-width`. Nello stato di salvataggio il contenuto è solo `<Spinner>` (~10.5px): larghezza stimata ~36-37px con padding, sotto il target di tocco durante il breve intervallo di salvataggio. `.lightbox__btn` invece è fisso 44×44px — standard non uniforme tra i due componenti.
Fix: `min-width: 44px` su `.care-act`.

**[P3] Segnale di urgenza debole e non ordinato in cima.**
`tipiCura` mantiene un ordine fisso indipendente da quali cure sono urgenti; con l'alertbox rimosso, l'unico segnale è testo/bordo `--rose-dark` sottile — nessun riepilogo aggregato, nessuna promozione delle righe urgenti in cima all'elenco.
Fix: ordinare `tipiCura` mettendo le urgenti per prime.

## Persona Red Flags

**Casey (mobile, in giardino alla luce del sole)**: nessuna riga urgente promossa in cima — deve scansionare tutto l'elenco; il segnale è solo testo/bordo rosa sottile, facile da perdere rispetto al vecchio box colorato.

**Sam (screen reader/tastiera)**: foto galleria ora raggiungibili da tastiera ma senza focus visibile (rischio taglio da `overflow:hidden`); le 4 nuove intestazioni di sottogruppo sono `<span class="field-label">`, non intestazioni semantiche — la navigazione per intestazioni le salta interamente; un errore su "Fatto"/"Elimina" non è annunciato (nessun `aria-live`/`role="alert"`), rischio di credere che l'azione sia riuscita.

**Riley (tester metodico)**: `eliminaPianta()` esegue `eliminaCartella` poi `eliminaPianta` in un unico try — se il primo riesce e il secondo fallisce, un retry rilancia su una cartella già vuota, messaggio d'errore generico non distingue il caso.

## Minor Observations

- Il commento in `main.css:829-832` cita ancora "PiantaView 'Da curare subito'" come consumatore di `.alertbox`: non lo è più, documentazione da aggiornare.
- `.field-label` (600 peso/0.05em) non corrisponde al token Label di DESIGN.md (700/0.13em, rispettato invece da `.slabel`); riusarlo per intestazioni statiche di sola lettura rende più visibile questa piccola deriva.
- `catch {}` generico senza parametro d'errore: messaggio sempre identico indipendentemente dalla causa reale (rete, RLS, vincolo) — scelta difendibile per restare in linguaggio semplice, ma impedisce diagnosi migliori in futuro.

## Questions to Consider

- Vale la pena definire ora un pattern unico per "azione distruttiva fallita" (il modale-con-errore-inline appena introdotto) e applicarlo retroattivamente a ConcimiView/ZoneView/SottozoneView/GalleryView, prima che nascano più varianti?
- Le nuove intestazioni di sottogruppo in "La specie" meriterebbero elementi di intestazione veri (anche solo visivamente identici) per dare a chi naviga con screen reader la stessa scansionabilità appena regalata a chi vede lo schermo?
- Se il colore è l'unico segnale di urgenza rimasto, ha senso ordinare le cure in ritardo in cima all'elenco?
