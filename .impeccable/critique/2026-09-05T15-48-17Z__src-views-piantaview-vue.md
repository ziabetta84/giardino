---
target: Scheda pianta (src/views/PiantaView.vue)
total_score: 27
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/PiantaView.vue"
target_fingerprint: "sha256:08b39cc300c3c17110e709e699cb3ddc075a3024b88d5290a8cc7d58e534b4e5"
target_path: /Users/rob/Sites/localhost/giardino/src/views/PiantaView.vue
timestamp: 2026-09-05T15-48-17Z
slug: src-views-piantaview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Euristica | Punteggio | Nodo specifico |
|---|-----------|-------|-----------------|
| 1 | Visibilità dello stato del sistema | 3 | Spinner/conferme solidi; il nuovo toast rischia sovrapposizione geometrica con la StatusBar sempre presente |
| 2 | Corrispondenza sistema/mondo reale | 4 | Italiano naturale, terminologia coerente |
| 3 | Controllo e libertà dell'utente | 2 | Annulla aggiunto solo in 1 delle 4 superfici che condividono lo stesso bottone "Fatto"; finestra fissa 6s; doppio tap ravvicinato perde silenziosamente il primo annulla |
| 4 | Coerenza e standard | 2 | Stessa azione "Fatto" con comportamento diverso tra Home/Attività/Dossier vs PiantaView; banner ConcimiView fuori standard cromatico rispetto ai modelli dichiarati (ZoneView/SottozoneView) |
| 5 | Prevenzione errori | 3 | Miglioramento reale in ConcimiView (chiuso un fallimento silenzioso) |
| 6 | Riconoscimento anziché ricordo | 3 | Tutto etichettato testualmente |
| 7 | Flessibilità ed efficienza d'uso | 3 | Galleria navigabile da tastiera, coerente con una scheda di dettaglio |
| 8 | Estetica e design minimalista | 3 | Gerarchia pulita; la sovrapposizione toast/statusbar è un difetto visivo concreto quando si verifica |
| 9 | Aiutare a riconoscere/recuperare errori | 3 | Messaggi vicini alla fonte; finestra di recupero del toast breve e senza estensione |
| 10 | Aiuto e documentazione | 1 | Nessun aiuto contestuale, invariato |
| **Totale** | | **27/40** | **Accettabile** (calo da 31/40) |

## Design Specificity Verdict

La pagina resta fortemente autoriale (Fraunces, filigrana Zorba, kv raggruppati, credito Wikimedia). Il nuovo `.cura-toast` è però l'elemento meno specifico introdotto finora: una pillola scura arrotondata in basso-centro è un pattern "snackbar" da libreria generica, non derivato dal vocabolario "Taccuino" (china/acquerello) — DESIGN.md descrive già un motivo diegetico più coerente per "una cura appena registrata" (la Goccia d'inchiostro, alone che si allarga e sparisce, già usata per i pallini della timeline progetti), mai riusato qui. Il toast è anche l'unica superficie a tinta piena `var(--ink)` di tutto il codebase (ogni altro scrim scuro è semi-trasparente) e usa un'ombra che non corrisponde a nessuno dei quattro livelli nominati in DESIGN.md.

Scansione deterministica: pulita, 0 anti-pattern reali (36 advisory, tutti pre-esistenti o dello stesso schema colore già in uso altrove). Verifica tecnica approfondita (Assessment B) conferma che la logica dei tre fix è internamente corretta — nessun difetto funzionale nel timer del toast, nell'annullamento (`annullaCura` verificato esatto contro `valutaCura`, nessuno stato "più urgente di prima"), nella posizione/z-index (`position:relative` non altera flex-basis né scroll-snap), né nella pulizia del banner errori di ConcimiView. Il calo di punteggio non viene da un difetto di logica ma da due problemi reali di superficie/copertura che una verifica solo tecnica non cattura.

## Overall Impression

I tre fix del round precedente sono tecnicamente solidi — verificati riga per riga, nessun bug di logica. Ma la revisione qualitativa trova due problemi P1 concreti che riportano il punteggio da 31 a 27: il toast "Annulla" esiste in una sola delle quattro superfici che condividono lo stesso identico bottone "Fatto" (Home, Attività, Dossier pianta restano senza rete di sicurezza), e il posizionamento fisso del toast (`bottom: calc(78px + safe-area)`) ragiona solo sulla BottomNav ma ignora che la StatusBar (sempre montata, nessun `v-if` in `App.vue:35`) si impila sopra di essa — lo stesso motivo per cui `App.vue` usa già `padding-bottom:128px` per il contenuto altrove. Il toast, alto ≈68px per via del target di tocco 44px sul bottone Annulla, rischia di sovrapporsi proprio al messaggio che dovrebbe rendere visibile.

