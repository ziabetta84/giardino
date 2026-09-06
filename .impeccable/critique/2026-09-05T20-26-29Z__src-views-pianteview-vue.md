---
target: Elenco piante (src/views/PianteView.vue)
total_score: 27
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 1
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/PianteView.vue"
target_fingerprint: "sha256:49b418d4cbc77487cf46867ae74abbb4e416ae13603935c1c22031aee6485f62"
target_path: /Users/rob/Sites/localhost/giardino/src/views/PianteView.vue
timestamp: 2026-09-05T20-26-29Z
slug: src-views-pianteview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Euristica | Punteggio | Nodo specifico |
|---|-----------|-------|-----------------|
| 1 | Visibilità dello stato del sistema | 3 | Skeleton, spinner ed errore nel modale coprono bene l'eliminazione; manca solo una conferma esplicita di successo oltre alla scomparsa della riga |
| 2 | Corrispondenza sistema/mondo reale | 4 | Lessico da giardino coerente, ordine naturale, italiano ovunque |
| 3 | Controllo e libertà dell'utente | 3 | Esc/Annulla nel modale, filtro "Tutte" per azzerare; manca una "×" per svuotare la ricerca in un tocco |
| 4 | Coerenza e standard | 2 | `.dest` porta sempre un chevron di navigazione, `.pr` no; il bottone elimina usa `--ink-faint` qui e in ConcimiView ma `--rose-ink` in ZoneView per lo stesso ruolo |
| 5 | Prevenzione errori | 3 | Conferma obbligatoria prima di eliminare c'è; il gap di 4px tra riga-link e bottone elimina resta un rischio attutito, non prevenuto |
| 6 | Riconoscimento anziché ricordo | 3 | Filtri sempre visibili, icona+testo per zona; manca solo l'affordance di navigabilità sulla riga |
| 7 | Flessibilità ed efficienza d'uso | 2 | Nessuna azione bulk, nessuna scorciatoia da tastiera |
| 8 | Estetica e design minimalista | 3 | Lista pulita, gerarchia chiara, nessun rumore visivo superfluo |
| 9 | Aiutare a riconoscere/recuperare errori | 3 | Messaggio in italiano semplice con azione suggerita, stato preservato |
| 10 | Aiuto e documentazione | 1 | Nessun aiuto contestuale, invariato |
| **Totale** | | **27/40** | **Accettabile, fascia alta** (in miglioramento da 20/40) |

## Design Specificity Verdict

La meccanica di riga resta un pattern di lista generico nella struttura, ma i dettagli sono ben ancorati al prodotto: nome specie sempre in Fraunces, varietà in corsivo come nota manoscritta secondaria, tessera con tinta di dominio invece di un placeholder grigio, sezione "Da curare" che rende visibile il differenziatore di prodotto (calcolo automatico delle urgenze) senza toni ansiogeni. Non è design "d'autore" aggiuntivo, ma coerente esecuzione del sistema esistente.

Scansione deterministica: pulita, solo 4 advisory pre-esistenti (font-size/radius), nessuna nuova dai 6 fix. Verifica tecnica approfondita conferma tutti e 6 i fix corretti con evidenza puntuale (nesting HTML, nome accessibile, target di tocco 44px letterale, contrasto 6.89–9.76:1 in entrambi i temi per i tre testi corretti, wiring errore/retry, filtro null-safe, stati mutuamente esclusivi). La revisione qualitativa trova però che lo stesso identico bug di contrasto appena corretto sul testo è sopravvissuto su un elemento adiacente toccato dallo stesso fix.

## Overall Impression

I 6 fix hanno funzionato: punteggio da 20 a 27/40, nessuna regressione tecnica trovata da nessuna delle due valutazioni indipendenti. Resta però un pattern ricorrente in questa sessione — un fix locale ben fatto che non si propaga al dettaglio adiacente più ovvio: il fix del bottone elimina ha sistemato HTML/aria-label/dimensione ma ha lasciato il colore del glifo "×" a `--ink-faint` (1.70:1, praticamente invisibile), la stessa classe di bug appena corretta due righe più sopra sul testo urgenza/zona/varietà. A questo si aggiunge che `.pill`/`.section-label` — componenti condivisi usati da questa stessa pagina per i filtri e le etichette di sezione — restano sotto soglia AA con gli stessi numeri già documentati, semplicemente perché vivono fuori da `PiantaRiga.vue` e non erano nello scope del fix originale.

## What's Working

