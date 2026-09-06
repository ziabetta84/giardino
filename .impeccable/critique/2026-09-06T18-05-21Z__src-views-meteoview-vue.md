---
target: Meteo (src/views/MeteoView.vue)
total_score: 18
max_score: 28
na_heuristics: 5,7,10
p0_count: 0
p1_count: 3
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/MeteoView.vue"
target_fingerprint: "sha256:318f35223fba5bd23b3895e86b2f9ed480af6988e8c51b03b96c85b693662fab"
target_path: /Users/rob/Sites/localhost/giardino/src/views/MeteoView.vue
timestamp: 2026-09-06T18-05-21Z
slug: src-views-meteoview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Euristica | Punteggio | Nodo specifico |
|---|-----------|-------|-----------------|
| 1 | Visibilità dello stato del sistema | 2 | Lo skeleton mostra solo 6 righe `.day-skel`, ma il layout caricato aggiunge sopra un hero "Adesso" e un nastro orario: il layout "salta" invece di riempirsi in-place |
| 2 | Corrispondenza sistema/mondo reale | 3 | Icone e descrizioni in italiano naturale; penalizzato perché su un vero fallimento di rete l'utente vede il messaggio grezzo dell'eccezione, non italiano |
| 3 | Controllo e libertà dell'utente | 4 | FoglioLaterale chiude con Esc/backdrop/×, restituisce il focus; ogni riga cliccabile risponde anche a Enter/Spazio |
| 4 | Coerenza e standard | 2 | Doppia violazione di regole già scritte nel progetto: uso ripetuto di Caveat fuori da Home, e `--rose-dark` invece di `--rose-ink` per testo su bianco (stesso bug già corretto altrove) |
| 5 | Prevenzione degli errori | n/a | Vista di sola lettura, nessun form/azione distruttiva |
| 6 | Riconoscimento anziché ricordo | 3 | "Adesso" e la lista giorni hanno sempre testo accanto all'icona; il nastro orario è icona-only e il pallino avviso non spiega da solo il motivo |
| 7 | Flessibilità ed efficienza d'uso | n/a | Lettura passiva di un forecast, non un flusso ripetitivo per cui avrebbe senso un percorso esperto |
| 8 | Estetica e design minimalista | 3 | Gerarchia pulita, filetti invece di card impilate; piccolo rumore: `.day__rain` mostra sempre un valore anche nei giorni di sole |
| 9 | Aiutare a riconoscere/recuperare errori | 1 | L'unico percorso di errore è la stringa grezza dell'eccezione, nessuna distinzione tra cause, nessuna azione di retry |
| 10 | Aiuto e documentazione | n/a | Nessuna superficie di help esiste in nessuna vista dell'app: penalizzare solo questa sarebbe fuorviante |
| **Totale** | | **18/28 (64%)** | **Accettabile** (7 euristiche applicabili su 10) |

## Design Specificity Verdict

Non è un widget meteo generico: le icone (Ink-Pooling, silhouette piena + ellisse `-dark` al 35-40%, un colore per dominio) sono applicate correttamente, con persino un commento nel codice che spiega la scelta dell'icona di errore. La vista riusa `.alertbox`/`.alertbox--rose`, `.exc`/`.exc__track`/`.exc__fill` e `FoglioLaterale` invece di inventare pattern locali. Due crepe concrete in questa coerenza: il font manoscritto Caveat, che DESIGN.md riserva esplicitamente alla data in Home ("nessun altro uso nell'app"), compare qui fino a 7 volte per schermata; e lo stato di errore usa `--rose-dark` per il testo, lo stesso difetto di contrasto che main.css documenta esplicitamente di aver già corretto altrove.

Scansione deterministica: pulita, solo 7 advisory di drift font-size/radius, nessuna nuova classe di problema. Verifica tecnica conferma con calcolo esatto il bug di contrasto (4.34:1, sotto 4.5:1) e trova due problemi strutturali che la sola lettura qualitativa non avrebbe potuto quantificare con la stessa precisione: un quarto stato non gestito (caricamento riuscito ma dati vuoti → pagina bianca) e una seconda istanza indipendente di `useMeteo()` — esattamente il pattern di duplicazione che `HomeView.vue` aveva già abbandonato per rischio di divergenza dei dati.

