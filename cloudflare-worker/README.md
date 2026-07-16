# Backend dell'assistente AI

## Stato attuale: Worker sospeso, workaround "coda su GitHub" attivo

L'account Anthropic collegato al Worker (`giardino.robertagenovese.workers.dev`)
risulta bloccato lato Anthropic. In attesa che venga risolto, `docs/js/agente.js`
**non chiama più** l'endpoint `/agente/chat` descritto sotto: scrive invece le
richieste in coda in `docs/data/richieste-agente.json` e le lascia in stato
`"in_attesa"`. Non serve alcuna chiave API per questo workaround: le richieste
vengono elaborate da una sessione Claude Code con accesso in scrittura al
repo (invocata manualmente, o da una Routine schedulata oraria), che legge la
coda, genera la risposta con le proprie capacità di visione/testo, e la
riscrive nello stesso file con `stato: "completata"` (o `"errore"`).

### Schema di `docs/data/richieste-agente.json`

Dizionario keyed by id (`richiesta-<timestamp>-<random>`):

```json
{
  "richiesta-1737000000000-ab12c": {
    "tipo": "salute" | "identifica_specie" | "genera_scheda_specie" | "chat",
    "messaggio": "testo libero (chat) o istruzione",
    "contesto": { "...": "vedi docs/js/agente.js per il payload esatto per tipo" },
    "speciesName": "string|null",
    "foto": "uploads/richieste/<id>.jpg" | null,
    "stato": "in_attesa" | "completata" | "errore",
    "creata": "ISO 8601",
    "elaborata": "ISO 8601|null",
    "risposta": null | {
      "testo": "string",              // tipo: salute, chat
      "candidati": [{ "nome": "...", "specieBotanica": "...", "confidenza": "alta|media|bassa", "note": "..." }],  // tipo: identifica_specie
      "schedaTop": { "...": "stesso schema di specie.json" },  // tipo: identifica_specie, bozza per il primo candidato
      "scheda": { "...": "stesso schema di specie.json" },     // tipo: genera_scheda_specie
      "messaggio": "string"            // solo se stato === "errore"
    }
  }
}
```

Chi elabora la coda deve, per ogni richiesta `in_attesa`:
1. Leggere l'eventuale foto al path indicato in `foto` (immagine JPEG committata nel repo).
2. Generare la `risposta` in base al `tipo`.
3. Impostare `stato: "completata"` (o `"errore"` con `risposta.messaggio`) e `elaborata` con la data corrente.
4. **Eliminare il file foto** dal repo (per non far crescere le dimensioni), se presente.
5. Committare e pushare direttamente su `main` (nessuna PR: è un aggiornamento dati ricorrente, non una modifica di codice).

Il frontend (`docs/js/agente.js`) traccia in `localStorage` gli id delle
richieste inviate da quel browser e mostra il loro stato/esito nel pannello
"Le mie richieste" di `agente.html`, ricontrollando `richieste-agente.json` a
ogni refresh manuale.

---

## Riferimento storico: endpoint Worker (`agente-worker.js`)

Il resto di questo documento descrive l'endpoint `/agente/chat` originario,
tenuto come riferimento per il giorno in cui l'account Anthropic tornasse
utilizzabile (o se in futuro si preferisse un altro provider). **Non è
attualmente in uso.**

`agente-worker.js` in questa cartella non è deployato automaticamente: va
integrato manualmente nel progetto Worker esistente.

### Passi di deploy

1. **Copia la logica**: incolla il contenuto di `agente-worker.js` nel progetto
   del Worker esistente (o importalo come modulo), ed esponi `handleAgenteChat`
   sulla route `/agente/chat`, es. nel router principale:

   ```js
   import { handleAgenteChat } from "./agente-worker.js";
   // ...
   if (url.pathname === "/agente/chat") return handleAgenteChat(request, env);
   ```

2. **Aggiungi la chiave API come secret** (non committarla mai in chiaro):

   ```bash
   wrangler secret put ANTHROPIC_API_KEY
   ```

3. **(Opzionale) limita l'uso al proprietario del repo**, per evitare che chi
   trova l'URL consumi la tua chiave API:

   ```bash
   wrangler secret put ALLOWED_GITHUB_LOGIN   # es. "ziabetta84"
   ```

4. **Verifica il CORS**: `ALLOWED_ORIGIN` in `agente-worker.js` è impostato su
   `https://ziabetta84.github.io` (dominio di GitHub Pages). Aggiornalo se usi
   un dominio personalizzato.

5. **Deploy** con la normale procedura del progetto Worker (`wrangler deploy`).

### Azioni supportate

L'endpoint `/agente/chat` gestisce tre azioni tramite il campo `action` nel body:

- **(default, senza `action`)** chat libera e valutazione salute pianta: risposta testuale (`{ reply }`).
- **`identifica_specie`**: identifica una pianta da una foto e propone fino a 4 specie candidate. Usa il tool-use di Anthropic con `tool_choice` forzato per garantire una risposta strutturata (`{ candidati: [{nome, specieBotanica, confidenza, note}] }`) invece di dover fare parsing di testo libero.
- **`genera_scheda_specie`**: dato un nome di specie (scelto tra i candidati o inserito manualmente dall'utente), genera la scheda di cura completa nello stesso formato di un record in `docs/data/specie.json` (`{ scheda: {...} }`), sempre via tool-use.

Vedi i commenti in cima a `agente-worker.js` per il contratto esatto di richiesta/risposta di ciascuna azione.

### Note

- Il frontend invia il token GitHub già salvato in `localStorage` (lo stesso
  usato per leggere/scrivere `docs/data/*.json`) come `Authorization: Bearer`.
  Il Worker lo valida chiamando `GET https://api.github.com/user` prima di
  autorizzare la chiamata a pagamento verso Anthropic.
- Le foto per la valutazione salute pianta vengono ridimensionate/compresse
  lato client (`resizeImageForAgente` in `docs/js/agente.js`, max 1568px sul
  lato lungo, JPEG qualità 0.85) prima dell'invio, così anche gli scatti da
  smartphone (spesso 8-15MB) arrivano al Worker già leggeri.
