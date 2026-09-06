---
target: Elenco piante (src/views/PianteView.vue)
total_score: 31
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 0
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/PianteView.vue"
target_fingerprint: "sha256:49b418d4cbc77487cf46867ae74abbb4e416ae13603935c1c22031aee6485f62"
target_path: /Users/rob/Sites/localhost/giardino/src/views/PianteView.vue
timestamp: 2026-09-06T15-07-52Z
slug: src-views-pianteview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Euristica | Punteggio | Nodo specifico |
|---|-----------|-------|-----------------|
| 1 | Visibilità dello stato del sistema | 3 | Skeleton ricalca esattamente forma/spaziatura della riga reale; errori mostrati inline con spinner |
| 2 | Corrispondenza sistema/mondo reale | 4 | Ordine informazioni rispecchia come si pensa a una pianta reale, terminologia coerente |
| 3 | Controllo e libertà dell'utente | 3 | Eliminazione con conferma + Esc + Annulla; manca un pulsante "×" per svuotare la ricerca |
| 4 | Coerenza e standard | 4 | I 4 fix di questo giro riusano token/pattern già stabiliti altrove (--rose-ink da ZoneView, .dest__chev 1:1) senza inventare nulla di nuovo |
| 5 | Prevenzione errori | 3 | Conferma esplicita, target 44×44 ora separato da un divisore; manca un periodo di grazia/undo post-eliminazione |
| 6 | Riconoscimento anziché ricordo | 4 | Filtri sempre visibili, miniatura reale aiuta il riconoscimento più del nome |
| 7 | Flessibilità ed efficienza d'uso | 2 | Nessuna azione bulk, nessuna scorciatoia |
| 8 | Estetica e design minimalista | 3 | Lista pulita; la riga urgente al carico massimo resta il punto più denso |
| 9 | Aiutare a riconoscere/recuperare errori | 3 | Messaggio azionabile, stato preservato; non distingue la causa reale |
| 10 | Aiuto e documentazione | 2 | Nessun aiuto contestuale, ma dominio semplice e autoesplicativo |
| **Totale** | | **31/40** | **Buono** (in miglioramento da 27/40) |

## Design Specificity Verdict

Alta: nome sempre in Fraunces, filetti hairline invece di card impilate (con commento esplicito nel codice sulla scelta), rosa riservato a distruttivo/urgente, badge campanella acquerellato per urgenza, fallback all'immagine hero della specie — scelte che nascono dai dati e dalla logica reali del giardino, non da un template di lista generico. I 4 fix di questo giro rinforzano ulteriormente questo verdetto invece di comprometterlo: ogni valore riusato (`--rose-ink`, `.dest__chev`, `--cream-dark` per il divisore) proviene da un pattern già stabilito altrove nell'app, verificato numero per numero da entrambe le valutazioni.

Scansione deterministica: pulita, solo 4 advisory pre-esistenti, nessuna nuova dai 4 fix. Verifica tecnica completa: contrasto 6.88–9.43:1 in entrambi i temi per il bottone elimina, meccanismo `currentColor` del chevron confermato funzionante (non inerte), matematica del divisore verificata (nessuna sovrapposizione, il pseudo-elemento risolve correttamente contro `.pr__del` grazie al `position:relative` esplicito), title/aria-label ora identici.

## Overall Impression

I 4 fix hanno funzionato senza eccezioni: punteggio da 27 a 31/40, "Buono". Entrambe le valutazioni concordano che nessuno dei fix ha introdotto una regressione — l'unico effetto collaterale trovato non è un bug nuovo ma un rischio di sistema preesistente riportato alla luce: il chevron riusa `--ink-soft` (lo stesso token di `.dest__chev`), che in light mode è a 3.00:1 contro `--cream` — esattamente al minimo WCAG per elementi grafici, senza margine. Non è stato introdotto da questo fix (era già così su `.dest__chev` altrove), ma rilocalizzarlo qui non lo risolve. Emergono anche due piccoli problemi indipendenti dai fix appena fatti: la ricerca non ha un modo rapido per essere svuotata, e `.pr__urg` (a differenza degli altri tre campi della riga) non tronca il testo, potendo andare a capo proprio nel caso di carico massimo che il chevron doveva già accomodare.

