---
target: ConcimiView
total_score: 31
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 1
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/ConcimiView.vue"
target_fingerprint: "sha256:8a96ec3e200bb45d4d5bbc7693a3841d2a62657e6a37289e8747aaa3a66510ba"
target_path: /Users/rob/Sites/localhost/giardino/src/views/ConcimiView.vue
timestamp: 2026-09-07T20-56-44Z
slug: src-views-concimiview-vue
---
Method: dual-agent (A: design-review subagent · B: detector-evidence subagent)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Skeleton, spinner per-riga su toggle e salvataggio, errori scoped all'azione che fallisce. |
| 2 | Match System / Real World | 4 | "Dispensa", "terminato", "Adatto per" — linguaggio di dominio corretto ovunque. |
| 3 | User Control and Freedom | 3 | Annulla, backdrop/Esc, conferma su eliminazione; nessun undo dopo eliminazione ma coerente con l'app. |
| 4 | Consistency and Standards | 4 | `.feed`/`.feedlist`/`.care__ic`/`ModalConferma`/`FoglioLaterale` riusati verbatim dai pattern di `AgenteView.vue`/`PiantaRiga.vue`. |
| 5 | Error Prevention | 3 | Salva disabilitato senza nome; `min="0"` sugli NPK è solo un suggerimento, non applicato in `salva()`. |
| 6 | Recognition Rather Than Recall | 2 | "Adatto per" troncato costringe l'utente a ricordare o indovinare il resto delle piante abbinate — nessun modo di consultarle. |
| 7 | Flexibility and Efficiency | 3 | Il toggle disponibilità a un tocco, senza aprire il foglio, è un vero guadagno di efficienza. |
| 8 | Aesthetic and Minimalist Design | 3 | Riga densa ma ben suddivisa (nome/descrizione troncata/riga meta); NPK+match correttamente su riga secondaria. |
| 9 | Error Recovery | 4 | Gli errori nominano il concime specifico invece di un toast generico. |
| 10 | Help and Documentation | 2 | Nessuna spiegazione del perché una pianta sia "adatta" (soglia di distanza invisibile) né che la riga stessa sia toccabile per altro dettaglio. |
| **Total** | | **31/40** | **Buono** |

## Design Specificity Verdict

**LLM:** ConcimiView riusa fedelmente il vocabolario dell'app (righe `.feed` condivise con `AgenteView.vue`, tessera `.care__ic--concimazione`, `FoglioLaterale`/`ModalConferma`, disciplina dei 44px documentata nei commenti stessi del codice). L'unico punto dove la specificità si rompe è esattamente dove vive il payoff della personalizzazione: la riga "Adatto per" è incollata alla riga come testo inerte con un taglio netto a "+N altre" e nessuna superficie altrove nel file per leggere il resto — la funzione che dovrebbe far sentire "l'app conosce il mio giardino" finisce invece in un vicolo cieco.

**Scansione deterministica:** ancora 5 riscontri advisory, stessi di prima. Verificato un dettaglio nuovo: il valore 20px sul glifo "×" del bottone elimina (riga 332) è l'unico punto dove il commento "stesso pattern di `.pr__del`" non corrisponde esattamente — `.pr__del` in `PiantaRiga.vue` usa 18px, non 20px, per lo stesso glifo. Scostamento minimo (2px), non un problema di sostanza.

**Verifica puntuale del problema segnalato**: tracciato riga per riga. `elencoAbbinati()` (righe 176-181) restituisce "A, B, C +2 altre" quando le piante abbinate superano 3; il template (riga 37) lo mostra come testo semplice, senza `title`, gestore di click, `aria-expanded` o altro. Il foglio di modifica che la riga apre (righe 65-98) contiene solo nome/NPK/descrizione/disponibilità — l'elenco completo delle piante abbinate (calcolato in `pianteAbbinatePerConcime`, righe 156-171) non viene mai mostrato altrove nel file. **Confermato**: le piante oltre la terza sono calcolate ma permanentemente irraggiungibili nell'interfaccia.

