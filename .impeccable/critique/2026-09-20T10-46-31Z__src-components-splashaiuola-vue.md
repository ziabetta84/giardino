---
target: SplashAiuola
total_score: 23
max_score: 32
na_heuristics: 5,10
p0_count: 1
p1_count: 3
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/components/SplashAiuola.vue"
target_fingerprint: "sha256:1faee7e320232abdd46c3f4daf1d3d9aa9ee1c057fa9b13ba33874829484ee90"
target_path: /Users/rob/Sites/localhost/giardino/src/components/SplashAiuola.vue
timestamp: 2026-09-20T10-46-31Z
slug: src-components-splashaiuola-vue
---
Method: dual-agent (A: revisione di design isolata · B: detector + evidenza browser isolata)

## Punteggio di salute del design

| # | Euristica | Punteggio | Problema chiave |
|---|-----------|-----------|------------------|
| 1 | Visibilità dello stato del sistema | 3/4 | Le fasi (0→1→2) leggono come un ritmo voluto, ma nulla segnala quanto durerà ancora lo splash |
| 2 | Corrispondenza col mondo reale | 4/4 | Saluto per fascia oraria, data reale, cancello come soglia — eccellente |
| 3 | Controllo e libertà dell'utente | 1/4 | **Verificato dal vivo**: cliccare sulla scena non chiude lo splash — `@click.self="salta"` non può mai scattare (vedi P0) |
| 4 | Coerenza e standard | 3/4 | Pattern modale coerente col resto dell'app; la timing bespoke è esplicitamente autorizzata da DESIGN.md per i "momenti di carattere" |
| 5 | Prevenzione degli errori | n/a | Nessuna azione distruttiva o reversibile su questa superficie passiva |
| 6 | Riconoscimento piuttosto che ricordo | 4/4 | Tutto il contenuto (nome, data, contatori) è già visibile |
| 7 | Flessibilità ed efficienza d'uso | 2/4 | Nessuna scorciatoia per chi apre l'app più volte al giorno oltre al gate "una volta per fascia" |
| 8 | Estetica e design minimalista | 4/4 | Il punteggio più alto — davvero bello, misurato, coerente col brand |
| 9 | Aiuto a riconoscere/diagnosticare errori | 2/4 | Stato d'errore ("Dati non disponibili") senza causa né azione, accettabile ma minimo |
| 10 | Guida e documentazione | n/a | Un'animazione d'ingresso di 5s che si autochiude è autoesplicativa per natura |
| **Totale** | | **23/32** | **Buono (71.9%)** |

## Verdetto di specificità del design

**Valutazione A (LLM)**: Inequivocabilmente autoriale, non un template generico. La composizione ruota attorno a un oggetto narrativo preciso — il cancello del giardino — con coordinate di fuoco calibrate a mano su ciascuna delle 8 tele stagione×luce, una sequenza "il contorno a china si disegna, poi il colore irrompe dal cancello" costruita sui tracciati SVG reali del dipinto (non uno shimmer generico), e una mascotte con una storia vera (un gatto reale sepolto nel giardino) i cui due battiti di ciglia hanno significati semanticamente distinti per regola esplicita di DESIGN.md. Nessun'altra app potrebbe riusare questo componente senza rifare otto dipinti e otto tracciati — è esattamente il tipo di cura che sostiene l'obiettivo di sponsorizzazione dichiarato nel progetto.

