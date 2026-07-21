Elabora le richieste pendenti dell'assistente AI dalla coda `public/data/richieste-agente.json`.

## Procedura

1. Leggi `public/data/richieste-agente.json` e identifica tutte le richieste con `stato: "in_attesa"`
2. Se non ce ne sono, rispondi "Nessuna richiesta in attesa" e fermati
3. Per ogni richiesta in attesa:
   - Leggi `public/data/piante.json` e `public/data/specie.json` per avere il contesto del giardino
   - Per `consiglio_concimazione`, leggi anche `public/data/concimi.json` (la dispensa dei concimi posseduti)
   - Se la richiesta contiene una foto in base64, analizzala
   - Genera una risposta dettagliata e pratica, in italiano, specifica per il giardino di Centinarola (Fano, clima mediterraneo collinare)
   - Aggiorna la richiesta nel JSON: `stato: "completata"`, `risposta: { messaggio: "...", elaborata: "<ISO date>" }`
   - **Imposta `foto: null`**: una volta elaborata la richiesta la foto non serve più. Il campo `foto` in base64 può pesare centinaia di KB per immagine; lasciarlo fa crescere `richieste-agente.json` oltre 1MB, soglia oltre la quale l'API Contents di GitHub non restituisce più il contenuto inline e l'app smette di riuscire a leggerlo (errore "Unexpected end of JSON input" in saveJSON).
4. Salva il file aggiornato con `saveJSON` (via GitHub Contents API) oppure direttamente su disco se sei in locale
5. Fai commit e push con messaggio "Elabora richieste agente pendenti"

## Formato risposta

La risposta deve essere:
- In italiano
- Pratica e concisa (max 200 parole)
- Specifica per il tipo di richiesta:
  - `identifica_specie`: nome comune, nome scientifico, caratteristiche distintive
  - `consiglio_cura`: azione concreta con tempistiche per il clima marchigiano
  - `consiglio_concimazione`: vedi procedura dedicata sotto
  - `diagnosi`: causa probabile + rimedio immediato
  - `altro`: risposta libera pertinente al contesto del giardino

## Procedura per `consiglio_concimazione`

L'utente chiede quale concime usare per una pianta (es. "che concime uso per la mia Passiflora?"). La logica di suggerimento nell'app (`src/composables/useConcimi.js`) confronta i concimi in dispensa con il fabbisogno NPK della specie **per rapporto**, non per concentrazione assoluta: usa lo stesso identico criterio, per coerenza con quanto l'utente vede già nelle Attività e nella scheda pianta.

1. Identifica la pianta/specie di cui parla il messaggio (per nome comune, nome scientifico, zona/sottozona menzionata) in `piante.json`/`specie.json`. Se il messaggio è ambiguo (più piante corrispondono, o nessuna), chiedi di specificare nella risposta invece di indovinare.
2. Determina la stagione corrente dalla data di elaborazione (primavera: mar-mag, estate: giu-ago, autunno: set-nov, inverno: dic-feb) e leggi `specie.manutenzione.npk[stagione]`. Se `manutenzione` o `npk` sono assenti/`null`, oppure il valore per la stagione non è nel formato `"N-P-K"` (es. `"5-10-10"`), tratta il fabbisogno come non presente.
3. Se non c'è un fabbisogno NPK per la stagione corrente: rispondi che al momento questa pianta non ha necessità di concimazione specifiche (o segnalalo se manca del tutto il dato NPK per quella specie, invitando eventualmente ad aggiungerlo tramite il form specie).
4. Altrimenti, confronta il rapporto richiesto con ciascun concime in `concimi.json` che ha un campo `npk: {n, p, k}` valido (salta le voci che ne sono prive):
   - Normalizza entrambi i rapporti (dividi ciascun valore per la somma n+p+k, così un concime "5-10-5" e uno "10-20-10" risultano equivalenti — è la concentrazione assoluta a incidere sul dosaggio, non sull'idoneità). Se la somma è 0 (es. concime "0-0-0", dato improbabile ma possibile in caso di errore di inserimento), imposta il rapporto normalizzato a 0 per tutti i componenti ({n: 0, p: 0, k: 0}) per evitare la divisione per zero, in coerenza con l'implementazione reale — non saltare la voce.
   - Calcola la distanza euclidea tra i due rapporti normalizzati
   - Individua il concime con distanza minore
5. Se nessun concime in dispensa ha un rapporto valido, se la distanza minima supera 0.15 (soglia usata anche in `useConcimi.js`), oppure la dispensa è vuota: nessun concime è abbastanza vicino. Dillo esplicitamente nella risposta e indica il rapporto NPK ideale da cercare quando ne acquista uno nuovo.
6. Altrimenti, indica per nome il concime consigliato dalla dispensa, il suo NPK, e conferma che è adatto alla stagione corrente.
