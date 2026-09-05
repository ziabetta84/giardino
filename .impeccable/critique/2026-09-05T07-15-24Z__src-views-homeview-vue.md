---
target: Home (src/views/HomeView.vue)
total_score: 27
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 1
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/HomeView.vue"
target_fingerprint: "sha256:5a422726fc94a8475a2d5ebf9139f6f7c95063e7b22b037b9cc6d2d5f7bfbd08"
target_path: /Users/rob/Sites/localhost/giardino/src/views/HomeView.vue
timestamp: 2026-09-05T07-15-24Z
slug: src-views-homeview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose) — ri-esecuzione dopo i fix su HomeView.vue

## Verifica dei 5 problemi precedenti

| # | Problema | Verdetto |
|---|----------|----------|
| 1 | [P0] Bottone "Fatto" senza handler | Risolto — cablato a pianteApi.registraCura, reattivo, doppio-tap prevenuto |
| 2 | [P1] Rassicurazione falsa su errore | Risolto — store.errore/meteoErrore distinti da "tutto ok", con retry funzionante |
| 3 | [P1] Saluto hardcoded "Rob" | Risolto ma con un nuovo difetto — non più hardcoded, ma con email senza separatori produce "Buongiorno, Robertagenovese" invece di un nome naturale |
| 4 | [P2] Conteggio "specie" errato | Risolto — etichetta ora dice "piante", corrisponde al dato |
| 5 | [P2] Meteo non collegato alla logica cure | Risolto ma con una nuova inconsistenza — la contraddizione visiva è chiusa, ma Home ora fa una seconda fetch meteo indipendente invece di riusare store.meteo (usato da AttivitaView.vue) |

## Design Health Score

| # | Euristica | Punteggio | Nodo specifico |
|---|-----------|-------|-----------------|
| 1 | Visibilità dello stato del sistema | 3 | Loading/errore/retry reali; ma le pillole dell'hero non hanno guard su store.loading |
| 2 | Corrispondenza sistema/mondo reale | 3 | Il saluto dice sempre "Buongiorno" a qualunque ora del giorno |
| 3 | Controllo e libertà dell'utente | 3 | Solido: nessuna trappola, retry disponibile |
| 4 | Coerenza e standard | 3 | Fonte meteo di Home diverge da quella usata da AttivitaView.vue |
| 5 | Prevenzione errori | 3 | Doppio-tap prevenuto su "Fatto" |
| 6 | Riconoscimento anziché ricordo | 3 | Icone quasi sempre con testo; icona persona nell'AppBar resta senza etichetta visibile |
| 7 | Flessibilità ed efficienza d'uso | 2 | Nessuna azione bulk su Home nonostante registraCuraMultipla esista già |
| 8 | Estetica e design minimalista | 3 | Gerarchia pulita, penalizzata dal flash di valori vuoti nell'hero al primo caricamento |
| 9 | Aiutare a riconoscere/recuperare errori | 2 | registra() non ha catch: un fallimento di rete su "Fatto" è silenzioso |
| 10 | Aiuto e documentazione | 2 | "Zorba dice" resta l'unico aiuto contestuale, nessun cambiamento |
| **Totale** | | **27/40** | **Accettabile** (soglia "Buono" è 28) |

## Design Specificity Verdict

Valutazione LLM: solido e confermato — HeroAiuola.vue, Zorba animato, Caveat usato una sola volta, filetti al posto di card impilate, codifica colore per dominio di cura: nessun elemento genericamente da dashboard.

Scansione deterministica: pulita, invariata — impeccable detect --json sui 7 file → 0 anti-pattern, exit code 0. Unica nota advisory preesistente (non legata ai fix): ZorbaLogo.vue:214, colore #d4b23c non catalogato in DESIGN.md — verificato di nuovo, non un falso positivo.

Overlay visivi: non disponibili anche in questo run — nessun tool di automazione browser esposto.

## Overall Impression

