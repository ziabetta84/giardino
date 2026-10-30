---
target: registrazione nuovo utente
total_score: 20
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:/home/user/giardino/src/views/AccountView.vue"
target_fingerprint: "sha256:85f215fdbe2c9cd53b06c85bc489b8be8e45962992cf22482f2787007c62fd00"
target_path: /home/user/giardino/src/views/AccountView.vue
timestamp: 2026-10-30T12-08-08Z
slug: src-views-accountview-vue
---
# Critica: registrazione di un nuovo utente

Method: dual-agent (A: revisione di design · B: rilevatore + browser)

Data: 30/10/2026. Percorso esaminato: modulo «Registrati» in `AccountView.vue`, verifica anti-robot, invito Ko-fi dopo «Crea account», schermata «Controlla la posta», mail di conferma, primo ingresso in Home. Provato nel browser a 390×844 e 1280×800 con Supabase e Turnstile simulati: nessun account vero creato.

## Punteggio (euristiche di Nielsen)

| # | Euristica | Voto | Problema chiave |
|---|---|:-:|---|
| 1 | Stato del sistema | 2 | Dopo il clic sul link nessuno dice «email confermata». Sul passo Ko-fi non si dice che la mail è già partita. |
| 2 | Linguaggio del mondo reale | 3 | Italiano e voce di Zorba ovunque; resta «Torna al login». La mail dice «un passo», la Home «tre passi». |
| 3 | Controllo e libertà | 2 | Su «Controlla la posta» non si può correggere l'indirizzo; ricaricando la pagina la schermata si perde. |
| 4 | Coerenza | 2 | Fumetti di validazione del browser fuori stile; bottone della mail a pillola, quelli dell'app a 12px. |
| 5 | Prevenzione degli errori | 1 | Nessun controllo dei refusi nell'email (`exmple.com` passa), regole della password non mostrate prima, niente «mostra password». |
| 6 | Riconoscere anziché ricordare | 2 | Chi accede con email non confermata trova una riga rossa senza pulsante per rimandare la mail, che però la mail promette. |
| 7 | Flessibilità ed efficienza | 2 | `autocomplete` corretti; password digitata una volta sola, senza poterla vedere, da telefono. |
| 8 | Estetica e minimalismo | 3 | Pulito e riconoscibile. Zorba compare due volte sul passo Ko-fi; in Home la guida è ripetuta da tre righe sotto. |
| 9 | Recupero dagli errori | 1 | `weak_password` ed `email_address_invalid` arrivano in inglese; «Esiste già un account» in produzione non compare quasi mai. |
| 10 | Aiuto e documentazione | 2 | La guida «Tre passi» è ottima; prima di registrarsi nulla dice che cosa fa l'app. |
| | **Totale** | **20/40** | **Sotto la media: l'aspetto è curato, il percorso ha buchi** |

## È fatto per questo prodotto?

L'aspetto sì: Fraunces, Zorba nero con le foglie d'oro, la carta con l'acquerello, «Lascia entrare Zorba in giardino», «Il cancello è quasi aperto», «Dona un ciuffo d'erba gatta», la mail con la voce di Zorba. Il percorso sotto invece è una registrazione Supabase di serie, con i buchi di serie: errori del server in inglese, fumetti del browser, nessun momento di conferma, account già esistente invisibile. La metafora del cancello è raccontata bene a parole ma i passi non la mantengono.

Rilevatore automatico: 7 segnalazioni (2 avvisi, 5 note). Reali: contrasto 3,2:1 nel testo grigio della mail (righe 23, 28, 29). Falsi positivi: `cream-palette` (è il colore carta della palette) e i valori fuori scala nella mail (le mail devono avere stili scritti a mano). Il controllo nel browser ha trovato più del rilevatore: le etichette Nome/Email/Password a 3,0:1, il bottone «Crea account» bianco su salvia a 3,0:1 (la salvia stessa non regge testo bianco piccolo), le pillole Accedi/Registrati a 3,0–3,2:1 e alte 36px, «Torna al login» a 3,0:1 e alto 20px. Nessun testo inglese visibile negli stati normali, nessun errore in console.

## Cosa funziona

1. **La voce è una sola**, dall'app alla mail alla guida: «sono Zorba… mi serve sapere che questo indirizzo è davvero tuo», «Magari più avanti». La mail è fatta bene (anteprima, link in chiaro di riserva, «se non l'hai chiesta tu»).
2. **La guida «Tre passi»** legge lo stato dai dati veri, un'azione per passo e spiega il perché («Finché non lo so, il meteo resta spento…»). Le pagine vuote sono scritte, non riempite.
3. **Ingresso sgombro e onesto**: niente menu da non loggati, e sul passo Ko-fi il «no» pesa quanto il «sì».

## Problemi in ordine di priorità

