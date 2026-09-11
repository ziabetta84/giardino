---
target: public/stato-progetto.html è destinato ad essere la presentazione del progetto all'agenzia, come lo miglioreresti?
total_score: 14
max_score: 24
na_heuristics: 5,7,9,10
p0_count: 0
p1_count: 3
target_identity: "file:/Users/rob/Sites/localhost/giardino/public/stato-progetto.html"
target_fingerprint: "sha256:04653f698e3a2be1da70cf3d975fc1b9dbc95aaadbd3b704d9234cae854c559a"
target_path: /Users/rob/Sites/localhost/giardino/public/stato-progetto.html
timestamp: 2026-09-10T22-24-40Z
slug: public-stato-progetto-html
---
Method: ⚠️ DEGRADED: single-context (nessun tool di sub-agent per Assessment A/B; nessun tool di automazione browser — detector CLI eseguito inline)

Target: public/stato-progetto.html — documento di presentazione del progetto all'agenzia (modalità Persuade)

## Design Health Score

| # | Euristica | Punteggio | Nota chiave |
|---|-----------|-----------|-------------|
| 1 | Visibilità dello stato | 2 | "Aggiornato al 28 ago" c'è, ma i contenuti sono fermi a 2 settimane fa; nessun indice/progresso su un documento lungo |
| 2 | Corrispondenza col mondo reale | 3 | Italiano naturale e curato; unico calo: il gergo tecnico della sezione 03 (RAG, pg_trgm, RLS, function calling) per un lettore d'agenzia |
| 3 | Controllo e libertà | 2 | Scroll unico molto lungo, nessun sommario, nessun salto di sezione, nessun torna-su |
| 4 | Coerenza e standard | 2 | Coerente al suo interno, ma **incoerente col prodotto che rappresenta**: font, palette, sfondo, uso di Zorba diversi dall'app |
| 6 | Riconoscere anziché ricordare | 2 | Il lettore deve tenere a mente il differenziale della sez. 02 fino a mercato (04) e richiesta (05), senza nav persistente |
| 8 | Estetica e minimalismo | 3 | Editoriale pulito e leggibile; pesano il titolo gradiente + glow animato e il muro della sez. 03 |
| **Totale** | | **14/24** | **Accettabile** (euristiche 5, 7, 9, 10 = n/a: documento statico senza input né percorso utente) |

## Verdetto di specificità

**Categoria-intercambiabile.** Togli il testo italiano e il segno di Zorba in alto a destra e questa è la pagina di stato di un qualsiasi prodotto indie: serif editoriale, hero con titolo in gradiente, griglia di card, timeline. Non sembra uscita dalla stessa mano dell'app che deve promuovere. È il problema che conta di più qui, perché **la tesi stessa del documento è che design e brand (Zorba) sono il fossato difensivo** — e la pagina non lo dimostra, lo descrive soltanto.

**Scansione deterministica (detector CLI):** 67 rilievi, quasi tutti = divergenza da DESIGN.md.
- `design-system-font` ×3: usa **Playfair Display + Lora**, non Fraunces/DM Sans/Caveat del sistema.
- `design-system-color` ×10, `design-system-radius` ×3 (18/16/14px fuori scala), `design-system-font-size` ×9: token propri che approssimano la palette con nomi diversi (`--rose-tile` vs `rose-bg`…).
- `gpt-thin-border-wide-shadow` ×24: ogni card è bordo 1px + ombra 28px di blur — l'app a riposo è piatta con ombra ambientale 0 2px 12px.
- `gradient-text` ×2, `side-tab` ×2 (i `.callout` con bordo sinistro 3px), `undersized-ui-text` ×10 (tag "Verificata"/"Bozza" a 10,88px), `skipped-heading` ×3 (h2→h4), `em-dash-overuse` (70 trattini lunghi nel corpo).

**Overlay visivi:** non disponibili (nessun tool browser in questa sessione). Nessun overlay a schermo è stato iniettato.

## Impressione generale

È un buon documento editoriale che fallisce come *pitch di Zorba* per due ragioni: non sembra Zorba, e non porta in primo piano la richiesta. Funziona come **rapporto di avanzamento interno** ("Dove siamo", "Aggiornato al…"), non come un testo che deve far decidere qualcuno. La più grande opportunità: ricostruirlo nel sistema visivo dell'app e riordinarlo attorno a "cosa chiediamo all'agenzia e cosa sblocca".

## Cosa funziona

- **Il filo dell'onestà del dato** (verificato vs bozza, "nessun dato inventato passa per confermato") attraversa tutto il documento in modo coerente ed è un differenziale vero, raro e credibile.
- **Le tre prove di progetto** (Orto 17 tappe, Albicocco da seme 2026→2029, Arancio *fallito*) sono concrete e specifiche — evidenza reale, esattamente ciò su cui PRODUCT.md dice di puntare. "Non nascondiamo gli insuccessi" è un'ottima mossa di fiducia.
- **Franchezza sui limiti** (nessun modello di visione dedicato come Planta/PictureThis; dati tarati su clima UK): dà credibilità al resto.
- Ritmo tipografico e numerazione delle sezioni: leggibili, ariosi.

## Problemi prioritari

### [P1] Il pitch non sembra il prodotto che promuove
**Perché conta:** il documento sostiene che il fossato è "design + brand (Zorba)" mentre è impaginato come una status page generica. Un'agenzia a cui chiedi di scommettere sulla qualità visiva sta guardando una pagina che non la esibisce. I 67 rilievi del detector misurano proprio questa distanza da DESIGN.md.
**Fix:** ricostruire la *shell* nel sistema dell'app — Fraunces/DM Sans, sfondo `--cream` con il lavaggio ad acquerello (i tre gradienti radiali rose/sage/gold 6–8%), raggi e ombre di DESIGN.md, Zorba come presenza ricorrente (segni di sezione, i callout "Zorba dice") e non un solo marchio d'angolo. Eliminare il titolo in gradiente + `glow-pulse` a favore di un display Fraunces.
**Comando:** `/impeccable typeset` poi `/impeccable polish` (o un giro di redesign della shell).

