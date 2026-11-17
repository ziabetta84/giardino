---
target: minisito /scopri/
total_score: 28
max_score: 36
na_heuristics: 9
p0_count: 0
p1_count: 2
target_identity: "file:/home/user/giardino/sito/src/pages/Giro.vue"
target_fingerprint: "sha256:4b126ce897885c90e92430694bb141604dccea3ad165d14935a77d7fe9079c9d"
target_path: /home/user/giardino/sito/src/pages/Giro.vue
timestamp: 2026-11-17T14-48-23Z
slug: sito-src-pages-giro-vue
---
Method: dual-agent (A: design review · B: detector + browser)

## Heuristics (28/36, n/a: 9)
1 Visibilità 3 (posizione nel giro non visibile su telefono) · 2 Mondo reale 4 · 3 Controllo 3 · 4 Coerenza 3 (icone in due stili; «Le aiuole» contiene progetti e meteo) · 5 Prevenzione 3 · 6 Riconoscimento 3 · 7 Efficienza 2 (home 7.900px su telefono, 2 tappe fuori schermo) · 8 Estetica 3 (griglia «tutto il resto» ripete le pagine interne) · 9 n/a · 10 Aiuto 4

## Specificity
Autoriale: tessere ad acquerello e tinte dell'app, Fraunces, Zorba nero, tavole «Esempio» fedeli, foto vera. Punti generici: griglia di 7 card al centro della home, icone piatte nere (lista=hamburger, allerta=triangolo a filo, matita, cerca) accanto a quelle ad acquerello.
Detector CLI: exit 0, 31 avvisi in stile.css (24 font-size, scala del minisito voluta; da sistemare i passi 15/15.5/17/18px; 7 radius, 16/18px fuori token). Browser: icon-tile-stack ripetuto (scelta di design), cream-palette falso positivo. Overflow 0. Tap target in testata 40px (minimo 44).

## Priority
P1 Icone dei Blocchi in due stili (lista, allerta, matita, cerca monocrome).
P1 In tema scuro il bottone principale quasi sparisce; Ko-fi pesa più di «Crea il tuo giardino».
P2 Griglia «E poi, tutto il resto» generica, 4+3 con buco, ripete le pagine interne.
P2 Nessuno screenshot vero dell'app.
P2 Telefono: bottone principale al limite della piega; «I tuoi dati» e «Domande» nascosti nella striscia.
Minor: ombra del link «salta» in alto a sinistra; Zorba nero poco leggibile sulla tessera oro in scuro; tap target 40px; colonna destra vuota nei Blocchi senza tavola; tre risposte di Zorba non dette in home.