## Overall Impression

L'esecuzione visiva è di alta qualità e specifica al prodotto nel 90% del file. Ma emergono problemi reali sotto la superficie: un errore di rete mostra testo tecnico grezzo (potenzialmente in inglese) proprio nello scenario più probabile per un'app di uso quotidiano da mobile; il bug di contrasto `--rose-dark` già risolto altrove è ricomparso qui; e soprattutto, la pagina dedicata al meteo non dice mai all'utente quando l'app ha già deciso di saltare un'irrigazione per pioggia in arrivo — quella logica esiste in `useCure.js` ma resta invisibile qui, con in più una soglia di allerta locale (20mm/giorno) che non corrisponde alla soglia reale che governa quella decisione altrove (5mm cumulati su 2 giorni).

## What's Working

- Set icone meteo con Ink-Pooling applicato correttamente, un colore per dominio, con un commento nel codice che documenta la scelta dell'icona di errore rispetto a una campanella generica.
- Riuso di pattern condivisi (`.alertbox`, `.exc`, `FoglioLaterale`) invece di varianti locali.
- Interazione da tastiera reale su ogni riga cliccabile (`role="button" tabindex="0"`, Enter/Spazio), non solo visiva; `FoglioLaterale` gestisce Esc, backdrop e ripristino del focus.
- Nessun accesso non protetto a proprietà potenzialmente `undefined`: ogni binding nel template è correttamente guardato dalle condizioni `v-if` a monte.

## Priority Issues

**[P1] Messaggio di errore grezzo, potenzialmente in inglese, su un vero fallimento di rete.**
`useMeteo.js` — `catch (e) { errore.value = e.message }`, mostrato letteralmente in `MeteoView.vue`. Su un fallimento di `fetch` per assenza di rete il browser produce eccezioni tecniche in inglese ("Failed to fetch"), non solo il messaggio italiano previsto per una risposta API non-ok.
Fix: normalizzare a un messaggio italiano fisso indipendente dalla causa, mandando il dettaglio tecnico solo a `console.error`.

**[P1] `--rose-dark` su sfondo bianco nello stato di errore — stessa regressione già corretta altrove.**
`MeteoView.vue` — `style="...color:var(--rose-dark);"` su `.card` (sfondo bianco): calcolato ~4.34:1, sotto la soglia AA 4.5:1. `main.css` documenta esplicitamente questo stesso identico bug come già risolto altrove sostituendo con `--rose-ink` (~7.36:1).
Fix: `--rose-ink` al posto di `--rose-dark`.

**[P1] Uso ripetuto del font Caveat fuori da Home, contro la Regola esplicita di DESIGN.md.**
`.adesso__label` e `.day__wd` (su ogni riga della lista giorni, fino a 6-7 volte per schermata) usano `var(--font-hand)`. DESIGN.md: "Hand... la data in Home; nessun altro uso nell'app." Usarlo qui su ogni riga lo svuota del suo significato di momento raro.
Fix: sostituire entrambe le occorrenze con `var(--font-sans)`.

