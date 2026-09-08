---
target: ProgettoView.vue
total_score: 23
max_score: 40
na_heuristics: 
p0_count: 1
p1_count: 3
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/ProgettoView.vue"
target_fingerprint: "sha256:47e573c98f054727346051069e98342c5f05b3d891c5731f14083d7a4ead5596"
target_path: /Users/rob/Sites/localhost/giardino/src/views/ProgettoView.vue
timestamp: 2026-09-08T16-18-11Z
slug: src-views-progettoview-vue
---
## Design Health Score — ProgettoView.vue

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2/4 | eliminaProgetto() senza catch, ModalConferma senza prop :errore |
| 2 | Match System/Real World | 4/4 | Scadenza (dall'ultima tappa) spiega la derivazione |
| 3 | User Control and Freedom | 2/4 | Nessun Annulla sui campi header, pannelli modifica/inserisci apribili insieme |
| 4 | Consistency and Standards | 1/4 | Bottone Fatto reimplementa l'anti-pattern .care-act, bandiera/pnode ignorano la regola urgenza-colore |
| 5 | Error Prevention | 2/4 | Eliminazione progetto con ModalConferma, tappa singola senza alcuna conferma |
| 6 | Recognition Rather Than Recall | 3/4 | Esito autoesplicativo, zona testo libero |
| 7 | Flexibility and Efficiency | 2/4 | Nessun percorso da tastiera per aprire una tappa |
| 8 | Aesthetic and Minimalist Design | 3/4 | Pulito, ma forte dipendenza da stili inline |
| 9 | Error Recovery | 1/4 | Errore Postgres grezzo mostrato verbatim, eliminazione fallita senza traccia |
| 10 | Help and Documentation | 3/4 | Scadenza spiegata, nessuna distinzione Fallito/Saltato |
| **Totale** | | **23/40** | **Accettabile, al limite basso** |

## Verdetto di specificita'
LLM: composto per il prodotto (intestazione a filetti, Fraunces sul titolo, timeline a china) ma consegna solo meta' della regola Goccia d'inchiostro (il pallino non rifa' il bloom al cambio esito); reintroduce nel proprio template il bug rosa-sempre appena corretto nella lista sorella; il bottone Fatto reimplementa l'anti-pattern che .care-act esiste apposta per evitare.
Detector: pulito a livello bloccante, 5 advisory (radius 16px skeleton riga 8, font-size 20px x2 input titolo righe 68/111, font-size 12px x2 riga meta/errore righe 96/125). Nessuna eccezione preesistente li copre.

## Impressione generale
Mappatura colore-esito quasi perfetta ma il momento che conta di piu' (completare l'ultima tappa) e' meccanicamente indistinguibile da un refuso corretto, e il compito centrale della vista (aprire una tappa) e' irraggiungibile da tastiera.

## Cosa funziona
1. Mappatura esito-colore esattamente corretta (oro/salvia/rosa/neutro).
2. Spiegazione della scadenza piu' trasparente della lista.
3. Crossfade del gradiente del trail, tocco autoriale genuino.

## Problemi prioritari

[P0] Modifica tappa irraggiungibile da tastiera - <p style="cursor:pointer" @click> senza role/tabindex/keydown, unico modo di aprire una tappa. Fix: bottone reale o role=button+tabindex+keydown. Comando: /impeccable harden

[P1] Eliminazione progetto puo' fallire in silenzio - eliminaProgetto() senza catch, ModalConferma senza prop :errore, a differenza di PianteView. Fix: try/catch + ref errore passato a ModalConferma. Comando: /impeccable harden

[P1] Conferma eliminazione non dice cosa si perde - messaggio generico invece di nominare le tappe registrate, a differenza di PianteView (foto) e ZoneView (sottozone). Fix: messaggio con conteggio tappe interpolato. Comando: /impeccable clarify

[P1] Goccia d'inchiostro non si ripete al cambio esito - .in scatta solo da updateTrail(), mai al cambio di t.esito dalla select; solo il gradiente del trail sfuma davvero. Fix: forzare .in a spegnersi/riaccendersi al cambio esito. Comando: /impeccable animate

[P2] Bottone Fatto reimplementa l'anti-pattern .care-act vietato esplicitamente da DESIGN.md - class="btn btn-sage" con stile inline invece della pillola canonica. Fix: sostituire con .care-act/.care-act--rose. Comando: /impeccable clarify

## Red flag per persona
Sam: non puo' aprire una tappa (P0); select stato e input titolo senza label/aria-label; bottone + senza aria-label mentre il bottone x adiacente ce l'ha; errore di salvataggio senza role=alert.
Riley: eliminazione progetto fallisce in silenzio; pannelli modifica/inserisci tappa apribili insieme; elimina tappa da link di testo senza conferma poi salva, tappa persa per sempre senza avviso.
Casey: bottone Elimina progetto probabilmente senza bordo visibile (border-color senza border-style su base .btn con border:none); icona bandiera sempre rosa rende impossibile distinguere scadenza tranquilla da scaduta.

## Osservazioni minori
- Icona bandiera e .pgoal .pnode rosa fisso, riproduce il bug appena corretto nella lista sorella.
- .step__date in Fraunces nonostante la Regola del Nome escluda i numeri.
- Zona testo libero non collegato al catalogo (causa condivisa con ProgettiView).
- Campi zona/descrizione con field-label senza for/id.
- Forte dipendenza da stili inline in tutto il file.

## Domande provocatorie
- Completare l'ultima tappa potrebbe innescare un momento di chiusura dedicato invece di passare dallo stesso Salva modifiche di un refuso?
- L'eliminazione di una tappa potrebbe passare dallo stesso ModalConferma del progetto quando il suo esito non e' piu' atteso?
