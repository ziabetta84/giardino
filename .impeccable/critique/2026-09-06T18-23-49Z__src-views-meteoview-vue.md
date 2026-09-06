---
target: Meteo (src/views/MeteoView.vue)
total_score: 21
max_score: 28
na_heuristics: 5,7,10
p0_count: 0
p1_count: 0
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/MeteoView.vue"
target_fingerprint: "sha256:8a33d6061746d0a9770ad521070c5d49e87293bbc56c902e8ca154be44fb7d2a"
target_path: /Users/rob/Sites/localhost/giardino/src/views/MeteoView.vue
timestamp: 2026-09-06T18-23-49Z
slug: src-views-meteoview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Euristica | Punteggio | Nodo specifico |
|---|-----------|-------|-----------------|
| 1 | Visibilità dello stato del sistema | 3 | Skeleton, evidenza ora corrente, stato d'errore chiaro; manca un'indicazione di freschezza dei dati |
| 2 | Corrispondenza sistema/mondo reale | 3 | Linguaggio naturale coerente; il buco in `WMO_LABEL` (codici 77/85/86) rompe la corrispondenza icona↔testo per condizioni di neve rare |
| 3 | Controllo e libertà dell'utente | 4 | `FoglioLaterale` con Esc, click overlay, X, gestione del focus — solido |
| 4 | Coerenza e standard | 3 | I fix hanno eliminato le vere incoerenze (Caveat, colore, soglia); resta che "Adesso" non porta mai un indicatore di rischio come ogni riga della lista giorni |
| 5 | Prevenzione degli errori | n/a | Vista di sola lettura, nessun input/azione distruttiva |
| 6 | Riconoscimento anziché ricordo | 3 | Info critiche sempre testo visibile; nastro orario icona+temperatura con descrizione solo sr-only, pattern consolidato da app meteo |
| 7 | Flessibilità ed efficienza d'uso | n/a | Nessun utente esperto necessita di scorciatoie per leggere il meteo |
| 8 | Estetica e design minimalista | 3 | La nuova nota irrigazione si inserisce senza rumore; pagina densa ma ordinata |
| 9 | Aiutare a riconoscere/recuperare errori | 2 | Messaggio ora in italiano semplice e dice "riprova", ma non esiste un bottone per farlo — l'interfaccia promette un'azione che non offre |
| 10 | Aiuto e documentazione | n/a | Vista non necessita di documentazione contestuale |
| **Totale** | | **21/28 (75%)** | **Buono** (in miglioramento da 18/28, 64%) |

## Design Specificity Verdict

Solido: la barra di escursione termica ricalibrata sul range della settimana, il mini-grafico SVG disegnato a mano (non una libreria di charting) e ora la nota "irrigazione sospesa" che collega esplicitamente il meteo alla logica di cura reale sono scelte specifiche di questo prodotto. I tre difetti del giro precedente (Caveat fuori luogo, soglia scollegata, contrasto non conforme) erano esattamente il tipo di cucitura che tradisce un componente importato da un altro sistema; ripararli aumenta misurabilmente la coerenza con "Il Taccuino da Giardino" invece di limitarsi a tappare un bug isolato. Verifica tecnica completa: contrasto 7.36:1/8.62:1 in entrambi i temi, aritmetica pioggia tracciata numero per numero (nessun rischio NaN/doppio arrotondamento rilevante), `.sr-only` byte-per-byte conforme al pattern standard, nessuna duplicazione-bug tra alertbox di pagina e foglio di dettaglio (testo diverso per contesto, non ripetizione identica).

## Overall Impression

