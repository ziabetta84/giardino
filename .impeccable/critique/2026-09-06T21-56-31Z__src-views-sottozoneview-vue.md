---
target: SottozoneView
total_score: 22
max_score: 36
na_heuristics: 10
p0_count: 1
p1_count: 1
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/SottozoneView.vue"
target_fingerprint: "sha256:47e02ed1ddbbfe2ee4e741db9709d12274070e6608dfb0ee3b974fe30dc86872"
target_path: /Users/rob/Sites/localhost/giardino/src/views/SottozoneView.vue
timestamp: 2026-09-06T21-56-31Z
slug: src-views-sottozoneview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | Nessuno skeleton di caricamento: una zona con sottozone può mostrare "Nessuna sottozona" prima che i dati arrivino |
| 2 | Match System / Real World | 3 | Il testo di eliminazione riflette accuratamente il comportamento reale (SET NULL, non cascade) |
| 3 | User Control and Freedom | 2 | Un'eliminazione fallita azzera `daEliminare`, costringendo l'utente a ritrovare la riga e ripartire da capo |
| 4 | Consistency and Standards | 2 | Regressione visibile rispetto alla vista gemella ZoneView su 4 dimensioni (vedi confronto sotto) |
| 5 | Error Prevention | 3 | Guard nome duplicato prima del salvataggio |
| 6 | Recognition Rather Than Recall | 2 | 45 icone senza etichette, senza raggruppamento, senza ricerca, celle ~30px |
| 7 | Flexibility and Efficiency | 3 | Adeguata per l'ambito, nessun attrito degno di nota oltre quanto già segnalato |
| 8 | Aesthetic and Minimalist Design | 3 | Layout a lista hairline appropriatamente essenziale, indebolito solo dai gap di identità visiva |
| 9 | Error Recovery | 2 | `e.message` grezzo mostrato sull'errore, scollegato dall'azione che l'ha causato |
| 10 | Help and Documentation | n/a | Nessun aiuto in-app esiste da nessuna parte nell'app — non un gap specifico di questa vista |
| **Total** | | **22/36** | **Acceptable** |

## Design Specificity Verdict

**LLM assessment**: SottozoneView è radicata nel modello dati reale dell'app (gerarchia zona→sottozona, semantica di eliminazione basata su FK spiegata correttamente nel testo) e riusa componenti reali del sistema taccuino (righe hairline `.dest`, `FoglioLaterale`, icone ad acquerello via `iconaSottozona`). Ma a livello di superficie si legge oggi più come una schermata CRUD generica di quanto non faccia ZoneView: i nomi sottozona sono in DM Sans invece di Fraunces, il selettore icone è una griglia nuda di 45 celle senza etichette indistinguibile da uno swatch-picker da pannello admin generico, e gli errori di eliminazione appaiono come un banner condizionale invece del pattern ancorato al modale del taccuino. Un'app CRUD qualunque potrebbe spedire esattamente questo markup di griglia icone e questo banner di errore senza modifiche; la lista di righe e il testo sono le parti che restano riconoscibili come questo prodotto.

**Deterministic scan**: `impeccable detect --json` → exit 0, **2 findings advisory** — `font-size: 12px` fuori scala (riga 10, il banner di errore in cima pagina) e `border-radius: 10px` fuori scala (riga 53, il contenitore del selettore icone). Sono esattamente gli stessi due finding che ZoneView aveva prima del primo giro di fix, a conferma diretta di quanto osservato dalla review qualitativa: SottozoneView è rimasta sul pattern precedente, il fix non è stato portato qui.

**Visual overlays**: non disponibili in questa sessione — nessuno strumento di automazione browser esposto.

## ZoneView Parity Check

Confronto punto per punto con i 4 fix già applicati a ZoneView nei due giri precedenti:

1. **Nomi in Fraunces** — **MANCANTE**. ZoneView.vue:27 usa `<span class="dest__n zname">` con `.zname{font-family:var(--font-display)}` (ZoneView.vue:114). SottozoneView.vue:22 ha `<span class="dest__n">{{ sz.nome }}</span>` semplice, nessuna classe equivalente in tutto il blocco di stile scoped (righe 256-269). I nomi restano in DM Sans a 13.5px (`.dest__n` globale, main.css:424).

