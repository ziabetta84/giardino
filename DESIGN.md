---
name: Giardino di Rob
description: Un taccuino da giardino disegnato a china e acquerello, con Zorba — il gatto nero, voce dell'assistente AI — che accompagna ogni cura.
colors:
  rose: "#cc6e6e"
  rose-dark: "#b85f5f"
  rose-light: "#f0d0d0"
  rose-pale: "#fdf4f4"
  rose-bg: "#f6e3e1"
  rose-ink: "#8a3f3a"
  gold: "#e0b84a"
  gold-dark: "#b8902a"
  gold-light: "#f5e9bc"
  gold-pale: "#fdfbf0"
  gold-bg: "#f7ecd0"
  gold-ink: "#7a5a15"
  sage: "#7a9e82"
  sage-dark: "#5a7e62"
  sage-light: "#c8d9c8"
  sage-pale: "#f2f7f2"
  sage-bg: "#e4ede4"
  sage-ink: "#37543f"
  olive: "#9aaa5a"
  olive-dark: "#6d7a3e"
  olive-light: "#d8e4b0"
  olive-bg: "#ececd8"
  olive-ink: "#545e2a"
  acqua: "#6f9fc0"
  acqua-dark: "#4c7793"
  acqua-bg: "#e2edf3"
  acqua-ink: "#2b566e"
  uovo: "#cbb994"
  uovo-dark: "#a68f63"
  ink: "#2a2218"
  ink-mid: "#5a4e3e"
  ink-soft: "#9a8e7e"
  ink-faint: "#c8bfb0"
  cream: "#faf7f2"
  cream-dark: "#f0ebe2"
  white: "#ffffff"
  zorba-black: "#141414"
typography:
  display:
    fontFamily: "Fraunces, Georgia, 'Times New Roman', serif"
    fontSize: "26px"
    fontWeight: 600
    lineHeight: "1.05"
    letterSpacing: "-0.01em"
  body:
    fontFamily: "DM Sans, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: "1.5"
  ui:
    fontFamily: "DM Sans, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 600
    lineHeight: "1"
  label:
    fontFamily: "DM Sans, system-ui, sans-serif"
    fontSize: "11px"
    fontWeight: 700
    lineHeight: "1"
    letterSpacing: "0.13em"
  hand:
    fontFamily: "Caveat, 'Segoe Script', cursive"
    fontSize: "19px"
    fontWeight: 400
    lineHeight: "1.1"
rounded:
  tag: "6px"
  chip: "11px"
  button: "12px"
  input: "14px"
  card: "20px"
  sheet: "22px"
  pill: "999px"
spacing:
  tight: "8px"
  base: "12px"
  loose: "16px"
  section: "24px"
components:
  button-primary:
    backgroundColor: "{colors.sage}"
    textColor: "{colors.white}"
    typography: "{typography.ui}"
    rounded: "{rounded.button}"
    padding: "10px 18px"
    height: "44px"
  button-primary-hover:
    backgroundColor: "{colors.sage-dark}"
  button-destructive:
    backgroundColor: "{colors.rose}"
    textColor: "{colors.white}"
    typography: "{typography.ui}"
    rounded: "{rounded.button}"
    padding: "10px 18px"
    height: "44px"
  button-destructive-hover:
    backgroundColor: "{colors.rose-dark}"
  button-ghost:
    backgroundColor: "{colors.cream-dark}"
    textColor: "{colors.ink-mid}"
    typography: "{typography.ui}"
    rounded: "{rounded.button}"
    padding: "10px 18px"
    height: "44px"
  card:
    backgroundColor: "{colors.white}"
    rounded: "{rounded.card}"
    padding: "16px"
  input:
    backgroundColor: "{colors.white}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.input}"
    height: "44px"
    padding: "10px 16px"
  pill:
    backgroundColor: "{colors.white}"
    textColor: "{colors.ink-soft}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "7px 14px"
  pill-active:
    backgroundColor: "{colors.sage}"
    textColor: "{colors.white}"
  badge-ok:
    backgroundColor: "{colors.sage-pale}"
    textColor: "{colors.sage}"
    rounded: "{rounded.pill}"
    padding: "3px 10px"
  badge-warn:
    backgroundColor: "{colors.rose-pale}"
    textColor: "{colors.rose-dark}"
    rounded: "{rounded.pill}"
    padding: "3px 10px"
  care-act:
    backgroundColor: "{colors.white}"
    textColor: "{colors.ink-mid}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "7px 12px"
    height: "44px"
  care-act-rose:
    textColor: "{colors.rose-dark}"
