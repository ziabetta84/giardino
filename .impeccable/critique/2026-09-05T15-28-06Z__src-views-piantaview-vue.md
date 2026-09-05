---
target: Scheda pianta (src/views/PiantaView.vue)
total_score: 31
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 0
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/PiantaView.vue"
target_fingerprint: "sha256:21763870911a8215a97e09b33c223d324a40008c05857abd1252b671a1c51707"
target_path: /Users/rob/Sites/localhost/giardino/src/views/PiantaView.vue
timestamp: 2026-09-05T15-28-06Z
slug: src-views-piantaview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Euristica | Punteggio | Nodo specifico |
|---|-----------|-------|-----------------|
| 1 | Visibilità dello stato del sistema | 3 | Skeleton, spinner su "Fatto"/eliminazione; manca conferma esplicita dopo registraCura riuscita oltre al ricalcolo dell'etichetta |
| 2 | Corrispondenza sistema/mondo reale | 3 | Linguaggio di dominio corretto; NPK non spiegato in pagina |
| 3 | Controllo e libertà dell'utente | 3 | Esc/click-fuori/back-link coerenti; nessun "annulla" dopo un "Fatto" inviato |
| 4 | Coerenza e standard | 3 | Pattern .care-act/ModalConferma riusati identici tra viste; incoerenza interna a ConcimiView (salva/toggleDisponibile ancora senza catch) |
| 5 | Prevenzione errori | 3 | Eliminazioni sempre dietro conferma con messaggio specifico; "Fatto" scrive subito senza rete di sicurezza |
| 6 | Riconoscimento anziché ricordo | 4 | Icone sempre con testo, puntini/contatore galleria mostrano posizione corrente |
| 7 | Flessibilità ed efficienza d'uso | 3 | Galleria navigabile da tastiera; nessuna azione bulk (non necessaria qui) |
| 8 | Estetica e design minimalista | 4 | Gruppi kv ≤3, sezioni condizionali, nessun elemento superfluo |
| 9 | Aiutare a riconoscere/recuperare errori | 3 | Messaggi vicini alla fonte, tono pacato; non spiegano mai la causa reale |
| 10 | Aiuto e documentazione | 2 | "Note tecniche" funge da guida incorporata; NPK non spiegato, nessun aiuto ricercabile |
| **Totale** | | **31/40** | **Buono** (in miglioramento da 29/40) |

## Design Specificity Verdict

Confermato autoriale: scrim+caption a tutta larghezza, filigrana Zorba al 7%, raggruppamento kv motivato a codice, tinte per dominio di cura, Regola del Nome in Fraunces rispettata. I tre fix mostrano cura di dettaglio (riuso del token canonico `--rose-ink` già usato altrove nel sistema, non un valore inventato) ma anche il limite tipico del fix locale: il focus ring risolto isolatamente non replica la soluzione già presente 10 righe sotto nello stesso file CSS (`.pbtn`/`.phead-cap`/`.gnote` si danno tutti `z-index:2` sopra lo scrim).

Scansione deterministica: pulita, 0 anti-pattern reali, solo advisory di drift tokenizzazione pre-esistenti e non correlati.

## Overall Impression

I tre fix di raffinamento hanno funzionato per lo scopo dichiarato: il contrasto passa AA ovunque sia stato applicato (6.89–9.43:1, verificato con calcolo completo in entrambi i temi), la gestione errori di GalleryView/ConcimiView ora rispecchia fedelmente il pattern di PiantaView copia per copia. Il punteggio sale da 29 a 31/40. Emerge però un effetto collaterale reale sul fix del focus: `.phead-scrim` (z-index:1) dipinge sopra `.gslide` (z-index:auto), quindi l'anello di focus si attenua proprio nel quarto inferiore della foto — dove sta il nome della pianta, il punto che un utente da tastiera vorrebbe individuare con certezza. È un difetto di secondo ordine (il fix non è inutile, solo incompleto), lo stesso tipo di problema di propagazione già visto nei run precedenti: una correzione locale ben fatta che non riusa una soluzione già presente altrove nello stesso file.

## What's Working

- `messaggioEliminaPianta` (PiantaView.vue:303-309): pluralizza correttamente e conta le foto coinvolte prima di un'eliminazione irreversibile.
- Raggruppamento `.kv` per categoria in "La specie" (righe 113-144): decisione motivata a codice contro il muro di dati.
- `altFoto()` (righe 263-266): alt text differenziato per foto, con commento che documenta il bug precedente risolto.
- Contrasto `--rose-ink`: verificato con calcolo WCAG completo, passa 4.5:1 con ampio margine in entrambi i temi su tutti e 4 gli usi corretti.

## Priority Issues

