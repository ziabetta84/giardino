---
target: Home (src/views/HomeView.vue)
total_score: 24
max_score: 40
na_heuristics: 
p0_count: 1
p1_count: 2
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/HomeView.vue"
target_fingerprint: "sha256:a289441be49ef324d1b6bc3fc49471746d4348b6ea401b57426db59edfc53af3"
target_path: /Users/rob/Sites/localhost/giardino/src/views/HomeView.vue
timestamp: 2026-09-05T06-50-27Z
slug: src-views-homeview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Euristica | Punteggio | Nodo specifico |
|---|-----------|-------|-----------------|
| 1 | Visibilità dello stato del sistema | 2 | Il bottone "Fatto" su ogni riga di cura non ha handler — tocco senza alcun feedback |
| 2 | Corrispondenza sistema/mondo reale | 3 | `{{ numPiante }} specie` mostra in realtà il conteggio delle piante, non delle specie |
| 3 | Controllo e libertà dell'utente | 3 | Solido: nessun modale, nessuna trappola, ogni riga è un link reversibile |
| 4 | Coerenza e standard | 3 | `.pill-mini` è interattivo altrove, silenziato a `cursor:default` qui: stesso componente, due contratti diversi |
| 5 | Prevenzione errori | 2 | Nessuna distinzione visiva tra "nessuna urgenza" e "dati non ancora caricati" |
| 6 | Riconoscimento anziché ricordo | 4 | Solido: ogni icona ha testo accanto, sezioni etichettate |
| 7 | Flessibilità ed efficienza d'uso | 1 | Nessuna azione bulk, nessuna scorciatoia, e l'unico acceleratore quotidiano ("Fatto") non è cablato |
| 8 | Estetica e design minimalista | 3 | Buona gerarchia a filetti, ma la prima schermata impila 4 categorie di attenzione in parallelo |
| 9 | Aiutare a riconoscere/recuperare errori | 1 | Fallimento silente di meteo/dati produce messaggi positivi falsi ("Nessuna cura urgente oggi") |
| 10 | Aiuto e documentazione | 2 | "Zorba dice" è un canale di aiuto contestuale specifico del prodotto, ma nessuna spiegazione su soglie/logica di urgenza |
| **Totale** | | **24/40** | **Accettabile** |

## Design Specificity Verdict

**Valutazione LLM**: alto. `HeroAiuola.vue` non è un asset generico: quattro varianti stagionali × due di luce, ciascuna con una sequenza di tratti `ink-trace` che si "ridisegnano a china" con `animation-delay` scaglionati (0.35s→5.27s), agganciata a dati reali (stagione, alba/tramonto). Zorba compare con la sua coreografia coda/occhio, sempre nero come da regola di DESIGN.md. Il font Caveat appare esattamente una volta, come prescritto. Le liste usano filetti hairline invece di card impilate. Questa Home potrebbe solo essere Il Giardino di Zorba — nessun tema dashboard generico produce questo.

**Scansione deterministica**: pulita. `impeccable detect --json` sui 7 file della superficie (`HomeView.vue`, `HeroAiuola.vue`, `ZorbaLogo.vue`, `Icon.vue`, `AppBar.vue`, `BottomNav.vue`, `SideNav.vue`) → 0 anti-pattern, exit code 0. Un'unica nota advisory (non conta ai fini del punteggio): `ZorbaLogo.vue:214` usa `#d4b23c`, un oro/senape non presente nella palette di DESIGN.md (né coincide con `gold`/`gold-dark`). Verificato manualmente: non rientra nell'eccezione "Zorba sempre nero" (è un layer decorativo separato, non il corpo del gatto) — drift genuino, non falso positivo, ma di severità minima.

**Overlay visivi**: non disponibili in questa sessione — nessun tool di automazione browser esposto, nessun dev server confermato attivo. Assessment B ha saltato esplicitamente il passo invece di fabbricare evidenza; nessun overlay è quindi mostrato in un tab [Human].

## Overall Impression

Il linguaggio visivo di questa Home è tra il lavoro più specifico e coraggioso di questa sessione — l'illustrazione stagionale a china e Zorba animato non sono decorazione, sono il prodotto. Ma sotto quella superficie curata, l'unica azione transazionale della pagina (segnare una cura come fatta) non fa nulla, e i due segnali più importanti — "hai piante da curare oggi" e "il meteo dice che pioverà" — possono contraddirsi a vista senza che l'app se ne accorga. La più grande opportunità non è estetica: è chiudere lo scarto tra quanto la Home sembra affidabile e quanto lo è davvero sull'unico compito per cui esiste.

## What's Working

- `HeroAiuola.vue`: la combinazione stagione×luce con tratti a china animati in cascata comunica "taccuino disegnato a mano" meglio di qualunque copy, ed è agganciata a dati reali (stagione, luce diurna reale).
- Trattamento dell'urgenza in `.stat b`: un colore (rosa) dentro una pillola neutra, non un badge rosso lampeggiante da SaaS — rispetta alla lettera "nessuna urgenza visiva se non quella reale" di DESIGN.md.
- `aria-hidden="true"` su `HeroAiuola`: l'illustrazione decorativa non sottrae nulla a chi usa uno screen reader, perché ogni informazione equivalente (data, saluto, conteggi) esiste già come testo reale accanto.