**Overlay visivi:** ancora non disponibili — nessuno strumento di controllo browser esposto in questo ambiente.

## Overall Impression

Il punteggio sale da 28 a 31/40. Il problema che hai segnalato è reale e confermato dal codice: non è "un troncamento comune", è un vicolo cieco vero e proprio, perché il dato esiste (`pianteAbbinatePerConcime`) ma non ha alcuna via di accesso dopo i primi 3 nomi. Nello stesso controllo è emerso anche un bug di sostanza collegato: il matching considera anche i concimi già segnati "terminato".

## What's Working

1. **"Adatto per" come idea** — derivare una rilevanza personalizzata dal vivo per ogni concime va ben oltre il CRUD d'inventario generico, e collega il dominio dei concimi a quello delle piante invece di elencare prodotti isolati.
2. **La disciplina dei 44px è genuinamente rispettata e auto-documentata** nei commenti CSS — un impegno di design reale, non solo dichiarato.
3. **I messaggi di errore nominano il concime specifico** che ha fallito, invece di un toast generico dismissibile.

## Priority Issues

**[P1] "Adatto per" troncato non ha alcuna via per leggere l'elenco completo — un vicolo cieco confermato, non un semplice limite comune.**
- **Perché conta**: il dato (`pianteAbbinatePerConcime.value[c.id]`) esiste già, completo, ma oltre i primi 3 nomi diventa permanentemente irraggiungibile nell'interfaccia — proprio nell'unica funzione che rende questa dispensa personalizzata invece che generica. Per un utente che torna dopo settimane (deve *riconoscere*, non *ricordare*), è il pattern peggiore possibile.
- **Fix**: la riga apre già `FoglioLaterale` per quel concime — aggiungere lì, in cima al foglio, una sezione di sola lettura "Adatto per" con l'elenco completo (piccoli badge o un paragrafo a capo, nomi in Fraunces come da regola dei nomi), mostrata solo quando `modificaId` è impostato e l'elenco non è vuoto. Nessun nuovo pattern d'interazione: niente tooltip (app da giardino, mani sporche/bagnate, niente hover), niente secondo elemento interattivo annidato dentro la riga già `role="button"` (creerebbe un conflitto di accessibilità con doppia attivazione da tastiera). Il riepilogo troncato a 3 nomi resta sulla riga così com'è: il fix è dare al foglio il contenuto che gli manca, non ridisegnare la riga.
- **Comando suggerito**: `/impeccable clarify`

**[P2] Il calcolo degli abbinamenti ignora i concimi già segnati "terminato".**
- **Perché conta**: `pianteAbbinatePerConcime` chiama `concimeConsigliato` su *tutta* la dispensa, inclusi i concimi appena segnati "terminato" con lo stesso toggle presente sulla riga — un prodotto esaurito può quindi comparire come "il miglior abbinamento NPK" per una pianta mentre la stessa riga lo etichetta "terminato", contraddicendosi da sola nell'unica schermata il cui scopo è tracciare cosa c'è davvero in dispensa.
- **Fix**: filtrare `store.concimi` a `disponibile !== false` prima di passarlo a `concimeConsigliato` dentro questo computed.
- **Comando suggerito**: `/impeccable harden`

**[P2] Nessun segnale visivo che la riga sia toccabile.**
- **Perché conta**: a differenza di `PiantaRiga.vue`, che ha un chevron esplicito (`.pr__chev`) a segnalare "questo porta altrove", la riga di ConcimiView ha icona+nome+toggle+elimina ma nulla che indichi che il corpo della riga apre un foglio — `role="button"` c'è per chi lo scopre, ma non per chi arriva la prima volta. Aggrava il problema P1: anche dopo il fix, l'utente deve prima scoprire che toccare la riga è il modo per vedere di più.
- **Fix**: aggiungere un piccolo chevron o indicatore visivo coerente con `.pr__chev`.
- **Comando suggerito**: `/impeccable clarify`

