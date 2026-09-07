---
target: HomeView (src/views/HomeView.vue)
total_score: 33
max_score: 40
na_heuristics: 
p0_count: 1
p1_count: 1
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/HomeView.vue"
target_fingerprint: "sha256:1012a7121d5bcbb82a8bb1ee6a16903780266754d65a9fc3ec7d5483998b9ab0"
target_path: /Users/rob/Sites/localhost/giardino/src/views/HomeView.vue
timestamp: 2026-09-07T07-55-09Z
slug: src-views-homeview-vue
---
# Critique: `src/views/HomeView.vue` (punteggio aggiornato dopo il commit)

Method: dual-agent (A: general-purpose design review · B: general-purpose detector/evidence). Ho verificato personalmente i punti chiave della nuova scoperta P1 (gap meteo/location) prima di includerla: confermato che `stores/dati.js` non ha alcun fallback quando `settings.location` è vuoto, che `MeteoView.vue:185` ne ha uno (Fano, 43.8309/12.9860) che `dati.js` non riusa, che `SettingsView.vue` non offre geolocalizzazione automatica (il campo parte `null` finché l'utente non lo compila a mano), e il meccanismo esatto del conflitto `aria-hidden`/`aria-label` in `Icon.vue`.

**Environment disclosure:** nessuno strumento di automazione browser disponibile — confermato da entrambe le valutazioni.

## Cosa conferma questo run

Assessment B ha verificato lo stato committato riga per riga: il fix del concime consigliato è presente e corretto (import, computed, template, CSS globale); il gap delle tappe di progetto è confermato ancora aperto come previsto (nessun import di `useProgetti`/`tappeAttese`); la guardia anti-race su `caricaTutto()` è intatta. Assessment A ha fatto una revisione completa (non solo sul punto delle tappe) e ha trovato un problema nuovo, indipendente, mai emerso nei round precedenti: **la riga meteo di Home — e con essa la sospensione dell'irrigazione in caso di pioggia — non funziona mai per un utente che non ha ancora visitato `/impostazioni`**, perché `dati.js` non ha alcun fallback di coordinate mentre `MeteoView.vue` sì.

## Design Health Score

| # | Heuristic | Score | Nota |
|---|-----------|-------|------|
| 1 | Visibilità dello stato | 2 | Il momento a più alto rischio della schermata ("Tutto in ordine!") può essere falso — vedi P0 |
| 2 | Corrispondenza con il mondo reale | 4 | Nessun problema |
| 3 | Controllo e libertà dell'utente | 4 | Undo di 6s su ToastCura, retry, disabilitazione durante il salvataggio |
| 4 | Coerenza e standard | 3 | `.attivita-riga__sugg` ora davvero condivisa e identica fra le due viste; il badge Progetti resta strutturalmente incapace di segnalare urgenza (`urgent: false` fisso) |
| 5 | Prevenzione errori | 3 | Nessun problema nuovo |
| 6 | Riconoscere piuttosto che ricordare | 4 | Il suggerimento concime elimina la necessità di consultare la dispensa a memoria |
| 7 | Flessibilità ed efficienza | 3 | Zero efficienza per il lato progetti di questa schermata |
| 8 | Design minimale ed estetico | 3 | La schermata è vicina al limite di quanto può portare con grazia, ma ancora coerente oggi |
| 9 | Aiutare a riconoscere/recuperare dagli errori | 3 | Il meteo, a differenza di ogni altro stato vuoto/errore del file, non offre alcuna via di recupero quando manca la location |
| 10 | Aiuto e documentazione | 4 | "Zorba dice" è la risposta corretta a questa euristica per questo prodotto |
| **Totale** | | **33/40** | **Buono** |

*Punteggio: 35 → 33.* Non è un regresso dei fix committati — tutti verificati intatti — ma la scoperta di un problema P1 reale e indipendente (meteo/location) durante una revisione volutamente più ampia della sola questione tappe.

## Verdetto di specificità del design

Confermato ancora una volta: decisioni come il flag di modulo per l'animazione "una volta a sessione", `rangoUrgenza()` per evitare NaN nel comparatore, il sottotitolo di Zorba che nomina la pianta reale più scaduta, sono ingegneria vera, non decorazione. L'unica vera crepa è strutturale: la promessa centrale della schermata — "niente viene trascurato" — oggi copre solo le piante, non i progetti su cui si basa la metrica di successo dichiarata del prodotto.

## Punti di forza

- **`.attivita-riga__sugg` è ora davvero una singola fonte di verità** — stessa classe CSS globale, stessa forma dati (`item.suggerimento`), Home e Attività non possono più divergere silenziosamente su questa funzionalità.
- **`rangoUrgenza()`** continua a essere segnalato positivamente round dopo round come ingegneria attenta a un caso limite reale.
- **Il flag di sessione per il traguardo "Tutto in ordine!"** separa correttamente "primo render di questo mount" da "transizione dal vivo durante la sessione" — una sottigliezza facile da sbagliare in Vue, documentata inline per chi la toccherà in futuro.

## Priorità

**[P0] "Da fare oggi"/"Tutto in ordine!" ignora le tappe di progetto scadute — confermato ancora aperto**
Invariato dal round precedente: `HomeView.vue` non importa mai `tappeAttese` da `useProgetti.js`, mentre `AttivitaView.vue` lo fa per lo stesso identico scopo. Il badge Progetti aggrava il problema fissando `urgent: false` a prescindere da cosa sia realmente scaduto. Un utente con zero cure urgenti ma una tappa di progetto scaduta vede ancora oggi un falso "Tutto in ordine!" — l'esatto scenario che la metrica di successo del prodotto dice non debba accadere silenziosamente.
**Direzione confermata da Assessment A**: integrare le tappe scadute nello stesso array/ordinamento di `daFareOggi` (stessa forma `{key, tipo, label, giorni}`, stesso `rangoUrgenza`), non come una sezione a parte aggiunta sopra — altrimenti la schermata, oggi coerente per disciplina, rischia di ribaltarsi in una accozzaglia di sezioni.
**Comando suggerito**: `/impeccable harden`

**[P1] La riga meteo — e la sospensione dell'irrigazione in caso di pioggia — non funzionano mai senza una location configurata a mano**
Verificato: `dati.js:327-329` carica il meteo solo `if (lat && lon)` da `settings.value?.location`, senza alcun fallback. `SettingsView.vue` non offre geolocalizzazione automatica — il campo parte `null` finché l'utente non lo compila da `/impostazioni`. Un nuovo utente che non ha ancora visitato quella pagina ottiene: (a) una riga meteo permanentemente morta su Home, senza alcuna via di recupero — a differenza di ogni altro stato vuoto/errore di questo file; (b) più seriamente, `pioggiaInArrivo()` (`useCure.js`) non scatta mai, quindi l'urgenza di irrigazione per le piante esterne ignora silenziosamente le previsioni di pioggia — proprio il differenziale "dati reali, non consigli generici" su cui il prodotto si posiziona. `MeteoView.vue:185` ha già un fallback ragionevole (43.8309, 12.9860 — Fano) che `dati.js` non riusa: Home e `/meteo` possono quindi dare risposte diverse per lo stesso utente.
**Fix**: riusare lo stesso fallback di coordinate in `dati.js`, o quantomeno dare alla riga meteo di Home un CTA di recupero coerente con gli altri stati vuoti del file.
**Comando suggerito**: `/impeccable harden`

**[P2] Il badge Progetti resta incapace di segnalare urgenza anche dopo il fix delle tappe**
Indipendente dalla causa radice del P0: `homeCards`' `count` per `/progetti` è solo "N aperti", senza alcuna variante urgente definita. Anche dopo aver integrato le tappe in `daFareOggi`, questa card specifica avrà comunque bisogno della propria logica `urgent`/conteggio — non è un sottoprodotto automatico del fix del computed.
**Comando suggerito**: `/impeccable clarify`

## Persona a rischio

**Nuovo utente multi-account, prima sessione**: non visita mai `/impostazioni`; la riga meteo è morta e, invisibilmente, ogni pianta esterna ignora le previsioni di pioggia — proprio il pubblico che più avrebbe bisogno di vedere il differenziale del prodotto funzionare al primo giorno.

**Utente quotidiano con un progetto attivo**: diligente con le piante ma con una tappa in ritardo, vede "Tutto in ordine!" e chiude l'app soddisfatto — la cura artigianale messa in quell'animazione (gated per sessione, mai banalizzata) viene spesa su una premessa falsa, il che erode la fiducia più velocemente di nessuna animazione.

## Osservazioni minori

- `HomeView.vue` passa `aria-label="Terminato"` a `<Icon>`, il cui template ha `aria-hidden="true"` fisso. Verificato: Vue aggiunge `aria-label` come attributo separato via fallthrough automatico, ma non rimuove `aria-hidden="true"` già scritto esplicitamente — risultato, un elemento con entrambi gli attributi, dove `aria-hidden="true"` rende `aria-label` inutile per la lettura assistita. Bug reale, minore, isolato a questa unica icona che dovrebbe essere annunciata.
- Il sottotitolo di fallback di "Zorba dice" è l'unico punto di Home che menziona i progetti quando non c'è nulla di urgente per le piante — una riga generica, non uno stato reale, a fronte di quattro stati distinti per la cura delle piante.

## Domande da considerare

Entrambe le valutazioni convergono: una volta chiuso il P0 nel modo giusto (integrato nello stesso ordinamento, non una sezione a parte) e sistemato il fallback meteo, questo file è vicino a un punto di arrivo naturale — non servono nuovi stati, solo rendere veritieri quelli che già esistono.