**Scansione deterministica**: `impeccable detect` su `SplashAiuola.vue` + `HeroAiuola.vue` — uscita 0 (pulita, solo avvisi), 3 riscontri `design-system-color` (colori non documentati in DESIGN.md: `#f3c9c2` per il testo urgente in Splash, `rgba(255,224,158,.9)` del bagliore e `#0f1608` dell'inchiostro del contorno, entrambi in HeroAiuola). Nessun blocco reale, solo un disallineamento di documentazione — la Valutazione A non li aveva notati.

**Evidenza da browser**: l'iniezione del detector è riuscita (verificata con una mutazione reale del DOM, non solo una lettura). Sulla pagina live, il detector ha segnalato 3 anomalie, identiche su tutte e 3 le combinazioni stagione/luce testate (segno che legge CSS statico, non i pixel effettivamente renderizzati per scena):
- `cream-palette` sullo sfondo `<body>` — **falso positivo**, confermato dalla Valutazione B: `.splash` copre l'intero viewport (`position:fixed; inset:0; z-index:480`), quindi quello sfondo non è mai visibile all'utente.
- Due `low-contrast` (1.1:1 e 1.2:1, contro i 4.5:1/3:1 richiesti) sul testo crema/bianco contro lo sfondo sage piatto — **non un falso positivo**: confermato via screenshot che è reale mail per una finestra di transizione di ~1.8s (circa 700ms–2500ms dopo il mount, durante il disegno del contorno, prima che il dipinto e la sfumatura scura compositino). Dopo quella finestra il contrasto torna a posto. Nessuno dei due assessment aveva previsto l'altro: la A non aveva misurato il contrasto durante quella fase transitoria, la B non giudica l'intento narrativo — insieme individuano un problema reale che nessuna delle due avrebbe trovato da sola.

Non ho lasciato un overlay aperto in un tab visibile: l'iniezione è stata eseguita in un browser headless isolato dalla Valutazione B, non nel browser dell'utente.

## Impressione generale

Il picco emotivo (il colore che irrompe dal cancello, la camera che si avvicina, il pattern dorato di Zorba) funziona davvero le prime volte ed è un argomento concreto per la sponsorizzazione — ma tre problemi concreti (skip via click morto, tocco troppo piccolo, cancello invisibile su mobile) intaccano proprio l'unico contesto d'uso reale dichiarato nel progetto: un telefono in mano, in giardino. La più grande opportunità: il crop mobile, perché nessuno dei due assessment ha trovato prova che le 8 tele siano mai state validate fuori da un viewport desktop.

## Cosa funziona bene

- **Il passaggio contorno→bloom→colore**: ordinare i tratti per lunghezza (le sagome grandi prima dei dettagli fini) fa sembrare che una mano abbia disegnato la scena, non un loop Lottie generico — è esattamente il tipo di cura invisibile che distingue un pezzo da portfolio da un template.
- **L'ingresso indipendente di Zorba**: il gatto è già nero pieno e presente al frame 0 mentre il giardino si sta ancora formando attorno a lui — letta generosamente, questa scelta lo mette in scena come "già di casa nel giardino", coerente con la sua storia di essere sepolto lì.
- **Il percorso "riduci movimento" è un vero fallback**, non un ripiego: verificato dal vivo che con quella preferenza il dipinto appare subito a colori pieni, senza clip-path/bloom/zoom — e la Valutazione B ha scoperto (senza saperlo, in isolamento) che questo percorso evita anche la finestra di basso contrasto: una convergenza involontaria ma reale tra le due valutazioni.

## Problemi prioritari

**[P0] "Clicca per saltare" non funziona.** Verificato con Playwright: cliccare sulla scena visibile non emette mai `fine` — `document.elementFromPoint` conferma che il bersaglio del click è sempre `.zc-scene` (figlio a piena pagina), mai `.splash` stesso, quindi `@click.self="salta"` non può strutturalmente scattare: `.splash__scene` con `inset:0` intercetta ogni click prima che raggiunga il genitore. Su mobile (niente tasto Esc), l'unico modo che funziona davvero è il piccolo pill "Salta".
**Perché conta**: il cursore è impostato a `pointer` su `.splash`, promettendo un'interazione che non esiste — un utente che segue quel segnale resta bloccato.
**Fix**: sposta il gestore del click su `.splash__scene` stesso (o rimuovi `.self` ed escludi esplicitamente testo/Zorba/bottone con `event.target.closest(...)`), e verifica dal vivo — non solo leggendo il template — che scatti davvero.
**Comando suggerito**: `/impeccable harden`

**[P1] Contrasto reale e insufficiente per ~1.8s ad ogni apertura.** Trovato dal detector ed confermato via screenshot dalla Valutazione B: durante la fase di disegno del contorno (prima che dipinto e sfumatura compositino), il testo crema/bianco (data, saluto) sta su uno sfondo sage piatto a 1.1:1–1.2:1 di contrasto, ben sotto i minimi WCAG. Succede identicamente su tutte le scene, notte comprese.
**Perché conta**: è una finestra breve ma reale e sistematica, non un caso limite — capita ad ogni singola apertura dello splash, fino a 3 volte al giorno.
**Fix**: scurisci leggermente lo sfondo di `.splash` durante la fase di disegno (prima che il dipinto arrivi), o ritarda la comparsa del testo fino a dopo l'inizio della dissolvenza a colori.
**Comando suggerito**: `/impeccable polish`

**[P1] Il tasto "Salta" è alto 28px, sotto il minimo di 44px che il sistema stesso impone.** Misurato dal vivo: `61×28px`, `top:16px; right:16px`. DESIGN.md dichiara esplicitamente 44px come "altezza minima (target di tocco)" per ogni bottone dell'app — questo pill non lo rispetta, ed è anche l'unico dismiss affidabile su touch dato il P0 sopra.
**Fix**: aumenta il padding verticale fino a raggiungere 44px, come ogni altro bottone del sistema.
**Comando suggerito**: `/impeccable adapt`

**[P1] Il cancello — il soggetto di tutta la coreografia — è tagliato fuori schermo su mobile in verticale.** Misurato: il dipinto (1536×1024, rapporto 1.5) va in `object-fit:cover` su un riquadro 390×844 (rapporto 0.46); con `object-position: center bottom` è visibile solo il 30.8% centrale della larghezza dell'immagine (~34.6%–65.4%). Il punto-fuoco calibrato per desktop (x≈69% per autunno/giorno) cade fuori da quella fascia. Sullo screenshot mobile non c'è cancello, non c'è vialetto: solo fiori e un palo isolato. Bloom, rivelazione a colori e spinta di camera sono tutti centrati su un punto invisibile sul telefono.
**Perché conta**: è la discrepanza più grande tra "impeccabile su desktop" e l'unico contesto d'uso reale dichiarato per questa PWA (in mano, in giardino).
**Fix**: `object-position` calcolato da `--fx`/`--fy` per breakpoint, oppure un ritaglio/punto-fuoco dedicato per il verticale su tutte e 8 le tele.
**Comando suggerito**: `/impeccable adapt`

**[P2] La cadenza "una volta per fascia" sottostima l'usura.** Non è una volta al giorno: è fino a 3 volte (mattina/pomeriggio/sera), identica al pixel ogni volta entro la stessa stagione, senza alcuna via d'uscita per chi apre l'app spesso.
**Fix**: un interruttore nelle Impostazioni per disattivarlo, o un decadimento automatico (dopo N visioni in una stagione, passa al trattamento istantaneo di "riduci movimento" anche senza quella preferenza di sistema).
**Comando suggerito**: `/impeccable shape`

## Segnali per persona

**Casey (distratta, su mobile)**: due problemi si sommano. Tocca la scena aspettandosi che si chiuda (il cursore è pure `pointer`) — non succede (P0). Poi deve cercare il vero tasto d'uscita, un pill di 28px in alto a destra, col pollice che probabilmente lo manca o lo copre in una presa a una mano. E anche una volta uscita, sul suo telefono l'intero climax compositivo (il cancello, il bloom, "benvenuta dentro") non è mai visibile (P1, crop mobile).

**Sam (dipendente da accessibilità)**: `role="dialog" aria-modal="true" aria-label="Il tuo giardino"` non riassume il contenuto reale (saluto, data, contatori) per chi usa uno screen reader e non ha ancora esplorato il corpo del dialogo, senza alcun controllo di pausa entro i 5.2s di autochiusura. Gli elementi decorativi sono correttamente `aria-hidden`, quindi non è un buio totale — ma il payload di dati live è proprio la parte non anticipata nel nome accessibile.

**Alex (utente esperto, apre l'app spesso)**: nessun "non mostrarlo più" — l'unico freno è "una volta per fascia", quindi fino a 3 blocchi da 5.2s al giorno che sembrano obbligatori, con lo skip sia rotto (P0) sia troppo piccolo (P1).

## Osservazioni minori

- 3 colori non documentati in DESIGN.md (`#f3c9c2`, `rgba(255,224,158,.9)`, `#0f1608`) — trovati dal detector, non dalla revisione LLM: vale la pena aggiungerli alla palette ufficiale dato che sono già in produzione.
- Contenuto a tempo senza pausa/estensione (WCAG 2.2.1): lo splash porta dati reali (piante/zone/urgenti) e si autochiude a 5.2s senza modo di allungare il tempo, solo di accorciarlo.
- `.splash__txt` riserva 152px fissi a destra per Zorba a ogni larghezza — su mobile forza il saluto su due righe e il terzo pill statistico su una riga propria; nessuna media query nel file oltre a `prefers-reduced-motion`.
- Nomi utente lunghi non testati contro il blocco di testo a posizione fissa (`text-wrap: balance` su un h1 di 32px).
- Il pattern dorato di Zorba (mount indipendente, ~1.6–2.0s) e la rivelazione del giardino (~2.6–3.9s) sono due timeline autoriali che si sovrappongono per coincidenza più che per coreografia condivisa — non sbagliato, ma un candidato per un'eventuale stretta futura.
- Copy dello stato d'errore ("Dati non disponibili") più freddo del tono caldo del resto dell'app.

## Domande da considerare

1. Se il cancello è l'ancora compositiva e narrativa di tutte e 8 le tele, perché il crop mobile non è mai stato controllato prima d'ora — le tele sono state approvate solo su desktop?
2. "Una volta per fascia" è davvero la cadenza giusta per un momento di carattere, o funzionerebbe meglio — e si consumerebbe più lentamente — come "una volta al giorno vero", accettando un po' meno di freschezza per non diventare arredo?
3. Qualcuno ha mai visto un utente vero provare a chiudere lo splash toccando la scena, o quel percorso è stato dato per funzionante solo leggendo il template?