**[P3] La semantica del tocco sulla riga è sovraccaricata (il form di modifica raddoppia come vista di dettaglio).**
- **Perché conta**: toccare una riga apre "Modifica concime" — un'intenzione di modifica — ma dopo il fix P1 sarebbe anche l'unico posto per *leggere* l'elenco piante abbinate, un'intenzione di visualizzazione. `AgenteView.vue` separa le due cose con una vista di dettaglio in sola lettura.
- **Fix**: da valutare in un secondo momento; il fix pragmatico di P1 resta comunque corretto anche con questa sovrapposizione irrisolta.
- **Comando suggerito**: `/impeccable shape`

**[P3] Gli input numerici NPK non hanno un limite/formato oltre `min="0"`.**
- **Perché conta**: `salva()` scrive i valori N/P/K senza altro controllo che `npkONull`; un valore negativo incollato o un caso limite non numerico non viene intercettato lato client. Severità bassa (dati mono-utente), ma degno di nota dato quanto la correttezza NPK sia centrale per tutta la funzione di matching.
- **Fix**: un clamp minimo lato client prima del salvataggio.
- **Comando suggerito**: `/impeccable harden`

## Persona Red Flags

**Sam (ritorna dopo settimane, si affida al riconoscimento non alla memoria)**: il troncamento attuale è il pattern peggiore possibile per lei — le vengono dati 3 nomi e "+2 altre" senza alcun modo di consultare o recuperare chi siano gli altri due, costringendola a un puro richiamo mnemonico proprio dove dovrebbe bastare il riconoscimento.

**Riley (mobile, in giardino, mani potenzialmente sporche/bagnate)**: un fix basato su tooltip per il problema P1 l'avrebbe esclusa specificamente — niente hover, tocco impreciso; il fix proposto (dentro il Foglio) è la scelta corretta per lei.

**Jordan (tastiera/screen reader)**: qualunque implementazione di un "vedi tutto" direttamente sulla riga (invece che dentro il foglio) rischierebbe di annidare un elemento interattivo dentro il `role="button"` già esistente sulla riga, producendo un'attivazione da tastiera ambigua o doppia — il fix proposto la evita del tutto.

## Minor Observations

- `elencoAbbinati(c.id)` viene invocato due volte per riga nel template (una nel `v-if`, una nell'interpolazione) — ricalcola slice/join due volte per render senza motivo; costo trascurabile qui, ma da tenere a mente se il pattern si diffonde.
- L'ordine dei nomi in `elencoAbbinati` segue l'ordine di iterazione di `Object.values(store.piante)` (ordine di inserimento), non alfabetico — i 3 nomi mostrati su N potrebbero apparire arbitrari/incoerenti tra un caricamento e l'altro.
- La soglia `SOGLIA_DISTANZA = 0.15` fa sì che un concime che l'utente associa mentalmente a certe piante, ma che è un "secondo classificato" NPK molto vicino, non mostri alcuna riga "Adatto per" — non è un errore, ma può leggersi come "l'app non riconosce questo abbinamento" quando in realtà un concorrente di poco più vicino esiste.

## Questions to Consider

- Se "Adatto per" serve a costruire fiducia nel fatto che l'app capisca il giardino specifico dell'utente, perché l'unico posto dove vive quel dato tratta i concimi "terminato" come raccomandazioni valide — non erode silenziosamente proprio la fiducia che la funzione vuole costruire?
- Dato che `FoglioLaterale` è l'unica superficie generica di "dettaglio senza lasciare la pagina" dell'app, toccare una riga concime deve davvero aprire di default un form di *modifica* — o converrebbe separare "vedi dettaglio" (in sola lettura, con l'elenco completo) da "modifica" (un'icona matita, come altrove nell'app)?
- Un taglio netto a esattamente 3 nomi senza alcun modo di raggiungere il resto è difendibile in un'app il cui ethos dichiarato è un taccuino tenuto a mano — un taccuino vero non permetterebbe sempre di girare pagina invece di troncare la frase a metà?
