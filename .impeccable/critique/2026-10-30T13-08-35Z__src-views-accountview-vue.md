---
target: registrazione nuovo utente (dopo correzioni)
total_score: 29
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:/home/user/giardino/src/views/AccountView.vue"
target_fingerprint: "sha256:f0aecb6229bb485510485adcb766f119f87d66b722af37ea2288191b15cb2f5d"
target_path: /home/user/giardino/src/views/AccountView.vue
timestamp: 2026-10-30T13-08-35Z
slug: src-views-accountview-vue
---
# Seconda critica: registrazione di un nuovo utente

Method: dual-agent (A: revisione di design · B: rilevatore + browser)

Data: 30/10/2026, sulla PR #201 (commit e6b06dd). Provato a 390×844 e 1280×800, chiaro e scuro, con Supabase e Turnstile simulati. Prima critica di stamattina: 20/40.

## Punteggio

| # | Euristica | Prima | Ora | Problema chiave rimasto |
|---|---|:-:|:-:|---|
| 1 | Stato del sistema | 2 | 3 | Dopo «Invia di nuovo» il pulsante torna subito attivo, senza attesa né ora dell'invio. |
| 2 | Linguaggio del mondo reale | 3 | 4 | Il cancello regge dall'app alla mail alla Home. |
| 3 | Controllo e libertà | 2 | 2 | «Più tardi» sulla guida dei Tre passi la chiude per sempre: nessun punto dell'app la riapre. |
| 4 | Coerenza | 2 | 3 | «Password troppo debole» arriva in fondo al modulo, non sotto il campo. |
| 5 | Prevenzione degli errori | 1 | 3 | Un errore rimasto sotto l'email nasconde il suggerimento «Intendevi…». |
| 6 | Riconoscere anziché ricordare | 2 | 3 | Gli avvisi al ritorno dal link fanno scegliere tra due casi (registrazione o password). |
| 7 | Flessibilità ed efficienza | 2 | 3 | La pagina apre sempre su «Accedi», anche per chi arriva la prima volta. |
| 8 | Estetica e minimalismo | 3 | 3 | Avvisi di quattro frasi, piccole note del Ko-fi su tre righe, piede della mail lungo. |
| 9 | Recupero dagli errori | 1 | 2 | Gli errori dei campi non spariscono mentre si corregge. |
| 10 | Aiuto e documentazione | 2 | 3 | Il consiglio più utile della mail (aprire il link sullo stesso dispositivo) è nel piede grigio. |
| | **Totale** | **20** | **29/40** | **Buono** |

## Che cosa dice il controllo automatico

Contrasti tutti sopra 4,5:1 (il più basso: bottone «Crea account» a 4,57, al limite), tocchi da 44px, etichette collegate, `aria-invalid` e `aria-describedby` giusti, campi a 16px, nessuna parola inglese, nessuna richiesta alle tabelle da non loggati. Le segnalazioni rimaste sono attese: colore carta e Fraunces sono la palette del marchio, le mail hanno valori scritti a mano per forza. Una sola nuova: in tema scuro bottone e scheda attiva hanno un alone verde (`dark-glow`), da decidere se è voluto.

## Cosa funziona

1. **I casi difficili hanno tutti una strada**: indirizzo già registrato, accesso non confermato, link aperto altrove, link scaduto. L'attesa della mail resiste al ricaricamento.
2. **Accessibilità curata**: focus sul titolo a ogni passo, errori collegati ai campi, «Mostra» con lo stato giusto.
3. **Voce rispettata**: Zorba parla nei paragrafi, i pulsanti dicono l'azione.

## Problemi rimasti

**[P1] Manca uno spazio nella schermata più vista.** «Ti ho mandato una mail a**maria@gmail.com**» (`AccountView.vue:142`): Vue toglie lo spazio tra `</template>` e `<strong>` a capo. In una demo si vede subito. Correzione di una riga.

**[P1] Gli errori dei campi restano mentre si corregge.** Dopo un invio a vuoto, bordo rosso e «Scrivi il tuo indirizzo email.» restano anche a campo compilato, e nascondono il suggerimento sui refusi (`AccountView.vue:322-342`, `197-198`). Correzione: togliere l'errore di un campo appena lo si modifica.

**[P1] «Più tardi» sulla guida vuol dire «mai più».** `usePrimiPassi.js:88` salva «chiuso» per sempre. Chi tocca «Più tardi» al primo ingresso perde la guida. Correzione: nasconderla solo per la sessione, oppure aggiungere «Riapri i primi passi» in Account.

**[P2] Password debole: il messaggio non è sotto il campo, e la regola scritta può non essere quella vera.** Il suggerimento dice «Almeno 6 caratteri.», ma se Supabase chiede di più il rifiuto arriva in fondo al modulo. Correzione: errore sotto il campo con focus; allineare la regola a quella impostata nel dashboard (Authentication → Policies → Password).

**[P2] Avvisi al ritorno dal link troppo lunghi.** Quello «altro browser» è una buona notizia scritta in giallo d'avviso; entrambi mescolano registrazione e cambio password. Correzione: una riga d'esito in grassetto (salvia se confermato, oro se scaduto), una riga d'azione, il caso password in una riga breve a parte.

## Osservazioni minori

- Ko-fi: «Prima di aprirla, una cosa:» fa sembrare la mail bloccata dalla donazione; «Mentre aspetti la mail…» è più onesto. La terza riga di note ripete «Magari più avanti».
- «Invia di nuovo»: attesa di 60 secondi e ora dell'ultimo invio, per non finire nel limite di Supabase.
- Mail: spostare «apri il link sul dispositivo con cui ti sei registrato» sotto il pulsante.
- Turnstile sta tra il testo e l'azione: quando appare, i pulsanti saltano. Riservargli l'altezza o metterlo sotto.
- Su desktop la colonna da 360px galleggia in una pagina vuota.

## Domande

1. «Controlla la posta» è la schermata dove ogni nuovo iscritto aspetta, ed è la meno disegnata: che cosa fa Zorba lì, intanto?
2. La pagina dovrebbe aprire su «Registrati» quando il dispositivo non ha mai avuto un accesso?
3. Una demo all'agenzia partirebbe da una registrazione vera: quale schermata vuoi che resti in mente, e oggi è quella più curata?