I 5 fix hanno funzionato sulla sostanza: il bottone "Fatto" scrive davvero, gli errori non mentono più, l'etichetta "specie" è corretta, e la contraddizione meteo↔irrigazione è chiusa nel caso comune. Ma due dei cinque fix hanno introdotto un secondo livello dello stesso tipo di problema: il nome derivato dall'email può risultare innaturale, e la nuova fetch meteo duplica quella già presente nello store invece di riusarla. Il punteggio sale da 24 a 27/40 ma resta nella fascia "Accettabile" — non per nuovi problemi estetici, ma perché il salvataggio di una cura può ancora fallire in silenzio, la stessa famiglia di rischio del P1 originale, spostata dal caricamento al salvataggio.

## What's Working

- contestoPianta() + valutaCura: la soppressione dell'urgenza di irrigazione in caso di pioggia è ora intelligenza di dominio applicata, coerente con la Positioning di PRODUCT.md.
- .alertbox--rose per l'errore di caricamento: messaggio in linguaggio naturale + azione di recupero immediata.
- Il bottone "Fatto" ora reattivo: la riga sparisce da sola quando store.piante si aggiorna, stessa logica già in uso in PiantaView.vue/DossierPianta.vue.

## Priority Issues

**[P1] "Fatto" può fallire in silenzio.**
Perché conta: registra() non ha alcun catch — se registraCura fallisce (rete instabile, lo scenario "in giardino" descritto in PRODUCT.md), lo spinner sparisce e il bottone torna a "Fatto" senza alcun messaggio.
Fix: avvolgere la chiamata in try/catch e mostrare un alertbox/messaggio di errore invece di limitarsi al finally.

**[P2] Il bottone più toccato dell'app è sotto il target di tocco che il sistema di design si è dato.**
Perché conta: .care-act (~26-28px reali) è più piccolo dei 44px minimi che DESIGN.md dichiara per i bottoni.
Fix: .care-act { min-height: 44px }, allineandolo a .btn.

**[P2] Il saluto dice sempre "Buongiorno", a qualunque ora.**
Perché conta: DESIGN.md descrive il "ritmo lento da fine giornata in giardino" come North Star.
Fix: variare il prefisso per fascia oraria, riusando la stessa logica del nome.

**[P2] Le pillole dell'hero mostrano etichette senza numero al primo caricamento.**
Perché conta: numPiante/numZone/numUrgenti sono null finché store.piante non è pronto, interpolati come stringa vuota.
Fix: avvolgere .stat in v-if="!store.loading" con uno skeleton.

**[P3] Fetch meteo duplicata, non allineata al resto dell'app.**
Perché conta: HomeView.vue istanzia un proprio useMeteo() invece di riusare store.meteo (già usato da AttivitaView.vue).
Fix: sostituire l'istanza locale con store.meteo.

## Persona Red Flags

**Alex (potere/uso ripetuto)**: nessuna azione bulk su Home nonostante registraCuraMultipla esista già e sia usata in AttivitaView.vue.

**Sam (screen reader/tastiera)**: durante il salvataggio il bottone "Fatto" mostra solo lo Spinner (SVG aria-hidden), perdendo il proprio nome accessibile; né successo né fallimento sono annunciati via aria-live.

**Casey (mobile distratta)**: "tocca Fatto → la riga sparisce" è l'unico segnale di successo, senza conferma persistente.

## Minor Observations

- Un commento in main.css dichiara lo stagger enter/leave già in uso in "Home, Piante, Attività", ma la .tasklist di Home non è avvolta in un TransitionGroup.
- L'icona "persona" nell'AppBar resta icon-only con solo aria-label.
- homeCards con 6 destinazioni resta leggermente sopra la soglia di ≤4-5 per un menu a un livello.

## Questions to Consider

- Se il fallimento di rete durante "Fatto" è realistico, perché la scrittura non ha la stessa resilienza percepita della lettura, che ha già cache offline?
- Il saluto "Buongiorno" fisso è sopravvissuto al fix del nome: è stato rivisto l'intero computed o solo la parte che generava il nome sbagliato?
- Se il North Star è "un quaderno che si sfoglia" con ritmo di fine giornata, ha senso che l'unica transizione animata sia l'ambientazione, mentre l'unico gesto d'interazione reale non abbia coreografia?
