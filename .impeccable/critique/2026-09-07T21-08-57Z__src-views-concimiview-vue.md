---
target: ConcimiView
total_score: 26
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/ConcimiView.vue"
target_fingerprint: "sha256:1af157f3f9f7a71b6f3f882e21c5dfe5ee945b6b47b244ca72c89435351000c5"
target_path: /Users/rob/Sites/localhost/giardino/src/views/ConcimiView.vue
timestamp: 2026-09-07T21-08-57Z
slug: src-views-concimiview-vue
---
Method: dual-agent (A: design-review subagent · B: detector-evidence subagent)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Spinner ed errore per-riga solidi; manca conferma/undo dopo eliminazione, e "Adatto per" può cambiare silenziosamente quando un altro concime cambia stato. |
| 2 | Match System / Real World | 3 | "Dispensa", "Adatto per", "terminato" — registro naturale; NPK come rapporto grezzo, convenzione di dominio corretta. |
| 3 | User Control and Freedom | 2 | Nessun undo dopo eliminazione (solo conferma); il chevron incastrato prima del toggle invita a un tocco accidentale verso la modifica quando si voleva solo il toggle. |
| 4 | Consistency and Standards | 2 | Rompe due pattern gemelli propri dell'app: `AgenteView.vue` (stessa riga `.feed--tap`) non ha alcun chevron; `PiantaRiga.vue` mette il chevron come *ultimo* elemento del link, non incastrato tra i controlli. L'icona `.care__ic--concimazione` è fissa su ogni riga, mentre ovunque altro le varianti `.care__ic--*` cambiano per tipo di cura riga per riga. |
| 5 | Error Prevention | 2 | I tre controlli finali (chevron, toggle, elimina) sono ravvicinati con `@click.stop` dentro una riga già `role="button"`; l'elimina ha il filetto di separazione, il toggle no — separato dal chevron invece che isolato dall'elimina. |
| 6 | Recognition Rather Than Recall | 3 | NPK, "Adatto per", "terminato" tutti visibili in riga. |
| 7 | Flexibility and Efficiency | 3 | Ricerca, elenco troncato, toggle a un tocco senza aprire il foglio. |
| 8 | Aesthetic and Minimalist Design | 2 | L'icona identica ripetuta è la violazione di minimalismo più chiara: 34×34px di tessera colorata, ripetuta N volte, senza informazione differenziante in una lista la cui intera premessa è "sono tutti concimi". |
| 9 | Error Recovery | 3 | Errori specifici e scoped per riga/campo, non generici. |
| 10 | Help and Documentation | 3 | L'empty state spiega il perché aggiungere un concime, sostituendo un vero help a questa scala. |
| **Total** | | **26/40** | **Accettabile** |

## Design Specificity Verdict

**LLM:** Non è una lista da SaaS generico — il vocabolario è quello dell'app (righe `.feed`/`.feedlist` a filetti, tessera Ink-Pooling, Fraunces sul nome, NPK via `useConcimi.js`). Ma la specificità del "chrome" ha superato quella della "tessera icona": la tessera è copiata dal pattern generico `.care__ic` usato per i badge tipo-cura (dove la *variazione* è il punto — irrigazione/concimazione/calcio ricevono ciascuno una tessera diversa) senza adattarlo a un contesto dove il tipo è costante e qualcos'altro varierebbe davvero (rapporto NPK, numero di abbinamenti, stato di scorta). È un divario specifico e diagnosticabile, non un vago "rendilo più bello".

**Scansione deterministica:** stessi 5 riscontri advisory di sempre; confermato che riga 370 (20px sul glifo "×") resta l'unico punto dove il valore diverge dal gemello 18px di `.pr__del` in `PiantaRiga.vue` (stesso ruolo, valore diverso).

