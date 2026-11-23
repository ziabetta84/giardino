---
target: il nuovo menù mobile
total_score: 28
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:/home/user/giardino/src/components/MenuMobile.vue"
target_fingerprint: "sha256:01d96574183dc8e64f113d6702e7d201a3187405228453c6853e866821a0c794"
target_path: /home/user/giardino/src/components/MenuMobile.vue
timestamp: 2026-11-22T16-31-42Z
slug: src-components-menumobile-vue
---
# Critica del menù mobile («l'Indice») — 22/11/2026

Metodo: due revisioni indipendenti (design · rilevatore automatico e misure nel browser con Playwright, iPhone 13 e SE, chiaro e scuro).

## Punteggio (euristiche di Nielsen): 28/40, buono

| # | Euristica | Voto | Problema principale |
|---|---|---|---|
| 1 | Stato del sistema | 2 | A menù chiuso nessun segnale di dove sei o di cure in scadenza |
| 2 | Corrispondenza col mondo reale | 4 | Metafora del taccuino riuscita; «Gallery» resta in inglese |
| 3 | Controllo e libertà | 2 | Il gesto «indietro» del telefono cambia pagina invece di chiudere il menù |
| 4 | Coerenza | 3 | Stesso ordine della sidebar; la testata aperta perde il filetto dell'appbar |
| 5 | Prevenzione errori | 3 | Righe da 50px adiacenti, tocchi sbagliati possibili con i guanti |
| 6 | Riconoscimento | 3 | Etichette e icone sempre insieme; le pagine però ora sono nascoste |
| 7 | Efficienza | 2 | Ogni cambio di pagina = 2 tocchi + ~0,5 s di animazione; Attività è settima |
| 8 | Estetica e sobrietà | 4 | Sobrio e bello in entrambi i temi |
| 9 | Recupero dagli errori | 2 | Il gesto «indietro» diventa l'errore tipico |
| 10 | Aiuto | 3 | «Zorba dice», «Concimi» opachi per chi arriva |

## Specificità
Fatto per questo prodotto: indice del taccuino, Fraunces, macchia d'inchiostro, «sei qui» a penna, Zorba nero. La forma è d'autore, il contenuto è un elenco piatto di 9 righe uguali.
Rilevatore: 0 problemi nel menù (1 avviso: 21px fuori dalla scala, voluto per schermi bassi). Il controllo in pagina ha trovato 4 segnalazioni, tutte della pagina Concimi dietro il menù.

## Funziona
- Metafora coerente e disciplinata; animazione verificata: il cerchio parte davvero dal pulsante (0→990px in 260 ms).
- Accessibilità di base solida: dialogo modale, focus intrappolato e restituito, Esc, aria-current, movimento ridotto = dissolvenza (tutto verificato).
- Robusto: si chiude a ogni cambio di rotta e oltre i 640px, sta sopra StatusBar e toast.

## Problemi in ordine di priorità
1. [P1] Il gesto «indietro» (Android, swipe iOS) a menù aperto porta alla pagina precedente invece di chiudere solo il menù. Fix: voce di cronologia all'apertura, chiusura su popstate.
2. [P1] Il compito quotidiano costa di più e non si vede niente a colpo d'occhio: Attività è la 7ª voce, nessun segnale di cure in scadenza. Fix: pallino/numero sul pulsante del menù e «3 da fare» sulla riga Attività; ordine per frequenza (Home, Attività, Piante, Zone, Zorba dice, Progetti, Concimi, Meteo, Gallery), lo stesso nella sidebar.
3. [P2] «sei qui» in chiaro ha contrasto 4,28:1 (serve 4,5:1); icone inattive esattamente a 3:1; filetti 1,1:1, al sole le righe si fondono. Fix: sage-ink per «sei qui», icone ink-mid, filetti un tono più scuri.
4. [P2] Testata fissa senza sfondo: dove il pannello scorre (schermi bassi) le voci passano sotto «Zorba in giardino» e la croce. Fix: sfondo carta con sfocatura come l'appbar, e filetto sotto, che ora manca rispetto alla barra chiusa.
5. [P2] Animazione lunga per un gesto ripetuto: l'ultima voce si posa a ~520 ms. Fix: ritardi più stretti (30 ms + 12 ms per voce), tutto entro ~350 ms.

## Personas
- Casey (telefono, una mano, all'aperto): apri e chiudi in alto a destra, la zona più scomoda; filetti invisibili al sole; uno swipe indietro la porta via dalla pagina.
- Jordan (prima volta): icona senza scritta «Menù»; «Zorba dice»/«Concimi» senza spiegazione.
- Sam (lettore di schermo): manca `inert` sul resto della pagina, alcuni lettori escono dal dialogo.
- Rob in giardino coi guanti: per sapere cosa bagnare servono menù → 7ª riga → pagina.

## Osservazioni minori
- `viewport-fit=cover` manca in index.html: le aree sicure valgono 0 (innocuo oggi); se lo si aggiunge, l'appbar va allineata alla testata del menù.
- In orizzontale ogni telefono supera i 640px: compare la sidebar, che non sta nello schermo e scorre (problema della sidebar, non del menù).
- «Scrivi a chi costruisce l'app» è la voce più lunga per l'azione meno usata.
- In fondo allo schermo, dove arriva il pollice, ora c'è solo l'invito «Dona».

## Domande
- E se ogni riga dell'Indice portasse una riga viva («3 da bagnare», «pioggia domani»)?
- Meteo merita una voce, visto che la Home lo mostra già?
- Va bene che il punto più comodo per il pollice chieda una donazione invece di offrire la cura del giorno?