2. **Etichette/raggruppamento selettore icone** — **MANCANTE, non ereditato**. SottozoneView.vue:94 importa ancora `ICONE_ZONA` piatto, non `ICONE_ZONA_GRUPPI` (che esiste già, useIconeZona.js:10-18). La griglia (righe 52-59) non ha campo di ricerca, etichette di categoria, né `:aria-label`/`:aria-pressed`/`:title` sui pulsanti, e usa `minmax(30px,1fr)` con `gap:0` invece del `minmax(44px,1fr)` di ZoneView. Combinato con `.pill-icona{padding:0;min-height:0}` globale (main.css:249-250), la cella effettivamente toccabile qui resta ~30px, sotto la regola dei 44px che il fix di ZoneView aveva stabilito.

3. **Wiring `:errore` su ModalConferma** — **MANCANTE**. SottozoneView.vue:78-85 passa solo `:aperto`, `titolo`, `messaggio`, `:caricamento` — nessun `:errore`. Al fallimento, `eliminaSottozona()` (righe 247-249) azzera anche `daEliminare.value` nello stesso blocco catch, quindi il modale si chiude e l'errore riappare solo come il paragrafo scollegato in cima pagina (righe 10-12) — esattamente il pattern pre-fix che ZoneView ha sostituito.

4. **Target di tocco/overflow/rendering descrizioni** — **PARZIALMENTE ereditato**:
   - `.pill-mini` min-height 44px: **ereditato gratis** (regola globale, main.css:452), si applica automaticamente ai pulsanti modifica/elimina (righe 26-29).
   - tipo/esposizione mostrati in riga: **già presenti** (righe 23, 32) — non un fix da portare.
   - CTA nello stato vuoto: **mancante** (righe 14-17, solo icona+testo, a differenza di ZoneView.vue:20).
   - Overflow nomi lunghi: **mancante**, nessuna regola `min-width:0`/`text-overflow` per `.dest__n` in questo file.
   - Rendering v-html delle descrizioni formattate: **mancante e con un bug attivo**. `descrizioneSottozona()` (righe 130-132) fa ancora `.replace(/<[^>]*>/g,'').trim()`, lo stesso approccio pre-fix di ZoneView — con l'aggravante che senza separatore tra paragrafi, una descrizione multi-paragrafo concatena in un'unica parola (es. "Ombra"+"fresca" → "Ombrafresca").

## Overall Impression

SottozoneView conferma esattamente quanto sospettato: condivide il pattern di ZoneView, ma non ha ricevuto nessuno dei due giri di fix. Ha ereditato "gratis" solo ciò che viveva in file condivisi (target di tocco di `.pill-mini` da main.css), mentre tutto ciò che viveva nel file della vista stessa — Fraunces, selettore icone, wiring dell'errore, rendering v-html — è rimasto sulla versione precedente. Il problema più serio non è nemmeno un problema di design puro ma un bug di visualizzazione reale: la rimozione dell'HTML senza separatore concatena i paragrafi in un'unica parola.

## What's Working

- Testo di eliminazione accurato e rassicurante che riflette la semantica reale del backend (SET NULL, non cascade) invece di un avviso generico allarmante — SottozoneView.vue:81.
- Gestione attenta di rinomina/collisione che rispecchia il pattern di ZoneView, inclusa la riconciliazione dei dati denormalizzati — SottozoneView.vue:155-219.
- `aria-label`/`title` già presenti sui pulsanti icona modifica/elimina di riga — SottozoneView.vue:26-29 — un'igiene di accessibilità che non è regredita.

## Priority Issues