## What's Working

- Fix del focus-ring: chirurgico, riusa uno z-index già in convenzione nel file (`.pbtn`/`.gnote`/`.phead-cap`), nessun effetto collaterale su scroll-snap verificato per via spec.
- Logica di `annullaCura`: cancellare la chiave invece di scrivere `null` riproduce esattamente lo stato pre-tap (verificato contro `useCure.js`) — un dettaglio facile da sbagliare, gestito bene.
- I catch block di ConcimiView chiudono un vero buco di silent-failure, riusando il linguaggio d'errore già stabilito nell'app.

## Priority Issues

**[P1] L'annulla "Fatto" esiste in una sola delle quattro superfici che condividono lo stesso pattern.**
`HomeView.vue:257`, `AttivitaView.vue:219/229`, `DossierPianta.vue:98` chiamano lo stesso `pianteApi.registraCura` dietro lo stesso bottone `.care-act` — DESIGN.md lo dichiara pattern canonico in tutti e quattro i luoghi. Un tap accidentale in Home (la superficie di uso quotidiano per PRODUCT.md) resta senza recupero.
Fix: estrarre la logica del toast in un composable condiviso e riusarlo nei tre luoghi mancanti.

**[P1] Il toast si sovrappone geometricamente alla StatusBar sempre presente.**
`bottom: calc(78px + safe-area-inset-bottom)` considera solo la BottomNav, ignorando che `StatusBar.vue` è montata incondizionatamente e si impila sopra di essa (da cui `App.vue:118`, `padding-bottom:128px`, scelto apposta per coprire entrambe). Su desktop l'offset fisso `bottom:24px` cade dentro la fascia 0-44px della StatusBar desktop.
Fix: misurare l'offset dinamicamente come già fa `StatusBar.vue` (`getBoundingClientRect()` sulla `.statusbar` reale) invece di un valore fisso indovinato.

**[P2] Doppio "Fatto" ravvicinato su due tipi di cura perde silenziosamente il primo annulla.**
`apriToastCura` sovrascrive senza avviso un toast già aperto — scenario realistico (irrigare e concimare nello stesso giro), proprio il caso che una rete di sicurezza dovrebbe coprire.

**[P2] Token colore incoerente nel banner `erroreDisponibile` di ConcimiView.vue.**
Usa `--rose-ink` invece di `--rose-dark` su sfondo `--rose-pale`, deviando dai due modelli esplicitamente citati (`ZoneView.vue`/`SottozoneView.vue`) e da ogni altro banner rose-pale del codebase.

**[P3] Finestra di annullamento fissa a 6000ms, senza pausa su hover/focus.**
In un contesto reale ("in giardino, mani sporche, sole"), 6s per leggere+decidere+toccare è stretto.

## Persona Red Flags

**Casey (mobile, in giardino)**: la sovrapposizione toast/StatusBar può rendere più difficile toccare con precisione "Annulla"; se interrotta prima dei 6s, perde l'unica via di recupero senza avviso persistente.

**Riley (stress tester)**: toccare "Fatto" su irrigazione e poi subito su concimazione fa sparire il primo toast senza preavviso.

**Jordan (first-timer)**: se il primo tap accidentale avviene in Home — la schermata più probabile per un primo utilizzo — non trova alcun annulla, a differenza della scheda pianta.

## Minor Observations

- `.cura-toast` è l'unica superficie a tinta piena `var(--ink)` del codebase e usa un'ombra bespoke non codificata in DESIGN.md.
- Il `min-height:44px` sul bottone Annulla è corretto per il target di tocco, ma è anche la causa principale per cui l'altezza reale del toast eccede quella stimata nell'offset fisso.
- Race condition preesistente in ConcimiView (non introdotta da questo round): `salvandoDisponibile`/`erroreDisponibile` sono ref singole condivise — due toggle in volo contemporaneamente su concimi diversi possono interferire tra loro nel `finally`.

## Questions to Consider

- Se un tap accidentale su "Fatto" merita un annulla in PiantaView, perché non nella Home, dove probabilmente accade più spesso?
- Questo toast dovrebbe diventare subito un composable condiviso, prima che la stessa logica venga ricopiata con variazioni altrove?
- 6 secondi bastano davvero a qualcuno con le mani sporche di terra, sotto il sole, per leggere, decidere e toccare "Annulla"?
