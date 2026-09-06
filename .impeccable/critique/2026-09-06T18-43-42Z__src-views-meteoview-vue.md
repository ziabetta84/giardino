---
target: Meteo (src/views/MeteoView.vue)
total_score: 23
max_score: 28
na_heuristics: 5,7,10
p0_count: 0
p1_count: 0
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/MeteoView.vue"
target_fingerprint: "sha256:adff6451cf2bdf4de8479cdd19c4c8aa5c33fbbd639708bc0057152db308163c"
target_path: /Users/rob/Sites/localhost/giardino/src/views/MeteoView.vue
timestamp: 2026-09-06T18-43-42Z
slug: src-views-meteoview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Euristica | Punteggio | Nodo specifico |
|---|-----------|-------|-----------------|
| 1 | Visibilità dello stato del sistema | 3 | Skeleton, `.hour.now`+sr-only; manca un "aggiornato alle" e un feedback esplicito al click di Riprova oltre al passaggio allo skeleton |
| 2 | Corrispondenza sistema/mondo reale | 4 | Italiano idiomatico e caldo ovunque |
| 3 | Controllo e libertà dell'utente | 4 | Foglio si apre/chiude liberamente, Riprova non distruttivo |
| 4 | Coerenza e standard | 3 | `.adesso__flag` riusa gli stessi valori CSS di `.day__flag` ma in un contenitore geometricamente diverso (flex a larghezza di contenuto vs. grid a piena larghezza): stesso codice, esito visivo incoerente |
| 5 | Prevenzione degli errori | n/a | Vista di sola lettura |
| 6 | Riconoscimento anziché ricordo | 3 | Lista giorni sempre con descrizione testuale visibile; nastro orario solo icona+temperatura per utenti vedenti (descrizione solo sr-only) |
| 7 | Flessibilità ed efficienza d'uso | n/a | Vista di sola consultazione |
| 8 | Estetica e design minimalista | 3 | Composizione pulita; il nuovo pallino rischia di leggersi come segno isolato nello spazio vuoto invece che come dettaglio intenzionale, specie su desktop |
| 9 | Aiutare a riconoscere/recuperare errori | 3 | Ora c'è un bottone Riprova con messaggio semplice; diagnosi volutamente generica (scelta esplicita, non un difetto) |
| 10 | Aiuto e documentazione | n/a | Non necessaria per una vista di sola consultazione |
| **Totale** | | **23/28 (82%)** | **Buono** (in miglioramento da 21/28, 75%) |

## Design Specificity Verdict

Solido: copy colloquiale in tono "taccuino", codifica colore per dominio rispettata, e soprattutto la nota "Irrigazione delle piante esterne sospesa" collega esplicitamente il meteo alla logica di cura reale — esattamente il posizionamento dichiarato in PRODUCT.md. Verifica tecnica completa: nessuna seconda mappa WMO disallineata altrove nel codebase, nessun dato stantio possibile durante l'errore (i tre stati sono strutturalmente mutuamente esclusivi), bottone Riprova correttamente cablato (`carica()` resetta `errore`/`loading` alle proprie prime righe).

## Overall Impression

Due dei tre fix sono pienamente riusciti (Riprova, `WMO_LABEL`); il terzo (`.adesso__flag`) risolve il problema originale (nessun indicatore su "Adesso") ma introduce un problema più piccolo: il pallino riusa gli stessi valori CSS di `.day__flag`, ma `.adesso` è un contenitore flex a larghezza di contenuto senza superficie da card (niente sfondo/bordo), mentre `.day` è una riga grid a piena larghezza che riempie davvero lo spazio — la stessa regola copiata produce un esito visivo diverso perché il contenitore di riferimento è geometricamente diverso. Su desktop (`.app-main` fino a 920px) questo può isolare il pallino a centinaia di pixel dal contenuto a cui si riferisce. Verifica tecnica conferma la meccanica (il pallino non si sovrappone all'icona, è geometricamente nell'angolo in alto a destra del contenitore) ma non giudica se quel posizionamento comunichi bene l'informazione — quello è il giudizio qualitativo aggiunto in questo giro.

Emerge anche una race condition reale ma di basso impatto: `carica()` non ha guardia contro invocazioni concorrenti, e un doppio click rapido su "Riprova" può far vincere l'ordine di completamento della rete invece dell'ordine dei click — mitigato oggi dal fatto che il bottone stesso sparisce dal DOM non appena riparte il caricamento, ma un difetto strutturale se la funzione venisse richiamata da un secondo punto in futuro (es. refresh automatico).

