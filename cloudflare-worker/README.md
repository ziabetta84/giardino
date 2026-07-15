# Backend dell'assistente AI — riferimento da distribuire manualmente

`docs/js/agente.js` chiama `POST https://giardino.robertagenovese.workers.dev/agente/chat`,
lo stesso Worker Cloudflare già usato per il login GitHub (`/login`). Il codice
sorgente di quel Worker **non è in questo repository**, quindi `agente-worker.js`
qui accanto è solo un riferimento: va integrato manualmente nel progetto Worker
esistente, non verrà deployato da qui.

## Passi di deploy

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

## Azioni supportate

L'endpoint `/agente/chat` gestisce tre azioni tramite il campo `action` nel body:

- **(default, senza `action`)** chat libera e valutazione salute pianta: risposta testuale (`{ reply }`).
- **`identifica_specie`**: identifica una pianta da una foto e propone fino a 4 specie candidate. Usa il tool-use di Anthropic con `tool_choice` forzato per garantire una risposta strutturata (`{ candidati: [{nome, specieBotanica, confidenza, note}] }`) invece di dover fare parsing di testo libero.
- **`genera_scheda_specie`**: dato un nome di specie (scelto tra i candidati o inserito manualmente dall'utente), genera la scheda di cura completa nello stesso formato di un record in `docs/data/specie.json` (`{ scheda: {...} }`), sempre via tool-use.

Vedi i commenti in cima a `agente-worker.js` per il contratto esatto di richiesta/risposta di ciascuna azione.

## Note

- Il frontend invia il token GitHub già salvato in `localStorage` (lo stesso
  usato per leggere/scrivere `docs/data/*.json`) come `Authorization: Bearer`.
  Il Worker lo valida chiamando `GET https://api.github.com/user` prima di
  autorizzare la chiamata a pagamento verso Anthropic.
- Le foto per la valutazione salute pianta vengono ridimensionate/compresse
  lato client (`resizeImageForAgente` in `docs/js/agente.js`, max 1568px sul
  lato lungo, JPEG qualità 0.85) prima dell'invio, così anche gli scatti da
  smartphone (spesso 8-15MB) arrivano al Worker già leggeri; non serve alcuna
  configurazione aggiuntiva sul Worker per gestirle.
- Finché questo endpoint non è distribuito, `docs/agente.html` resta
  utilizzabile: l'azione "Cosa fare oggi" funziona comunque (non chiama il
  Worker), mentre chat libera e valutazione salute mostreranno un errore
  gestito ("Worker non raggiungibile").
