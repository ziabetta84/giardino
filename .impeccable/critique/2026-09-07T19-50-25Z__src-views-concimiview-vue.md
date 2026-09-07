---
target: ConcimiView
total_score: 24
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 1
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/ConcimiView.vue"
target_fingerprint: "sha256:d96d2dcbaee0280315eae011f2cbb40fe899f1ff2290b4bc4097c00ccc640dd0"
target_path: /Users/rob/Sites/localhost/giardino/src/views/ConcimiView.vue
timestamp: 2026-09-07T19-50-25Z
slug: src-views-concimiview-vue
---
Method: dual-agent (A: design-review subagent · B: detector-evidence subagent)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Skeleton loading, spinner nel knob del toggle durante il salvataggio, senza spostamenti di layout. |
| 2 | Match System / Real World | 3 | "Concimi"/"dispensa"/NPK, vocabolario corretto per un giardiniere — ma NPK resta senza spiegazione per un principiante. |
| 3 | User Control and Freedom | 3 | Foglio richiudibile (X/backdrop/Esc), eliminazione dietro conferma con proprio Annulla — mancano vie d'uscita solo sulla riga stessa (vedi accessibilità sotto). |
| 4 | Consistency and Standards | 2 | Riusa fedelmente `.feed`/`.care__ic`/`.pill`/`.foglio-actions`, ma eredita anche una violazione sistemica: i bottoni del Foglio sono forzati a `min-height:40px` inline, sotto il minimo di 44px dell'app. |
| 5 | Error Prevention | 3 | Salva disabilitato a nome vuoto, eliminazione dietro conferma, `min="0"` sugli input NPK. |
| 6 | Recognition Rather Than Recall | 3 | NPK e tag "terminato" visibili direttamente in lista. |
| 7 | Flexibility and Efficiency | 1 | Nessuna ricerca/filtro/ordinamento alternativo, nessuna azione bulk, nessun percorso da tastiera per aprire una riga. |
| 8 | Aesthetic and Minimalist Design | 2 | Pulito nel dettaglio, ma la riga ammassa icona + testo + badge NPK + toggle + elimina in una larghezza fissa molto stretta. |
| 9 | Error Recovery | 3 | Messaggi di errore specifici per salvataggio/eliminazione/toggle, quello del toggle nomina il concime coinvolto. |
| 10 | Help and Documentation | 1 | Nessuna spiegazione di cosa significhino i numeri NPK o come funzioni l'abbinamento con le piante. |
| **Total** | | **24/40** | **Accettabile** |

## Design Specificity Verdict

**Valutazione LLM (Assessment A):** ConcimiView è ormai correttamente "vestita" nel sistema Taccuino — nome in Fraunces, tessera icona olive con ink-pooling, linguaggio da dispensa, righe a filetti invece di card impilate — ma non è ancora *autorata* per cosa sia davvero una dispensa di concimi. L'unica vera intelligenza di prodotto di questa funzione, il matching a distanza NPK di `useConcimi.js` (`classificaConcimiPerFabbisogno`, `concimeConsigliato`, soglia 0.15), resta completamente invisibile in questa vista: chi sfoglia la dispensa non vede mai quale concime venga effettivamente consigliato a quale pianta, né perché. Il dettaglio più specifico del prodotto — la distinzione `formattaNPK` tra "N/D" e "0" per un concime fatto in casa mai testato — vive nella logica ma non ha alcun riscontro visivo in questa schermata (nessuna differenziazione dei concimi "N/D" in lista, nessuna spiegazione di cosa significhino i numeri per un principiante). L'interruttore disponibilità resta l'elemento più genericamente "da SaaS" della pagina — una pillola/pallino in stile iOS standard — accanto a icone disegnate a china.

