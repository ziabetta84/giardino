---
target: GalleryView
total_score: 33
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/GalleryView.vue"
target_fingerprint: "sha256:062252169f2ae10b9a1af9648f294e6fa97fd79483d473bf3d9943d848a53d16"
target_path: /Users/rob/Sites/localhost/giardino/src/views/GalleryView.vue
timestamp: 2026-09-07T15-25-09Z
slug: src-views-galleryview-vue
---
Method: dual-agent (A: ad22bdcff86b9e061 · B: ad451fd4df5388105)

# Critique: GalleryView.vue — Album Polaroid redesign

## Punteggio di Salute del Design

| # | Euristica (Nielsen) | Punteggio | Nodo chiave |
|---|---|---|---|
| 1 | Visibilità dello stato del sistema | 3 | Skeleton, retry, contatori e "+N altre" presenti; nessuna affordance di caricamento per aprire un ventaglio da 30 foto |
| 2 | Corrispondenza sistema/mondo reale | 4 | Pila fisica + data scritta a mano è una metafora forte e leggibile per un diario di giardino |
| 3 | Controllo e libertà dell'utente | 3 | "Richiudi" esiste ma manca l'Esc per chiudere il ventaglio, a differenza di ogni altro overlay dell'app |
| 4 | Coerenza e standard | 3 | Riusa bene .chip/.pbtn/.gdel; "Richiudi" usa .pill (36px) invece del minimo 44px |
| 5 | Prevenzione errori | 4 | Eliminazione sempre confermata via ModalConferma |
| 6 | Riconoscimento piuttosto che ricordo | 4 | "+N altre", puntini e rotazione comunicano stato senza richiedere memoria |
| 7 | Flessibilità ed efficienza | 2 | Nessuna azione bulk, nessun modo di scorrere più piante senza aprire ogni pila |
| 8 | Design estetico e minimalista | 4 | Taglio a 3 carte+badge disciplinato; didascalia ridotta alla sola data |
| 9 | Aiuto a riconoscere/recuperare errori | 3 | Messaggi di errore distinti e chiari — invariato dal giro precedente |
| 10 | Guida e documentazione | 3 | Hint contestuali minimi ma appropriati |
| **Totale** | | **33/40** | **Buono** |

Trend per GalleryView: 19 -> 33 (su 40).

## Verdetto di Specificità del Design

Miglioramento reale, ma il fondamento è sottile. "Pila di Polaroid" è di per sé un pattern da manuale quanto "feed stile Instagram" lo era. Ciò che guadagna l'identità "Taccuino da Giardino": la rotazione deterministica (hash del path, mai ricalcolata a caso, motivata nel codice), il riuso della regola Caveat appena estesa in DESIGN.md, il riuso deliberato del linguaggio visivo di .pbtn per .gdel, la decisione esplicita "niente lightbox" datata nel codice.

Scansione deterministica: exit code 0 su entrambi i file, 7 finding tutti advisory. 4 dei 7 sono falsi positivi da riuso deliberato confermato (stesso pattern × 20px in AgenteView/ProgettoView, stesso errore 12px in SettingsView/AccountView, stesso puntino attivo 3px in PiantaView/main.css, stesso rgba(22,16,8,.42) di .pbtn con commento esplicito nel codice). Un quinto (hover .62) è un'estensione difendibile della stessa famiglia di colore. Due (thumbnail 8px, raggio 3px della foto) restano drift a bassa priorità non confermato da un precedente identico — il primo è debito tecnico sistemico preesistente, non introdotto oggi.

Overlay visivo: non disponibile, nessun tool di automazione browser, /gallery richiede sessione autenticata. Nessun finding visivo inventato.

## Impressione Generale

Il salto da 19 a 33 riflette lavoro reale: i due P0 precedenti (lightbox mancante, eliminazione invisibile) sono risolti, colori coerenti, errori in italiano. Il trucco CSS della pila è più robusto del previsto. Ma lo spostamento di zona/sottozona/coltivato_in nell'header crea rischio di affollamento, e Caveat come unico contenuto della didascalia è una scommessa da verificare su dispositivo reale, non solo a tavolino.