---

# Design System: Giardino di Rob

## Overview

**Creative North Star: "Il Taccuino da Giardino"**

Il sistema è un bullet journal da giardino: una pagina di carta calda, scritta e disegnata a mano, dove Zorba — il gatto nero realmente esistito e sepolto nel giardino, oggi voce dell'assistente AI — entra e esce dalle pagine per accompagnare chi cura il giardino. Non è un pannello di controllo: è un quaderno che si sfoglia, con un fondo a lavaggio d'acquerello sempre presente sotto ogni schermata, illustrazioni a china (l'aiuola della Home, che cambia con stagione e ora del giorno) e icone dipinte come macchie di pigmento più che come segnaletica.

L'atmosfera voluta è calda e quieta: nessuna urgenza visiva se non quella reale delle cure da fare, ritmo lento da fine giornata in giardino, mai il tono energico o affollato di un'app da produttività. I componenti sono morbidi e arrotondati — angoli generosi (12–22px), ombre soffuse, niente spigoli — così che toccare un bottone o aprire un foglio senta "di carta e cuscino", non di scheda tecnica.

Rifiuti visivi confermati: niente estetica da SaaS/dashboard generico (card piatte grigie, blu corporate, icone outline sottili da tool aziendale); niente cliché da app di giardinaggio da stock (foto botaniche generiche, verde/marrone scontati) al posto dell'illustrazione a china/acquerello.

**Key Characteristics:**
- Pagina di carta calda (`--cream`) con un lavaggio d'acquerello organico sempre presente sullo sfondo
- Fraunces per ogni nome e titolo, mai per il corpo del testo o i numeri di servizio
- Icone come macchie di pigmento: silhouette piena + un accenno più scuro dove il colore "si raccoglie"
- Zorba sempre nero, unica eccezione alla palette, presenza ricorrente dell'assistente AI
- Angoli generosi e ombre soffuse ovunque; liste separate da filetti sottili, non da riquadri

## Colors

Una palette calda da erbario — non un blu/grigio da prodotto software — con un colore per ogni dominio di cura del giardino, così che irrigazione, concimazione e potatura si riconoscano a colpo d'occhio prima ancora di leggere l'etichetta.

### Primary
- **Verde Salvia Diluito** (`#7a9e82`, `sage`): l'azione affermativa principale — salva, conferma, invia — su quasi tutti i form dell'app (impostazioni, progetti, zone, concimi, account). È anche il colore del "in corso" (voce di navigazione attiva, tab selezionata).

### Secondary
- **Rosa ad Acquerello** (`#cc6e6e`, `rose`): riservato ad azioni distruttive o urgenti — elimina, conferma di cancellazione, cure in ritardo, avvisi meteo. Mai usato come bottone di salvataggio: la sua presenza segnala sempre "attenzione" o "questa azione non si annulla".
- **Ocra Dorata** (`#e0b84a`, `gold`): accento di messa a fuoco (focus ring su input) e di rilievo positivo (badge, evidenza nella timeline progetti). Usato con parsimonia, mai come sfondo di superfici larghe.

### Tertiary (colori funzionali per dominio di cura)
- **China Blu Cielo** (`#6f9fc0`, `acqua`): irrigazione.
- **Verde Muschio** (`#9aaa5a`, `olive`): concimazione.
- **Ocra Uovo** (`#cbb994`, `uovo`): apporto di calcio/altri trattamenti minori.
- **Verde Salvia** (`sage`, riuso del primary): cura generica/NPK.
- **Rosa ad Acquerello** (`rose`, riuso del secondary): potatura.

Ogni colore funzionale ha una coppia "-bg"/"-ink" (es. `acqua-bg #e2edf3` / `acqua-ink #2b566e`) usata per tessere icona, chip e badge di quel dominio: fondo tinta chiarissima, testo/icona nella tinta scura leggibile (AA). Le stesse coppie diventano superfici scure sature in dark mode, non un semplice inverti-colore.

### Neutral
- **Carta** (`#faf7f2`, `cream`): sfondo di pagina.
- **Carta Ombrata** (`#f0ebe2`, `cream-dark`): bordi, divisori, sfondo dei pulsanti ghost.
- **Inchiostro** (`#2a2218`, `ink`): testo principale.
- **Inchiostro Diluito** (`#5a4e3e`, `ink-mid`) / **Inchiostro Sbiadito** (`#9a8e7e`, `ink-soft`) / **Inchiostro Appena Visibile** (`#c8bfb0`, `ink-faint`): gerarchia di testo secondario, dalla didascalia al placeholder.
- **Bianco** (`#ffffff`, `white`): superficie di card, input, sheet — mai lo sfondo di pagina.

### Named Rules
**La Regola di Zorba Nero.** Zorba è identità, non decorazione: resta nero (`#141414`) in ogni tema e in ogni superficie che lo mostra — unica eccezione ammessa alla palette. In dark mode non si schiarisce: gli si aggiunge un alone chiaro (`drop-shadow`) che lo separa dallo sfondo scuro.

**La Regola del Caldo-al-Buio.** Il dark mode non è un grigio neutro invertito: ogni token scuro nasce dalla tinta del suo equivalente chiaro. L'accento base si schiarisce (non si scurisce) per leggibilità; le tinte pallide (`-light`/`-pale`, sfondi pillola/badge) diventano versioni scure sature della stessa tinta; le coppie `-bg`/`-ink` restano sempre superficie scura satura + testo chiaro.

## Typography

**Display Font:** Fraunces (con Georgia, Times New Roman come fallback)
**Body Font:** DM Sans (con system-ui, sans-serif come fallback)
**Label/Mono Font:** DM Sans, stessa famiglia del body ma in maiuscolo tracciato per le etichette
**Hand Font:** Caveat (con Segoe Script, cursive come fallback) — accento manoscritto

**Character:** Fraunces porta la voce calda e un po' letteraria del taccuino ovunque compaia un nome — di pianta, di pagina, di persona — mentre DM Sans resta discreto e leggibilissimo per tutta l'interazione. Caveat appare una sola volta per pagina (la data in Home), come se qualcuno l'avesse scritta a penna in un angolo.

### Hierarchy
- **Display** (600, 24–26px, line-height 1.05–1.1): titoli di pagina (`.page-title`) e saluto della Home (`.greet`); stesso peso e famiglia, poco più piccoli (14.5–16px), per nomi di card e titoli di modale/foglio.
- **Title** (600, 13–15px, line-height 1.2–1.25): nomi di riga in liste (progetti, attività, zone) — Fraunces anche qui, non DM Sans: ogni "nome" nel taccuino usa il display font, indipendentemente dalla dimensione.
- **Body** (400, 12.5–14px, line-height 1.4–1.62): testo corrente, descrizioni, risposte dell'assistente AI.
- **Label** (700, 9.5–11px, letter-spacing 0.04–0.13em, maiuscolo): etichette di sezione (`.slabel`), etichette di campo, chip di stato — sempre tracciate e maiuscole, mai in Fraunces.
- **Hand** (400, 19px, Caveat): la data in Home; nessun altro uso nell'app.

### Named Rules
**La Regola del Nome in Fraunces.** Ogni volta che l'interfaccia mostra un *nome* — di pianta, progetto, zona, pagina, persona — usa Fraunces, qualunque sia la dimensione. Numeri, etichette, pulsanti e chrome di navigazione restano sempre in DM Sans: la distinzione è semantica (identità vs. servizio), non solo dimensionale.

## Layout

L'app è una PWA a singola colonna su mobile (barra in alto con blur, `.appbar`, e barra di navigazione in basso, `.bottomnav`) che diventa a due colonne da 640px in su, con una sidebar fissa a sinistra (200px) al posto della barra orizzontale — l'area di contenuto (`.app-main`) arriva fino a 920px. Non esiste una griglia a colonne multiple per il contenuto: ogni vista è un flusso verticale singolo, denso ma arioso, con card e liste che si susseguono.

Le liste preferiscono i **filetti** (hairline `1px solid var(--cream-dark)` tra una riga e l'altra) al posto di racchiudere ogni riga in una card separata — un pattern esplicito nel codice ("liste con filetti") che tiene le pagine leggere invece di impilare bordi su bordi. Le card restano riservate a contenuti che devono davvero isolarsi dal flusso (form, riepiloghi, blocchi di avviso).

Uno sfondo organico (tre gradienti radiali molto tenui in rose/sage/gold, opacità 6–8%) resta fisso dietro ogni pagina per tutta la sessione: è la "carta" del taccuino, non un dettaglio di una singola vista.

## Elevation & Depth

Sistema ibrido: le superfici sono piatte a riposo con un'ombra ambientale molto soffusa, e si sollevano solo in risposta a un'interazione. Non ci sono livelli di elevazione numerati alla Material: la profondità è un evento (hover, apertura), non uno stato permanente delle card.

### Shadow Vocabulary
- **Ambientale** (`box-shadow: 0 2px 12px rgba(42,34,24,0.06)`): riposo di ogni `.card`.
- **Sollevata** (`box-shadow: 0 8px 28px rgba(42,34,24,0.12)` + `translateY(-2px)`): hover di una card cliccabile (`.hover-card`).
- **Flottante** (`box-shadow: 0 20px 60px rgba(42,34,24,0.2)`): superfici che escono dal flusso della pagina — modale di conferma.
- **Di Bordo** (`box-shadow: -18px 0 50px -22px rgba(30,22,10,0.4)` / equivalente verticale su mobile): il foglio laterale/bottom sheet, che deve leggersi come una pagina che scivola sopra le altre.

### Motion
Un'unica curva di decelerazione morbida per ogni transizione di stato (`--ease-standard: cubic-bezier(0.4, 0, 0.2, 1)`), su due sole durate: `--motion-quick` (0.18s, la risposta immediata di un controllo — bottone, pillola, input, toggle) e `--motion-sheet` (0.26s, una superficie che scorre o si rivela — foglio, drawer, modale, un elemento che appare nella pagina). Nessun rimbalzo, nessun elastico: un oggetto reale decelera, non supera il punto d'arrivo per poi tornare indietro.

Restano fuori da questo sistema, di proposito, le animazioni "di carattere" — la coda e l'occhio di Zorba, il disegno a china dell'aiuola, il ridisegno cinematico su cambio stagione/luce, l'impulso della StatusBar, lo shimmer degli skeleton, la rotazione dello spinner, l'ingresso di "Tutto in ordine!" in Attività (600ms invece di 180-260ms: l'unico vero traguardo di quella vista, non un cambio di stato qualsiasi) — sono cicli, tratti meccanici o eventi rari che parlano con la voce del prodotto, non feedback d'interfaccia, e per questo restano su `ease-in-out`/`linear` invece che sulla curva di decelerazione, o usano la stessa curva ma con una durata propria da momento autoriale.

### Named Rules
**La Regola del Sollevamento Solo-su-Interazione.** Niente ombra profonda su una superficie ferma: l'ombra si intensifica solo quando l'elemento risponde a un tocco, hover o apertura. Una card statica non deve mai competere in profondità con un foglio o un modale aperto.

**La Regola della Decelerazione Unica.** Ogni transizione di stato (hover, focus, apertura, comparsa) usa `--ease-standard`, mai un rimbalzo/elastico (`cubic-bezier` con overshoot). Il "pop" giocoso è un'eccezione che si nota — e nel Taccuino da Giardino non c'è: anche un pallino che compare in una timeline si posa, non rimbalza.

## Shapes

Angoli sempre generosi, mai vivi: 6px sulle etichette più piccole (`.zona-tag`), 11–12px su tessere icona e bottoni, 14px su input, 20px sulle card, 22px su modale e foglio, fino al pieno 999px su pillole/badge/chip. Nessun elemento interattivo scende sotto i 6px di raggio — è la firma "morbida" del sistema, distinta da qualunque estetica da dashboard con angoli quasi retti.

I bordi sono quasi sempre hairline (`1px solid var(--cream-dark)`), usati per separare non per contenere: dividono righe di lista, chiudono in basso l'appbar, aprono in alto il foglio. Le uniche forme piene senza bordo sono le superfici bianche sollevate (card, input, sheet) su fondo carta.

## Components

### Buttons
- **Shape:** angoli morbidi (12px, `{rounded.button}`), altezza minima 44px (target di tocco).
- **Primary:** sfondo Verde Salvia Diluito, testo bianco, ombra colorata soffusa nel proprio hue (`0 3px 14px rgba(122,158,130,0.3)`) — l'azione di salvataggio/conferma in quasi ogni form.
- **Destructive:** stessa forma, sfondo Rosa ad Acquerello — solo per eliminare o confermare un'azione irreversibile (mai per salvare).
- **Ghost:** sfondo Carta Ombrata, testo Inchiostro Diluito, nessuna ombra — azione secondaria/annulla.
- **Hover / Focus:** scurimento della tinta + lieve sollevamento (`translateY(-1px)`); pressione: leggera contrazione (`scale(0.97)`).

### Azione di riga (`.care-act`)
Bottone compatto usato per confermare un singolo elemento di una lista — una cura registrata, una tappa di progetto completata — sempre con la stessa etichetta "Fatto" (mai "✓ Fatto" o varianti): pillola a contorno sottile su bianco, testo Inchiostro Diluito, 44px di altezza minima come ogni altro bottone dell'app. Variante `.care-act--rose` quando la riga è urgente/scaduta. È il pattern canonico per "questa riga è completata" ovunque compaia nell'app (scheda pianta, dossier pianta, Home, Attività): non introdurre una seconda implementazione con `.btn`/`.btn-rose` e dimensioni forzate via stile inline.

### Pills, Chips & Badges
- **Pill (filtro):** contorno sottile su bianco, diventa piena in Verde Salvia Diluito da attiva; variante quadrata "icona" (`.pill-icona`) per i selettori di icona zona/sottozona.
- **Badge (stato):** pillola piena in tinta pallida del dominio (`ok` = salvia, `warn` = rosa, `gold` = oro), testo nella tinta scura corrispondente.
- **Chip (etichetta compatta):** maiuscolo, tracciato, spesso con icona inline; variante "on-photo" per leggersi sopra un'immagine.

### Cards / Containers
- **Corner Style:** 20px (`{rounded.card}`).
- **Background:** bianco su fondo carta, mai carta-su-carta.
- **Shadow Strategy:** vedi Elevation — ambientale a riposo, sollevata su hover se cliccabile.
- **Border:** hairline 1px Carta Ombrata.
- **Variante urgente:** `.card-urgent` sostituisce bianco/hairline con Rosa Pallido/Rosa Chiaro per segnalare una cura scaduta senza cambiare forma.

### Inputs / Fields
- **Style:** bianco, bordo hairline, raggio 14px, ombra ambientale leggerissima.
- **Focus:** bordo Ocra Dorata + alone (`box-shadow: 0 0 0 3px rgba(224,184,74,0.15)`) — l'oro è il colore di messa a fuoco in tutta l'app, coerente con la Colors section.

### Navigation
- **Mobile:** appbar in alto con blur (`backdrop-filter: blur(8px)`) su carta semi-trasparente, e barra di tab in basso; le icone inattive diventano monocromatiche (`currentColor`), quella attiva riprende il colore originale — la navigazione "si accende" solo dove sei.
- **Desktop (≥640px):** sidebar fissa a sinistra (200px), stesso principio di ricolorazione icona attiva/inattiva; l'appbar mobile scompare.

### L'Aiuola (Home) — scena a china viva
La scena SVG dell'hero (`HeroAiuola.vue`) non è un'illustrazione statica: al mount, una matita a china ripassa l'intera scena una volta sola (tratti con `stroke-dasharray`, sfalsati nel tempo). Oltre a questo, se stagione o luce cambiano davvero mentre l'app resta aperta (un tramonto reale, un mese che finisce), la scena non scatta più da uno stato all'altro: il cielo dissolve con la View Transitions API mentre gli elementi della nuova stagione si ridisegnano a china con la stessa coreografia dell'apertura, riusando i medesimi ritardi/durate per tratto — un'animazione di carattere, fuori dal sistema di decelerazione. Su browser senza View Transitions (Firefox) il ridisegno a china resta, senza la dissolvenza di sfondo; con `prefers-reduced-motion` tutto scatta all'istante, senza alcuna animazione.

Un'oscillazione permanente dei singoli fiori/cespugli ("il vento nell'aiuola") è stata tentata e scartata: `transform-box:fill-box` sui gruppi `<use>`+`transform` di questa scena disallineava i tratti a china dalle forme colorate su WebKit (bug/incompatibilità del motore, non un errore di battitura nei valori) — vedi verifica del 05/09/2026. Non riprovare la stessa tecnica senza prima validarla in browser reale.

### Il Foglio (bottom sheet / side sheet) — segnaposto ricorrente
Pannello che scivola dal basso su mobile (angoli 22px solo in alto) e da destra su desktop (larghezza fissa 420px), usato per form di dettaglio (specie, cura, storico dell'agente) senza lasciare la pagina sottostante. Overlay scuro semitrasparente dietro, "maniglia" orizzontale visibile solo su mobile. È il modo standard con cui l'app apre un compito breve senza cambiare rotta.

### Timeline delle tappe (progetti)
Linea verticale che si disegna progressivamente (stroke-dasharray animato) mentre si scorre la pagina, con un pallino colorato per esito di ogni tappa (oro/salvia/rosa/neutro). È la rappresentazione visiva del progresso di un progetto di giardino nel tempo, non una lista piatta di date.

**Goccia d'inchiostro.** Quando un pallino entra in vista (o si cambia l'esito di una tappa), non scatta a scala piena: un alone dello stesso colore si allarga e sparisce (450ms) mentre il pallino pieno si assesta, come inchiostro che si posa sulla carta invece di una spunta generica. Il colore della traccia stessa non cambia di scatto quando un esito viene modificato: sfuma (`--motion-sheet`) da un colore all'altro. **Tentato e scartato**: una distorsione "a mano libera" della linea via filtro SVG (`feTurbulence`/`feDisplacementMap`) — verificata con rendering reale, non solo letto nel codice: a tratto spesso il colore della traccia spariva del tutto. Stessa lezione di `HeroAiuola.vue`/`transform-box:fill-box` — non riprovare una tecnica SVG esotica su questi elementi senza prima validarla con un rendering vero, non solo a occhio sul codice.

### Icone ad acquerello — sistema firma
Ogni icona (cura, meteo, zona) è una silhouette piena in stile Phosphor "fill" nella tinta del proprio dominio, con un'ellisse più scura della stessa famiglia (`-dark`) ritagliata dentro la forma a opacità 40%, a simulare il punto in cui il colore "si raccoglie" come acquerello vero. Un solo colore per icona, mai un contorno sottile: a 16–19px (barra di navigazione) una linea sottile risulterebbe illeggibile.

### Zorba — mascotte/assistente
SVG a china animato: coda che oscilla (4.6s, easing morbido) e occhio che sbatte le palpebre (6.2s) in loop continuo, disattivati con `prefers-reduced-motion`. Compare come logo (Home, header), come piccola icona (`.zorba-mini`, 21px) ovunque l'assistente AI sia coinvolto (drawer storico richieste, form richiesta), e come filigrana quasi invisibile (7% di opacità, tono carta non nero) dietro la sezione "La specie" di una pianta. È sempre e solo nero (vedi Named Rule in Colors).

**Due momenti di delight, stesso linguaggio, significato diverso** — entrambi via `ZorbaLogo.vue`, entrambi rispettano `prefers-reduced-motion` (nessuna reazione), nessuno dei due è un'animazione decorativa indipendente:
- **"Zorba nota il cambiamento"** — quando l'Aiuola della Home si ridisegna davvero per un cambio reale di stagione/luce (evento raro, vedi sopra), un battito di ciglia più lento del solito (0.9s invece di 0.4s, stesso keyframe). Metodo `reagisci()`, richiamato da `HomeView.vue` sull'evento `cambio-scena` di `HeroAiuola.vue`.
- **"Zorba conferma"** — quando una cura viene registrata con successo dal bottone "Fatto" in Home, lo stesso battito breve del risveglio al mount (0.4s) — un "ok" leggero, non una celebrazione, pensato per restare discreto anche alla decima cura della sessione. Metodo `confermaCura()`, richiamato da `HomeView.vue → registra()` dopo il successo di `pianteApi.registraCura`.

**La Regola dei Due Battiti.** Lento = un evento raro che merita di essere notato. Normale = una conferma frequente che deve solo sentirsi certa. Non scambiarli: usare il battito lento per un'azione quotidiana lo svaluterebbe, usare quello normale per un evento raro lo renderebbe invisibile.

## Do's and Don'ts

### Do:
- **Do** mantenere il lavaggio d'acquerello di sfondo (gradienti radiali rose/sage/gold, 6–8% opacità) su ogni pagina: è la carta del taccuino, non un dettaglio opzionale.
- **Do** usare Fraunces per ogni nome/titolo, a qualunque dimensione, e riservare DM Sans a tutto ciò che è servizio (numeri, etichette, chrome).
- **Do** applicare la Regola di Ink-Pooling a ogni nuova icona: silhouette piena in tinta di dominio + un'ellisse `-dark` clippata al 40% di opacità.
- **Do** riservare il Verde Salvia Diluito alle azioni affermative e il Rosa ad Acquerello solo a quelle distruttive/urgenti — non scambiarli.
- **Do** separare le righe di lista con filetti hairline, non con card impilate una sopra l'altra.
- **Do** dare alle superfici che escono dal flusso (modale, foglio, appbar) un'ombra o un blur più marcato di qualunque card ferma.
- **Do** usare `--ease-standard` per ogni transizione di stato, e una delle due durate condivise (`--motion-quick`/`--motion-sheet`) invece di inventare un nuovo numero.

### Don't:
- **Don't** introdurre superfici piatte grigie, blu corporate o icone outline sottili da tool aziendale: rompe l'identità di giardino disegnato a mano.
- **Don't** sostituire l'illustrazione a china/acquerello con foto stock botaniche generiche o gradienti verde/marrone scontati da app di giardinaggio.
- **Don't** schiarire o ricolorare Zorba, nemmeno per uno stato disabilitato/muto: resta nero, al massimo con un alone in dark mode.
- **Don't** stringere il sistema di raggi (6–22px) verso angoli da 2–4px "da dashboard": la morbidezza è la firma tattile del sistema.
- **Don't** incorniciare in una card con bordo pieno una lista che già usa il pattern a filetti — sarebbe una doppia gerarchia di contenimento.
- **Don't** usare un easing con overshoot (rimbalzo/elastico) su un elemento d'interfaccia: rompe la Regola della Decelerazione Unica ed è in tensione diretta con un sistema "caldo e quieto".
