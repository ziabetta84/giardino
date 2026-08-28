Elabora le richieste pendenti dell'assistente AI dalla coda `public/data/richieste-agente.json`.

## Procedura

1. Leggi `public/data/richieste-agente.json` e identifica tutte le richieste con `stato: "in_attesa"`
2. Se non ce ne sono, rispondi "Nessuna richiesta in attesa" e fermati
3. Per ogni richiesta in attesa:
   - Leggi `public/data/piante.json` per il contesto del giardino; per le specie, interroga la tabella `specie` su Supabase (MCP `execute_sql`, progetto `ncuhhsvtjwcolhpdxbkt`) per slug o nome — **non `public/data/specie.json`**, che è solo una copia di riserva offline e può essere disallineato (le scritture vanno tutte su Supabase dalla Fase 2)
   - Per `consiglio_concimazione`, leggi anche `public/data/concimi.json` (la dispensa dei concimi posseduti)
   - Per `revisione_specie`, vedi procedura dedicata sotto: **aggiorna anche la riga corrispondente nella tabella `specie` su Supabase**, non solo la risposta testuale
   - Per `pianifica_progetto`, vedi procedura dedicata sotto: **aggiorna anche `public/data/progetti.json`**, non solo la risposta testuale
   - Se la richiesta contiene una foto in base64, analizzala
   - Genera una risposta dettagliata e pratica, in italiano, specifica per il giardino di Centinarola (Fano, clima mediterraneo collinare)
   - Aggiorna la richiesta nel JSON: `stato: "completata"`, `risposta: { messaggio: "...", elaborata: "<ISO date>" }`
   - **Imposta `foto: null`**: una volta elaborata la richiesta la foto non serve più. Il campo `foto` in base64 può pesare centinaia di KB per immagine; lasciarlo fa crescere `richieste-agente.json` oltre 1MB, soglia oltre la quale l'API Contents di GitHub non restituisce più il contenuto inline e l'app smette di riuscire a leggerlo (errore "Unexpected end of JSON input" in saveJSON).
4. Salva `richieste-agente.json` aggiornato con `saveJSON` (via GitHub Contents API) oppure direttamente su disco se sei in locale — per `revisione_specie` applica nello stesso passaggio anche la modifica alla tabella `specie` su Supabase (MCP `apply_migration`), per `pianifica_progetto` salva anche `progetti.json`
5. Fai commit e push con messaggio "Elabora richieste agente pendenti"

## Formato risposta

La risposta deve essere:
- In italiano
- Pratica e concisa (max 200 parole)
- Specifica per il tipo di richiesta:
  - `identifica_specie`: vedi procedura dedicata sotto
  - `revisione_specie`: vedi procedura dedicata sotto
  - `consiglio_cura`: azione concreta con tempistiche per il clima marchigiano
  - `consiglio_concimazione`: vedi procedura dedicata sotto
  - `diagnosi`: causa probabile + rimedio immediato
  - `pianifica_progetto`: vedi procedura dedicata sotto
  - `altro`: risposta libera pertinente al contesto del giardino

## Procedura per `identifica_specie`

Prima di analizzare la foto, usa l'API di identificazione **PlantNet** come riscontro oggettivo (non come sostituto del tuo giudizio): decodifica il campo `foto` (base64) in un file temporaneo, poi:

```bash
curl -s -X POST "https://my-api.plantnet.org/v2/identify/all?api-key=$PLANTNET_API_KEY&lang=it&type=kt&nb-results=5" \
  -F "images=@/percorso/foto.jpg" \
  -F "organs=auto"
```

