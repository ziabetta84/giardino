---
target: src/views (sponsorizzabilità)
total_score: 31
max_score: 36
na_heuristics: 10
p0_count: 0
p1_count: 1
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views (sponsorizzabilità)"
timestamp: 2026-09-09T20-35-34Z
slug: src-views-sponsorizzabilit
---
Method: dual-agent (A: general-purpose sub-agent · B: inline, no browser tool exposed in this session)

## Punteggio di salute del design

| # | Euristica | Punteggio | Nota chiave |
|---|-----------|-------|-----------|
| 1 | Visibilità dello stato del sistema | 4 | Skeleton per view, stato "in attesa" richieste AI, banner token persistente |
| 2 | Corrispondenza sistema/mondo reale | 4 | Terminologia da giardiniere reale, tutto in italiano |
| 3 | Controllo e libertà dell'utente | 3 | Annulla ovunque, ma nessun undo dopo eliminazione (solo conferma preventiva) |
| 4 | Coerenza e standard | 3 | Pattern chiave coerenti; ma inline-style pesante e drift dai token proprio nelle view di servizio |
| 5 | Prevenzione degli errori | 3 | Validazioni base (nome duplicato, limite foto), pochi vincoli oltre `required` |
| 6 | Riconoscimento piuttosto che ricordo | 4 | Filtri visibili, icone, ricerca sempre presente |
| 7 | Flessibilità ed efficienza | 3 | Azioni di gruppo presenti, nessuna scorciatoia tastiera |
| 8 | Design estetico e minimalista | 4 | Aderenza forte al "Taccuino", niente rumore visivo |
| 9 | Riconoscere/diagnosticare/risolvere errori | 3 | Errori tradotti in più punti, ma messaggi Supabase grezzi (spesso in inglese) sul login |
| 10 | Guida e documentazione | n/a | App operativa personale, non prevista documentazione in-app |
| **Totale** | | **31/36** | **Buono (86%)** |

## Verdetto di specificità del design

**Autoriale, non un template di giardinaggio intercambiabile.** La regola "ink-pooling" delle icone, i "Due Battiti" di Zorba (`reagisci()`/`confermaCura()` in `ZorbaLogo.vue`), l'album a polaroid con didascalia manoscritta in Galleria, la scena a china stagionale di `HeroAiuola.vue` con View Transitions: sono tutti cablati nel flusso reale, non showcase isolati. Il codice porta decine di commenti che citano date di critica passate e il *perché* di scelte non ovvie — segno di iterazione vera con un punto di vista, non checklist.

Punto debole: le view "di servizio" (Account, Settings, Progetto, Concimi) usano molto `style="..."` inline invece delle classi di sistema (278 occorrenze totali in `src/views/*.vue`; `AccountView.vue` 37, `ProgettoView.vue` 34). Lo scanner deterministico conferma la stessa storia da un altro angolo: 59 valori "advisory" fuori dal sistema di design (36 font-size, 13 border-radius, 10 colori non documentati), concentrati proprio in quelle view e in alcuni componenti (`SelettoreSpecie.vue`, `MiniEditor.vue`, `GalleryView.vue`) — due assessment indipendenti che convergono sullo stesso sintomo: il risultato *visivo* regge, ma la disciplina del sistema si allenta fuori dalle schermate "vetrina".

**Evidenza automatica (deterministica)**: nessun errore bloccante nello scan (`impeccable detect`, 0 exit code); solo i 59 scostamenti advisory sopra citati. Nessuna evidenza browser disponibile in questa sessione (nessuno strumento di automazione browser esposto): la valutazione visiva si basa sulla lettura del codice, non su screenshot reali — dichiarato esplicitamente, non uno scan completo.

## Impressione generale

Le fondamenta reggono bene il confronto con un prodotto vero: 31/36 sulle euristiche di Nielsen è un punteggio alto per un progetto a sviluppatore singolo, e l'identità visiva (Zorba, acquerello, palette) non è solo dichiarata in DESIGN.md ma implementata con coerenza dove conta di più. La sponsorizzabilità non è minacciata da difetti UX generici, ma da due cose molto più specifiche e facili da isolare: un requisito architetturale (token GitHub) che trapela in UI proprio al primo contatto, e un divario di rifinitura tra le schermate che un utente apre spesso (Home, Meteo, Attività) e quelle che aprirebbe un valutatore tecnico per prime (Account, sorgente).

## Cosa funziona

- **`HeroAiuola.vue`**: scena SVG stagionale/diurna con ridisegno a china coreografato e View Transitions API per il cambio scena — ingegneria di frontend reale, non un gradiente CSS con etichetta.
- **Gestione errori per-riga in `AttivitaView.vue`**: ogni azione (cura singola, cura di gruppo, tappa) ha uno stato d'errore tracciato per chiave, pensato per l'uso reale su mobile con connessione instabile in giardino.
- **Distinzione "zero piante" vs "tutto in ordine"** in `HomeView.vue`: due stati vuoti concettualmente diversi con copy diversa, non un empty-state pigro riusato ovunque.
- **Prima impressione tecnica curata**: title, favicon, `theme-color`, script anti-flash per il dark mode, manifest PWA con nome/descrizione coerenti — dettagli che normalmente un side-project salta e che invece qui ci sono.

## Problemi prioritari