**[P0] L'errore di eliminazione chiude il modale invece di restare inline**
- **Perché è importante**: il ciclo di feedback su un'azione distruttiva è rotto — l'utente vede il modale sparire senza motivo visibile, deve scorrere per capire perché, esattamente l'anti-pattern già identificato e corretto due volte su ZoneView.
- **Fix**: passare `:errore="erroreEliminazione"` a `ModalConferma` e non azzerare più `daEliminare` nel ramo catch, mirroring ZoneView.vue:97-105/300-336.
- **Dove**: SottozoneView.vue:10-12, 78-85, 247-249.
- **Comando suggerito**: `/impeccable clarify`

**[P1] Selettore icone sulla vecchia griglia piatta, senza etichette, celle ~30px**
- **Perché è importante**: viola la regola dei 44px di target di tocco, fallisce nome/ruolo/valore WCAG per ogni pulsante icona (nessun aria-label/pressed), forza il recall su 45 opzioni indifferenziate.
- **Fix**: sostituire `ICONE_ZONA` con `ICONE_ZONA_GRUPPI`, aggiungere ricerca ed etichette di categoria, portare la griglia a `minmax(44px,1fr)`, aggiungere `:aria-label`/`:aria-pressed`/`:title` — copiare il pattern da ZoneView.vue:63-78/129/160-166.
- **Dove**: SottozoneView.vue:52-59, 94.
- **Comando suggerito**: `/impeccable audit`

**[P2] `descrizioneSottozona()` concatena i paragrafi senza separatore — bug di visualizzazione reale**
- **Perché è importante**: non è solo formattazione persa — una descrizione multi-paragrafo diventa un'unica parola illeggibile (es. "Ombrafresca"), e scarta grassetto/corsivo che MiniEditor sanifica apposta per essere v-html-sicuro.
- **Fix**: rendering `v-html` sanificato con CSS a paragrafo inline, come già fa ZoneView.
- **Dove**: SottozoneView.vue:130-132; riferimento ZoneView.vue:34, 291-293, 124-125.
- **Comando suggerito**: `/impeccable clarify`

**[P2] Nomi sottozona in DM Sans, non Fraunces**
- **Perché è importante**: viola l'unica regola tipografica semantica esplicita di DESIGN.md, proprio sulla schermata il cui unico compito è nominare/organizzare sotto-aree.
- **Fix**: aggiungere una classe `zname` (o equivalente) allo span del nome e una regola scoped `font-family:var(--font-display)` corrispondente.
- **Dove**: SottozoneView.vue:22 (classe mancante); confronto ZoneView.vue:27/114.
- **Comando suggerito**: `/impeccable typeset`