## Priority Issues

**[P0] Il bottone "Fatto" non ha alcun handler — l'unica azione transazionale della Home è finta.**
Perché conta: è visivamente un bottone interattivo (stessa classe `.pill-mini` usata come cliccabile altrove) ma un commento nel codice stesso ammette che è "volutamente non wireato". È il gesto che un utente farebbe ogni giorno, a mani sporche di terra, per chiudere il cerchio di una cura appena fatta — e non succede nulla.
Fix: cablarlo a `usePianteApi.js` (stessa via di `.care-act` in `AttivitaView.vue`) o rimuoverlo dalla Home finché non è pronto.
Comando suggerito: /impeccable harden

**[P1] Nessuna distinzione tra "tutto ok" e "dati non caricati" — rassicurazione falsa nel momento più a rischio.**
Perché conta: se il caricamento di meteo o cure fallisce silenziosamente, il meteo resta bloccato su "Caricamento meteo…" a tempo indeterminato e la lista urgenze vuota produce il testo positivo "Nessuna cura urgente oggi." Per un'app il cui successo si misura in piante non trascurate, confondere un errore con un giardino sano è il rischio peggiore possibile su questa superficie.
Fix: stato di errore esplicito e distinguibile, con azione di retry.
Comando suggerito: /impeccable harden

**[P1] "Buongiorno, Rob" è hardcoded, ma il prodotto è ora multiutente.**
Perché conta: PRODUCT.md conferma che altre persone hanno ormai il proprio giardino isolato. Questo è il momento di apertura di ogni sessione, l'esatto "peak" emotivo che l'app costruisce bene altrove — e per chiunque non si chiami Rob è semplicemente sbagliato.
Fix: leggere il nome da `useAuth()`/profilo utente, con fallback neutro se non impostato.
Comando suggerito: /impeccable harden

**[P2] `{{ numPiante }} specie` conta le piante, non le specie.**
Perché conta: mostra un dato oggettivamente falso sul proprio giardino, nella riga più prominente della pagina.
Fix: etichettare correttamente come "piante", o calcolare il conteggio specie distinte se è quello il dato voluto.
Comando suggerito: /impeccable clarify

**[P2] La Home carica il meteo ma non lo usa nella logica di cura che lei stessa promuove come differenziatore.**
Perché conta: `valutaCura` supporta già `contesto.meteo` per sospendere l'irrigazione in caso di pioggia in arrivo, ma la Home non lo passa — può segnalare "irrigazione urgente" nello stesso istante in cui la riga meteo appena sopra mostra pioggia in arrivo.
Fix: passare `{ esterno: true, meteo: meteoGiorni.value }` a `valutaCura` in `daFareOggi`.
Comando suggerito: /impeccable harden

## Persona Red Flags

**Casey (mobile, distratta, una mano sola, in giardino)**: il bottone "Fatto" — l'azione che userebbe più spesso, a mani sporche — non fa nulla e non dà nessun feedback di tocco a vuoto. I conteggi dell'hero non hanno stato di caricamento (nessuno `.skeleton`, a differenza di altre view): con connessione debole all'aperto vede per un istante pillole vuote.

**Alex (potere/uso quotidiano ripetuto)**: nessuna azione bulk — chiudere 5 cure richiederebbe 5 tocchi su un bottone che oltretutto non funziona. Nessuna scorciatoia né riordino di `.destlist`: l'esperienza non accelera mai con l'uso.

**Sam (screen reader/tastiera)**: il bottone "Fatto" è un `<button>` reale senza `disabled`/`aria-disabled` — arriva nel tab order e viene annunciato come pienamente interattivo. Per Sam l'app mente attivamente sull'interattività del controllo, peggio del semplice "non fa nulla" visto da un utente vedente.

## Minor Observations

- `ZorbaLogo.vue:214` usa `#d4b23c`, un oro non catalogato in DESIGN.md — probabile one-off invece di riuso di `gold`/`gold-dark` esistenti (finding advisory dello scanner, non un fallimento).
- Al mount partono due coreografie a china indipendenti e non sincronizzate (Zorba: 1.2–2.0s; HeroAiuola: fino a 5.27s+) — vale la pena chiedersi se leggano come un'unica apertura di scena.
- `.destlist` con 6 righe subito sotto una lista task già densa: valutare se raggrupparle o mostrarne un sottoinsieme prioritario.

## Questions to Consider

- Quanto tempo può restare visibile un'azione finta come "Fatto" prima che l'utente smetta di fidarsi degli altri bottoni "verdi" dell'app?
- Se il meteo che contestualizza le cure è il differenziatore dichiarato, perché la Home — che ha già il meteo in mano — non è il primo posto dove quella promessa si vede?
- Cosa vede oggi, davvero, un familiare appena registrato con il proprio giardino isolato, quando legge "Buongiorno, Rob"?
