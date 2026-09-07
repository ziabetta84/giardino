---
target: HomeView (src/views/HomeView.vue) - concime consigliato mancante
na_heuristics: 
p0_count: 0
p1_count: 0
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/HomeView.vue"
target_fingerprint: "sha256:8a7f0ba6d0097002a8e15cf1115e235bcd2f66f0387970af811b4ccfe16ebcf9"
target_path: /Users/rob/Sites/localhost/giardino/src/views/HomeView.vue
timestamp: 2026-09-07T07-24-11Z
slug: src-views-homeview-vue
---
# Critique: `src/views/HomeView.vue` — le righe di concimazione non mostrano il concime consigliato

Method: dual-agent (A: general-purpose design review · B: general-purpose detector/evidence). Entrambi hanno verificato indipendentemente il punto sollevato; ho verificato io stesso i dettagli chiave (esistenza di `stagioneCorrente` come computed riusabile fuori dal template, copy esatta dello stato vuoto di `ConcimiView.vue`).

**Environment disclosure:** nessuno strumento di automazione browser disponibile — confermato da entrambe le valutazioni.

## Severity Verdict: P2 (non P0/P1)

Assessment A ha argomentato esplicitamente contro il default "è di nuovo Home-manca-qualcosa-che-ha-Attività quindi è P0 come le tappe": il caso delle tappe era P0 perché produceva un **falso stato di quiete** (la UI affermava attivamente qualcosa di sbagliato). Qui non c'è nulla di falso — `a.label` ("concimazione — scaduta 3 gg fa") è corretto, l'urgenza è corretta, il flusso "Fatto" funziona. Manca un **secondo livello di informazione** (quale prodotto usare) che Attività calcola e mostra per lo stesso tipo di task. È un gap di parità/completezza fra una vista condensata e la sua versione completa — esattamente il compromesso che "Da fare oggi" (`slice(0,5)` + "Vedi tutte") dichiara di accettare.

Non è nemmeno un nitpick P3: la corrispondenza NPK-con-la-tua-dispensa-reale è la manifestazione più concreta della proposta di valore del prodotto ("non consigli generici, il tuo concime reale"), e sparisce silenziosamente — senza nemmeno un'icona o un link che ne segnali l'esistenza — dalla superficie a uso quotidiano, one-tap, più usata dell'app. Nessuno stato falso, ma un'invisibilità totale di una funzionalità di punta sulla schermata con più traffico: **P2**.

## Cosa perde l'utente, in concreto

Oggi: tocca "Fatto" su una concimazione, la task sparisce, non ha mai saputo quale concime usare — nonostante l'app avesse già calcolato la risposta. Il momento in cui la ToastCura/il blink di Zorba confermano il salvataggio arriva *prima* che l'utente pensi di controllare Attività, quindi il suggerimento non viene mai scoperto. Con la riga visibile: stessa sequenza di tap, ma la scelta ("cosa vado a prendere dal capanno") è informata nel momento esatto in cui viene presa — puro guadagno informativo, nessun costo di flusso aggiuntivo.

## Direzione di design (entrambe le valutazioni concordano)

**Seconda riga dedicata dentro `.task__m`, non testo aggiunto a `.task__d`.** Il tile `.care__ic` di Home resta alla dimensione base 34px (non i 40px che `AttivitaRiga.vue` applica localmente per ancorare una riga già a tre linee) — comprimere urgenza+prodotto in un'unica riga da 12px danneggerebbe la scansionabilità. Riusare esattamente il trattamento di `.attivita-riga__sugg` (`font:400 11px/1.4 var(--font-sans); color:var(--sage-dark)`, icona `allerta` rosa se `disponibile === false`) invece di inventare una nuova semantica solo per Home. Nessun link/rimando — nasconderlo dietro un click reintrodurrebbe esattamente il problema di scoperta descritto sopra.

## Punti di implementazione concreti

- **Import**: `import { concimeConsigliato } from '@/composables/useConcimi'`.
- **`daFareOggi`**: nel loop `tipi`, quando `tipo === 'concimazione' && c.urgente`, calcolare `concimeConsigliato(sp?.manutenzione?.npk?.[stagioneCorrente.value], store.concimi)` — stessa chiamata, stessa fonte (`store.concimi`) di `AttivitaView.vue:173-176`, così le due viste non possono mai consigliare prodotti diversi — e aggiungerlo all'oggetto pushato.
- **Template**: riga identica nella struttura a `AttivitaRiga.vue:9-12`, con guardia `v-if="a.tipo === 'concimazione' && a.suggerimento"`.
- **CSS**: promuovere `.attivita-riga__sugg`/`.attivita-riga__sugg-warn` (oggi scoped solo in `AttivitaRiga.vue`, non in `main.css`) a classe globale condivisa e riusarla in entrambi i posti — coerente con come `.care__ic`/`.care-act` sono già condivise, invece di duplicare le stesse 3 dichiarazioni CSS una seconda volta.
- **Nessuna modifica a `useConcimi.js`** — `concimeConsigliato` è già agnostico rispetto alla vista.

## Effetto collaterale minore da sistemare in corsa

`ConcimiView.vue:43` — lo stato vuoto della dispensa dice *"Aggiungi i concimi che possiedi per ricevere suggerimenti **nelle Attività**"*. Con questo fix, i suggerimenti compaiono anche su Home: la frase diventa leggermente imprecisa. Riformulazione minima (togliere il riferimento alla vista specifica), non un blocco.

## Casi limite (verificati contro `useConcimi.js`)

- **Nessun concime abbastanza vicino** (`distanza > SOGLIA_DISTANZA` 0.15): `concimeConsigliato` ritorna `null`, la guardia `v-if` non renderizza nulla — riga identica a oggi, nessuna regressione.
- **Concime consigliato esaurito** (`disponibile === false`): il campo passa attraverso lo spread `{ id, ...c, distanza }` — stessa icona di avviso di Attività, stesso significato, nessuna ragione di divergere.
- **Dispensa vuota**: già gestito identicamente da entrambe le viste (nessun suggerimento su nessuna delle due) — non è un problema di onboarding introdotto da questo fix.

## Persona

L'utente quotidiano di fretta, in giardino, che usa apposta Home invece di Attività perché è più veloce — esattamente il pubblico per cui questa schermata esiste — tocca "Fatto", prende il primo concime a portata di mano, e non scopre mai che l'app aveva già calcolato quale concime della sua dispensa fosse quello giusto (o che il suo solito è segnato come terminato).