**[P1] Il commento "TEMPORANEO... da rimuovere quando non serve più" nel sorgente di `HomeView.vue` (righe 37-43, 272-274) racconta "prototipo" a chi legge il codice, anche se il pannello è correttamente escluso dalla build di produzione (`import.meta.env.DEV`, verificato: dead-code elimination di Vite).**
- Perché conta: uno sponsor tecnico che clona il repo (probabile, se l'agenzia valuta di investirci) legge il sorgente prima o insieme alla demo. Il rischio non è funzionale, è narrativo: comunica "lavoro non rifinito" nel punto più facile da controllare.
- Fix: rinominare il commento senza il tono "da buttare" (es. spiegare che è infrastruttura di QA visiva permanente, se lo è) o spostare il pannello dietro un flag dedicato invece di un commento che suona provvisorio.
- Comando suggerito: `/impeccable polish`

**[P2] Messaggi di errore grezzi di Supabase (spesso in inglese, es. "Invalid login credentials") mostrati direttamente in `AccountView.vue` sul login/registrazione — proprio nel momento di primo contatto.**
- Perché conta: viola la regola esplicita "nessuna stringa UI in inglese" già scritta in CLAUDE.md/PRODUCT.md, ed è il primo momento in cui uno sponsor che prova ad accedere con credenziali sbagliate per errore vedrebbe la crepa.
- Fix: mappare i messaggi Supabase noti (credenziali invalide, email già registrata, rate limit) a testo italiano prima di mostrarli.
- Comando suggerito: `/impeccable clarify`

**[P2] Divario di rifinitura tra le view "vetrina" (Home, Meteo, Attività — CSS scoped pulito) e le view "di servizio" che un valutatore aprirebbe per prime (Account, Progetto, Galleria) — confermato da entrambi gli assessment: 278 style inline nelle view, concentrati in Account (37) e Progetto (34); 59 valori fuori dal sistema di design (font-size/radius/colore) nello stesso gruppo di file.**
- Perché conta: il risultato visivo probabilmente regge oggi (le classi condivise sono giuste), ma è il tipo di deriva che peggiora ad ogni modifica futura e che un occhio tecnico nota subito confrontando due pagine.
- Fix: passare quelle view sui token/classi di sistema esistenti invece di `style` inline, come già fatto in Home/Meteo.
- Comando suggerito: `/impeccable polish`

**[P3] Il banner "Token GitHub non configurato" e il relativo campo in `AccountView.vue`/`App.vue` espongono un dettaglio architetturale (coda AI su GitHub/JSON) come richiesta di configurazione utente, subito dopo la registrazione.**
- Perché conta: per un first-timer (e per uno sponsor che prova l'app come farebbe un utente) è la domanda scomoda "perché un'app di giardinaggio mi chiede un token GitHub" nei primi 30 secondi — l'unico punto in cui l'architettura interna si vede invece di restare invisibile.
- Fix: rendere il banner chiaramente opzionale/rimandabile con una riga di spiegazione in linguaggio utente ("serve solo per le richieste all'assistente AI, puoi aggiungerlo più tardi"), non solo un avviso tecnico giallo.
- Comando suggerito: `/impeccable onboard`

## Persona a rischio

**Jordan (first-timer)**: si registra, e prima ancora di vedere una pianta incontra il banner giallo "Token GitHub non configurato" (`App.vue`) — un avviso tecnico senza contesto per un utente comune. Rischio concreto di abbandono nei primi 30 secondi, leggendolo come un errore di configurazione dello sviluppatore invece che un prompt normale.

**Casey (mobile distratta)**: in `PianteView.vue`, ricerca + filtro zona + filtro sottozona + sezione "urgenti" separata richiedono parecchio scroll orizzontale delle pillole su schermo piccolo; se le pillole attive non stanno tutte a vista, rischia di concludere erroneamente che una zona non ha piante.

## Osservazioni minori

- `ProgettoView.vue` e `GalleryView.vue` hanno rispettivamente 34 e 27 `style="..."` inline: stesso pattern di `AccountView.vue`, peserà su un futuro passaggio di dark-mode se non passano dai token.
- Colori non documentati che meritano una verifica puntuale: `#ddd`/`#999` in `MiniEditor.vue` (grigi generici, in tensione con la palette calda "da erbario" del sistema), `#d4b23c` in `ZorbaLogo.vue` (verificare se è una variante intenzionale di `gold`/`gold-dark` o un refuso).
- Il commento "TEMPORANEO" compare due volte nello stesso file (`HomeView.vue:37,272`) per lo stesso pannello — ridondante ma coerente tra loro.

## Domande da considerare

- Se un tecnico dell'agenzia legge il sorgente prima della demo, il commento "da rimuovere quando non serve più" comunica "prodotto finito" o "prototipo in corso"? La build è pulita, il sorgente racconta un'altra storia.
- Il requisito di un token GitHub personale per la coda AI regge il confronto con "prodotto pronto per terzi", o è il segnale più chiaro che l'architettura dati è ancora quella di un progetto personale cresciuto organicamente (vedi anche `richieste-agente.json` fuori scope dalla migrazione Supabase, per ora)?
- Le view più curate (Home, Meteo, Attività) coincidono esattamente con "cosa un utente vede spesso" — è una scelta consapevole su cui vale la pena essere espliciti con l'agenzia, o solo l'ordine in cui sono state scritte?
