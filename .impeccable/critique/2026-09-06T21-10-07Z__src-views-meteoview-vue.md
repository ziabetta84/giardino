---
target: Meteo (src/views/MeteoView.vue)
total_score: 25
max_score: 28
na_heuristics: 5,7,10
p0_count: 0
p1_count: 0
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/MeteoView.vue"
target_fingerprint: "sha256:e61741122728b965624260171782fe705e97845c3b153afe27f9bed4a1673406"
target_path: /Users/rob/Sites/localhost/giardino/src/views/MeteoView.vue
timestamp: 2026-09-06T21-10-07Z
slug: src-views-meteoview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Euristica | Punteggio | Nodo specifico |
|---|-----------|-------|-----------------|
| 1 | Visibilità dello stato del sistema | 3 | Skeleton/errore/Riprova solidi; la didascalia "Aggiornato alle" resta congelata e visibile anche durante un retry fallito, comunicando una freschezza che il sistema sa non essere vera |
| 2 | Corrispondenza sistema/mondo reale | 4 | Italiano naturale, WMO tradotto in etichette leggibili sempre accompagnate da testo |
| 3 | Controllo e libertà dell'utente | 4 | Foglio laterale con Esc/click fuori/focus restituito |
| 4 | Coerenza e standard | 4 | Pattern condivisi riusati correttamente ovunque, `.hour__cond` ora coerente con `.day__desc` |
| 5 | Prevenzione degli errori | n/a | Vista di sola lettura |
| 6 | Riconoscimento anziché ricordo | 4 | `.hour__cond` visibile in chiaro elimina un vero carico di inferenza dall'icona sola |
| 7 | Flessibilità ed efficienza d'uso | n/a | Nessuna azione ripetitiva da accelerare |
| 8 | Estetica e design minimalista | 3 | Pulito; il margine di troncamento su "Temporale con grandine" è ora al limite, e il contrasto della nuova didascalia (~1.7:1) è ben sotto soglia AA |
| 9 | Aiutare a riconoscere/recuperare errori | 3 | Messaggio semplice + Riprova funzionante; genericità confermata come soffitto deliberato |
| 10 | Aiuto e documentazione | n/a | Non pertinente |
| **Totale** | | **25/28 (89%)** | **Buono — invariato rispetto al run 4** |

## Design Specificity Verdict

Confermato solido e specifico al prodotto: palette per dominio rispettata alla lettera, nota "irrigazione sospesa" che riusa letteralmente la stessa soglia di `useCure.js` invece di reinventare un criterio, tono "quieto" della nuova didascalia coerente col North Star. Verifica tecnica approfondita mostra però che l'obiettivo dichiarato di uno dei due fix (più spazio per il testo del nastro orario) non è stato raggiunto dai numeri: il font è cresciuto dell'11.8% mentre la larghezza cella solo del 6.7%, un rapporto netto leggermente peggiorativo, non migliorativo, verificato con calcolo esplicito da entrambe le valutazioni indipendentemente.

## Overall Impression

Punteggio grezzo fermo a 25/28 per la seconda misurazione consecutiva: i due fix di questo giro hanno rimosso i due problemi P3 del round precedente ma ne hanno introdotti/rivelati altri di peso comparabile — un pareggio, non un progresso netto. Due problemi reali e verificati da entrambe le valutazioni:

1. **Regressione di margine**: quando `aggiornatoAlle` è `null` (primissimo caricamento, o permanentemente se il primo tentativo fallisce), il gap tra il titolo e il contenuto sottostante collassa a 4px invece dei 20px originali — nessuna regola compensa l'assenza della didascalia.
2. **Didascalia non invalidata su retry fallito**: `aggiornatoAlle` non viene mai azzerato nel `catch` di `carica()`. Se un primo caricamento riesce e un retry successivo fallisce, "Aggiornato alle 14:32" resta visibile e fisso sopra il messaggio d'errore — una piccola contraddizione di significato (rassicurazione + errore mostrati insieme).

