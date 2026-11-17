---
target: cura per zona in Attività
total_score: 24
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:/home/user/giardino/src/views/AttivitaView.vue"
target_fingerprint: "sha256:3f2440171c359920707f2f37ee0ff45eb5bb3148929f22d0ab8e9df89f6b52af"
target_path: /home/user/giardino/src/views/AttivitaView.vue
timestamp: 2026-11-17T18-46-47Z
slug: src-views-attivitaview-vue
---
Method: dual-agent (A: design review · B: detector + browser)

| # | Euristica | Voto | Problema |
|---|---|---|---|
| 1 | Stato del sistema | 2 | Il foglio non dice quale cura registra; Est conta anche Orto senza dirlo |
| 2 | Corrispondenza col mondo reale | 3 | Verbi giusti; triple NPK ripetute riga per riga |
| 3 | Controllo e libertà | 3 | Annulla c'è; le spunte si azzerano in silenzio cambiando concime |
| 4 | Coerenza | 1 | Commutatore grigio stile iOS, checkbox native, concimi in card impilate, nessun colore di dominio |
| 5 | Prevenzione errori | 3 | Escluse bloccate; piante "possono" spuntate senza segno visivo |
| 6 | Riconoscimento | 2 | Le tre sezioni sono identiche a vista |
| 7 | Efficienza | 3 | Modo ricordato; lista concimi ~250px prima delle piante |
| 8 | Estetica e minimalismo | 2 | Rosa su ogni pulsante zona; tre file di controlli; avviso ripetuto |
| 9 | Recupero errori | 3 | Errore in linea e Annulla |
| 10 | Aiuto | 2 | Nessuna spiegazione quando il concime non va bene per nessuna pianta |
| Totale | | 24/40 | Accettabile |

P1 nessun colore/icona di dominio (acqua/olive/uovo) nel flusso per zona; P1 concimi in card impilate (contro DESIGN.md); P1 checkbox native (dark mode: quadrati bianchi); P2 commutatore .modo estraneo al sistema e 36px; P2 gerarchia del foglio (intestazione senza cura, sezioni uguali, avviso ripetuto). Detector: contrasto .fcz__motivo 3.2:1, .pz__d 3.0/4.1:1, testo 10.5px su .care-act, pillole 36px, raggio 10px fuori scala.
