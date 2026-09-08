---
target: ProgettiView.vue
total_score: 25
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/ProgettiView.vue"
target_fingerprint: "sha256:27fa7f2786af99ba0ea1e5af02135e6c007a2ba22f95aa50b71657bb41c469e7"
target_path: /Users/rob/Sites/localhost/giardino/src/views/ProgettiView.vue
timestamp: 2026-09-08T15-51-31Z
slug: src-views-progettiview-vue
---
## Design Health Score — ProgettiView.vue

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2/4 | salvaProgetto() senza catch, su fallimento nessuna indicazione |
| 2 | Match System/Real World | 4/4 | Vocabolario naturale, nessun gergo |
| 3 | User Control and Freedom | 3/4 | Foglio si chiude bene, nessuna eliminazione dalla lista |
| 4 | Consistency and Standards | 2/4 | Bottone Aggiungi 36px sotto il minimo 44px gia' corretto in ConcimiView |
| 5 | Error Prevention | 1/4 | Nessun try/catch, zona testo libero non collegato al catalogo |
| 6 | Recognition Rather Than Recall | 3/4 | Zona richiede di ricordare un nome esatto |
| 7 | Flexibility and Efficiency | 2/4 | Nessun filtro/ordinamento oltre l'alfabetico |
| 8 | Aesthetic and Minimalist Design | 4/4 | Essenziale, nessun rumore decorativo |
| 9 | Error Recovery | 1/4 | Nessun percorso d'errore |
| 10 | Help and Documentation | 3/4 | Nulla spiega che la scadenza e' calcolata, non impostata |
| **Totale** | | **25/40** | **Accettabile** |

## Verdetto di specificita'
LLM: autoriale nella composizione (filetti, Fraunces sul titolo, icone ink-pooling, MiniEditor minimale) ma perde identita' nei dettagli: icona scadenza permanentemente rosa, chip di stato che fallisce il contrasto, nessuna segnalazione di urgenza a differenza del precedente "Urgenti" di PianteView.
Detector: pulito, nessun rilievo (array vuoto, exit 0).

## Impressione generale
Lista disciplinata nella composizione che non riesce a fare la cosa che il prodotto dichiara di voler ottenere: nessun modo di vedere quale progetto si sia arenato, ordinamento puramente alfabetico, icona scadenza sempre rosa che segnala falsi allarmi.

## Cosa funziona
1. Righe a filetto invece di card impilate, regola DESIGN.md rispettata alla lettera.
2. descrizioneBreve() ben fatta: taglia a confine di frase/parola, mai a meta' parola.
3. Stato vuoto caldo e concreto, non un placeholder generico.

## Problemi prioritari

[P1] Fallimento silenzioso alla creazione — salvaProgetto() senza catch, su fallimento il foglio resta aperto senza spiegazione. Fix: try/catch con messaggio inline, stesso pattern di PianteView. Comando: /impeccable harden

[P1] Nessuna urgenza mai segnalata — ordinamento alfabetico, nessuna priorita' visiva per progetti scaduti. Fix: ordinare prima gli scaduti/urgenti o raggruppare separatamente i completati/cancellati. Comando: /impeccable layout

[P1] Chip di stato .st--n fallisce contrasto WCAG AA — ink-soft su carta-2 e' ~2.77:1, sotto il minimo 4.5:1, usato per "Aperto" e "Cancellato". Fix: token di inchiostro dedicato piu' scuro per il chip neutro. Comando: /impeccable harden

[P2] Target di tocco sotto standard sul bottone Aggiungi — 36px invece di 44px, difetto gia' corretto in ConcimiView (.pill--cta) ma non qui. Fix: class="pill pill--cta". Comando: /impeccable polish

[P2] Icona scadenza sempre rosa indipendentemente dall'urgenza reale — dilulisce il significato del rosa nell'app. Fix: neutra di default, rosa solo quando urgente e' vero. Comando: /impeccable colorize

## Red flag per persona
Jordan: nessun campo data nel form di creazione, zona testo libero senza suggerimento, primo salvataggio silenzioso se fallisce.
Sam: chip illeggibile a basso contrasto, toggle MiniEditor senza aria-pressed, contenteditable senza role/aria-label, label Titolo senza for/id.
Casey: bottone Aggiungi sotto la soglia di tocco, nessun filtro/ricerca, icona sempre rosa fa sembrare "in difficolta'" progetti innocui a colpo d'occhio.

## Osservazioni minori
- .prow__t (titolo) senza line-clamp a differenza di .prow__d.
- "Aperto" e "Cancellato" condividono lo stesso chip, indistinguibili se non dal testo.
- Nessun toast di successo dopo il salvataggio.
- Skeleton di caricamento ben fatto, nessuna modifica necessaria.

## Domande provocatorie
- Ordinare di default per scadenza con una sezione Storico collassata renderebbe questa lista una vera superficie di triage quotidiano?
- La creazione di un progetto potrebbe riusare il battito lento "Zorba nota il cambiamento" gia' codificato per eventi rari?