## Cosa Funziona

1. Rotazione deterministica per foto (hash del path, mai ricalcolata a caso) — impedisce il tremolio a ogni render, motivata nel codice.
2. Il trucco di dimensionamento della pila (grid, align-items:start, didascalia solo sulla carta frontale) regge meglio del previsto, senza spazio vuoto orfano né ritagli.
3. Un solo modello di interazione indipendentemente dal conteggio (2 o 30 foto usano lo stesso flusso pila->ventaglio).

## Problemi Prioritari

[P1] L'header può affollarsi e schiacciare il nome della pianta su mobile stretto — .gpost__hd non ha flex-wrap, chip e contatore sono flex:none, tutta la compressione ricade sul nome Fraunces. Fix: flex-wrap:wrap su .gpost__hd o max-width+ellissi sulla chip zona. Comando: /impeccable layout

[P1] Caveat come unico contenuto della didascalia rischia la leggibilità in un contesto Operate — prima la data era una delle più voci, ora è l'unico contenuto in corsivo, in un contesto d'uso reale spesso in piena luce. Fix: verificare su schermo reale; se debole, aumentare la dimensione o usare DM Sans per il dato numerico. Comando: /impeccable typeset

[P2] Accessibilità incompleta nel pattern pila->ventaglio — button reale annidato in div[role=button] (anti-pattern ARIA), span generico con aria-label sulla chip coltivato_in (non garantito da screen reader), nessun Esc per chiudere il ventaglio (rompe la convenzione di ModalConferma/FoglioLaterale). Fix: spostare .gdel fuori dal sottoalbero role=button, dare un ruolo esplicito alla chip, aggiungere @keydown.esc. Comando: /impeccable harden

[P2] Più pile possono restare aperte insieme, senza collasso automatico — il muro di foto che il redesign doveva risolvere si ricompone silenziosamente durante uno scorrimento reale. Fix: collassare gli altri ventagli all'apertura di uno nuovo, o aggiungere "richiudi tutto". Comando: /impeccable harden

[P3] Rotazione+traslazione+badge vicini al bordo mobile da 16px — su dispositivi stretti (≤375px) è plausibile, non confermato, che la pila sconfini oltre il bordo pagina. Fix: verificare su dispositivo stretto reale. Comando: /impeccable adapt

## Persona: Bandiere Rosse

Alex (power user): verificare foto su un giardino grande richiede aprire/richiudere una pila per pianta invece di scorrere un feed — regressione di efficienza (euristica #7, 2/4). Nessuna eliminazione bulk.

Sam (accessibilità): button annidato in role=button, span generico con aria-label non garantito, nessun Esc per il ventaglio — insieme rendono header e ventaglio le superfici meno accessibili della vista.

Casey (mobile distratto): .gdel 32px ulteriormente spostato dalla rotazione, adiacente all'area di tocco "apri ventaglio" — un tocco impreciso destinato a eliminare può invece aprire l'intero ventaglio.

## Osservazioni Minori

- title + aria-label ridondanti sulla chip coltivato_in su touch.
- La carta frontale della pila chiusa non ha long-press/tasto destro come accelerator (solo ventaglio aperto e foto singola).
- -webkit-touch-callout:none su .polaroid sopprime correttamente il menu nativo iOS, buona attenzione preesistente.

## Domande da Considerare

- Con 40 piante fotografate, il modello "tocca per rivelare" riduce il carico cognitivo o sposta il problema dallo scroll a un muro di tocchi?
- La regola "mai lightbox" entra in tensione con la diagnosi AI da foto, che richiede guardare da vicino un dettaglio?
- È stato provato con un dataset reale "molte piante, molte foto" per vedere se il comportamento "i ventagli non si richiudono da soli" resta gestibile dopo una sessione di scorrimento reale?
