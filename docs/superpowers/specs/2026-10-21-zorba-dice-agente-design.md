# Zorba dice: l'agente AI in app — design

Data: 21/10/2026. Stato: approvato a sezioni in conversazione, da rivedere come documento.

## Obiettivo

Zorba risponde **dentro l'app**, in pochi secondi, alle richieste di "Zorba dice", con le regole oggi scritte in `.claude/commands/zorbadice.md` (tono, ambito, procedure per tipo, PlantNet, abbinamento NPK). Sostituisce la coda `public/data/richieste-agente.json` elaborata a mano con `/zorbadice`.

Criteri di successo:

- una richiesta tipica riceve risposta in app, con il testo che compare man mano, entro 10-30 s;
- la spesa resta sotto controllo con tre livelli di limite (per filo, per utente al mese, globale);
- i dati di un utente non sono mai visibili ad altri; il catalogo condiviso (`schede`) non è mai scritto dall'app;
- l'app resta presentabile a terzi (obiettivo di diffusione in `CLAUDE.md`): nessun elemento abbozzato, errori spiegati con garbo.

Fuori ambito: ricerca vettoriale (RAG con embedding), apprendimento automatico dai voti, chat libera senza tipi, rimozione del token GitHub per la galleria.

## Decisioni prese con l'utente

1. **Fili brevi**: ogni richiesta è un filo; l'utente può rispondere (anche con una foto) fino a **3 volte**, poi il filo si chiude.
2. **Limiti**: 3 repliche per filo; **30 risposte di Zorba al mese per utente** (contate per risposta, non per filo; il curatore non ha tetto); **limite di spesa di $20/mese** impostato nella console Anthropic.
3. **Modello per tipo**, fissato per tutto il filo dal tipo della richiesta iniziale:

   | Tipo | Modello |
   |---|---|
   | `identifica_specie`, `diagnosi` | `claude-opus-5-5` |
   | `segnalazione_scheda` (ex `revisione_specie`), `consiglio_cura`, `consiglio_concimazione`, `pianifica_progetto`, `altro` | `claude-sonnet-5-5` |

4. **`revisione_specie` diventa "Segnala un problema nella scheda"** (`segnalazione_scheda`): l'utente sceglie la voce del catalogo e scrive cosa non va; Zorba (Sonnet) dà subito un primo parere, senza mai dire che la scheda è stata corretta; la segnalazione, con il filo, va al curatore, che la elabora in locale con `/zorbadice` e ne imposta lo stato (in attesa / accolta / non accolta) con una nota visibile all'utente.
5. **Architettura**: una Supabase Edge Function con risposta in streaming (scelta tra tre: streaming, coda asincrona con Realtime, Claude Managed Agents).
6. **Niente RAG con embedding**: i dati sono strutturati e si recuperano esattamente con strumenti; 15.770 schede vettorizzate costerebbero ~90 MB su un margine di ~147 MB. Si può aggiungere in futuro come strumento.
7. **Feedback**: pollice su/giù su ogni risposta di Zorba, con motivo e commento facoltativi sul pollice giù.

## Stima dei costi (prezzi di listino, ottobre 2026)

Ipotesi: regole ~8.000 token in cache; dati letti dagli strumenti 3.000-5.000 token; foto ~2.000-2.500 token; uscita 1.500-3.000 token (ragionamento compreso); 2-3 chiamate API per risposta.

| Modello | Input / output per M token | Risposta tipica | Filo pieno (4 risposte) |
|---|---|---|---|
| Opus 5.5 | $4 / $20 (cache in lettura $0,20) | $0,10-0,15 | ~$0,50 |
| Sonnet 5.5 | $2 / $10 (cache in lettura $0,20) | $0,05-0,08 | ~$0,25 |

Con la ripartizione per tipo e lo storico reale (43 richieste da luglio, 55% di tipo Opus) la media è ~$0,09 per risposta; l'utente principale spende $1-3/mese; il caso peggiore di un utente al tetto è ~$4/mese. La stima va confermata dalla prova sul campo (vedi Verifiche).