## What's Working

- Integrazione meteo↔cura reale: la nota "Irrigazione... sospesa" con la soglia condivisa di `useCure.js` è un'integrazione di prodotto genuina, non decorativa.
- Recupero errore ora completo: messaggio in italiano semplice + azione concreta, chiude davvero il gap del giro precedente.
- `WMO_LABEL` verificato senza debito residuo: nessuna altra tabella weathercode nel codebase è rimasta disallineata (unica fonte di verità in `useMeteo.js`).
- Tutti e 3 i fix verificati con evidenza tecnica puntuale; nessuna regressione di accessibilità introdotta (pattern `aria-hidden`+`.sr-only` replicato correttamente).

## Priority Issues

**[P2] `.adesso__flag` si posiziona rispetto a un contenitore invisibile e a piena larghezza, non rispetto al contenuto visibile.**
Su desktop il pallino può apparire isolato a centinaia di pixel dall'icona/temperatura a cui si riferisce; anche su mobile manca un bordo/sfondo visibile su cui "appoggiarsi", a differenza di `.day__flag` che vive in una riga grid a piena larghezza.
Fix: dare a `.adesso` una superficie da card (sfondo/bordo, coerente col sistema `.card`), oppure ancorare `.adesso__flag` a un wrapper dimensionato al contenuto reale invece che all'intera riga flex.

**[P3] `carica()` non è protetta da invocazioni concorrenti.**
Nessun `AbortController` né flag "in corso"; oggi il bottone Riprova si autoprotegge sparendo dal DOM appena `loading` diventa vero, ma la funzione resta fragile se in futuro avesse un secondo punto di chiamata.
Fix: guardia minima in cima a `carica()` (`if (loading.value) return`) o `AbortController` sulla fetch precedente.

**[P3] Nastro orario icon-only per gli utenti vedenti.**
La descrizione testuale della condizione esiste solo come `sr-only`; un utente al primo utilizzo non ha modo di leggere "Nevischio" vs "Pioggia leggera" senza aprire il dettaglio del giorno, mentre la lista giorni sotto mostra sempre la descrizione in chiaro.

Nessun P0/P1 trovato: la vista, dopo questo terzo giro, è sostanzialmente pulita — i problemi rimasti sono di rifinitura, non blocchi funzionali o di comprensione.

## Persona Red Flags

**Jordan (primo utilizzo)**: vede il pallino rosso vicino ad "Adesso" (specialmente se scollegato dal contenuto su schermi larghi) senza etichetta visibile, potrebbe leggerlo come un difetto grafico invece che come segnale di allerta finché non scorre fino a "Occhio a questi giorni".

**Sam (screen reader/tastiera)**: lato accessibilità il fix è corretto — `aria-hidden` sul pallino + `.sr-only` di allerta, stesso pattern già in uso per `.day__flag`, nessuna regressione. Resta (pre-esistente) l'assenza di `:focus-visible` dedicato su `.day`/`.adesso`/`.btn`, ereditata anche dal nuovo bottone Riprova.

**Riley (tester metodico)**: doppio click rapido su Riprova — race condition reale ma finestra minima nella UI attuale; stato d'errore verificato pulito, mai dati vecchi contraddittori mescolati al messaggio.

## Minor Observations

- Nessun indicatore "aggiornato alle" o refresh manuale oltre al remount della vista.
- Il testo sr-only di allerta resta generico ("Attenzione: vedi avvisi meteo") indipendentemente dal tipo di allerta, sia per `.day__flag` che per il nuovo `.adesso__flag` — pattern pre-esistente, non introdotto ora.

## Questions to Consider

- Perché `.adesso` non ha mai avuto uno sfondo/bordo da card come il resto del sistema — se lo avesse, il pallino d'allerta avrebbe un angolo visibile su cui posizionarsi invece di un rettangolo invisibile esteso fino al bordo della pagina?
- Il nastro orario mostra temperatura e icona ma mai la descrizione in chiaro: un utente al primo utilizzo distingue davvero "nevischio" da "pioggia leggera" dal solo pittogramma?
- Ora che `carica()` può essere invocata sia dal mount sia dal retry, vale la pena blindarla prima di riusarla altrove (es. un refresh automatico) invece di continuare a fidarsi del fatto che il bottone sparisca abbastanza in fretta?