**[P2] Duplicazione dell'istanza `useMeteo()` — rischio di divergenza già affrontato una volta in HomeView.**
`MeteoView.vue` istanzia una propria `useMeteo()` (7 giorni) indipendente da quella dello store (2 giorni, usata da `useCure.js` per decidere le urgenze). `HomeView.vue` porta un commento che documenta di essere stata corretta esattamente per questo rischio di divergenza; `MeteoView.vue` non ha ricevuto lo stesso trattamento. Lo store stesso fallisce silenziosamente su errore di rete, quindi le due fonti possono mostrare stati diversi (una vede pioggia, l'altra no) senza alcun segnale.

**[P2] Il collegamento meteo→cure resta invisibile su questa vista, con soglie disallineate.**
`useCure.js` sospende l'urgenza di irrigazione quando la pioggia cumulata di oggi+domani raggiunge 5mm; `MeteoView.vue` genera un proprio avviso solo a partire da 20mm in un singolo giorno, un criterio completamente diverso, e non mostra mai la frase "irrigazione sospesa per pioggia prevista". Un utente che consulta il meteo per capire perché una cura è stata saltata non trova quel segnale qui.
Fix: riusare lo stesso calcolo di `useCure.js` (o lo stesso dato dello store) per mostrare esplicitamente quando l'irrigazione verrà saltata.

**[P2] Il pallino di avviso in lista non spiega il rischio nel foglio di dettaglio.**
Il pallino `.day__flag` (6px, `aria-hidden`) apre al click `MeteoGiorno.vue`, che non renderizza mai gli avvisi — l'unico posto dove il testo esiste è l'alertbox più in alto nella stessa pagina. Un utente deve tornare su e fare corrispondenza manuale per data.
Fix: passare a `MeteoGiorno` gli avvisi che corrispondono a quel giorno specifico.

**[P2] Nastro orario icona-only, senza alternativa testuale per la condizione.**
Ogni cella del nastro mostra ora/icona/temperatura ma mai la descrizione testuale della condizione; l'icona è sempre `aria-hidden`. Un utente di screen reader riceve solo ora e temperatura per le prossime ore, zero informazione su sole/pioggia/temporale — a differenza di "Adesso" e della lista giorni, dove il testo accompagna sempre l'icona.

**[P3] Quarto stato non gestito: caricamento riuscito ma dati vuoti.**
La catena `v-if="loading" / v-else-if="errore" / v-else` è esaustiva su `{loading, errore}` ma non su "dati vuoti senza errore": se `giorni` risultasse `[]` dopo un caricamento andato a buon fine, la pagina renderizza sostanzialmente nulla sotto il titolo, senza messaggio né azione di retry. Non causa un crash, ma è un caso scoperto.

## Persona Red Flags

**Casey (mobile, in giardino)**: deve fare lei stessa il calcolo "pioggia prevista → salto l'irrigazione" leggendo mm grezzi, proprio il calcolo che l'app fa già altrove — nel momento di minor pazienza. Con connessione debole, la cache del service worker (fino a 6h) può mostrare un forecast non più fresco senza alcuna indicazione che i dati non sono live.

**Sam (screen reader/tastiera)**: nastro orario icona-only con `aria-hidden`, condizione mai letta; il pallino avviso è `aria-hidden` e privo di testo, uno screen reader non saprà mai che un giorno porta un rischio; l'ora "corrente" nel nastro si distingue solo per colore di sfondo, nessun testo "ora attuale" nella cella stessa.

**Jordan (familiare/amico, primo utilizzo)**: il pallino avviso non ha etichetta né tooltip — impossibile indovinarne il significato senza già conoscere il pattern; "Evapotraspirazione" nel foglio di dettaglio è gergo agronomico puro, senza spiegazione inline.

## Minor Observations

- Stile inline sul titolo pagina invece di una classe condivisa — piccola incoerenza rispetto al resto del file, che usa quasi solo classi.
- `.day__rain` mostra sempre un valore ("0.0 mm") anche nei giorni di sole pieno, rumore visivo costante.
- Tensione (non necessariamente un bug, pattern già stabilito nel CSS condiviso) tra la Regola del Nome in Fraunces ("i numeri restano sempre in DM Sans") e l'uso di Fraunces per temperature/numeri del giorno.
- `titoloGiorno()` produce titoli minuscoli mentre `.day__wd` forza `text-transform:capitalize` — differenza di case fra due rappresentazioni della stessa informazione, cosmetica.
- Nessun `:focus-visible` dedicato su `.day`/`.adesso` (si affidano al default del browser) — non un fallimento, solo un'incoerenza rispetto ad altri elementi dell'app che hanno un anello di focus personalizzato.

## Questions to Consider

- Questa vista sa già, via `useCure.js`, quando la pioggia annullerà un'innaffiatura: perché non dirlo qui, dove l'utente sta letteralmente guardando le previsioni per decidere se annaffiare?
- Se Caveat deve restare "un momento raro" per avere senso, vale la pena vietarlo esplicitamente fuori da HomeView in una regola di revisione, prima che ricompaia in altre viste con liste di date?
- Quante altre viste condividono lo stesso `catch (e) { errore.value = e.message }` che espone testo tecnico grezzo, senza che nessuno se ne sia accorto finora?
