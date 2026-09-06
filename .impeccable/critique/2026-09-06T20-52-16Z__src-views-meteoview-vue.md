---
target: Meteo (src/views/MeteoView.vue)
total_score: 25
max_score: 28
na_heuristics: 5,7,10
p0_count: 0
p1_count: 0
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/MeteoView.vue"
target_fingerprint: "sha256:099154645019a1352b7d9899a954b730ca857994e4666c1130c029512ab5a792"
target_path: /Users/rob/Sites/localhost/giardino/src/views/MeteoView.vue
timestamp: 2026-09-06T20-52-16Z
slug: src-views-meteoview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Euristica | Punteggio | Nodo specifico |
|---|-----------|-------|-----------------|
| 1 | Visibilità dello stato del sistema | 3 | Skeleton, errore, retry, evidenziazione "now" tutti presenti; manca un indicatore di freschezza dato — `carica()` gira una sola volta al mount e mai più |
| 2 | Corrispondenza sistema/mondo reale | 4 | Unità italiane, date in `it-IT`, linguaggio naturale |
| 3 | Controllo e libertà dell'utente | 4 | `FoglioLaterale` con Esc/aria-modal/gestione focus; vista di sola lettura, ma quel che c'è è ben gestito |
| 4 | Coerenza e standard | 4 | Bottone Riprova su token standard `.btn.btn-ghost`; pattern badge riusato in 3 punti con differenze documentate a commento come scelte deliberate |
| 5 | Prevenzione degli errori | n/a | Vista di sola lettura, nessun input da validare |
| 6 | Riconoscimento anziché ricordo | 4 | Il fix del ribbon chiude l'ultima lacuna: sia ribbon che lista giorni mostrano sempre la descrizione testuale |
| 7 | Flessibilità ed efficienza d'uso | n/a | Nessuna azione ripetitiva da accelerare |
| 8 | Estetica e design minimalista | 3 | Impaginazione pulita; l'8.5px di `.hour__cond` è sotto la soglia minima che il sistema stesso si è dato (9.5px) |
| 9 | Aiutare a riconoscere/recuperare errori | 3 | Messaggio semplice e azionabile; non pinpointa la causa reale — tensione reale con la scelta di semplicità già presa in sessione, non superata da questo giro |
| 10 | Aiuto e documentazione | n/a | Non pertinente per una vista di consultazione |
| **Totale** | | **25/28 (89%)** | **Buono, a un soffio da Eccellente** (in miglioramento da 23/28, 82%) |

## Design Specificity Verdict

Confermato solido: icone ad acquerello per dominio, Fraunces riservato ai numeri di temperatura come protagonisti, filetti hairline invece di card impilate, nota "irrigazione sospesa" che riusa esplicitamente lo stesso criterio di `useCure.js`. Verifica tecnica approfondita: il pallino d'allerta riposizionato è stato controllato contro i colori reali di tutte le icone meteo (oro/acqua/ink-soft) — nessuna collide con `--rose`, il rischio ipotizzato di confusione col pittogramma non si materializza. La guardia `inCorso` è verificata priva di fughe su ogni percorso di uscita della funzione. Il wrap testuale di `.hour__cond` è stato calcolato per le tre etichette più lunghe di `WMO_LABEL`: il wrap naturale produce 2 righe piene senza troncamento a metà parola nel caso reale (anche se Assessment B nota che con un'assunzione di larghezza carattere leggermente diversa le due stringhe più lunghe di 23 caratteri potrebbero troncare — la differenza tra le due valutazioni è nell'assunzione di larghezza media del carattere, non nel meccanismo, che entrambe confermano corretto).

## Overall Impression

Tutti e 3 i fix confermati corretti. La vista è oggi sostanzialmente pulita — nessun P0/P1. Il fix del ribbon (punto 6) introduce però un piccolo prezzo: il testo `.hour__cond` a 8.5px scende sotto la scala tipografica documentata in DESIGN.md (minimo 9.5px per le label), un'ironia notata da entrambe le valutazioni — il fix ha risolto un problema di accessibilità (icona-only) introducendone uno più piccolo ma reale (font sotto soglia di leggibilità). L'allargamento delle celle (52→68px) riduce inoltre le ore visibili a colpo d'occhio da ~5-6 a ~4 su un telefono stretto, un trade-off reale per far stare il testo.

## What's Working

- Pallino d'allerta verificato geometricamente e cromaticamente robusto contro tutte le icone meteo reali dell'app.
- Guardia `inCorso`: soluzione minima e corretta, distingue con precisione lo stato "visibile all'utente" (`loading`) da quello "di controllo interno" (re-entrancy).
- Wrap testuale di `.hour__cond` verificato con calcolo esplicito sulle etichette più lunghe.
- Nessuna stringa in inglese residua in nessun messaggio, incluso quello d'errore.

## Priority Issues

**[P3] `.hour__cond` a 8.5px è sotto la scala tipografica di DESIGN.md.**
Il minimo documentato per le label è 9.5px. Fix a costo quasi zero: portarlo a 9-9.5px, la cella ha ancora margine.

**[P3] Nessun indicatore di freschezza dato.**
`carica()` gira una volta al mount e mai più; su una sessione lasciata aperta a lungo l'utente non ha modo di sapere se il meteo mostrato è ancora reale.

**[P3, strutturale/deliberato] Granularità diagnostica degli errori ferma a un messaggio unico.**
Scelta di prodotto esplicita per restare in linguaggio semplice, in tensione diretta con l'idea di distinguere rete/server/timeout. Portarla a 4/4 significherebbe ribaltare una decisione già presa consapevolmente in questa sessione, non solo rifinire.

**28/28 non è il prossimo traguardo automatico**: i primi due punti sono a portata di mano e porterebbero H1/H8 a 4/4 (27/28 credibile); l'ultimo è un tetto strutturale.

## Persona Red Flags

**Sam (accessibilità)**: `.hour__cond` a 8.5px è sotto qualunque soglia di leggibilità comoda anche con zoom moderato — ironia da correggere: il fix ha risolto un problema di accessibilità introducendone uno più piccolo ma reale.

**Casey (mobile distratta)**: l'allargamento del ribbon riduce le ore visibili a colpo d'occhio da ~6 a ~4-5 — un tap in più per vedere l'ora prevista tra 5-6 ore.

**Jordan (prima volta)**: i pallini d'allerta comunicano solo tramite colore+posizione, senza etichetta visibile — non bloccante (la card è cliccabile e "Occhio a questi giorni" spiega tutto), ma un piccolo salto di fiducia richiesto.

## Minor Observations

- Il commento nel codice per `.adesso__flag` dice "bordo bianco come .pr__badge" ma usa `--cream`, non `--white` — imprecisione cosmetica nel commento, non nel comportamento.
- `.day__flag`/`.adesso__flag` restano volutamente diversi per dimensione/trattamento, documentato a commento — non un difetto, ma da tenere a mente per un futuro terzo punto d'allerta.

## Questions to Consider

- Vale la pena un "aggiornato alle HH:mm" ora che il resto della vista è così rifinito, o la sua assenza è coerente col tono "quieto" del taccuino?
- Il font a 8.5px è nato per risolvere un problema di accessibilità: meglio scendere sotto la scala tipografica per far entrare il testo, o accettare celle leggermente più larghe pur restando dentro i 9.5px minimi?
- La soglia di errore singola è una scelta di semplicità dichiarata: con dati reali alla mano su utenti confusi, meriterebbe un secondo sguardo?