**[P2] Anello di focus su `.gslide` attenuato da `.phead-scrim`.**
`.gtrack`/`.gslide` sono `position:absolute` con `z-index:auto`; `.phead-scrim` ha `z-index:1` esplicito — dipinge sopra l'anello. Calcolo del colore composito: in alto (scrim ~30% nero) l'anello resta leggibile (~rgb(149,82,79)), in basso (scrim fino a 68% nero, proprio dove sta `.phead-cap` col nome pianta) diventa quasi indistinguibile dallo sfondo (~rgb(80,46,41)). Gli altri elementi sovrapposti alla stessa foto (`.pbtn`, `.phead-cap`, `.gnote`) risolvono lo stesso conflitto dandosi `z-index:2`; il nuovo anello di focus è l'unico elemento aggiunto che non replica quella soluzione già presente nel file.
Fix: alzare lo z-index di `.gslide:focus-visible` (o un `::after` dedicato) sopra lo scrim, replicando il pattern già usato da `.pbtn`/`.phead-cap`/`.gnote`.

**[P2] "Fatto" (registraCura) non ha rete di sicurezza né via di recupero.**
`ultima_cura[tipo]` conserva solo l'ultimo valore per tipo; un tap accidentale su una pillola compatta in una riga densa sovrascrive silenziosamente il dato che alimenta i calcoli di urgenza altrove nell'app (Home, Attività), senza modo di annullare da questa schermata — a differenza del trattamento molto più protetto riservato a eliminazione foto/pianta nello stesso file.
Fix: un toast leggero "Annulla" post-conferma, senza introdurre un dialogo di conferma preventivo che contraddirebbe l'intento a basso attrito del bottone.

**[P3] Incoerenza di gestione errori interna a `ConcimiView.vue`.**
Il fix ha reso `eliminaConcime` coerente col resto dell'app, ma `salva()` (140-165) e `toggleDisponibile()` (167-178), nello stesso file, restano `try{...}finally{...}` senza `catch` — lo stesso bug di fallimento silenzioso sopravvive due funzioni più sotto.

## Persona Red Flags

**Sam (screen reader/tastiera)**: l'anello di focus su `.gslide` diventa quasi invisibile nel quarto inferiore della foto (vedi P2 sopra); `.phead-credit` (attribuzione Wikimedia, 9px) è sotto la soglia comoda di lettura/tocco.

**Casey (mobile distratto)**: l'errore di `registraCura` è una semplice riga di testo colorato in una riga già densa, senza rilievo aggiuntivo (nessuno sfondo/icona) — facile da non notare in una scansione veloce, a differenza degli errori di eliminazione che vivono in un modale impossibile da ignorare.

**Riley (stress tester)**: `.phead-cap` (bottom:20px, cresce verso l'alto) dentro `.phead-photo` con `overflow:hidden` e altezza fissa — un nome scientifico/varietà molto lungo rischia di essere tagliato in alto (nessun contenimento verticale, solo `text-wrap:balance`); eliminare l'ultima foto passa istantaneamente a `.phead-text`/fallback senza la dissolvenza condivisa già esistente altrove nell'app (`.fade-enter-active`).

## Minor Observations

- `GalleryView.vue:290` (`erroreUpload.value = e.message`) mostra il messaggio grezzo di Supabase/Storage, in contrasto di tono con la frase curata appena introdotta per l'eliminazione foto nello stesso file.
- `.badge-warn` (main.css:217, `--rose-dark` su `--rose-pale`) non toccato da questo fix e resta nello stesso schema sotto-soglia — non usato in PiantaView, ma stesso pattern, probabile prossimo candidato.
- Il fix di contrasto era scoped a 4 punti precisi: restano ~29 altri usi testuali di `--rose-dark` in 15 file (incl. `GalleryView.vue:21,119` e `ConcimiView.vue:221`, toccati proprio in questo giro per altro motivo) con lo stesso identico problema (4.06-4.34:1).
- `fabbisognoNpk` ("10-5-8") non ha spiegazione inline per un utente alle prime armi.

## Questions to Consider

- Se l'anello di focus e i pulsanti risolvono lo stesso conflitto con `.phead-scrim` dandosi un proprio z-index:2, ha senso applicare subito la stessa soluzione all'anello invece di lasciarlo attenuato?
- "Fatto" sovrascrive silenziosamente l'unico dato di "ultima cura" usato per le urgenze in tutta l'app: vale la pena un breve "Annulla" post-conferma?
- Il criterio "mai fallire in silenzio su un errore di rete/RLS" ha già raggiunto 3 file (PiantaView/GalleryView/ConcimiView solo per l'eliminazione): estenderlo anche a `salva()`/`toggleDisponibile()` di ConcimiView chiuderebbe l'ultimo buco noto?