## What's Working

- I 3 fix CSS di questo giro non sono invenzioni ad-hoc: riusano token e pattern già stabiliti (`--rose-ink` da `ZoneView.vue`, `.dest__chev` riprodotto 1:1) — così si chiude un debito di coerenza senza crearne uno nuovo.
- Distinzione "giardino vuoto" vs "nessun risultato dal filtro" con commento esplicito nel codice, evita la trappola del messaggio unico confuso.
- Skeleton di caricamento ricalca dimensioni e spaziatura esatte della riga reale, riducendo il layout shift.
- Tutti e 4 i fix verificati corretti con evidenza tecnica puntuale da entrambe le valutazioni indipendenti (contrasto calcolato, meccanismo currentColor confermato, matematica di posizionamento del divisore).

## Priority Issues

**[P2] Nessun pulsante per svuotare la ricerca.**
`.search-input` non ha una "×" per azzerare `cerca`; su mobile con una mano sola bisogna cancellare carattere per carattere.
Fix: mostrare un pulsante clear quando `cerca` non è vuoto.

**[P2] `.pr__urg` non tronca il testo.**
A differenza di `.pr__name`/`.pr__var`/`.pr__zona` (tutti con `white-space:nowrap`/ellissi), `.pr__urg` non ha controllo di overflow: più cure scadute concatenate possono andare a capo, allungando proprio la riga già al carico massimo che il nuovo chevron doveva accomodare.
Fix: stesso trattamento nowrap+ellissi degli altri tre campi, eventualmente con "+N altre" oltre una soglia.

**[P3] `--rose-ink` fa doppio lavoro nella stessa riga.**
`.pr__urg` (urgenza) e `.pr__del` (eliminazione) usano lo stesso colore quando la pianta è urgente — coerente con la regola "rose = distruttivo O urgente" di DESIGN.md, ma potenzialmente ambiguo a un primo sguardo tra "questa pianta ha bisogno di cure" e "questo elimina la pianta".

**[P3] Chevron a contrasto minimo in light mode.**
`--ink-soft` sul chevron è a 3.00:1 contro `--cream` in light mode — esattamente il minimo WCAG per elementi grafici, senza margine (schiarisce a ~4.73:1 in dark mode). Non introdotto da questo fix (stesso token di `.dest__chev` altrove), ma non risolto riusandolo qui.

**[P3] Nessuna azione bulk.**
Nessun modo di eliminare/spostare più piante insieme — accettabile alla scala di un giardino personale, unico vero limite di flessibilità residuo.

## Persona Red Flags

**Casey (mobile, un pollice)**: nessun pulsante clear sul campo ricerca; positivo però che `.pr__del` sia ora 44×44px con gap e divisore, riducendo il rischio di mis-tap segnalato nel round precedente.

**Sam (accessibilità)**: chevron a contrasto minimo (3.00:1, zero margine) in light mode; il nome accessibile del link è la concatenazione grezza di nome+varietà+zona+urgenza, funzionale ma non strutturata. Positivo: aria-label/title ora allineati, target di tocco corretto.

**Riley (stress tester)**: una pianta con 3+ cure scadute produce una stringa `.pr__urg` non troncata che può andare a capo, superando l'altezza che il fix del chevron doveva già gestire; il messaggio di errore di eliminazione resta sempre generico indipendentemente dalla causa reale.

## Minor Observations

- Il divisore `.pr__del::before` è a `left:-6px` in un gap di 10px: leggermente decentrato rispetto al centro esatto (-5px), scostamento di 1px, impercettibile.
- Il messaggio di errore di eliminazione non specifica mai la causa reale (rete/permessi/galleria foto).

## Questions to Consider

- Se il giardino cresce a 50-100 piante, la lista piatta con filtri a pillola regge ancora, o servirà un'azione bulk prima che diventi un problema reale?
- `--rose-ink` fa doppio lavoro nella stessa riga (urgenza + eliminazione): basta la regola di DESIGN.md a disambiguare sul campo, o vale la pena una tinta dedicata solo all'azione distruttiva?
- Ha senso troncare `.pr__urg` a una sola cura più prominente ("+2 altre") invece di concatenarle tutte senza limite?
