---
target: ZoneView
total_score: 32
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/ZoneView.vue"
target_fingerprint: "sha256:984a450c9b8702d0c93c7ea30b6a1625f21cd33c76cd0eabda8e5c05e73e7c74"
target_path: /Users/rob/Sites/localhost/giardino/src/views/ZoneView.vue
timestamp: 2026-09-06T21-37-46Z
slug: src-views-zoneview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Nessuna conferma positiva dopo un salvataggio riuscito: il foglio si chiude e basta |
| 2 | Match System / Real World | 4 | Vocabolario da giardino preciso, nessun gergo tecnico |
| 3 | User Control and Freedom | 3 | Esc/backdrop/× ok; nessun undo post-salvataggio (accettabile per modifiche a basso rischio) |
| 4 | Consistency and Standards | 4 | Struttura quasi identica a SottozoneView; unica divergenza: ZoneView tiene il modale aperto sull'errore (corretto), SottozoneView no |
| 5 | Error Prevention | 4 | Guard nome duplicato lato client + messaggio tradotto specifico sul blocco FK |
| 6 | Recognition Rather Than Recall | 2 | Griglia di 45 icone senza etichette visibili; il `title` è invisibile su touch e mostra slug letterali ("lego", "orma") |
| 7 | Flexibility and Efficiency | 2 | Nessuna ricerca/filtro zone, nessuna azione bulk; l'edge case "zona con molte sottozone" non è supportato |
| 8 | Aesthetic and Minimalist Design | 3 | Lista pulita; il foglio nuova/modifica impacchetta 6 campi in un flusso continuo senza sezioni |
| 9 | Error Recovery | 4 | Errori inline, umanizzati, in italiano, azionabili |
| 10 | Help and Documentation | 3 | Nessun aiuto esplicito, ma i placeholder di MiniEditor fanno da guida leggera in-contesto |
| **Total** | | **32/40** | **Good** |

## Design Specificity Verdict

**LLM assessment**: ZoneView non è una schermata CRUD generica riverniciata — implementa visibilmente il sistema taccuino: `.zname` forza Fraunces su ogni nome zona (riga 27, CSS `main.css:107`), la lista usa righe hairline `.dest`/`.destlist` invece di card impilate, le icone `zona-…` sono glifi ad acquerello invece di un'icona generica, e il foglio laterale segue il contratto di movimento condiviso. Due elementi restano territorio da widget generico: il `<select>` nativo per tipo (righe 55-58) e, più seriamente, la griglia di 45 icone senza etichette visibili (righe 64-71) — un pattern da "selettore icone" da stock, senza categorie né cornice specifica del taccuino, l'unico punto della vista che potrebbe essere trapiantato in un'app qualunque senza modifiche.

**Deterministic scan**: `impeccable detect --json` → exit 0, **1 finding advisory** (invariato dal giro precedente): `border-radius: 10px` fuori scala alla riga 64 — il contenitore della griglia icone, la stessa area che la review qualitativa continua a segnalare come punto debole indipendentemente. Confermato: questo è l'unico problema residuo del giro precedente, esattamente dove atteso (il selettore icone il cui ripensamento è stato rimandato).

**Visual overlays**: non disponibili in questa sessione — nessuno strumento di automazione browser esposto; live-server e iniezione saltati per regola di fallback.

## Overall Impression

I cinque fix del giro precedente hanno funzionato: consistenza e prevenzione errori sono ora tra i punti più forti della vista (4/4 entrambi), e i due P0 sono scomparsi dal punteggio. Il punteggio sale da 21/40 (Accettabile) a 32/40 (Buono). Il problema centrale però non si è spostato: il selettore di 45 icone resta l'unico elemento della vista che non porta la voce del prodotto, e ora è anche il punto dove la review nota un nuovo dettaglio concreto — i target di tocco (icona e pillole di riga) sono sotto il minimo di 44px richiesto dal sistema, proprio nell'app pensata per l'uso "sul campo, da mobile".

## What's Working

- Regola del Nome in Fraunces applicata correttamente e solo dove serve (`ZoneView.vue:27`, `.zname { font-family: var(--font-display) }` a riga 107), mentre i metadati restano in DM Sans — esattamente lo split semantico richiesto da DESIGN.md.
- Recupero errore reale e specifico invece di un fallimento generico: il ramo di violazione FK (`ZoneView.vue:266-269`) traduce un errore Postgres 23503 in "Non puoi eliminare una zona che contiene ancora piante: spostale o eliminale prima", tenendo il dialogo di conferma aperto con l'errore inline (`ModalConferma :errore`, riga 95) invece di rispedire l'utente a una lista vuota.
- Guard anti-sovrascrittura silenziosa su rinomina/creazione (`ZoneView.vue:184-187`) protegge dati (criticità/manutenzione, non presenti in questo form) che verrebbero altrimenti persi da un salvataggio con lo stesso nome.