**Verifica puntuale (ordine markup)**: confermato riga per riga. In `ConcimiView.vue` l'ordine dei figli della riga è: tessera icona → blocco nome/meta → chevron → bottone toggle → bottone elimina. In `PiantaRiga.vue` il chevron è l'**ultimo** elemento dentro il contenuto cliccabile del link, e il bottone elimina sta *fuori* dal link, dopo. `AgenteView.vue`, con la stessa riga `.feed--tap`, non ha alcun chevron. ConcimiView è l'unica delle tre righe comparabili a incastrare il chevron tra il testo e due bottoni azione.

**Overlay visivi:** ancora non disponibili — nessuno strumento di controllo browser in questo ambiente.

## Overall Impression

Il punteggio scende da 31 a 26/40: i due problemi che hai segnalato sono entrambi confermati reali dal confronto diretto col resto del codebase, e il fix del chevron del giro precedente ha introdotto la seconda regressione (rischio di tocco-sbagliato) mentre risolveva la scopribilità. La logica sotto il cofano resta solida; il problema è tutto nella tessera icona e nell'ordine dei controlli finali.

## What's Working

1. **Gestione N/D-vs-zero e troncamento dell'elenco abbinamenti** — modellazione di dominio reale, documentata con commenti datati che mostrano un'iterazione deliberata.
2. **Errori scoped e azionabili per riga/campo** — nessun fallimento silenzioso o generico.
3. **Esclusione dei concimi "terminato" dal matching** — un fix di correttezza non ovvio: un prodotto esaurito non può più comparire come "miglior abbinamento" sulla stessa riga che lo etichetta terminato.

## Priority Issues

**[P1 — confermato, segnalato da te] L'icona identica ripetuta su ogni riga non porta informazione.**
- **Perché conta**: la tessera a riga 29 è fissa — non calcolata, non condizionale, non guidata dai dati. In `PiantaRiga.vue` lo slot equivalente mostra la foto reale della pianta quando disponibile, e anche il fallback varia (urgente→campanella, altrimenti→foglia) più un cambio di colore di sfondo. `AgenteView.vue` varia l'icona per tipo di richiesta. ConcimiView è l'unica delle tre righe comparabili a spendere un'intera tessera da 34px e una codifica colore su un valore costante per costruzione (questa lista è *sempre* concimi) — decorazione, non un marcatore di dominio che si guadagna lo spazio.
- **Fix**: rimuovere la tessera fissa e ridare lo spazio recuperato al blocco nome/meta (che già oggi compete per spazio con icona+toggle+elimina, ammesso nel commento CSS del file). Se si vuole comunque un marcatore in testa alla riga, farlo variare con un dato già presente: colore per nutriente NPK dominante, oppure per stato di scorta (olive se disponibile, spenta/outline se terminato — ridurrebbe anche la dipendenza dal solo tag testuale "terminato"). Non farlo variare per numero di abbinamenti "adatto per": è già mostrato come testo, sarebbe una doppia codifica dello stesso fatto.
- **Comando suggerito**: `/impeccable layout`

