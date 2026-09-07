---
target: ConcimiView
total_score: 34
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 1
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/ConcimiView.vue"
target_fingerprint: "sha256:d4c3a3d20b08b5ef0a5e79009e767aa36e04afba773d696a835b62a1ec6c4bf7"
target_path: /Users/rob/Sites/localhost/giardino/src/views/ConcimiView.vue
timestamp: 2026-09-07T21-26-03Z
slug: src-views-concimiview-vue
---
Method: dual-agent (A: design-review subagent · B: detector-evidence subagent)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 4 | Spinner per-riga, Salva disabilitato durante il salvataggio, errori scoped per id. |
| 2 | Match System / Real World | 3 | Linguaggio di dominio corretto, ma "Adatto per" oggi significa qualcosa di più stretto ("il singolo migliore, sotto soglia rigida") di quanto un utente dedurrebbe da una lista semplice. |
| 3 | User Control and Freedom | 4 | Foglio richiudibile in più modi, ModalConferma con Annulla e retry inline. |
| 4 | Consistency and Standards | 2 | Coerente internamente, ma il segnale *tra schermate* no: la stessa funzione di matching NPK è calcolata da due funzioni diverse con regole di inclusione diverse in `PiantaView.vue` vs `ConcimiView.vue` — una pianta può comparire come candidata top-3 nella propria pagina e non comparire mai in "Adatto per" per lo stesso concime qui. |
| 5 | Error Prevention | 4 | `npkONull` blocca NPK negativi/non numerici prima di Supabase; eliminazione dietro conferma. |
| 6 | Recognition Rather Than Recall | 4 | NPK, descrizione e abbinamento tutti visibili in riga, senza dover incrociare un'altra schermata. |
| 7 | Flexibility and Efficiency | 3 | Ricerca, toggle a un tocco, tap sulla riga per modificare. |
| 8 | Aesthetic and Minimalist Design | 3 | Visivamente sobrio, ma molti `style=""` inline sparsi nel template accanto al blocco `&lt;style scoped&gt;` — non rumore per l'utente, ma un rischio di manutenzione. |
| 9 | Error Recovery | 4 | Errori scoped all'azione fallita, in italiano semplice, mai un vicolo cieco. |
| 10 | Help and Documentation | 3 | Buona base di accessibilità (aria-label, gestori da tastiera), ma la riga `role="button"` contiene due `&lt;button&gt;` reali — lo stesso tipo di problema che l'app ha già risolto nella direzione opposta in `PiantaRiga.vue`. |
| **Total** | | **34/40** | **Buono** |

## Design Specificity Verdict

**LLM:** Specifico, non da SaaS generico — il file è denso di commenti di razionale datati "07/09/2026" che documentano un'iterazione già risolta in questo stesso file (N/D vs zero, 44px, troncamento, esclusione "terminato", clamp NPK). Un team che itera contro il proprio design system, non un template. L'unico vero divario è una **decisione di logica/prodotto, non visiva** — vedi Priority Issue #1.

**Scansione deterministica:** stessi 5 riscontri advisory. Confermato: 2 dei 5 sono riuso esplicitamente citato di pattern già stabiliti (`PianteView.vue`/`PiantaRiga.vue`), 1 cita lo stesso pattern ma con un valore leggermente diverso (20px vs 18px), 2 non hanno un precedente citato o trovato.

**Verifica puntuale (la tua segnalazione)**: tracciato riga per riga in `useConcimi.js`, `PiantaView.vue`, `ConcimiView.vue`. Tabella dei fatti:

| Vista | Funzione usata | Soglia 0.15 applicata? | Concimi accreditati per pianta |
|---|---|---|---|
| `PiantaView.vue` (`classificaConcimiPianta`) | `classificaConcimiPerFabbisogno` | No — la funzione non controlla mai la distanza | Fino a 3 (`.slice(0,3)` fisso), indipendentemente dalla qualità del match |
| `ConcimiView.vue` (`pianteAbbinatePerConcime`) | `concimeConsigliato` | Sì, dentro la funzione chiamata | Esattamente 1 (il singolo migliore, o nessuno se supera 0.15) |

**Overlay visivi:** ancora non disponibili.

## Overall Impression

Il punteggio sale da 26 a 34/40 — i fix di icona e ordine pulsanti dei giri precedenti hanno funzionato bene. La tua diagnosi è corretta sul concetto (un concime utile-ma-non-il-migliore dovrebbe poter essere accreditato), ma il fix "a parità" che proponi (stesso criterio di PiantaView, top-3 senza soglia) importerebbe il difetto di PiantaView stessa: con una dispensa di 1-3 concimi, "i primi 3" degenera in "tutta la dispensa", e "Adatto per" finirebbe per accreditare un concime a una pianta che abbina solo vagamente.

## What's Working

1. **Disambiguazione N/D vs zero reale** in `formattaNPK` — un dettaglio di correttezza facile da non notare, genuinamente ben fatto.
2. **Errori scoped alla riga/campo esatto che fallisce**, mai un toast generico o un vicolo cieco.
3. **Empty state e stato "nessun risultato" correttamente differenziati**, coerenti col pattern già usato in `PianteView.vue`.

## Priority Issues