## Architettura

```
App (AgenteView, ZorbaDiceSidebar)
  │  POST + stream (SSE)            ┌──────────────────────────┐
  └────────────────────────────────▶│ Edge Function `zorba`    │
                                    │  1. sessione + limiti    │──▶ Storage `zorba-foto` (privato)
                                    │  2. salva messaggio/foto │──▶ tabelle zorba_fili / zorba_messaggi
                                    │  3. PlantNet (se foto,   │──▶ my-api.plantnet.org
                                    │     identifica/diagnosi) │
                                    │  4. Claude + strumenti   │──▶ api.anthropic.com
                                    │  5. salva risposta+costo │──▶ Supabase con la sessione utente (RLS)
                                    └──────────────────────────┘
```

La funzione usa due client Supabase: uno **con il JWT dell'utente** per tutte le letture e per l'unica scrittura di dati del giardino (`salva_piano`), così l'RLS vale anche per Zorba; uno **service-role** solo per i campi che l'utente non deve poter scrivere (contatori di costo, stato della risposta, stato della segnalazione non lo scrive nessuno dall'app).

Il lavoro prosegue fino in fondo anche se il client si disconnette (`EdgeRuntime.waitUntil`): la risposta viene salvata e ritrovata nello storico.

## Dati

### `zorba_fili`

| Colonna | Note |
|---|---|
| `id` uuid pk | |
| `owner_id` uuid | default `auth.uid()`, FK `auth.users`, on delete cascade |
| `tipo` text | uno dei sette tipi (check) |
| `modello` text | fissato alla creazione dalla tabella sopra; null per i fili importati |
| `stato` text | `aperto` / `chiuso` |
| `voce` text | `t:<uuid>` / `c:<uuid>` per `segnalazione_scheda`; null altrimenti |
| `nome_voce` text | nome mostrato al momento della richiesta |
| `progetto_id` uuid | FK `progetti` on delete set null; per `pianifica_progetto` |
| `titolo_progetto` text | titolo di un progetto nuovo, finché non viene creato |
| `segnalazione_stato` text | `in_attesa` / `accolta` / `non_accolta`; solo per `segnalazione_scheda` |
| `segnalazione_nota` text | nota del curatore, visibile all'utente |
| `in_elaborazione` boolean | una risposta alla volta per filo |
| `ultima_lettura` timestamptz | per il pallino "risposta nuova" |
| `creato`, `aggiornato` timestamptz | |

### `zorba_messaggi`

| Colonna | Note |
|---|---|
| `id` uuid pk, `filo_id` FK on delete cascade, `owner_id` | |
| `ruolo` text | `utente` / `zorba` |
| `testo` text | per Zorba: il testo finale mostrato |
| `foto_path` text | percorso in Storage, al più una per messaggio |
| `esito` text | solo Zorba: `completata` / `in_corso` / `errore` |
| `strumenti` jsonb | solo Zorba: elenco degli strumenti usati con esito sintetico (per le righe di stato nello storico e per il debug), non i risultati completi |
| `input_token`, `output_token`, `cache_lettura_token`, `cache_scrittura_token` int, `costo_usd` numeric | solo Zorba, scritti dalla funzione |
| `voto` smallint (-1/1), `voto_motivo` text, `voto_commento` text, `votato_il` | solo sui messaggi di Zorba, scritti dall'utente |
| `creato` timestamptz | |

Permessi (RLS per `owner_id = auth.uid()`, come le altre tabelle dell'utente):

- `zorba_fili`: l'utente legge i propri; può aggiornare solo `ultima_lettura`. Inserimenti e altri aggiornamenti solo dalla funzione.
- `zorba_messaggi`: l'utente legge i propri; può aggiornare solo i campi `voto*` sui messaggi di Zorba. Inserimenti solo dalla funzione.
- Restrizioni per colonna con `grant update (colonne)` invece di policy più larghe.

### Foto

Bucket Storage privato `zorba-foto`, percorso `{owner_id}/{filo_id}/{id_messaggio}.jpg`; policy di lettura sul primo segmento del percorso = `auth.uid()`. L'app ridimensiona prima dell'invio (lato lungo 1.568 px, JPEG ~0,85). Nessuna foto nel database: è a 353 MB su 500.

### Curatore

`CURATORE_ID` (uuid) è un segreto della funzione: unico effetto, nessun tetto mensile. Le segnalazioni si leggono e aggiornano in locale con `/zorbadice` (accesso di servizio).

### Storico

Le 43 richieste di `richieste-agente.json` diventano 43 fili `chiuso`, ciascuno con il messaggio dell'utente e la risposta di Zorba (`esito = completata`, costi null). Le `revisione_specie` diventano `segnalazione_scheda` con `segnalazione_stato = accolta`. Le foto rimaste in base64 (se presenti) vanno in Storage. Poi `richieste-agente.json` non è più letto dall'app; il file resta nella storia di git.

## La funzione `zorba`

### Richiesta

`POST /functions/v1/zorba` con il JWT dell'utente:

```json
{ "filo_id": null,
  "nuovo": { "tipo": "diagnosi", "voce": null, "progetto_id": null, "titolo_progetto": null },
  "testo": "…", "foto": "<base64 jpeg opzionale>" }
```

Per una replica: `filo_id` valorizzato, `nuovo` assente. Per ritentare una risposta fallita: `{ "filo_id": "…", "riprova": true }`.

### Passi

1. Verifica sessione. Se `ZORBA_ATTIVO` è falso e l'utente non è `CURATORE_ID` → errore `in_pausa` (il curatore può provare la funzione anche in pausa).
2. Controlli (con il client service-role, in una funzione SQL che blocca la riga del filo per evitare due invii contemporanei):
   - filo dell'utente, `stato = aperto`, `in_elaborazione = false`;
   - repliche dell'utente nel filo < 4 messaggi utente in totale (1 iniziale + 3 repliche);
   - risposte di Zorba `completata` nel mese corrente (fuso Europe/Rome) < 30, salvo `CURATORE_ID`;
   - imposta `in_elaborazione = true`.
3. Salva il messaggio dell'utente e la foto in Storage.
4. Se c'è una foto e il tipo è `identifica_specie` o `diagnosi`: chiama PlantNet (identificazione o malattie, come in `zorbadice.md`) **prima** di Claude; i risultati entrano nel messaggio per Claude come riscontro, con l'istruzione di non nominare la fonte. Fallimento o punteggi < 0,2: si prosegue senza.
5. Costruisce la richiesta a Claude:
   - `system`: le regole (vedi sotto), in cache;
   - `messages`: il filo come testo (messaggi dell'utente con la loro foto, risposte finali di Zorba come testo semplice; nessun blocco di ragionamento o di strumenti dei turni precedenti: la cronologia è sempre solo in aggiunta, quindi compatibile con il controllo del ragionamento preservato);
   - in coda all'ultimo messaggio utente, un blocco con data di oggi, stagione e (per `segnalazione_scheda`) la voce scelta; per `pianifica_progetto` il progetto o il titolo nuovo;
   - `thinking: {type: "adaptive"}`, `output_config.effort: "medium"` per entrambi i modelli (da tarare con la prova sul campo);
   - `fallbacks: "default"` con la beta `server-side-fallback-2026-07-01`;
   - streaming.
6. Ciclo con gli strumenti, al più 8 passaggi; ogni chiamata a uno strumento manda al client una riga di stato.
7. Salva la risposta (`esito`, testo, strumenti, token, costo), `in_elaborazione = false`; se il filo ha raggiunto 4 messaggi utente, `stato = chiuso`.

Tempo massimo complessivo 120 s; `max_tokens` 8.000 per chiamata.

### Eventi in streaming (SSE)

`filo` (id del filo creato), `stato` (riga di stato, es. "guardo la foto…"), `testo` (frammento), `progetto` (id e titolo dopo `salva_piano`), `fine` (id del messaggio, risposte rimaste nel mese), `errore` (codice + messaggio per l'utente).

### Regole (prompt di sistema)

File accanto alla funzione, in `supabase/functions/zorba/regole/`: `tono.md`, `ambito.md` e un file per tipo. Contenuto preso da `zorbadice.md`, tolte le istruzioni su SQL, MCP, JSON, commit e UUID. `/zorbadice` rimanda agli stessi `tono.md` e `ambito.md`, così le regole di voce esistono in un solo posto. Il prompt di sistema è identico per tutti i tipi (resta in cache); la procedura del tipo corrente è indicata nel blocco in coda all'ultimo messaggio.

Nuova procedura `segnalazione_scheda`: leggere la voce con `cerca_catalogo`/`pianta`, valutare la segnalazione (plausibile, dubbia, non verificabile, con le ragioni), dire che passa a chi cura il catalogo, mai dire che la scheda è stata corretta, mai invitare l'utente a modificarla.

### Strumenti

Tutti con il client che porta il JWT dell'utente; definizioni con `strict: true`.

| Strumento | Cosa restituisce / fa |
|---|---|
| `piante_giardino` | indice compatto: id, nome mostrato, zona, sottozona, `coltivato_in` |
| `pianta(id)` | voce del catalogo (`catalogo_voci`), `ultima_cura` con giorni trascorsi, note, zona |
| `cerca_catalogo(testo)` | `cerca_catalogo` RPC, primi risultati con chiave, nome, nome scientifico, NPK |
| `consiglia_concime(pianta_id)` | NPK della stagione dalla voce, concimi dell'utente, migliore e distanza con la logica di `src/composables/useConcimi.js` |
| `meteo` | Open-Meteo per le coordinate di `settings` (ripiego `LOCATION_FALLBACK`): oggi e 7 giorni |
| `progetti` | progetti dell'utente con le tappe |
| `conversazioni_precedenti(testo)` | fili recenti dell'utente il cui testo contiene le parole cercate: data, tipo, estratto della domanda e della risposta (al più 5) |
| `salva_piano(...)` | **solo nei fili `pianifica_progetto`**: crea il progetto se nuovo (e aggiorna `zorba_fili.progetto_id`), aggiunge tappe, aggiorna l'esito di tappe esistenti, imposta descrizione/zona come da procedura; tutto in una chiamata |

La logica pura di `useConcimi.js` (`parseNPK`, `normalizza`, `distanza`, scelta del migliore) viene spostata in un modulo senza dipendenze da Vue, importato sia dall'app sia dalla funzione, con prove `node --test`.

Nessuno strumento cancella dati o scrive su `schede`, `taxa`, `cultivar`, `nomi_comuni`.

## Interfaccia

Struttura di `AgenteView.vue` invariata (form, dettaglio, storico nel Foglio, `ZorbaDiceSidebar.vue` da 1440 px).

- **Form**: stessi tipi; "Revisiona/completa specie" diventa "Segnala un problema nella scheda" (selettore della voce + testo obbligatorio). Riga "Questo mese ti restano N risposte di Zorba" (assente per il curatore); a zero il form è disattivato con la data di ripartenza. Via il blocco "Serve un token…".
- **Dettaglio = filo**: messaggi alternati (utente a destra, Zorba a sinistra con `ZorbaLogo`), foto nel filo, righe di stato durante il lavoro, testo che compare man mano; sotto ogni risposta i pollici (sul giù: motivi *Sbagliata*, *Poco chiara*, *Non c'entra*, *Troppo generica* e un commento facoltativo); in fondo il campo di risposta con testo e foto e "puoi rispondere ancora N volte"; a filo chiuso, "Questo filo è concluso" con un pulsante che apre una richiesta nuova dello stesso tipo. Per le segnalazioni, in alto stato e nota del curatore; per i progetti, dopo `salva_piano`, una scheda "Apri il progetto". Una riga discreta vicino ai pollici: le risposte valutate possono essere lette da chi cura Zorba.
- **Storico**: fili al posto delle richieste, stesse icone per tipo, pallino sui fili con una risposta più recente di `ultima_lettura`.
- **Offline**: storico consultabile (cache NetworkFirst già attiva sul REST di Supabase); invio disattivato con un messaggio.
- **Token GitHub**: il banner globale in `App.vue` si mostra solo in `GalleryView` (dove serve per i caricamenti); nessun altro lavoro su quel flusso.

La logica di dati e streaming sta in un composable `useZorba.js` (sostituisce `caricaRichiesteAgente` in `useRichiesteAgente.js`), usato da `AgenteView.vue` e `ZorbaDiceSidebar.vue`.

## Errori

Il messaggio dell'utente resta salvato; una risposta non riuscita non conta nel tetto.

| Caso | Comportamento |
|---|---|
| Claude sovraccarico / irraggiungibile | 2 tentativi automatici dell'SDK, poi "Zorba non riesce a rispondere adesso" + **Riprova** |
| Limite di spesa dell'organizzazione raggiunto | "Zorba è in pausa per questo mese"; evidenziato nel riepilogo di `/zorbadice` |
| `stop_reason: refusal` dopo il ripiego | messaggio garbato, nessun testo parziale mostrato |
| PlantNet non risponde | si prosegue con la sola analisi della foto |
| Client disconnesso | la funzione completa e salva |
| Funzione interrotta / tempo scaduto | `esito = errore`, `in_elaborazione = false` (anche al successivo invio se rimasto bloccato da più di 3 minuti), **Riprova** |
| Limiti raggiunti | errore esplicito prima di chiamare Claude, con il motivo |

## `/zorbadice` dopo il cambio

Diventa lo strumento del curatore:

1. **Segnalazioni** `in_attesa`: legge il filo (compreso il parere di Zorba), verifica, propone le modifiche alla scheda, le applica su `schede` dopo l'approvazione dell'utente (stessa procedura dell'attuale `revisione_specie`, passo 5), imposta `segnalazione_stato` e `segnalazione_nota`.
2. **Voti negativi** del periodo, con il filo.
3. **Spesa del mese** per tipo e modello, risposte in errore, utenti al tetto.

Le procedure per gli altri tipi passano nei file `regole/` della funzione.

## Segreti e configurazione

Segreti della funzione: `ANTHROPIC_API_KEY`, `PLANTNET_API_KEY`, `CURATORE_ID`, `ZORBA_ATTIVO`. Prima del rilascio l'utente crea una chiave Anthropic valida (quella in `.env.local` risponde 401) e imposta nella console il limite di spesa di $20/mese.

## Verifiche

1. **Prove automatiche** (`node --test` / `deno test`): logica NPK condivisa, conteggio dei limiti, costruzione dei messaggi per Claude dal filo, strumenti con un client Supabase finto, ciclo con un client Anthropic finto (strumenti, errori, rifiuto).
2. **Prove dei permessi** (script SQL in transazione annullata, come per le fasi della tassonomia): un utente non legge fili, messaggi e foto di un altro; dall'app non si inseriscono messaggi, non si scrivono costi né `segnalazione_stato`; i voti si scrivono solo sui propri messaggi di Zorba.
3. **Prova sul campo**: 10 richieste storiche reali (identificazioni, una diagnosi, un progetto su un progetto di prova, una concimazione, una segnalazione) sulla funzione pubblicata; confronto con le risposte di allora per tono e correttezza; costo reale misurato contro la stima (~$1).
4. **Verifica nel browser**, telefono e schermo largo: filo completo con repliche e chiusura, foto, pollici, tetto raggiunto, offline, errore simulato con Riprova.

## Ordine di rilascio

1. Migration (tabelle, permessi, bucket) e importazione dello storico.
2. Funzione pubblicata con `ZORBA_ATTIVO = false`, segreti impostati, prova sul campo con il solo account curatore.
3. App nuova pubblicata; `ZORBA_ATTIVO = true`.
4. `/zorbadice` e `CLAUDE.md` aggiornati.