**[P1 — confermato, segnalato da te] L'ordine dei pulsanti a destra non ha senso: il chevron incastrato tra testo e azioni, ed elimina troppo vicino al toggle frequente.**
- **Perché conta**: in `PiantaRiga.vue` il chevron è l'ultimo elemento del contenuto cliccabile, con l'azione distruttiva separata fuori dal link; `AgenteView.vue`, stessa riga `.feed--tap`, non usa affatto un chevron. ConcimiView invece incastra il chevron tra il testo e due bottoni azione — non chiude la riga (altri due controlli seguono) né segna il bordo di un figlio navigabile distinto (l'intera riga è già `role="button"`, non un `&lt;a&gt;`). In più, l'ordine toggle-poi-elimina inverte la gerarchia di rischio: il toggle è frequente e reversibile, l'elimina è raro e distruttivo — tenerli adiacenti nello stesso ordine vanifica in parte il filetto di separazione già introdotto apposta per l'elimina.
- **Fix**: rimuovere il chevron incastrato (la riga resta comunque scopribile tramite `role="button"`/cursore, come già dimostra `AgenteView.vue` senza chevron); riordinare i controlli restanti a toggle, poi elimina, mantenendo il filetto di separazione già implementato tra loro.
- **Comando suggerito**: `/impeccable layout`

**[P2] Il vincolo `min="0"` sugli input NPK è solo estetico, non applicato prima del salvataggio.**
- **Perché conta**: un valore negativo digitato/incollato viene accettato e mostrato senza alcun avviso finché non si preme Salva, dove viene silenziosamente riportato a 0 — una piccola sorpresa, non un rischio, ma un'esperienza poco onesta.
- **Fix**: un messaggio di validazione inline al blur, invece di una correzione silenziosa solo al salvataggio.
- **Comando suggerito**: `/impeccable clarify`

**[P3] Il troncamento "Adatto per" può far sembrare inutile un concime che è in realtà un quasi-abbinamento.**
- **Perché conta**: `pianteAbbinatePerConcime` assegna ogni pianta al SOLO concime più vicino; un secondo concime perfettamente valido entro la soglia non riceve mai la riga "Adatto per", il che può leggersi come "questo concime non serve a nulla" quando in realtà esiste solo un concorrente di poco più vicino.
- **Fix**: da valutare in futuro (es. un livello secondario "Adatto anche per"), non urgente.
- **Comando suggerito**: `/impeccable clarify`

## Persona Red Flags

**Riley (bassa alfabetizzazione digitale/poca pazienza per l'ambiguità)**: il chevron incastrato tra testo e bottoni è esattamente il tipo di elemento ambiguo "è un bottone o no?" che blocca un utente poco sicuro.

**Casey (una mano sola, guanti/mani bagnate, all'aperto)**: il toggle ora è incastrato tra un chevron non-bersaglio e un bottone elimina distruttivo invece di stare in una posizione chiaramente isolata — sotto le sue condizioni (tocco impreciso), essere a un controllo di distanza da "elimina" invece di due è una regressione misurabile rispetto a tenere l'elimina al vero bordo estremo.

**Alex (power user con dispensa ampia)**: con una lista lunga di macerati fatti in casa, la colonna di icone identiche non aggiunge alcun valore di scansione proprio per chi scorre più velocemente — il posto dove la variazione aiuterebbe di più (colore per nutriente o per stato di scorta) è oggi assente.

## Minor Observations

- Il pattern "area di tocco 44px attorno a un binario visivo 42×24" del toggle è un buon accorgimento, riusabile come modello per altri toggle futuri nell'app.
- `.care__ic--npk`/`.care__ic--calcio` esistono già come varianti CSS ma non sono referenziate da nessuna vista attuale oltre ai commenti — CSS quasi morto, non un problema di questo file, ma il fix del punto 1 potrebbe far rivivere `--npk` come variante genuinamente usata invece di introdurne una nuova da zero.

## Questions to Consider

- Se ogni riga di questa lista è, per costruzione, un concime — a cosa serve davvero l'icona? Se la risposta onesta è "perché la riga non sembri spoglia", una tessera colorata è lo strumento più economico per risolvere lo spazio vuoto, o si sta risolvendo un problema (lo spazio bianco) con lo strumento sbagliato (un'icona di dominio che implica un significato che non porta)?
- Il chevron è stato aggiunto, per il suo stesso commento CSS, come "unico segnale visivo che la riga apre il foglio" — ma `AgenteView.vue`, riga strutturalmente identica, non ne ha e presumibilmente nessuno l'ha segnalata come poco chiara. Il chevron risolve un vero problema di scopribilità in ConcimiView, o risolve un vuoto creato proprio dalla perdita di differenziazione dell'icona (una volta che l'icona sembra decorativa, la riga ha bisogno di un segnale separato "fidati, è toccabile" che non le serviva quando si sentiva più ricca)?
- Dato che `pianteAbbinatePerConcime` calcola già il segnale più ricco e specifico di dominio del file (quali piante ne hanno bisogno, ora, in questa stagione) — perché quel segnale resta relegato a una riga di testo secondaria mentre l'icona non informativa occupa lo spazio visivo primario in testa alla riga?