A questo si aggiunge un problema di contrasto sulla stessa nuova didascalia: `--ink-faint` su `--cream` è calcolato a ~1.7:1, molto sotto soglia AA — coerente con un uso già esistente altrove nell'app di questo token per didascalie, ma questo fix ha aggiunto un nuovo caso d'uso reale (informazione di freschezza, non solo decorativa) dove il problema si sente di più.

Entrambe le valutazioni indipendenti segnalano esplicitamente rendimenti fortemente decrescenti su questo file: nessun P0/P1 rimasto, punteggio grezzo stazionario, i problemi residui sono tutti rifiniture su un componente già solidissimo.

## What's Working

- Il segnale di rischio resta centellinato, mai generalizzato: pallini d'allerta solo su giorni con avvisi reali, sempre accompagnati da testo sr-only.
- `.hour__cond` visibile in chiaro è un vero miglioramento di riconoscimento, non solo estetico.
- La nota "irrigazione sospesa" riusa la logica reale di cura (`pioggiaInArrivo`/`pioggiaCumulata2gg` importate da `useCure.js`), garantendo che meteo e cure non divergano mai.
- Il commento su `.adesso__flag` ora corrisponde esattamente al codice.

## Priority Issues

**[P2] Il margine anti-troncamento di `.hour__cond` non è stato effettivamente creato.**
Il rapporto larghezza/font è rimasto sostanzialmente invariato (anzi leggermente peggiorato). "Temporale con grandine" — la stringa che segnala il rischio più grave — è ora la più vicina al troncamento con ellissi.
Fix: allargare `.hour` più aggressivamente (es. 80px) così che il rapporto cresca davvero, oppure accorciare le etichette più lunghe di `WMO_LABEL`.

**[P3] Gap titolo→contenuto crolla a 4px quando `aggiornatoAlle` è `null`.**
Non solo un lampo del primo paint: se il primo caricamento fallisce, resta così permanentemente.
Fix: dare a `.ledger`/alla card d'errore un margin-top che compensi l'assenza della didascalia.

**[P3] `aggiornatoAlle` non invalidato su un retry fallito dopo un successo precedente.**
Resta visibile accanto a un messaggio di errore, implicando una freschezza che il sistema sa non essere vera.
Fix: azzerarlo all'inizio di `carica()`, oppure — per non perdere l'informazione utile — cambiare la label solo nel ramo d'errore ("Ultimi dati disponibili: 14:32").

## Persona Red Flags

**Riley (tester metodico)**: troverebbe "Temporale con grandine" al limite esatto della capacità di 2 righe, e la sequenza "carica bene → va offline → Riprova" con la didascalia congelata su un orario superato accanto al messaggio d'errore.

**Sam (accessibilità)**: la nuova didascalia a ~1.7:1 di contrasto è probabilmente impercettibile a bassa vista, vanificandone lo scopo rassicurante — debito di sistema reso più visibile da questo fix, non introdotto da esso.

**Casey (mobile distratta)**: comportamento del ribbon sostanzialmente invariato; se la tile parzialmente visibile fosse proprio quella con "Temporale con grandine" troncato, vedrebbe un frammento di avviso poco chiaro scorrendo distrattamente.

## Minor Observations

- `-webkit-line-clamp:2` non ha `text-overflow:ellipsis` esplicito ma non serve — l'implementazione box-based lo aggiunge da sola.
- Nessuna regione `aria-live` sulla didascalia di freschezza — coerente con "nessun allarme", da tenere a mente se in futuro si aggiungesse un auto-refresh periodico.

## Questions to Consider

- Se la didascalia non si aggiorna mai da sola restando la scheda aperta per ore, ha senso chiamarla "Aggiornato alle" senza nemmeno un refresh periodico leggero (30-60 min)?
- Vale la pena testare le larghezze con le stringhe reali più lunghe del catalogo invece di stimare "qualche px in più" a intuito ogni volta che si tocca `.hour`?
- Con il punteggio fermo a 25/28 per il secondo giro consecutivo, ha ancora senso investire altri cicli di critica su questo singolo file, o le energie renderebbero meglio altrove nell'app?