- Sezione urgenze separata e non allarmistica: traduce il vero valore di prodotto senza toni ansiogeni, coerente con "nessuna urgenza visiva se non quella reale" di DESIGN.md.
- Gestione robusta dei dati mancanti nella ricerca e nel filtro sottozona: `?? ''`/`?.` ovunque servono, incluso il calcolo delle sottozone effettivamente in uso.
- Contratto errore/retry con `ModalConferma` implementato esattamente come nel resto dell'app, verificato riga per riga contro il componente reale — nessuna reinvenzione.
- Tutti e 6 i fix precedenti verificati corretti con evidenza tecnica puntuale (contrasto calcolato, nesting HTML, gating degli stati).

## Priority Issues

**[P1] Il bottone elimina è praticamente invisibile.**
`PiantaRiga.vue` — `.pr__del { color: var(--ink-faint) }` dà 1.70:1 (light)/1.78:1 (dark), ben sotto anche la soglia 3:1 per elementi grafici. È la stessa classe di bug appena sanata sul testo della riga, non controllata sul bottone toccato dallo stesso fix. `ZoneView.vue` usa `--rose-ink` per lo stesso tipo di bottone.
Fix: allineare `.pr__del` a `--rose-ink`.

**[P2] Nessuna affordance di navigabilità sulla riga.**
Rimossa la card (e il suo hover-lift), `.pr__link` non ha alcuno stile `:hover`/`:active` né un chevron, a differenza di `.dest` che lo ha sempre. La riga non comunica più visivamente "questo porta a un dettaglio".
Fix: aggiungere un chevron coerente con `.dest__chev`, o quantomeno uno stato `:active` sottile.

**[P2] Gap di soli 4px tra l'area di navigazione e il bottone elimina.**
`.pr { gap: 4px }` tra `.pr__link` (porta al dettaglio) e `.pr__del` (azione distruttiva) senza alcuna separazione visiva. Su mobile a una mano il rischio di toccare "elimina" per errore mentre si mira alla riga è reale, mitigato solo dalla conferma.
Fix: aumentare il gap o inserire un divisore visivo leggero tra le due zone di tap.

**[P3] `title="Elimina"` vs `aria-label="Elimina pianta"` non coincidono.**
Piccola incoerenza di rifinitura, nessun impatto funzionale.

**[Da verificare in browser, non un difetto confermato] Possibile flash dello stato vuoto al primo caricamento diretto su `/piante`.**
`giardinoVuoto` è gated correttamente sotto `v-else` di `store.loading`, ma la route è caricata lazy: un bookmark/refresh diretto su `/piante` potrebbe in teoria mostrare per un frame "Il tuo giardino è ancora vuoto" prima che `caricaTutto()` completi, a seconda di quale delle due operazioni asincrone (chunk della rotta vs caricamento dati) risolve per prima. Non verificabile senza browser reale in questa sessione.

## Persona Red Flags

**Sam (screen reader/bassa visione)**: aria-label e target di tocco del bottone elimina sono corretti, ma il suo glifo "×" a 1.7:1 è invisibile senza screen reader attivo. Le pillole di filtro zona/sottozona (3.21:1) e le etichette "Da curare"/"Tutte le piante" (~3.0:1) restano sotto AA — controlli primari della pagina, non dettagli marginali.

**Casey (mobile, in giardino)**: il gap di 4px tra riga-link e bottone elimina, senza divisore visivo, è un rischio concreto di tocco impreciso scorrendo rapidamente una lista di decine di piante.

**Riley (tester metodico)**: la ricerca con `varieta`/`specie` mancante non genera eccezioni (verificato). Il caso "primo caricamento diretto su `/piante`" (bookmark, refresh, PWA riaperta su quella rotta) merita un test reale in browser per il possibile flash dello stato vuoto.

## Minor Observations

- Molti stili inline sparsi nel template invece di classi scoped — non visibile all'utente, ma è proprio così che il gap di 4px del bottone elimina è passato inosservato.
- I due stati vuoti riusano la stessa icona `foglia`; una leggera differenziazione (es. `cerca` per "nessun risultato") rafforzerebbe la distinzione appena introdotta.
- `PianteView.vue` ha ora due punti di CTA "aggiungi pianta" (in alto e nello stato vuoto) mentre `ZoneView.vue` con lo stesso caso non ne ha uno nello stato vuoto — piccola asimmetria tra viste sorelle.

## Questions to Consider

- Il colore `--ink-faint` compare sia sul bottone elimina di `PiantaRiga` sia su quello di `ConcimiView`, mentre `ZoneView` usa `--rose-ink` per lo stesso ruolo: vale la pena una passata trasversale su tutti i bottoni-elimina dell'app invece di correggerli uno alla volta?
- Se `.dest` porta sempre un chevron per segnalare "questa riga naviga altrove", è una scelta deliberata che `PiantaRiga` non lo faccia, o un'omissione nel passaggio da card a filetto?
- Con 6 zone reali già oggi, la riga di filtri è vicina alla soglia "5-7, attenzione" della rubrica del carico cognitivo: serve un piano prima che diventi un problema reale?
