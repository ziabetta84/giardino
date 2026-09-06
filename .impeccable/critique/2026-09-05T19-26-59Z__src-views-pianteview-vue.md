---
target: Elenco piante (src/views/PianteView.vue)
total_score: 20
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/PianteView.vue"
target_fingerprint: "sha256:bb02435c7ef2450fcc5f9693ab115fa7255d3a0e91238fe95c49714b05c35a11"
target_path: /Users/rob/Sites/localhost/giardino/src/views/PianteView.vue
timestamp: 2026-09-05T19-26-59Z
slug: src-views-pianteview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Euristica | Punteggio | Nodo specifico |
|---|-----------|-------|-----------------|
| 1 | Visibilità dello stato del sistema | 3 | Skeleton a 5 card durante il caricamento, spinner nel modale di eliminazione; manca solo una conferma esplicita post-eliminazione |
| 2 | Corrispondenza sistema/mondo reale | 2 | Il placeholder promette "Cerca per nome o specie…" ma il filtro cerca solo su `p.id`/`p.specie` (slug), mai su `p.varieta` — il campo mostrato in evidenza in ogni riga |
| 3 | Controllo e libertà dell'utente | 3 | Reset filtro con un tap, modale annullabile; manca un "azzera tutto" con più filtri attivi insieme (edge case minore) |
| 4 | Coerenza e standard | 1 | Tre violazioni verificabili: righe-card invece di filetti (contro Layout/Shapes/Don't di DESIGN.md), `--rose-dark` invece di `--rose-ink` per l'urgenza, stato vuoto reimplementato invece di riusare `.empty` |
| 5 | Prevenzione errori | 3 | Modale di conferma con testo esplicito sulle conseguenze ("verranno eliminate anche le foto associate") |
| 6 | Riconoscimento anziché ricordo | 3 | Filtri sempre visibili; il bottone "×" di eliminazione ha solo `title`, invisibile su touch |
| 7 | Flessibilità ed efficienza d'uso | 1 | Nessuna azione bulk, nessun controllo di ordinamento oltre l'automatico "urgenti primi", nessuna scorciatoia — pesa su un giardino con decine di piante |
| 8 | Estetica e design minimalista | 2 | Trattamento a card-con-ombra per riga aggiunge peso visivo non necessario; uso pesante di stili inline al posto di classi condivise esistenti |
| 9 | Aiutare a riconoscere/recuperare errori | 1 | `eliminaPianta()` ha `try/finally` ma nessun `catch`: un fallimento di rete lascia il modale aperto senza messaggio e senza via di recupero |
| 10 | Aiuto e documentazione | 1 | Nessun aiuto contestuale |
| **Totale** | | **20/40** | **Accettabile (fascia bassa)** |

## Design Specificity Verdict

Questa è l'unica vista lista dell'app che abbandona il pattern a filetti hairline per tornare a un'estetica da card-list generica: ogni riga (`PiantaRiga.vue:2`, `class="card hover-card pr"`) porta bordo, `border-radius:20px`, ombra ambientale e sollevamento all'hover — esattamente il pattern che DESIGN.md respinge esplicitamente in tre punti (Layout, Shapes, e un Don't dedicato: "non incorniciare in una card... una lista che già usa il pattern a filetti"). Ogni altra lista dell'app (`.dest`, `.feed`, `.task`, `.wxrow`, `.prow`) usa correttamente filetti da 1px. Con decine di piante (realtà multiutente, non i 5-10 della demo) il risultato è una colonna di ombre impilate — la firma di una dashboard SaaS generica, non di un quaderno.

A questo si somma un token colore sbagliato (`--rose-dark` invece di `--rose-ink`) proprio nel punto in cui `main.css` ha già documentato e corretto lo stesso identico errore altrove, e uno stato vuoto reimplementato ad hoc con una classe fantasma (`text-light`, mai definita) invece di riusare `.empty`. Punti di forza reali esistono (`.pill--acqua` per non rendere illeggibile l'icona su verde saturo, `pianteFiltrate` che evita di duplicare le urgenze, nomi in Fraunces) ma il vocabolario visivo specifico è applicato solo a metà: si riconosce subito che questa vista non ha ricevuto lo stesso passaggio di restyle "Taccuino" di Attività/Progetti/Concimi/Zone.

Scansione deterministica: pulita, 6 advisory (drift di font-size/radius), nessuna regola di accessibilità/contrasto rilevata dal detector — tutti i problemi di contrasto e di nesting HTML sono emersi dalla verifica manuale, non dallo strumento, il tipo di difetto che un detector non può strutturalmente vedere.

## Overall Impression

`PianteView.vue` funziona (filtri, ricerca, sezione urgenze) ma è la vista che si allontana di più dal sistema di design consolidato nel resto dell'app in questa sessione. Il problema principale non è un bug isolato ma una scelta strutturale — card-per-riga — che DESIGN.md vieta esplicitamente e che il resto dell'app ha già superato. A questo si aggiungono difetti concreti verificati con calcolo del contrasto: `--rose-dark` sull'etichetta urgenza fallisce AA (4.33:1 in light mode), `--ink-soft` sulla zona fallisce (3.21:1), e `--ink-faint` sulla varietà è quasi invisibile (1.82:1 in light, 1.62:1 in dark) — tre livelli di testo su quattro nella riga pianta sono sotto soglia o gravemente sotto soglia.

## What's Working

- `pianteFiltrate` (righe 187-189): quando non c'è filtro né ricerca, le piante urgenti sono escluse dalla lista "Tutte le piante" perché già mostrate in "Da curare" — evita di vedere la stessa pianta due volte, decisione silenziosa ma corretta.
- `.pill--acqua` per i filtri zona/sottozona: variante attiva con sfondo azzurro tenue invece del verde salvia pieno, per non rendere illeggibile l'icona azzurra di dominio — un dettaglio di produzione reale.
- `PiantaRiga.vue` rispetta comunque la Regola del Nome in Fraunces per nome/varietà, anche quando il resto del componente si allontana dal sistema.
- Nessun problema di scala: ogni `v-for` ha una key stabile (id, non indice), il filtro/ordinamento è O(n)/O(n log n), le miniature si caricano in un'unica chiamata — tiene bene fino a centinaia di piante.

## Priority Issues

**[P1] Righe-pianta come card impilate invece di filetti.**
`PiantaRiga.vue:2` — `<RouterLink class="card hover-card pr">`; `main.css:198-212` per `.card`/`.hover-card`. DESIGN.md lo vieta esplicitamente tre volte proprio per evitare l'estetica "da dashboard generico" che il progetto rifiuta per nome.
Fix: rimuovere `.card.hover-card`, adottare un pattern a filetti coerente con `.dest`/`.feed` (bordo 1px `var(--cream-dark)`, nessuna ombra a riposo).

**[P1] Tre livelli di testo sotto soglia AA nella riga pianta.**
`.pr__urg` (riga urgenza, `color: var(--rose-dark)`) → 4.33:1 in light mode, sotto 4.5:1 — l'esatto errore già corretto altrove (`main.css:812-815`, `--rose-ink` invece di `--rose-dark` con lo stesso identico ragionamento). `.pr__zona` (`color: var(--ink-soft)`) → 3.21:1 light / 4.32:1 dark, entrambi sotto soglia. `.pr__var` (`color: var(--ink-faint)`) → 1.82:1 light / 1.62:1 dark, quasi invisibile in entrambi i temi — e questo è il campo che dovrebbe distinguere piante della stessa specie.
Fix: `.pr__urg` → `--rose-ink`; `.pr__zona`/`.pr__var` → un token con contrasto verificato (es. `--ink-mid`, già usato altrove per testo secondario a norma).

**[P1] Eliminazione pianta senza gestione errori.**
`PianteView.vue:201-212` — `try { ...await...; daEliminare.value = null } finally { eliminando.value = false }`, nessun `catch`. Se una delle due chiamate fallisce, `daEliminare` non viene mai azzerato (era dentro il `try`, dopo gli `await`), lo spinner si ferma ma il modale resta aperto senza alcun messaggio — nessun modo di sapere se l'eliminazione è riuscita, parziale, o fallita.
Fix: stesso pattern già stabilito in PiantaView/GalleryView/ConcimiView — `catch` con messaggio inline nel modale, `daEliminare` preservato per un retry.

**[P2] La ricerca non cerca sul campo mostrato in evidenza (varietà).**
`PianteView.vue:179-183` filtra solo su `p.id`/`p.specie` (slug), mai su `p.varieta` — il dato che la riga mostra in evidenza (`pr__var`, es. "San Marzano") e che un utente con più piante della stessa specie userebbe proprio per distinguerle. Il placeholder promette una funzione che il codice non implementa.
Fix: includere `p.varieta` (e se disponibile senza costo, `specie?.nome`) nel filtro.

**[P2] Stato vuoto non distingue "nessuna pianta nel giardino" da "nessun risultato per il filtro".**
`PianteView.vue:76-83` — stesso messaggio fisso ("Prova a cambiare il filtro o la ricerca") sia con lista vuota per filtro attivo, sia per un giardino appena creato senza alcuna pianta — scenario reale e frequente ora che l'app è multiutente. Usa anche `class="text-light"`, mai definita in nessun CSS del progetto (classe fantasma, innocua solo perché lo stile reale viene da `style` inline).
Fix: condizionare il messaggio — con store senza piante e nessun filtro attivo, invitare ad aggiungere la prima pianta con link diretto.

**[P3] Bottone di eliminazione sotto soglia di tocco, senza aria-label, annidato in un link.**
`PiantaRiga.vue:24` — `<button title="Elimina">×</button>` dentro `<RouterLink class="card hover-card pr">` (riga 2): `<button>` dentro `<a>` è contenuto non valido HTML5. Il nome accessibile reale è "×" (il testo del bottone ha priorità su `title`), non "Elimina". Area cliccabile stimata ~34×34px (`.pr__del { padding: 8px 10px; font-size: 18px }`), sotto i 44×44px che l'app impone ovunque altrove.
Fix: `aria-label="Elimina pianta"`, area cliccabile a 44×44px minimo, valutare di spostarlo fuori dal contenuto interattivo del link.

## Persona Red Flags

**Casey (mobile, in giardino)**: bottone elimina ~34px, difficile da colpire con un tocco impreciso all'aperto; ogni riga-card con ombra aumenta l'altezza per pianta, allungando lo scroll one-handed con 30-40 piante; la sezione "Da curare" scompare non appena si tocca un filtro di zona, togliendo l'indicatore di urgenza più leggibile proprio quando Casey cerca "cosa curo oggi in questa zona".

**Sam (screen reader/tastiera)**: `<button>` annidato in `<RouterLink>` — struttura non valida, comportamento imprevedibile con tab/screen reader; `.pr__urg` sotto soglia AA proprio sull'informazione più critica della riga (quale cura manca); il campo di ricerca non ha `aria-label`/`<label>`, solo un placeholder che sparisce alla digitazione.

**Jordan (nuovo utente, giardino appena creato)**: con zero piante riceve "Prova a cambiare il filtro o la ricerca" quando non ha ancora usato né l'uno né l'altra — istruzione fuorviante nel momento in cui serve la guida più chiara.

## Minor Observations

- `class="text-light"` (righe 81-82) non è definita da nessuna parte in `src/` — classe fantasma.
- Uso pesante di stili inline in tutto il file dove esistono già pattern condivisi equivalenti (`.slabel`, `.empty`).
- Nessuna delle viste con pillola "+Aggiungi" (Zone, Sottozone, Concimi, Progetti, Gallery, Piante) usa il vero `button-primary` sage pieno del design system per l'azione di creazione — convenzione app-wide su cui riflettere, non un difetto locale di questo file.
- Il badge campanella sulla miniatura compare solo quando c'è anche una foto — una pianta urgente senza foto (il caso più comune) perde questo segnale e si affida solo al testo `.pr__urg`.
- `.pill` (filtri zona/sottozona) ha `min-height:36px`, sotto i 44px standard dei controlli dell'app — sistemico, non specifico di questo file.

## Questions to Consider

- Se ogni altra lista dell'app usa i filetti, perché la lista più usata quotidianamente — quella delle piante — è rimasta sull'estetica a card? È un residuo pre-restyle "Taccuino"?
- Con un giardino da 40+ piante multiutente reale, questa vista scala visivamente (non solo in performance), o resta pensata per la demo da 5-10 piante?
- Cosa succede davvero, nell'interfaccia, quando `eliminaPianta()` fallisce a metà — l'utente lo scoprirebbe mai, o crederebbe che la pianta sia stata eliminata quando magari solo la cartella foto lo è stata?
