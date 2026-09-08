---
target: EditPiantaView.vue
total_score: 21
max_score: 40
na_heuristics: 
p0_count: 1
p1_count: 3
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/EditPiantaView.vue"
target_fingerprint: "sha256:2ccabffa38066973ef18445e0d41f052b6e2b3568133b9268ec79c7f44fe1bb5"
target_path: /Users/rob/Sites/localhost/giardino/src/views/EditPiantaView.vue
timestamp: 2026-09-08T14-40-30Z
slug: src-views-editpiantaview-vue
---
## Design Health Score — EditPiantaView.vue

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2/4 | Nessun indicatore durante il caricamento iniziale in modifica |
| 2 | Match System/Real World | 4/4 | Vocabolario coerente con come pensa un giardiniere |
| 3 | User Control and Freedom | 2/4 | Nessun avviso modifiche non salvate, nessun Annulla esplicito |
| 4 | Consistency and Standards | 1/4 | Rosa su salvataggio, select nativo invece di icona zona, toggle senza aria-pressed |
| 5 | Error Prevention | 2/4 | Bottone disabilitato su campi obbligatori, ma sottozona non si azzera al cambio zona |
| 6 | Recognition Rather Than Recall | 2/4 | Pill vaso/terra/acqua solo icona, tooltip non scatta su touch |
| 7 | Flexibility and Efficiency | 3/4 | Filtro sottozona per zona riduce carico di memoria |
| 8 | Aesthetic and Minimalist Design | 3/4 | Card pulite, incrinate dal select nativo fuori sistema |
| 9 | Error Recovery | 0/4 | salva() senza catch, salvataggio fallito invisibile |
| 10 | Help and Documentation | 2/4 | "Chiedi a Zorba" per specie mancante, nessun equivalente per zero zone |
| **Totale** | | **21/40** | **Accettabile, al limite basso** |

## Verdetto di specificità
LLM: split netto — SelettoreSpecie.vue autoriale (miniature ink-pooling, Fraunces, "Chiedi a Zorba"), il resto del form generico: Zona/Sottozona sono select nativi mentre ogni altra superficie dell'app usa icona+nome; nessun blocco <style> proprio.
Detector (exit 0, 2 advisory, stessa riga 58): design-system-radius (16px fuori scala), design-system-font-size (15px fuori scala) sullo stile inline del bottone salva. Nessuna eccezione approvata li copre. Nessun overlay visivo: nessuno strumento di automazione browser disponibile.

## Impressione generale
Form strutturalmente onesto (raggruppamento a card, filtro sottozona intelligente, corretta disciplina nel non reimplementare la conferma eliminazione) che tradisce identità visiva e affidabilità nei due punti che contano di più: bottone salva colorato come azione distruttiva, salvataggio fallito senza traccia.

## Cosa funziona
1. Disciplina di scope sull'eliminazione (delegata a ModalConferma condiviso).
2. Progressive disclosure nel campo specie (SelettoreSpecie collassa a nome+miniatura+link).
3. Filtro sottozona contestuale per zona scelta.

## Problemi prioritari

[P0] Salvataggio silenziosamente fallito — salva() (righe ~112-133) senza catch; una scrittura fallita sparisce nel nulla. Fix: try/catch con ref di errore locale mostrato vicino al bottone, form che resta compilato per il retry. Comando: /impeccable harden

[P1] Bottone salva rosa invece di salvia — riga 57, class="btn btn-rose" contraddice la Regola DESIGN.md "rosa mai su bottone di salvataggio". Fix: btn-rose -> btn-sage. Comando: /impeccable colorize

[P1] Zona/Sottozona select nativi invece di icona — righe 18-27, rompe la convenzione icona+nome usata ovunque altrove nell'app. Fix: selettore a icona che riusa store.iconaZona(). Comando: /impeccable adapt

[P1] form.sottozona non si azzera al cambio zona (bug integrità dati) — patch ottimistica locale scrive una sottozona mai persistita nel DB. Fix: watch su form.zona che azzera sottozona. Comando: /impeccable harden

[P2] Toggle coltivato_in senza aria-pressed, solo icona senza etichetta visibile — pattern gemello in ZoneView/SottozoneView già lo implementa. Fix: aggiungere aria-pressed e didascalie brevi. Comando: /impeccable harden

## Red flag per persona
Jordan: bottone "Aggiungi pianta" in rosa sulla prima azione; tendina Zona vuota senza via d'uscita se zero zone; icone senza didascalia visibile.
Sam: asterischi obbligatori senza aria-required; toggle coltivato_in senza aria-pressed; nessuna regione aria-live su errore di salvataggio.
Riley: doppio invio bloccato correttamente (positivo); cambio zona avanti e indietro riproduce il bug sottozona; rete interrotta durante il salvataggio colpisce il catch mancante, bottone si riabilita senza errore.

## Osservazioni minori
- Stile inline del bottone salva (riga 58) sovrascrive i token .btn con valori one-off, confermati fuori scala dal detector.
- Nessun blocco <style scoped> nel file, tutto affidato a stili inline.
- Nessun indicatore di caricamento durante onMounted in modifica.
- Nessun momento "Zorba conferma" al salvataggio riuscito.

## Domande provocatorie
- Il resto della pagina si leggerebbe ancora come intenzionale se Zona/Sottozona somigliassero a come appaiono ovunque altrove?
- L'aggiunta di una pianta è raggiungibile prima della creazione di una zona per un utente nuovo?