**[P3] Nessuno skeleton di caricamento, nessuna CTA nello stato vuoto, nessuna gestione overflow nomi lunghi**
- **Perché è importante**: su un caricamento lento/offline una zona con sottozone reali può mostrare "Nessuna sottozona" prima che i dati arrivino (falso negativo, peggio sulla connessione mobile/da campo per cui l'app è pensata); i primi utenti trovano uno stato vuoto più spoglio di ogni vista gemella; un nome lungo non ha alcuna rete di sicurezza ellissi/min-width.
- **Fix**: aggiungere lo stesso ramo skeleton di `store.loading` di ZoneView.vue:8-15, aggiungere un pulsante "+Aggiungi una sottozona" allo stato vuoto, aggiungere ellissi/min-width a `.dest__n` nello scope di questo file.
- **Dove**: SottozoneView.vue:14-17, 256-269 (ramo skeleton assente del tutto).
- **Comando suggerito**: `/impeccable onboard`

## Cognitive Load

Fallisce sul punto di decisione del selettore icone (45 opzioni, nessun chunking, nessun raggruppamento) e sul focus durante il recupero errore (banner in cima pagina mentre l'attenzione è sul modale/riga). Il nome non distinto come testo identitario (niente Fraunces) lo fa competere visivamente con i metadati. Il resto del flusso (sheet/modale esclusivi, divulgazione progressiva del form) porta un carico basso.

## Emotional Journey

I due momenti emotivamente carichi — eliminare una sottozona e trovarne una vuota — sono gestiti con buon istinto nel testo (spiegazione accurata e rassicurante delle conseguenze dell'eliminazione, stato vuoto calmo e non allarmante) ma con esecuzione debole: un'eliminazione fallita chiude silenziosamente il modale di conferma e sposta l'errore in un banner da cui l'utente potrebbe essersi già allontanato scorrendo, trasformando un'azione che dovrebbe sentirsi sicura e reversibile in un piccolo momento di "ha funzionato?" — l'opposto della chiusura calma e affidabile che un momento distruttivo-adiacente richiederebbe. Lo stato vuoto in sé è gradevole ma leggermente anticlimatico rispetto ai suoi simili (nessuna CTA), un piccolo battito mancato più che una vera valle.

## Persona Red Flags

**Riley** (usa l'app all'aperto, da telefono, spesso con una mano, a volte con connessione da giardino instabile): colpito duramente dalle celle icona ~30px — davvero difficili da toccare con precisione con dita bagnate/sporche all'aperto; potrebbe anche vedere il falso "Nessuna sottozona" lampeggiare su una connessione lenta e pensare che i propri dati siano spariti.

**Jordan** (dipende da screen reader/tecnologie assistive, o ha vincoli motori/visivi): i pulsanti del selettore icone non hanno `aria-label`/`aria-pressed`, quindi uno screen reader non annuncia nulla di significativo per 45 controlli; il banner di errore eliminazione non è associato al modale né annunciato vicino all'azione che l'ha innescato.

**Alex** (un familiare nuovo all'app, alle prime armi con il proprio giardino sul proprio account): atterra su uno schermo sottozone vuoto senza CTA inline (solo il pill in intestazione, meno scopribile a colpo d'occhio), e una volta aggiunte le sottozone ne vede i nomi nello stesso font del chrome UI ordinario intorno — il piccolo segnale "quest'app è stata fatta per me e il mio giardino" che Fraunces dovrebbe dare sulle cose nominate manca esattamente qui.

## Minor Observations

- Le etichette checkbox di esposizione (`nord`, `sud`, `est`, `ovest`) sono stringhe minuscole senza `text-transform`, a differenza del trattamento capitalize dato a `tipo` altrove (SottozoneView.vue:62-66).
- `e.message` grezzo di Supabase mostrato testualmente sull'errore di salvataggio/eliminazione (righe 215, 248) con solo un fallback generico in italiano — un errore Postgres/PostgREST potrebbe far trapelare testo inglese non tradotto in un'interfaccia solo italiana.
- Il `gap:0` della griglia icone (riga 53) fa toccare le celle da 30px bordo a bordo, aggravando il problema di target di tocco oltre alla sola dimensione.
- `contaPiante` (righe 124-128) fa una scansione completa di `Object.values(store.piante)` per riga a ogni render — accettabile alla scala attuale, ma senza memoizzazione.

## Questions to Consider

- Dato che ZoneView ha richiesto due giri separati di critica e fix per arrivare al suo stato attuale, SottozoneView è stata lasciata deliberatamente sul vecchio pattern, o il fix semplicemente non è mai stato portato qui — e in questo secondo caso, quale processo eviterebbe che schermate gemelle si disallineino di nuovo così (un sotto-componente condiviso per selettore icone/modale errore invece di markup copiato)?
- Se l'eliminazione di una sottozona è "sicura" (le piante perdono solo l'assegnazione di sottozona, nessuna perdita di dati), il modale di conferma dovrebbe usare lo stesso trattamento rosa/distruttivo e la stessa intensità di "Elimina" dell'eliminazione di una zona (che può bloccarsi su FK), o trattarle allo stesso modo sovrastima la posta in gioco dell'azione a rischio più basso?
- Un set piatto di 45 icone è davvero il pattern giusto alla granularità di sottozona (qualcuno potrebbe avere 5-10 sottozone per zona e volere un'assegnazione icona rapida e memorabile) — un set curato più piccolo per `tipo` (esterno/interno) ridurrebbe il selettore a una scelta genuinamente a basso carico cognitivo invece di aver bisogno di ricerca/raggruppamento per aggirare la propria dimensione?