### [P1] È un diario di stato, non una proposta — la richiesta è sepolta
**Perché conta:** apre con "Dove siamo / Aggiornato al". La spina persuasiva (differenziale = seguire un progetto nel tempo; mercato dimostrato; Zorba = moltiplicatore; la richiesta = scegliere la direzione di distribuzione + sponsorizzare il backend AI) è sparsa, e la cosa più vicina a "cosa ci serve da voi" è a 5/6 di documento, incorniciata come un bivio tecnico.
**Fix:** riordinare — gancio + proposta di valore in una frase in cima (con il brand visibile); portare su la sezione 02 (il differenziale); estrarre "La richiesta" in una sezione propria, alta o in chiusura forte: quale decisione, cosa sblocca la sponsorizzazione, il percorso a basso rischio (mockup Figma + demo cliccabile).
**Comando:** `/impeccable shape` (ristrutturazione) o `/impeccable clarify`.

### [P1] I contenuti fermi minano la credibilità
**Perché conta:** datato 28 agosto (oltre 2 settimane). Dice "3/6 fasi", "Fase 5 a metà settembre", "RHS 37.452 pagine ~12%, in corso" — quando la Fase 5 è completata e l'import da sitemap RHS è chiuso dal 30/08 (catalogo → 15.742 righe). Un lettore che apre l'app live o il repo vede che il documento è indietro; e i numeri fermi *sottostimano* i progressi reali.
**Fix:** aggiornare cifre e timeline; consolidare **ogni numero + la data "aggiornato al"** in un unico blocco dati, così che l'aggiornamento futuro sia una modifica sola; valutare di generare i conteggi di testa da un piccolo JSON in build.
**Comando:** perlopiù refresh di contenuto; `/impeccable harden` per la parte "una fonte sola per i dati".

### [P2] La sezione 03 è un muro tecnico di 5 blocchi al centro del pitch
**Perché conta:** ~800 parole di difesa su RAG/function calling/pg_trgm/RLS/Workers tra il differenziale e mercato+richiesta. Per un pubblico d'agenzia non tecnico è una valle emotiva.
**Fix:** aprire la 03 con 2–3 frasi in lingua piana ("l'AI non inventa mai una data — orchestra codice deterministico"), poi collassare i blocchi profondi dietro un "per chi vuole il dettaglio tecnico" o spostarli in appendice.
**Comando:** `/impeccable distill`.

### [P2] Nessuna identità di condivisione per un documento che vive solo come link
**Perché conta:** `<title>Stato del Progetto</title>` generico, nessuna favicon, nessun meta OG/Twitter, nessuna riga "chi/cosa". Inviato ai contatti dell'agenzia via Slack/email compare come URL nudo; un lettore a freddo non sa chi l'ha scritto né cos'è "il progetto".
**Fix:** `<title>` con il brand ("Zorba in giardino — la proposta"), favicon Zorba, meta OG (titolo/descrizione/immagine), un sottotitolo di una riga sotto l'H1 con contesto e autore.
**Comando:** `/impeccable polish`.

## Bandiere rosse per persona

**Il decisore d'agenzia (Persuade, persona di progetto):** apre il link su un titolo "Stato del progetto", scorre "Dove siamo", "aggiornato al 28 agosto". Nei primi due schermi non trova: cos'è in una frase, perché dovrebbe importargli, cosa gli si chiede. La richiesta arriva dopo il muro tecnico. Rischio: chiude prima di arrivare all'ask.

**Casey (mobile):** nella sezione 05 il blocco `grid-template-columns:1fr 1fr` inline non si impila — due colonne strette sotto i ~460px. Documento lunghissimo senza torna-su né indice: su telefono è tutto scroll cieco. La timeline finale (11 item) a thumb è interminabile.

**Riley (valutatore scettico):** controlla le affermazioni contro la realtà. Apre il repo/app: la Fase 5 è fatta, il documento dice "a metà settembre". "37.452 pagine (~12%)" contro un import già concluso. Ogni numero fermo che scopre indebolisce la fiducia negli altri numeri — inclusi quelli che giocano a favore.

## Osservazioni minori

- Salto di livello dei titoli h2→h4 (manca h3): accessibilità, fix banale.
- 70 trattini lunghi nel corpo: la prosa legge come un unico respiro; variare la punteggiatura.
- I `.callout` sono densi quanto il testo attorno: il dispositivo "asporto" non stacca. Ridurre a una frase ciascuno.
- Le chip dei concorrenti sono sei nomi in fila senza "il punto è questo": una riga di posizionamento lavorerebbe di più.
- `--ink-soft` è impostato uguale a `--ink-mid` (#5a4e3e): il gradino di testo terziario è collassato, molto corpo testo su un solo peso.
- `.gradient-title` con `glow-pulse` infinito: in tensione con DESIGN.md ("decelerazione unica", caldo e quieto) ed è l'elemento più vistoso e insieme più generico.
- Numeri cablati in ~20 punti: trappola di obsolescenza (vedi P1 #3).

## Domande da considerare

- Se il fossato è design + Zorba, che aspetto avrebbe questo documento se fosse *la prima prova* di quel fossato invece della sua descrizione?
- Qual è l'unica decisione con cui vuoi che l'agenzia esca pronta — ed è visibile nel primo schermo?
- Al lettore d'agenzia serve davvero l'argomento RAG-sì/RAG-no, o è materiale per una futura figura tecnica?
