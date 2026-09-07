---
target: ConcimiView
total_score: 22
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/ConcimiView.vue"
target_fingerprint: "sha256:3536f33a1407ea2e38e752f2fe84418c49a4673bf24f9f77eaa4467f9b7d8510"
target_path: /Users/rob/Sites/localhost/giardino/src/views/ConcimiView.vue
timestamp: 2026-09-07T19-20-44Z
slug: src-views-concimiview-vue
---
Method: dual-agent (A: design-review subagent · B: detector-evidence subagent)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Skeleton loading, per-action spinners e disabled state su salva/toggle/elimina — solido. |
| 2 | Match System / Real World | 2 | "NPK" e rapporti come "20-20-20" compaiono senza alcuna legenda: si presume che l'utente sappia già cosa significano N, P, K. |
| 3 | User Control and Freedom | 3 | Annulla sempre disponibile, toggle reversibile, eliminazione protetta da conferma. Nessun "undo" post-eliminazione, ma coerente col resto dell'app. |
| 4 | Consistency and Standards | 1 | Nome prodotto in DM Sans invece di Fraunces, target di eliminazione ~28px invece di 44px, empty state senza il CTA che le altre liste ripetono, `.toggle-switch` è un one-off senza equivalente altrove nel codebase. |
| 5 | Error Prevention | 3 | `min="0"` sugli input NPK, Salva disabilitato a nome vuoto, eliminazione dietro conferma esplicita. |
| 6 | Recognition Rather Than Recall | 3 | Rapporto NPK e tag "terminato" visibili direttamente in lista, senza dover aprire ogni riga. |
| 7 | Flexibility and Efficiency | 1 | Nessuna ricerca, nessun filtro (es. "solo disponibili"), ordinamento fisso alfabetico: con una dispensa ampia diventa solo scroll. |
| 8 | Aesthetic and Minimalist Design | 2 | Visivamente spoglio, ma la sobrietà si legge come "incompiuto", non come "editato": nessuna icona, nessun colore di dominio. |
| 9 | Error Recovery | 3 | Messaggi di errore specifici e in italiano naturale per ogni azione, non un toast generico. |
| 10 | Help and Documentation | 1 | L'unica spiegazione di cosa serva questa schermata vive solo nell'empty state e sparisce per sempre al primo concime aggiunto. |
| **Total** | | **22/40** | **Accettabile** |

## Design Specificity Verdict

**Valutazione LLM (Assessment A):** ConcimiView si legge come una schermata CRUD generica d'inventario che indossa il chrome dell'app (`.page-title`, `.pill`, lo scheletro `.card`, `FoglioLaterale`) più che una schermata pensata per la mensola dei concimi di un taccuino da giardino. La prova è comparativa: la riga pianta gemella (`PiantaRiga.vue`) dà a ogni riga una tessera icona 48px in colore di dominio, un nome in Fraunces e un bersaglio di eliminazione 44×44px — una composizione curata. La riga di ConcimiView (righe 22-38) è spoglia: nessuna icona, nessun colore di dominio in tutta la pagina, nome in DM Sans (`.feed__n`, `main.css:449`), eliminazione ridotta a una `×` nuda. L'unica icona presente — la provetta dell'empty state — è colorata `var(--sage)` (`IconDefs.vue:79`), il colore delle azioni affermative, non `var(--olive)`, che CLAUDE.md riserva esplicitamente al dominio concimazione; l'app possiede già un'icona `i-concimazione` dedicata e olive, usata correttamente altrove (`AttivitaRiga.vue`), e ConcimiView non la usa mai. Il form (nome + 3 numeri NPK + descrizione + interruttore) potrebbe essere l'inventario di viti o spezie: nulla in layout, colore o tipografia segnala "mensola dei concimi in un taccuino disegnato a mano" — zero Caveat, zero colore di dominio, zero eco visiva del lavaggio ad acquerello oltre lo sfondo ambientale condiviso da tutta l'app.

