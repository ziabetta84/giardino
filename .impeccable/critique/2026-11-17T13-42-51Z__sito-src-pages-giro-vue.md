---
target: minisito /scopri/
total_score: 27
max_score: 36
na_heuristics: 9
p0_count: 0
p1_count: 2
target_identity: "file:/home/user/giardino/sito/src/pages/Giro.vue"
target_fingerprint: "sha256:f0201b8a466f806413215044537477fe06328ce59241ae42115072d99dbb4048"
target_path: /home/user/giardino/sito/src/pages/Giro.vue
timestamp: 2026-11-17T13-42-51Z
slug: sito-src-pages-giro-vue
---
Method: dual-agent (A: design review · B: detector + browser)

## Heuristics (27/36, n/a: 9)
1 Visibilità 3 · 2 Mondo reale 4 · 3 Controllo 3 · 4 Coerenza 2 (CTA in concorrenza; home ricca vs tappe testuali) · 5 Prevenzione 3 · 6 Riconoscimento 3 (strip mobile nasconde 2 tappe) · 7 Efficienza 3 · 8 Estetica 3 · 9 n/a · 10 Aiuto 3 (prezzo abbonamento assente)

## Specificity
Home autoriale (sentiero, Zorba, scheda vera, foto). Pagine di tappa: Blocco.vue ripetuto, colonna destra vuota, nessun sentiero né Zorba: leggono come documentazione.
Detector: 0 hard; 25 advisory (21 font-size intenzionali per scala minisito, 15.5px x4 ad hoc; radius 10px NPK e 16px cambio-tappa drift minore). Browser: heading-rhythm x4, cream-palette, clipped-overflow thead: falsi positivi.

## Priority
P1 Nessun «Crea il tuo giardino» in 5 pagine su 7; header «Apri l'app» porta al login.
P1 Pagine di tappa senza firma (sentiero/pietre/Zorba), blocchi solo testo con colonna vuota.
P2 Nessuno screenshot vero dell'app.
P2 Testata mobile 140px, strip nasconde 2 tappe, fondo traslucido.
P3 Domande: «Tappa precedente» dopo la CTA finale; abbonamento senza prezzo.
Minor: Zorba grigio durante la dissolvenza di uscita; testo «Chi è Zorba» ripetuto con finale diverso in Zorba.vue; «si prova in un minuto»; scala tipografica minisito non documentata.