Tutti e 6 i fix confermati corretti da entrambe le valutazioni indipendenti, punteggio da 18 a 21/28 (64%→75%). Emergono due problemi reali che i fix stessi hanno reso più visibili: lo stato d'errore ora dice "riprova" in italiano ma non offre alcun modo di farlo dall'interfaccia (il testo promette un'azione che non esiste), e il nuovo alt testuale per il nastro orario eredita silenziosamente un buco preesistente in `WMO_LABEL` (mancano le chiavi per 3 codici di neve/nevischio) — per quelle ore lo screen reader non annuncia nulla, tornando di fatto al comportamento "icona muta" che il fix voleva eliminare, solo per un sottoinsieme di condizioni invece che per tutte.

## What's Working

- Coerenza cromatica del segnale "irrigazione sospesa": acqua-ink invece di rosa, rispetta con precisione la regola di dominio (rosa solo per urgenza/distruttivo) invece di trattare ogni notifica come un allarme.
- Unificazione del criterio senza over-engineering: esportare la soglia da `useCure.js` invece di rifare tutto il fetch è pragmatico e documentato nel codice stesso, evitando sia il bug originale sia un refactor sproporzionato.
- Grafico orario in `MeteoGiorno.vue`: SVG fatto a mano con `role="img"` e `aria-label` descrittivo — un dettaglio di qualità che nessuno dei 6 fix ha rotto.
- Tutti e 6 i fix verificati corretti con evidenza tecnica puntuale (contrasto calcolato, aritmetica tracciata, null-safety confermata).

## Priority Issues

**[P2] Stato d'errore senza azione di recupero.**
Il messaggio dice "Controlla la connessione e riprova" ma il template non offre alcun bottone "Riprova" — l'unica via è ricaricare l'app o cambiare pagina e tornare.
Fix: un bottone che richiami `carica(lat, lon)` con gli stessi parametri usati in `onMounted`.

**[P2] `WMO_LABEL` incompleto rompe sia la descrizione visibile sia il nuovo alt testuale per 3 codici meteo.**
`WMO_LABEL` non copre i codici 77/85/86 (nevischio, rovesci di neve), mentre la mappa icone sì. Per queste condizioni sia la descrizione visibile sia il nuovo `<span class="sr-only">` risultano stringa vuota — non è una regressione di questo fix (il buco è preesistente e affliggeva già la descrizione visibile), ma la correzione di accessibilità eredita silenziosamente questo limite.
Fix: aggiungere le tre chiavi mancanti a `WMO_LABEL`.

**[P3] La card "Adesso" non porta mai un indicatore di rischio, a differenza di ogni riga della lista giorni.**
Se oggi stesso ha un avviso, compare in "Occhio a questi giorni" come "Oggi — ..." ma la card "Adesso" in cima non ha alcun equivalente del `.day__flag` — l'utente deve fare il collegamento mentale da solo.

## Persona Red Flags

**Sam (screen reader/tastiera)**: il nastro orario ora ha testo alternativo, ma per le ore con codice 77/85/86 quel testo è vuoto — un'icona che "non dice niente", esattamente il difetto che il fix voleva eliminare, solo spostato su un sottoinsieme di condizioni. Se apre lo stato d'errore, gli viene detto "riprova" ma nessun elemento permette di farlo senza uscire dalla pagina.

**Riley (tester metodico)**: neve leggera/nevischio (WMO 77) produce un'icona senza descrizione sia a schermo sia per screen reader; l'errore di rete non offre modo di "ritentare" dall'interfaccia stessa.

**Casey (mobile, in giardino)**: nessuna red flag specifica di questo giro — target di tap adeguati, la nota irrigazione non aggiunge frizione. Unico neo: se interrompe l'app durante un errore di rete, deve ricordarsi di ricaricare da sola.

## Minor Observations

- `.day__wd`/`.adesso__label` a peso 600 invece del 700 documentato in DESIGN.md per "Label" — non introdotto da questo fix (combacia con `.feed__tag`/`.st`/`.step__esito` già esistenti), vale la pena allineare la documentazione alla pratica reale.
- `MeteoGiorno.vue`'s `.mg__avvisi` usa `a.testo` come key del `v-for` invece del già disponibile `a.key` (univoco) — nessun bug osservabile oggi, ma scelta meno robusta.
- I 6-7 punti cliccabili simultanei della lista giorni + card "Adesso" sono al limite superiore della regola dei 4±3 elementi — accettabile per un pattern da calendario, da tenere d'occhio.
- Chiudere il foglio di dettaglio smonta `MeteoGiorno` istantaneamente mentre il contenitore anima l'uscita per ~260ms: per quella finestra il pannello scivola via vuoto — pattern preesistente condiviso da tutta l'app, non introdotto da questo giro.

## Questions to Consider

- `pioggiaInArrivo`/`pioggiaCumulata2gg`/`SOGLIA_PIOGGIA_MM` vivono ora in `useCure.js`, un composable il cui nome dichiara logica di cura delle piante: è la casa giusta per una funzione che una vista meteo importa per la propria copy, o la direzione di dipendenza dovrebbe essere invertita?
- Se il messaggio d'errore dice esplicitamente "riprova", perché l'unica via per farlo davvero è uscire dalla pagina?
- Ora che esiste un pattern consolidato per "questo giorno ha un rischio", ha senso che l'unico giorno a non portarlo mai sia proprio "oggi" — l'unico per cui l'utente sta probabilmente già decidendo un'azione?
