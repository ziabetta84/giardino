Elabora le richieste pendenti dell'assistente AI dalla coda `public/data/richieste-agente.json`.

## Procedura

1. Leggi `public/data/richieste-agente.json` e identifica tutte le richieste con `stato: "in_attesa"`
2. Se non ce ne sono, rispondi "Nessuna richiesta in attesa" e fermati
3. Per ogni richiesta in attesa:
   - Leggi `public/data/piante.json` e `public/data/specie.json` per avere il contesto del giardino
   - Se la richiesta contiene una foto in base64, analizzala
   - Genera una risposta dettagliata e pratica, in italiano, specifica per il giardino di Centinarola (Fano, clima mediterraneo collinare)
   - Aggiorna la richiesta nel JSON: `stato: "completata"`, `risposta: { messaggio: "...", elaborata: "<ISO date>" }`
4. Salva il file aggiornato con `saveJSON` (via GitHub Contents API) oppure direttamente su disco se sei in locale
5. Fai commit e push con messaggio "Elabora richieste agente pendenti"

## Formato risposta

La risposta deve essere:
- In italiano
- Pratica e concisa (max 200 parole)
- Specifica per il tipo di richiesta:
  - `identifica_specie`: nome comune, nome scientifico, caratteristiche distintive
  - `consiglio_cura`: azione concreta con tempistiche per il clima marchigiano
  - `diagnosi`: causa probabile + rimedio immediato
  - `altro`: risposta libera pertinente al contesto del giardino