**Scansione deterministica (Assessment B):** Il detector segnala ancora 5 riscontri, tutti advisory: righe 8 e 74 (12px, testo di errore — pattern ripetuto identico in `SettingsView.vue`, `AccountView.vue`, `ProgettoView.vue`, `GalleryView.vue`, `App.vue`, `StatusBar.vue`, `MeteoView.vue`: una convenzione di fatto trasversale a tutto il repo, non un'invenzione di questo file), riga 241 (raggio 8px sul bottone elimina, verificato identico a `.pr__del` in `PiantaRiga.vue:183`, esplicitamente lo stesso pattern citato nel commento del codice), riga 245 (20px sul glifo "×", confrontabile con i 18px dello stesso ruolo in `PiantaRiga.vue:188`) e riga 288 (10px sul glifo dello spinner nel toggle — qui senza un precedente diretto nel codebase, essendo il primo `.toggle-switch` esistente). Nessun falso positivo di lettura; quattro dei cinque riscontri sono riusi verificabili di pattern già stabiliti altrove, non nuovo drift introdotto da questo file.

**Overlay visivi:** non disponibili di nuovo — nessuno strumento di controllo browser è esposto in questo ambiente (verificato da entrambi gli assessment tramite ricerca esplicita nei tool disponibili, non per assunzione).

## Overall Impression

Rispetto al giro precedente (22/40), la schermata ha chiuso i cinque problemi allora prioritari — bersaglio di eliminazione a 44px, "N/D" invece di "0-0-0", nome in Fraunces, tessera icona olive, CTA nell'empty state — e il punteggio sale a 24/40. La prossima soglia da superare non è più di fedeltà visiva ma di sostanza: la riga apre il form di modifica solo al clic del mouse (inaccessibile da tastiera/screen reader), e la vista continua a non mostrare mai l'unica cosa che la rende "di questo giardino" — quale concime serva a quale pianta.

## What's Working

1. **La distinzione N/D vs. zero in `formattaNPK`** è un giudizio di dominio preciso: un concime fatto in casa mai testato non si legge più come "non contiene nutrienti". Non è formattazione di superficie, è vero product thinking.
2. **Il bottone elimina a 44px con filetto verticale** replica esattamente il pattern `.pr__del` di `PiantaRiga.vue` — la stessa soluzione, applicata in modo identico in due viste diverse, a un problema reale di tocco accidentale.
3. **Il feedback di caricamento in-place sul toggle** (spinner nel pallino da 18px) dà un riscontro per-riga senza alcuno spostamento di layout — una soluzione compatta e misurata.

## Priority Issues

**[P1] La riga si apre in modifica solo al clic del mouse: inaccessibile da tastiera e screen reader.**
- **Perché conta**: `&lt;div class="feed feed--tap" @click="apriModifica(c)"&gt;` non ha `tabindex`, `role`, né gestore da tastiera — è l'unico modo per modificare un concime esistente, ed è totalmente fuori dall'ordine di tabulazione e invisibile alla tecnologia assistiva. `PiantaRiga.vue` risolve lo stesso bisogno con un `&lt;RouterLink&gt;` nativamente focalizzabile; `AgenteView.vue` con `role="button" tabindex="0"` + gestori da tastiera sullo stesso pattern `.feed--tap`. Un utente da tastiera o screen reader può toccare/eliminare/attivare il toggle di una riga, ma non aprirla.
- **Fix**: aggiungere `role="button" tabindex="0"` e `@keydown.enter.prevent="apriModifica(c)" @keydown.space.prevent="apriModifica(c)"` alla riga, sullo stesso modello già presente in `AgenteView.vue`.
- **Comando suggerito**: `/impeccable audit`

**[P2] Lo stato "disponibilità" è codificato due volte, e la codifica ridondante abbassa il contrasto del testo.**
- **Perché conta**: la disponibilità è già comunicata dal tag testuale "terminato" (rosa-ink) *e* da `opacity:.7` su tutta la riga — che attenua contemporaneamente nome, descrizione e NPK proprio sulle righe che un utente deve leggere per decidere se riordinare. Alle dimensioni 10.5–11px di `.feed__d`/`.feed__npk`, questa è esattamente la fascia più sensibile a una riduzione di contrasto.
- **Fix**: mantenere solo il tag testuale "terminato" (già sufficiente da solo) e rimuovere l'opacità sull'intera riga, oppure limitare l'attenuazione alla sola tessera icona.
- **Comando suggerito**: `/impeccable polish`

**[P2] La larghezza fissa della riga (icona 34px + NPK + toggle 42px + elimina 44px ≈ 205-215px di chrome non comprimibile) lascia poco spazio al nome su schermo stretto, e né il nome né la descrizione troncano.**
- **Perché conta**: un nome realistico ("Concime organico universale a lenta cessione") va a capo in modo scomodo contro il gruppo NPK/toggle/elimina, indebolendo la composizione "calma e generosa" del Taccuino e aumentando il rischio di tocco tra il toggle (senza alcun filetto di separazione, a differenza del bottone elimina) e gli elementi adiacenti.
- **Fix**: spostare il badge NPK su una seconda riga sotto il nome (come fa `.pr__zona` in `PiantaRiga.vue` per la zona), oppure spostare il toggle fuori dalla riga densa, dato che il tag "terminato" comunica già lo stesso stato.
- **Comando suggerito**: `/impeccable layout`

**[P2] L'intelligenza di dominio che giustifica questa funzione non è mai mostrata qui.**
- **Perché conta**: il matching NPK di `useConcimi.js` (usato altrove per i suggerimenti di cura) non ha alcuna presenza in ConcimiView — nessun accenno di "adatto per", nessuna indicazione di quali piante un concime serva bene. È il divario concreto dietro il verdetto di specificità: l'unica cosa che farebbe sentire questa la dispensa *di questo giardino* invece di una lista d'inventario qualsiasi.
- **Fix**: anche un accenno leggero — es. "adatto per: Rosa, Limone" ricavato invertendo `classificaConcimiPerFabbisogno` per concime — riconnetterebbe la schermata al resto del sistema di cura.
- **Comando suggerito**: `/impeccable colorize`

**[P3] Il rispetto del minimo di 44px dell'app è rotto in due punti di questa stessa schermata (Salva/Annulla a 40px inline, pillole "+ Aggiungi" a 36px).**
- **Perché conta**: la regola dei 44px esiste proprio per l'uso in giardino, una mano sola, mani potenzialmente sporche/bagnate — e questi sono esattamente i bottoni che si toccano per aggiungere un concime da lì. È però un pattern sistemico copiato identico in `ZoneView.vue`/`SottozoneView.vue`/`ProgettiView.vue`, non un'invenzione di questo file.
- **Fix**: rimuovere gli override inline `min-height:40px` su Salva/Annulla (eredita i 44px di `.btn`); introdurre una variante pillola più grande per i CTA primari invece di riusare la pillola-filtro da 36px. Da valutare a livello di sistema, non solo qui.
- **Comando suggerito**: `/impeccable audit`

## Persona Red Flags

**Sam (accessibilità)**: la riga che apre l'editor è un `&lt;div&gt;` non interattivo, del tutto irraggiungibile da tastiera/screen reader (Priority 1); i bottoni toggle hanno `aria-label` sull'azione ma nessun `role="switch"`/`aria-checked`; l'`opacity:.7` sull'intera riga "terminato" riduce il contrasto proprio dove un utente ipovedente ne ha più bisogno.

**Casey (mobile, in giardino)**: i due bottoni che questa persona userebbe di più — la pillola header "+ Aggiungi" e il Salva nel Foglio — sono entrambi sotto il minimo di 44px (Priority 5); il toggle (42×24px) è a soli 11px dal bottone elimina da 44px, senza alcun filetto di separazione a proteggerlo (a differenza del bottone elimina, che quel filetto ce l'ha).

**Jordan (prima volta)**: i tre campi NPK nel form sono input nudi etichettati solo "N"/"P"/"K", senza un esempio di formato o una spiegazione di dove trovare quei numeri (sono stampati sulla confezione del concime, es. "10-10-10") — un principiante non ha modo di capire perché inserirli conti, dato che il matching a cui servono resta invisibile (Priority 4).

## Minor Observations

- Il banner di errore del toggle (righe 8-10) usa uno `style` inline ad hoc invece del componente `.alertbox`/`.alertbox--rose` già esistente in `main.css` — tre superfici di errore diverse in questa sola schermata (banner in cima, `&lt;p&gt;` nel Foglio, `.mc-errore` di ModalConferma) finiscono stilizzate in tre modi leggermente diversi per lo stesso concetto di "errore".
- `apriModifica` assume che `c.npk` esista sempre (`c.npk.n`); una riga legacy con `npk: null` lo romperebbe — varrebbe un `c.npk ?? {}` difensivo.
- `form.value` resetta i campi NPK a `null` in `apriNuovo()`, coerente con l'uso di `null` come sentinella introdotto in questo giro di fix.

## Questions to Consider

- Se il motore di matching NPK è abbastanza sofisticato da calcolare una distanza euclidea normalizzata e una soglia 0.15, perché la schermata dove vivono quei concimi non mostra mai quell'intelligenza all'utente — "Concimi" dovrebbe restare una lista muta, o diventare il posto dove si vede per quali piante ogni concime è davvero indicato?
- Vale la pena mantenere l'attenuazione dell'intera riga per "terminato" accanto a un tag testuale che dice già la stessa cosa a parole — la dispensa si leggerebbe più chiaramente, non meno, se gli esauriti restassero visivamente normali a parte il tag?
- Il pattern dei bottoni del Foglio forzati a 40px si ripete identico in quattro viste diverse (Zone, Sottozone, Progetti, Concimi): è un'eccezione voluta da codificare come variante ufficiale, o una regola che viene ignorata ovunque risulti scomoda?