**Scansione deterministica (Assessment B):** Il detector (`impeccable detect --json`, exit code 0) segnala 4 riscontri, tutti sulla stessa regola `design-system-font-size` (severità *advisory*, categoria *quality*): riga 8 e 72 (12px, testo di errore inline), riga 231 (20px, glifo "×" del bottone elimina) e riga 266 (10px, glifo dello spinner nell'interruttore). Verificati contro il file: nessun falso positivo nel senso di "il codice non fa quello che dice il detector" — i valori sono esattamente quelli riportati. C'è però una discrepanza interna a DESIGN.md stesso, non imputabile a ConcimiView: la sezione machine-readable elenca 4 valori discreti (26/13/11/19px), mentre la sezione prosa "Hierarchy" documenta intervalli più larghi (Body 12.5-14px, Label 9.5-11px); sotto questa seconda lettura, riga 266 (10px) rientrerebbe nell'intervallo Label, mentre righe 8/72 (12px, appena sotto 12.5px) e riga 231 (20px) resterebbero comunque fuori scala in entrambe le letture. Non è un difetto di ConcimiView da correggere isolatamente, ma un disallineamento nella fonte di verità (DESIGN.md) che vale la pena segnalare a parte.

**Overlay visivi:** non disponibili in questa sessione — nessuno dei due assessment aveva accesso a uno strumento di controllo browser (nessun Playwright/Puppeteer/screenshot esposto in questo ambiente), e ho verificato anch'io che nessun tool del genere è registrato. Nessun dei due assessment ha inventato uno screenshot o una console; entrambi lo hanno segnalato esplicitamente come fallback. Il server di sviluppo locale (`localhost:5173`) era comunque raggiungibile (HTTP 302, atteso dietro il guard di autenticazione Supabase).

## Overall Impression

La logica sotto il cofano (`useConcimi.js`, matching NPK a distanza normalizzata) è solida e già ben progettata. Il problema è tutto nella presentazione: ConcimiView è l'unica schermata dedicata al dominio "concimazione" a non usare mai il colore, l'icona o il font che l'app stessa ha già stabilito per quel dominio altrove. La più grande opportunità è semplice da cogliere: allineare questa vista ai pattern già maturi di `PiantaRiga.vue` (tessera icona olive, nome in Fraunces, bersaglio di eliminazione 44px) invece di lasciarla come CRUD grezzo.

## What's Working

1. **Gestione degli errori per-azione, non globale.** Salva, toggle e elimina hanno ciascuno il proprio messaggio in italiano e resettano il proprio stato di caricamento in `finally` — utile per l'uso mobile in giardino (connettività instabile), dove l'utente deve sapere *quale* azione specifica riprovare.
2. **Il pattern conferma-prima-di-eliminare è cablato correttamente**: `ModalConferma` riceve `:caricamento` e `:errore`, quindi un'eliminazione fallita mantiene il modale aperto con l'errore visibile invece di chiudersi prematuramente — stesso pattern corretto usato nel resto dell'app.
3. **Il motore di matching NPK è genuinamente ben progettato**: normalizzare i rapporti prima di calcolare la distanza euclidea tratta "10-10-10" e "20-20-20" come equivalenti, e la separazione tra `concimeConsigliato` (singolo migliore match, soglia 0.15) e `classificaConcimiPerFabbisogno` (classifica completa) è un'API pulita per due esigenze UI diverse. Il layer logico non è il problema — lo è la presentazione attorno ad esso.

## Priority Issues

**[P1] Il bersaglio di eliminazione riga è largo circa 28px, ben sotto il minimo di 44px che l'app stessa impone.**
- **Perché conta**: CLAUDE.md/DESIGN.md fissano 44px come altezza minima di tocco proprio perché l'app è pensata per l'uso "in giardino da mobile" — all'aperto, col telefono, plausibilmente con mani sporche o bagnate. Un bersaglio distruttivo da ~28px accanto a un interruttore alto 24px è il layout con il rischio di tocco-sbagliato più concreto del file.
- **Fix**: replicare il dimensionamento di `.pr__del` in `PiantaRiga.vue` (44×44px, icona/glifo centrato) al posto del glifo con solo `padding: 4px`.
- **Comando suggerito**: `/impeccable polish`

**[P1] Un concime salvato senza valori NPK mostra "0-0-0", che si legge come "non contiene nutrienti" invece di "NPK sconosciuto".**
- **Perché conta**: `form.value.n || 0` forza i campi NPK vuoti a `0`, e la riga mostra sempre `{{ npk.n }}-{{ npk.p }}-{{ npk.k }}` senza uno stato "non disponibile". Il placeholder della descrizione stessa invita esplicitamente a preparazioni casalinghe ("dosi, tempo di macerazione…") il cui NPK reale è quasi sempre ignoto — "0-0-0" è un dato fuorviante, non un "non disponibile" onesto, ed entra silenziosamente nel matching a distanza NPK verso le piante.
- **Fix**: rendere i tre campi opzionali con fallback visibile "N/D" in riga quando tutti e tre sono vuoti, oppure salvare `null` per nutriente e mostrare un trattino invece di "0".
- **Comando suggerito**: `/impeccable harden`

**[P2] Il nome del concime non usa Fraunces, in violazione della Regola del Nome in Fraunces del sistema di design.**
- **Perché conta**: è una regola esplicita e nominata del design system ("ogni volta che l'interfaccia mostra un nome... usa Fraunces, qualunque sia la dimensione"). `.feed__n` (`main.css:449`) è invece DM Sans a 13px — la violazione più concreta e verificabile di fedeltà al sistema in questo file, ed è anche il segnale più immediato di "lista generica" invece di "voce di taccuino".
- **Fix**: aggiungere `font-family: var(--font-display); font-weight: 600;` a `.feed__n` (o override locale come già fatto per `.feed--tap`/`.feed__del`). Nota: la stessa classe è riusata in `PianteView.vue` per "Concimi consigliati", quindi il fix in CSS condiviso risolve entrambi i punti insieme.
- **Comando suggerito**: `/impeccable typeset`

**[P2] La pagina non usa mai il colore olive (dominio concimazione) né l'icona `i-concimazione` già esistente e usata correttamente altrove.**
- **Perché conta**: CLAUDE.md nomina olive come colore di dominio della concimazione, e l'app dimostra già che il pattern funziona (`AttivitaRiga.vue`, icona + etichetta olive per gli eventi di concimazione). L'unica schermata interamente dedicata ai concimi è l'unico posto dove quel colore non compare mai — l'istanza più leggibile del problema "non autorato per questo prodotto", e un fix di poche righe.
- **Fix**: sostituire l'icona dell'empty state con `concimazione` (già olive), e dare a ogni riga una piccola tessera icona `--olive-tile` da 48px sul modello di `PiantaRiga.vue`, così la riga ottiene lo stesso ancoraggio visivo delle righe pianta.
- **Comando suggerito**: `/impeccable colorize`

**[P3] L'empty state omette il pulsante di call-to-action ripetuto che ogni altra vista a lista dell'app include.**
- **Perché conta**: `PianteView.vue` e `ZoneView.vue` ripetono entrambi la pillola "+ Aggiungi" nel corpo dell'empty state oltre che nell'header. L'empty state di ConcimiView ha solo icona e testo esplicativo, nessun pulsante — una regressione di scopribilità rispetto alla convenzione già stabilita dall'app stessa: un utente alla prima visita deve tornare con lo sguardo in alto invece di agire dove la sua attenzione già si trova.
- **Fix**: aggiungere una pillola "+ Aggiungi un concime" dentro il blocco `.empty`, sul modello esatto di `PianteView.vue`.
- **Comando suggerito**: `/impeccable onboard`

## Persona Red Flags

**Jordan (prima volta)**: nessuna legenda in pagina spiega cosa significhino "NPK" o i tre numeri (heuristics #2/#10 sopra) — chi arriva con una confezione di concime comprata al negozio deve indovinare se digitare i numeri in ordine N-P-K. L'unico testo di orientamento (empty state) è un messaggio usa-e-getta che sparisce per sempre al primo concime aggiunto e non ricompare mai più, nemmeno nel form.

**Casey (mobile, in giardino)**: il bersaglio di eliminazione ~28px (Priority Issue P1) accanto a un interruttore alto 24px, dentro una riga densa con `padding: 10px 2px`, è il layout col rischio di tocco-sbagliato più concreto del file per chi usa il telefono con una mano sola all'aperto. Inoltre nessuna vista specifica segnala se la cache offline (NetworkFirst su Supabase) sta servendo dati di dispensa non aggiornati.

**Sam (accessibilità)**: `.toggle-switch` è un `<button>` con solo `aria-label` — nessun `role="switch"`/`aria-checked` — quindi uno screen reader annuncia l'azione ("Segna come terminato") ma non lo stato corrente, diversamente dal comportamento standard atteso da un interruttore accessibile. Il tag "terminato" è inoltre a 9.5px fisso, senza alcun aggancio per lo scaling utente.

## Minor Observations

- `erroreDisponibile` è un banner nominalmente di pagina ma viene scritto anche dal fallimento del toggle per-riga; funziona solo perché un solo toggle può essere in corso alla volta, ma il nome della variabile promette uno stato più globale di quanto sia in realtà — rischio di race condition se in futuro si permettesse il toggle concorrente su più righe.
- `.toggle-switch` è definito una sola volta in tutto il codebase: se un'altra vista avrà bisogno di un interruttore binario, verrà probabilmente reinventato invece di riusato, non esistendo un `Toggle.vue` condiviso.
- `descrizioneBreve` tronca a un fisso di 150 caratteri indipendentemente dal viewport: su schermo stretto può comunque avvolgersi su 4-5 righe prima di raggiungere il limite.
- La pillola header "+ Aggiungi" usa `.pill` (min-height 36px), sotto il minimo di 44px del sistema — ma è un gap trasversale a `ProgettiView.vue`/`PianteView.vue`/`ZoneView.vue`, non specifico di questo file.
- I 4 riscontri del detector (`design-system-font-size`) sono tutti su glifi/testo di servizio (errore inline, "×", spinner), non su testo di contenuto — impatto visivo reale probabilmente basso, ma vale la pena chiudere insieme a un'eventuale revisione della scala tipografica di DESIGN.md stesso (vedi nota sulla discrepanza sopra).

## Questions to Consider

- Se lo scopo dichiarato di questa schermata (dal suo stesso empty state) è alimentare il suggerimento di abbinamento pianta-concime, perché la schermata non dà mai, mentre si gestiscono questi dati, visibilità su quella funzione — un'anteprima live "abbinerebbe a: [piante]" mentre si compila l'NPK?
- Il form tratta un concime sintetico comprato e un macerato fatto in casa (esplicitamente invitato dal placeholder) in modo identico: stessi tre numeri, stessa textarea. Uno schema unico serve davvero bene entrambi i casi, o il caso "fatto in casa" meriterebbe campi propri (es. "pronto il...") che farebbero sentire la schermata più *di questo* taccuino da giardino?
- `ToastCura.vue` esiste già per il momento emotivamente affine "cura registrata": la sua assenza qui (chiusura silenziosa del foglio al salvataggio) è una scelta deliberata per restare a basso attrito, o solo un'eredità da quando questa vista è stata costruita come CRUD nudo prima che il pattern toast esistesse?