**[P1 — la tua segnalazione, confermata ma con una correzione] Il disallineamento di criterio è reale; consigliata l'opzione "soglia senza tetto fisso", non la parità pura con PiantaView.**
- **Perché conta**: la tua diagnosi sul concetto è corretta — ma passare a "primi 3 come PiantaView, senza soglia" importerebbe il difetto di PiantaView: con una dispensa piccola (1-3 concimi, lo scenario tipico di questa app), il top-3 è l'intera dispensa, e "Adatto per" accrediterebbe anche un concime che abbina male.
- **Fix consigliato**: esportare `SOGLIA_DISTANZA` da `useConcimi.js` (oggi privata al modulo); in `pianteAbbinatePerConcime` sostituire la chiamata a `concimeConsigliato` (singolo vincitore) con `classificaConcimiPerFabbisogno(...).filter(c => c.distanza <= SOGLIA_DISTANZA)`, accreditando OGNI concime nella lista filtrata alla pianta, non solo il primo. Nessun tetto fisso a 3 sopra la soglia: è la soglia stessa a limitare la lista, un tetto aggiuntivo non risolverebbe nulla e nasconderebbe la vera portata di un concime davvero versatile. Segnalo ma non correggo qui: anche `PiantaView.vue` ha lo stesso difetto latente (nessuna soglia sul suo top-3) — da valutare a parte.
- **Estensione consigliata**: una volta che un concime può essere accreditato a rango 2 o 3 e non solo al primo posto, distinguere visivamente i due casi (come già fa `PiantaView.vue` con `.feed__rank`/`.feed__rank--dim`, sage pieno per il rango 1, tenue per gli altri): nel Foglio, due gruppi etichettati — "Scelta migliore per" (badge pieni, solo rango 0) e "Adatto anche per" (badge tenui/outline, ranghi successivi). La riga in lista può restare un'unica stringa troncata, non serve la stessa granularità lì.
- **Comando suggerito**: `/impeccable clarify`

**[P2] Controlli interattivi annidati dentro una riga `role="button"`.**
- **Perché conta**: la riga (`role="button" tabindex="0"`) contiene due `&lt;button&gt;` reali (toggle, elimina) — la stessa famiglia di problema che l'app ha già risolto nella direzione opposta in `PiantaRiga.vue` (bottone spostato fuori dal `&lt;RouterLink&gt;` perché un bottone dentro un link è HTML5 non valido e causava comportamento incoerente da tastiera/screen reader). `@click.stop` previene solo il doppio-fire visivo, non la semantica.
- **Fix**: stesso trattamento già applicato in `PiantaRiga.vue` — verificare il comportamento reale con screen reader e, se necessario, ristrutturare.
- **Comando suggerito**: `/impeccable audit`

**[P2] La logica di matching resta invisibile all'utente anche dopo il fix del criterio.**
- **Perché conta**: né la riga né il Foglio comunicano alcun segnale di qualità (nessun rango, nessuna distanza) — un utente curioso non ha modo di scoprire che la funzione ha criteri. Il raggruppamento a due livelli proposto nel fix P1 è anche la soluzione a questo problema: i due fix vanno spediti insieme.
- **Comando suggerito**: `/impeccable clarify`

**[P3] Molti `style=""` inline nel template accanto al blocco `&lt;style scoped&gt;`.**
- **Perché conta**: non è rumore visivo per l'utente, ma rende più facile perdere metà del file in una futura revisione della scala di spaziatura.
- **Comando suggerito**: `/impeccable extract`

## Persona Red Flags

**Sam (accessibilità)**: la riga `role="button"` con bottoni reali annidati (Priority 2) è esattamente il tipo di pattern che sembra a posto visivamente ma può produrre un ordine di focus confuso o un rischio di doppia attivazione sotto VoiceOver/TalkBack — non testato qui, ma segnalato come rischio reale dato che il team ha già risolto il bug gemello in `PiantaRiga.vue`.

**Riley (prima volta, poca conoscenza di dominio)**: non avrebbe modo di scoprire che "Adatto per" ha dei criteri — fino al fix P1, potrebbe ragionevolmente chiedersi "perché il mio compost non compare come adatto ai pomodori se l'ho visto candidato nella pagina del pomodoro?" senza modo di risolvere la confusione nell'app.

**Alex (power user, dispensa più grande)**: riceve oggi meno informazione su questa schermata che su PiantaView per quella che concettualmente è la stessa funzione — nessun rango, nessuna distanza, solo un nome — nonostante ConcimiView sia il posto più naturale per verificare "a cosa serve davvero ogni concime".

## Minor Observations

- `.concime-match-chip` è sempre Fraunces in grassetto indipendentemente dal rango — corretto oggi (solo il vincitore singolo), ma andrà differenziato una volta spedito il fix a due livelli.
- L'esclusione dei concimi "terminato" dal matching (già corretta nei giri precedenti) si riporterebbe pulita anche nel fix consigliato qui.
- `pianteAbbinatePerConcime` ricalcola su tutte le piante a ogni render — accettabile alla scala attuale di questa app, non da ottimizzare preventivamente.

## Questions to Consider

- Se un concime è al secondo posto per dieci piante diverse, è concettualmente diverso dall'essere primo per una pianta sola e assente per le altre nove — "Adatto per" dovrebbe mai comunicare *quanto bene* si abbina, o basta la presenza/assenza una volta fissata la soglia?
- Una volta che la soglia limita correttamente i falsi positivi, "a cosa serve questo concime" è davvero la domanda più utile che questa schermata può rispondere — o sarebbe più utile "quali delle mie piante non hanno oggi nessun concime sotto soglia" (una vista lacune/lista della spesa) per chi deve decidere cosa comprare o macerare?
- `PiantaView.vue` ha già risolto "mostra il rango visivamente, non solo i nomi" con il suo numero di rango attenuato — costruire ConcimiView senza lo stesso trattamento è stata una semplificazione deliberata, o solo il caso di due schermate costruite in momenti diversi senza incrociarle?