La chiave è in `PLANTNET_API_KEY` dentro `.env.local` (non versionato — leggila da lì, non chiederla all'utente). Usa i primi 3-5 candidati (`results[].species.scientificNameWithoutAuthor`, `results[].score`) come riferimento, ma decidi tu il risultato finale guardando comunque la foto: PlantNet è affidabile sulle specie botaniche "wild-type" ma meno su cultivar/varietà ornamentali specifiche, comuni in questo giardino. Se il tuo giudizio visivo diverge dal miglior candidato PlantNet, segnalalo esplicitamente nella risposta (es. "PlantNet suggerisce X con confidenza Y%, ma le caratteristiche nella foto sembrano più coerenti con Z"), invece di sceglierne uno in silenzio. Se la chiamata fallisce o restituisce risultati con score troppo bassi (es. sotto 0.2), procedi comunque con la sola analisi visiva senza bloccarti.

Oltre a nome comune, nome scientifico e caratteristiche distintive dalla foto, includi nella risposta una proposta di **fabbisogno NPK per ciascuna delle quattro stagioni** (primavera, estate, autunno, inverno), nello stesso formato usato nella tabella `specie` su Supabase (`"N-P-K"`, es. `"10-5-5"`, o indicando esplicitamente di lasciare il valore vuoto/null per le stagioni di riposo vegetativo — tipicamente l'inverno nel clima marchigiano — invece di descriverlo con del testo, dato che il form "nuova specie" si aspetta un numero o un campo vuoto, non una frase) — così, se l'utente aggiunge poi la specie tramite il form, ha già i valori pronti da inserire nella tabella invece di dover cercare altrove.

- Prima di proporre un valore, controlla se la specie identificata (o una molto simile) esiste già nella tabella `specie` su Supabase: se sì, usa lo stesso NPK già presente lì invece di inventarne uno diverso, per coerenza tra voci della stessa specie/categoria.
- Altrimenti, assegna il fabbisogno in base alla categoria botanica della pianta (lo stesso criterio già usato per popolare la tabella `specie`):
  - fogliame da interno → azoto prevalente (es. "20-10-10")
  - succulente/grasse → fabbisogno minimo, solo primavera (es. "5-5-5")
  - aromatiche mediterranee → scarso e bilanciato (es. "5-5-5")
  - aromatiche da foglia → azoto moderato (es. "10-5-5")
  - fiorite/perenni ornamentali → fosforo prevalente (es. "5-10-10")
  - da frutto → potassio prevalente (es. "5-10-15")
  - specie note per sensibilità a un nutriente specifico (es. l'avocado teme l'eccesso di fosforo) → tienine conto esplicitamente, preferendo un profilo azotato basso in fosforo invece del generico bilanciato
- Se non hai elementi sufficienti per una stima ragionevole (specie molto incerta o poco nota), ometti la proposta NPK invece di inventarne una a caso, e dillo nella risposta.

## Procedura per `revisione_specie`

L'utente indica una specie tramite il selettore del form (campo `specie` della richiesta, uno slug nella tabella `specie` su Supabase) e chiede di completare i campi mancanti o rivedere quelli già presenti — non serve indovinare la specie, è già identificata.

1. Leggi il record attuale con `execute_sql` (`select * from specie where slug = '<r.specie>'`, progetto `ncuhhsvtjwcolhpdxbkt`). Se lo slug non esiste più (es. rinominata o eliminata nel frattempo), dillo nella risposta e fermati per questa richiesta senza modificare nulla.
2. Per ogni campo vuoto/mancante (`descrizione`, `esigenze.luce/acqua/terreno`, `alert`, `manutenzione.irrigazione/concimazione/potatura/npk` per le quattro stagioni), proponi un valore usando la stessa categorizzazione botanica già in uso in questo file (fogliame da interno, succulente, aromatiche mediterranee/da foglia, fiorite/perenni ornamentali, da frutto) e lo stesso criterio per specie note per sensibilità particolari (es. l'avocado teme l'eccesso di fosforo).
3. Per i campi già presenti, correggili solo se c'è un'inconsistenza chiara (es. una schedulazione di concimazione reale per una stagione ma npk assente per la stessa stagione, un dato botanico palesemente errato) — non riscrivere valori plausibili solo per uniformarli a uno stile diverso: "revisiona" non vuol dire sovrascrivere tutto.
4. Se nel messaggio dell'utente (campo `messaggio`, opzionale) ci sono osservazioni dirette (es. "quest'inverno ha sofferto il freddo più del previsto"), tienine conto nella revisione.
5. Applica le modifiche con `apply_migration` (`update specie set ... where slug = '<slug>'`), append-only sui campi array/jsonb dove ha senso (`alert`, `fonti`) invece di sovrascrivere — stesso criterio di `fonti/criterio-importazione.md`. Cita la fonte in `fonti` (es. `"Revisione utente via /elabora — <data>"` se la correzione viene da un'osservazione diretta dell'utente). Fallo nello stesso passaggio in cui salvi `richieste-agente.json`.
6. Nella risposta, riassumi in italiano cosa hai aggiunto/corretto e perché (elenco puntato per campo), così l'utente ha un resoconto leggibile senza dover confrontare il record a mano. Se non c'era nulla da aggiungere o correggere, dillo esplicitamente invece di inventare modifiche cosmetiche.

## Procedura per `consiglio_concimazione`

L'utente chiede quale concime usare per una pianta (es. "che concime uso per la mia Passiflora?"). La logica di suggerimento nell'app (`src/composables/useConcimi.js`) confronta i concimi in dispensa con il fabbisogno NPK della specie **per rapporto**, non per concentrazione assoluta: usa lo stesso identico criterio, per coerenza con quanto l'utente vede già nelle Attività e nella scheda pianta.

1. Identifica la pianta/specie di cui parla il messaggio (per nome comune, nome scientifico, zona/sottozona menzionata) in `piante.json` e nella tabella `specie` su Supabase. Se il messaggio è ambiguo (più piante corrispondono, o nessuna), chiedi di specificare nella risposta invece di indovinare.
2. Determina la stagione corrente dalla data di elaborazione (primavera: mar-mag, estate: giu-ago, autunno: set-nov, inverno: dic-feb) e leggi `specie.manutenzione.npk[stagione]`. Se `manutenzione` o `npk` sono assenti/`null`, oppure il valore per la stagione non è nel formato `"N-P-K"` (es. `"5-10-10"`), tratta il fabbisogno come non presente.
3. Se non c'è un fabbisogno NPK per la stagione corrente: rispondi che al momento questa pianta non ha necessità di concimazione specifiche (o segnalalo se manca del tutto il dato NPK per quella specie, invitando eventualmente ad aggiungerlo tramite il form specie).
4. Altrimenti, confronta il rapporto richiesto con ciascun concime in `concimi.json` che ha un campo `npk: {n, p, k}` valido (salta le voci che ne sono prive):
   - Normalizza entrambi i rapporti (dividi ciascun valore per la somma n+p+k, così un concime "5-10-5" e uno "10-20-10" risultano equivalenti — è la concentrazione assoluta a incidere sul dosaggio, non sull'idoneità). Se la somma è 0 (es. concime "0-0-0", dato improbabile ma possibile in caso di errore di inserimento), imposta il rapporto normalizzato a 0 per tutti i componenti ({n: 0, p: 0, k: 0}) per evitare la divisione per zero, in coerenza con l'implementazione reale — non saltare la voce.
   - Calcola la distanza euclidea tra i due rapporti normalizzati
   - Individua il concime con distanza minore
5. Se nessun concime in dispensa ha un rapporto valido, se la distanza minima supera 0.15 (soglia usata anche in `useConcimi.js`), oppure la dispensa è vuota: nessun concime è abbastanza vicino. Dillo esplicitamente nella risposta e indica il rapporto NPK ideale da cercare quando ne acquista uno nuovo.
6. Altrimenti, indica per nome il concime consigliato dalla dispensa, il suo NPK, e conferma che è adatto alla stagione corrente.

## Procedura per `pianifica_progetto`

L'utente descrive un progetto (campo `messaggio`) e chiede di generarne le tappe. La richiesta indica in quale progetto scrivere tramite due campi alternativi:
- `progetto`: chiave esistente in `progetti.json` (l'utente ha scelto un progetto già creato da completare)
- `titolo_progetto`: solo se `progetto` è `null` — titolo per un progetto nuovo da creare da zero

Schema di riferimento per `progetti.json` (vedi anche `src/composables/useProgetti.js` e `src/views/ProgettoView.vue`):
```json
{
  "titolo": "string",
  "descrizione": "HTML semplice: solo <p>, <b>/<strong>, <i>/<em> — niente altri tag o attributi",
  "zona": "string libera, opzionale",
  "stato": "aperto | in_corso | completato | fallito | cancellato",
  "creato": "YYYY-MM-DD",
  "tappe": [
    { "data": "YYYY-MM-DD", "descrizione": "string", "esito": "atteso | riuscito | fallito | saltato" }
  ]
}
```
Non esiste un campo `scadenza` a parte: è sempre la data dell'ultima tappa, calcolata dall'app (`scadenzaCalcolata()` in `useProgetti.js`) — non c'è nulla da impostare qui.

`descrizione` è mostrata in pagina come HTML (editata tramite `MiniEditor.vue`, lo stesso usato per zone/sottozone): usa un paragrafo `<p>...</p>` per blocco logico (contesto, piano per zona, motivazioni, lista acquisti, ecc.) invece di un unico blocco di testo con `\n\n` — non è testo semplice.

1. **Se `progetto` è valorizzato**: leggi il record in `progetti.json`. Se la chiave non esiste più (rinominato o eliminato nel frattempo), dillo nella risposta e fermati per questa richiesta senza modificare nulla.
2. **Se `progetto` è `null`**: crea una nuova chiave `progetto-<timestamp in ms>` con `titolo: r.titolo_progetto`, `stato: "aperto"`, `creato` impostato alla data di elaborazione (YYYY-MM-DD), `tappe: []` — poi procedi come al punto successivo.
3. Genera le tappe dal `messaggio`, usando la stessa logica botanica/agricola già in uso per il resto dell'app (categorizzazione per tipo di pianta/coltura, stagionalità del clima marchigiano):
   - Ogni tappa ha una data stimata **a partire dalla data della richiesta** (campo `creata` della richiesta, non da quando la stai elaborando tu), una descrizione concreta e azionabile (cosa aspettarsi o cosa controllare/fare), ed `esito: "atteso"`.
   - Genera un numero di tappe proporzionato alla complessità descritta: indicativamente 2-4 per un intervento semplice su una singola pianta (es. una talea: ripresa attesa, prime foglie nuove), fino a una decina per un progetto stagionale con più colture/fasi (semine, trapianti, raccolte).
   - Se il messaggio riporta anche qualcosa già fatto (es. "ho tagliato due talee ieri"), aggiungi anche quella come tappa con `esito: "riuscito"` e la data corretta (non "atteso"), invece di ometterla.
4. **Se stai aggiungendo tappe a un progetto esistente**: non toccare le tappe già presenti (a meno che il messaggio non riporti esplicitamente un aggiornamento su una di esse, es. "la talea del progetto fittonia è marcita" — in quel caso aggiornane l'`esito` invece di aggiungerne una nuova identica). Aggiungi le nuove tappe generate e riordina l'intero array `tappe` per `data` crescente.
5. Aggiorna `descrizione` solo se il progetto è nuovo (usa una sintesi ordinata del `messaggio`, non necessariamente verbatim) o se `descrizione` era vuota; se il progetto esisteva già con una descrizione, non sovrascriverla.
6. `zona`: deducila dal messaggio se è chiaramente indicata (nome zona/sottozona coerente con `zone.json`/`sottozone.json`, o un riferimento generico tipo "orto", "soggiorno"); altrimenti lascia quella già presente (o `null` per un progetto nuovo senza indicazioni).
7. Salva `progetti.json` nello stesso passaggio di `richieste-agente.json`.
8. Nella risposta, elenca in italiano le tappe generate (data + descrizione), e se hai creato un nuovo progetto dillo esplicitamente con un link concettuale a dove trovarlo ("nuovo progetto creato: <titolo>").