## Priority Issues

**[P1] Target di tocco sotto i 44px minimi del sistema**
- **Perché è importante**: `.pill-mini` (usato per "Modifica"/"Elimina"/"Sottozone", righe 37-41) misura circa 22-26px di altezza (font 10.5px/line-height 1 + 6px di padding verticale, `main.css:452-453`), e le celle `.pill-icona` della griglia icone sono `minmax(30px,1fr)` quadrate (riga 64) — entrambe ben sotto la regola "altezza minima 44px (target di tocco)" che DESIGN.md impone per i bottoni, in un'app il cui uso primario dichiarato è "sul campo, da mobile".
- **Fix**: aumentare l'area di tocco di `.pill-mini` (padding o un min-height override) e ingrandire le celle/aree di tocco della griglia icone, oppure avvolgere la stessa dimensione visiva in un hit-slop invisibile più ampio.
- **Dove**: ZoneView.vue:37-41, 64; main.css:452-453.
- **Comando suggerito**: `/impeccable adapt`

**[P1] Selettore icone: griglia piatta di 45 opzioni senza etichette visibili**
- **Perché è importante**: viola apertamente la regola del carico cognitivo (≤4 opzioni visibili per decisione), forza il recall invece del riconoscimento (i tooltip `title` sono invisibili su touch, la modalità di input principale dell'app), ed è l'unico punto della schermata che si legge come widget da stock invece che design specifico del taccuino — in diretta tensione con l'atmosfera "calda e non affrettata" per quella che dovrebbe essere una scelta decorativa leggera.
- **Fix**: portare in UI il raggruppamento categoriale che già esiste nei commenti di `useIconeZona.js` (natura/interni/illuminazione/strutture) come intestazioni di sezione visibili, e/o aggiungere una ricerca leggera per nome sopra la griglia.
- **Dove**: ZoneView.vue:64-71.
- **Comando suggerito**: `/impeccable layout`

**[P2] La rinomina di una zona ricarica l'intero store**
- **Perché è importante**: `salva()` chiama `store.aggiorna()` su rinomina (`ZoneView.vue:227`), che azzera `piante.value` e ricarica da zero zone/sottozone/piante/progetti/tappe/settings/concimi/specie (`stores/dati.js:316-318`, `254-314`), portando `store.loading` a true — che questa stessa vista renderizza come skeleton a pagina intera al posto dell'intera lista zone (riga 9). Una modifica di un solo campo di testo non dovrebbe azzerare visivamente tutto lo schermo; è una rottura di proporzionalità nella "visibilità dello stato del sistema" e nel ritmo calmo richiesto dal brief.
- **Fix**: riconciliare la rinomina lato client ri-chiavendo i campi denormalizzati di `store.sottozone`/`store.piante` localmente invece di un reload completo, o quantomeno delimitare il flag di caricamento perché non azzeri viste che non ne hanno bisogno.
- **Dove**: ZoneView.vue:227; stores/dati.js:254-314, 316-318.
- **Comando suggerito**: `/impeccable optimize`

**[P3] Le descrizioni zona con formattazione sono di sola scrittura**
- **Perché è importante**: `MiniEditor` permette di mettere in grassetto/corsivo `descrizione`/`microclima` (usati per note reali come osservazioni sul microclima), ma la teaser in lista rimuove ogni markup via regex (`descrizioneZona()`, righe 244-246) e non esiste alcuna vista di dettaglio in ZoneView per rivedere il testo formattato — un'asimmetria reale tra ciò che si può scrivere e ciò che si rivede mai.
- **Fix**: preservare l'enfasi inline nella teaser (rendering HTML sanificato, già reso sicuro dal sanitizer di MiniEditor) o aggiungere un modo per espandere/vedere la nota completa formattata.
- **Dove**: ZoneView.vue:244-246.
- **Comando suggerito**: `/impeccable clarify`

**[P3] Nessuna gestione dell'overflow per nomi zona lunghi**
- **Perché è importante**: `.dest__n`/`.zname` (riga 27, CSS `main.css:424`) non ha regole `text-overflow`/`white-space` pur condividendo una riga flex con un badge tipo, un conteggio piante e uno chevron (righe 27-30); un nome lungo (un edge case esplicitamente citato nel brief) va a capo e può disallineare visivamente i metadati finali/chevron.
- **Fix**: definire un comportamento esplicito di troncamento o a capo e verificare un nome lungo contro il layout della riga.
- **Dove**: ZoneView.vue:27; main.css:424.
- **Comando suggerito**: `/impeccable adapt`

## Cognitive Load

3 fail su 8. Fuoco singolo, gerarchia visiva e carico di memoria di lavoro: pass. Falliscono chunking (griglia icone come gruppo unico da 45), ≤4 opzioni per decisione (griglia icone), divulgazione progressiva (icona/esposizione/microclima mostrati a piena vista invece che dietro un "altre opzioni"). Raggruppamento e "una decisione alla volta" sono parziali. Tutto converge sulla stessa causa radice: il selettore icone e il form piatto e non divulgato progressivamente. La lista zone in sé porta un carico bassissimo; il picco è tutto nel foglio nuova/modifica.

## Emotional Journey

La lista è calma e coerente con l'atmosfera "taccuino quieto": skeleton morbido, stato vuoto con una CTA chiara, righe hairline gentili. Il punto più basso — eliminare una zona con piante ancora dentro — è gestito bene: un potenziale vicolo cieco (rifiuto silenzioso del database) diventa una frase calda, specifica e azionabile dentro un dialogo di conferma che resta aperto, un buon design per un momento ad alto rischio. L'altro calo è autoinflitto: aprire "Nuova zona" e incontrare la griglia di 45 icone interrompe il ritmo "fine giornata" con un piccolo scatto di attrito decisionale che non si accorda con la promessa di un'esperienza illustrata e non affrettata — si legge come un widget da utility calato in un taccuino scritto a mano. La nota di chiusura sul salvataggio è smorzata anziché positiva: il foglio si chiude senza alcun riconoscimento, quindi la "chiusura" emotiva di un'azione completata è più piatta dell'apertura amichevole.

## Persona Red Flags

**Jordan (primo utilizzo)**: creare la prima zona lo scarica in una griglia di 45 icone senza etichette (righe 64-71) senza alcuna guida sul significato o sull'importanza della scelta — probabile blocco o scelta casuale. "Microclima" come etichetta di campo, pur mitigato dal placeholder, resta un gergo leggero non spiegato per chi non ha mai usato l'app.

**Sam (dipendente da accessibilità)**: i pulsanti icona hanno effettivamente `aria-label`/`aria-pressed` (riga 67), ma l'etichetta pronunciata è uno slug grezzo del nome file ("lego", "orma", "tronco") invece di una descrizione italiana significativa, quindi chi usa uno screen reader riceve una lista di 45 elementi tecnicamente etichettati ma semanticamente confusi. Inoltre `descrizione`/`microclima` usano un `MiniEditor` `contenteditable` invece di una textarea nativa, un punto debole noto per le tecnologie assistive; e per il punto P1 sopra, ogni controllo icon-only (modifica/elimina/sottozone) è ben sotto i 44px richiesti dal sistema stesso, penalizzando in modo sproporzionato scenari di uso con motricità ridotta o guanti da giardino.

**Riley (stress tester)**: il controllo anti-duplicato (`nomeNuovo !== nomeOriginale`, riga 184) è un confronto di stringhe case-sensitive esatto — "Est" ed "est" sono trattate come due zone diverse, invitando quasi-duplicati accidentali. Non c'è alcun limite di lunghezza lato client su `nome`, quindi una stringa molto lunga incontra il vuoto di gestione overflow del punto P3. E rinominare ripetutamente in rapida successione innesca ogni volta il reload completo dello store del punto P2, azzerando lo schermo con uno skeleton a metà interazione.

## Minor Observations

- Il `<select>` nativo per `tipo` (righe 55-58) è lo stile solo `.form-input`, l'unico momento di controllo HTML piatto in un form altrimenti illustrato.
- Nessun toast/conferma di successo al salvataggio: l'unico feedback è la chiusura del foglio e il riordino alfabetico della lista, che può far "saltare" una zona modificata di posizione senza alcun evidenziamento.
- `contaPiante()` (righe 248-251) fa una scansione lineare completa di tutte le piante per ogni zona a ogni render — non un difetto di design in sé, ma da notare perché scala con la dimensione del giardino.
- ZoneView tiene il modale di conferma aperto con errore inline sul fallimento di eliminazione (corretto), mentre la vista gemella SottozoneView chiude il proprio modale e mostra un banner di pagina sullo stesso tipo di fallimento — pattern di recupero incoerente tra le due schermate quasi identiche (nota: ora è SottozoneView a essere indietro, non più ZoneView).

## Questions to Consider

- Se l'icona è puramente decorativa (nessuna vista tratta `zona-icon` come dato significativo, per commento nello store), un selettore di 45 elementi senza etichette sta davvero rendendo il suo valore rispetto al costo cognitivo che impone a ogni creazione di zona?
- Dato che le rinomine di zona/sottozona richiedono già un reload completo dello store per correttezza, varrebbe la complessità di un patch mirato e più leggero dei campi denormalizzati per evitare il lampeggio dello skeleton a schermo intero su quella che l'utente vive come una modifica banale di testo?
- "Microclima" ed "esposizione" — entrambi contesto secondario e opzionale — dovrebbero finire dietro una divulgazione "più dettagli" così che la creazione di una prima zona chieda solo nome/tipo/icona, rimandando i campi più ricchi alla modifica successiva?