**[P1] Chi è già registrato non lo scopre mai, e il reinvio promesso dalla mail non c'è.**
Con la conferma email attiva, Supabase non dice se l'account esiste: per un indirizzo già confermato `signUp` risponde senza errore, con `identities: []`, e non manda nulla. L'utente vede Ko-fi e «Controlla la posta» e aspetta una mail che non arriverà. La traduzione «Esiste già un account» (`useAuth.js:82`) quindi non scatta. Al login con email non confermata c'è solo la riga rossa, mentre la mail dice «chiedine un altro dalla pagina di accesso».
*Correzione:* in `AccountView.vue:273` leggere il ritorno di `registrati()` e, se `identities` è vuoto, saltare Ko-fi e mostrare «Forse hai già un account con questa email» con Accedi e Recupera password. In `onInvia`, sull'errore «Email non confermata», aprire il pannello «Controlla la posta» con il pulsante per rimandarla.
*Comando:* `/impeccable harden`. Da confermare una volta con un indirizzo di prova vero (è il comportamento documentato di Supabase, non l'ho visto su una richiesta reale).

**[P1] Errori in inglese e fumetti del browser.**
`traduci()` (`useAuth.js:94`) traduce per testo esatto e lascia passare tutto il resto così com'è: «Password should contain at least one character of each…» arriva all'utente. I campi vuoti mostrano il fumetto del browser.
*Correzione:* tradurre per `error.code` (`weak_password`, `email_address_invalid`, `over_email_send_rate_limit`, `user_already_exists`, `signup_disabled`) con un messaggio italiano generico di ripiego, mai il testo grezzo. `novalidate` sul modulo e messaggi in linea. Regola della password scritta sotto il campo prima dell'invio, e pulsante mostra/nascondi.
*Comando:* `/impeccable clarify`.

**[P1] Etichette non collegate ai campi, contrasti sotto soglia.**
`AccountView.vue:132, 137, 141` (e `:80` nel recupero) hanno `<label>` senza `for`: Email e Password non hanno nome per un lettore di schermo e toccare l'etichetta non porta nel campo. Etichette, bottone «Crea account», pillole e «Torna al login» sono sotto 4,5:1.
*Correzione:* `id`/`for` come già fatto per `account-nome` (riga 27); `aria-live` sulle righe d'errore; focus sul titolo quando si passa al Ko-fi o alla posta. Testo del bottone salvia su `--sage-dark` o testo `--sage-ink` su salvia chiara; etichette in `--ink-mid`; pillole e link almeno 44px di tocco.
*Comando:* `/impeccable audit`, poi `/impeccable polish`.

**[P2] Nessun momento di conferma, nessun modo di correggere l'indirizzo.**
Il punto più alto del percorso manca: chi clicca il link (spesso aperto nel browser interno dell'app di posta) arriva al modulo di accesso senza un «Ci siamo». *Correzione:* al ritorno dal link (codice o `error_description` nell'URL) mostrare «Email confermata, ora entra» con il battito di Zorba, e un messaggio chiaro se il link si apre in un altro browser. Su «Controlla la posta» aggiungere «Indirizzo sbagliato? Correggilo» e sul modulo un suggerimento leggero per i refusi di dominio («gmial.com → intendevi gmail.com?»).
*Comando:* `/impeccable onboard`.

**[P2] Il passo Ko-fi e la prima Home: esecuzione.** (La posizione del Ko-fi resta com'è, come hai deciso.)
Sotto «Il cancello è quasi aperto» manca una riga che dica «Ti ho mandato una mail a {email}»: oggi la richiesta di sostegno arriva prima della notizia che l'account esiste. Zorba doppio (togliere il piccolo in `ContributoCard.vue:7` nella variante invito). In Home, finché la guida è aperta, nascondere la riga meteo, la riga «Zorba dice» e il titolo vuoto «Da fare oggi», che ripetono lo stesso invito; «Attività: tutto ok» con zero piante è una rassicurazione falsa.
*Comando:* `/impeccable distill`.

## Segnali d'allarme per persona

- **Giardiniera alla prima volta, da telefono:** password scritta una volta senza vederla; il riquadro anti-robot (sempre chiaro, ~65px) sembra un pedaggio; il sostegno chiesto prima di sapere che la mail è partita; il link apre il browser interno di Gmail su un modulo di accesso senza spiegazioni; «login» è gergo.
- **Chi non ricorda se si era già iscritta:** si registra di nuovo e riceve un falso «ti ho scritto»; accede con email non confermata e trova un vicolo cieco.
- **L'agenzia che guarda la demo:** errore in inglese nel mezzo della voce di Zorba, fumetti del browser, «un passo / tre passi».

## Osservazioni minori

- A 390px «Lascia entrare Zorba in giardino» lascia «giardino» da solo a capo (`text-wrap: balance`).
- I campi hanno testo a 14px: su iPhone lo schermo si ingrandisce al tocco (sotto 16px).
- Il placeholder «Come vuoi essere chiamato» è a 1,8:1.
- Da non loggati la pagina chiede comunque a Supabase zone, piante, fili di Zorba e impostazioni a ogni apertura.
- «Un momento…» è la stessa scritta per registrazione, reinvio e recupero.
- Su desktop il blocco è 340px in una pagina vuota: nulla dice che cosa fa l'app.

## Domande

1. Se la mail dice «un passo» e la Home «tre passi», qual è la porta vera? La conferma della mail potrebbe essere il passo zero della stessa guida.
2. Serve davvero una password a chi cura un giardino, quando la mail è già la chiave (link o codice via mail, il modello è già scritto)?
3. Che cosa dice Zorba a chi torna dal link? Oggi niente, ed è il momento che resta in mente.
