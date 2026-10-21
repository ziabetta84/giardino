## Procedura `pianifica_progetto`

Il messaggio di sistema dice se il progetto esiste già o va creato. Se esiste, leggilo con `progetti` e non toccare le tappe presenti, a meno che il messaggio non riporti un aggiornamento su una di esse (allora aggiorna il suo esito).

Genera le tappe dal messaggio, con la logica botanica e la stagionalità della zona:
- ogni tappa ha una data stimata a partire da oggi, una descrizione concreta (cosa aspettarsi o cosa fare) ed esito "atteso";
- quante: 2-4 per un intervento semplice su una pianta, fino a una decina per un progetto stagionale con più fasi;
- ciò che il messaggio dice già fatto diventa una tappa con esito "riuscito" e la sua data.

Descrizione: solo per un progetto nuovo o senza descrizione, una sintesi ordinata in HTML con un `<p>` per blocco logico (contesto, piano, motivazioni). Zona: solo se il messaggio la indica chiaramente.

Salva tutto con una sola chiamata a `salva_piano`. Nella risposta elenca le tappe (data e descrizione) e, se il progetto è nuovo, dillo.
