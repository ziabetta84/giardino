# Nuovo modello tassonomico — specifica

Data: 13/10/2026 · Stato: approvata dall'utente il 13/10/2026, rivista lo stesso giorno dopo la verifica tecnica (vedi "Decisioni dopo la verifica"). Nessuna modifica al database prima dell'approvazione del piano di ciascuna fase.

## Perché

Lo scopo iniziale era permettere a chi non conosce il nome scientifico di trovare la propria pianta col nome italiano. Il lavoro sui nomi (lotti 1–13, generi, doppioni) ha seguito un modello in cui `specie.nome` è contemporaneamente identità della riga (UNIQUE) e nome mostrato, e in cui le cultivar venivano rinominate una per una. Ne sono derivate collisioni, righe "Genere spp." con contenuti di specie, decine di migration correttive e incoerenze (es. "Calendola"/"Calendula", righe di genere in latino con cultivar in italiano). Questa specifica sostituisce quell'approccio con un modello basato sulle convenzioni di chi fa questo lavoro (codici internazionali, Catalogue of Life, RHS), senza perdere il lavoro di contenuto già fatto.

Scopi dell'app che il modello deve servire:

1. l'utente trova la sua pianta col nome che conosce (italiano, scientifico, vecchio nome, nome della cultivar);
2. l'utente gestisce le cure delle sue piante;
3. l'agente AI ha una base di informazioni solida, con fonte e livello di ogni dato registrati nel database (la fonte non viene mai mostrata all'utente).

## Fonti e regole adottate (non scelte nostre)

- **Nomi scientifici e gerarchia: Catalogue of Life Extended Release (COL XR)**, CC BY 4.0. GBIF ha adottato COL XR come tassonomia predefinita; il vecchio GBIF Backbone è fermo al 2023 e non verrà più aggiornato ([GBIF Data Blog, 23/06/2026](https://data-blog.gbif.org/post/catalogue-of-life-taxonomic-backbone/)). Accesso: API GBIF con `checklistKey=7ddf754f-d193-4cc9-b351-99906754a03b` (es. `https://api.gbif.org/v2/species/match?scientificName=…&checklistKey=…`) oppure download completo (ColDP: `https://download.checklistbank.org/col/xr_latest_coldp.zip`; DwC-A: `https://download.checklistbank.org/col/xr_latest_dwca.zip`; entrambi con i nomi comuni, ma solo ColDP ne riporta la fonte). Identificatori alfanumerici (es. `72ZGR`); esiste una mappa dalle vecchie chiavi intere GBIF (`https://download.checklistbank.org/col/gbif/README.html`), utile perché `generi.gbif_key` usa le vecchie chiavi.
- **Ibridi (ICN)**: gli ibridi con nome sono taxon normali. In COL XR *Mentha × piperita* è una specie accettata (rango SPECIES) con "×" nel nome. L'API di GBIF non ha un campo "ibrido", ma il formato ColDP sì (`notho`); non tutti i notogeneri però sono marcati (vedi "Decisioni dopo la verifica"). I notogeneri (*× Fatshedera*) sono generi.
- **Cultivar (ICNCP, 9ª edizione, 2016, Scripta Horticulturae 18)**:
  - Art. 21.1: il nome di una cultivar è il nome del genere *o di un taxon inferiore* a cui è assegnata, *oppure il suo nome comune non ambiguo*, più l'epiteto (es. "snowdrop 'John Gray'" per *Galanthus* 'John Gray'). Quindi "Bucaneve 'John Gray'" è un nome corretto, purché il nome comune non sia ambiguo.
  - Art. 32.1: l'epiteto di una cultivar **non si traduce**.
  - Art. 21.4: l'epiteto non cambia se cambia il taxon a cui la cultivar è assegnata.
  - Art. 6.2: l'epiteto è unico all'interno della "classe di denominazione", di norma il genere: per questo molte cultivar sono assegnate solo al genere (pratica RHS).
  - Art. 22.1: i Gruppi (es. *Brassica oleracea* Gruppo Capitata) sono un livello tra taxon e cultivar.
  - Art. 13.1: i nomi commerciali non sono nomi regolati dal codice e vanno tenuti distinti dall'epiteto.
- COL XR non contiene cultivar: per *Hedera helix* 'Goldchild' l'API risponde con la specie (match HIGHERRANK, verificato il 13/10/2026). Le cultivar restano dati nostri, da RHS.

## Principi

1. **Nessun contenuto si perde.** La tabella `specie` attuale resta intatta e diventa la fonte da cui si copia; si spegne solo dopo la verifica completa, e resta comunque in sola lettura.
2. **Migrazione additiva.** Tabelle nuove accanto a quelle vecchie; l'app passa alle nuove solo alla fine.
3. **Identità ≠ nome mostrato.** L'identità è il taxon (COL XR) o la cultivar; il nome mostrato si calcola e non si salva riga per riga.
4. **Ogni dato ha una fonte.** Nomi comuni, schede e assegnazioni portano la fonte; le scelte dell'utente sono registrate come fonte "scelta dell'utente".
5. **Niente nomi inventati.** Dove non c'è un nome comune da una fonte, si mostra il nome scientifico.

## Modello dati

Rivisto il 13/10/2026 dopo la verifica tecnica (schema del database, convenzioni del repository, prove sulle API di COL e ChecklistBank). Le decisioni prese in quella revisione sono elencate in "Decisioni dopo la verifica".

### `taxa` — da COL XR, più i taxon locali
`id` (chiave nostra, uuid), `origine` (`col` oppure `locale`), `col_id` e `versione_col` (identificatore e rilascio COL, solo per `origine = col`), `rango` e `stato` (vocabolari di COL, in inglese, così come sono: per esempio `genus`, `species`, `tribe`; `accepted`, `synonym`, `ambiguous synonym`…), `nome_scientifico` (senza autore), `autore`, `notho` (parte ibrida del nome secondo ColDP: `generic`, `specific`…), `ibrido` (calcolato da `notho` o dal "×"), `accettato_id` (per i sinonimi), `padre_id` (padre nella classificazione COL, compresi i ranghi intermedi come tribù e sottofamiglia), `nota`, `importato_il`. I taxon COL non si modificano a mano: si aggiornano solo reimportando. I taxon `locale` servono per i nomi che COL non contiene (ibridi senza nome, notogeneri non riconosciuti come × Fatshedera), così che ogni contenuto abbia un posto.

### `nomi_comuni`
`taxon_id`, `lingua` (codice ISO a due lettere, `it`, come `lingua_descrizione`), `nome`, `preferito` (al più uno per taxon e lingua), `fonti` (elenco: lo stesso nome può venire da più fonti, es. iNaturalist e PlantNet), `nota`. Un nome compare una sola volta per taxon e lingua. Qui confluiscono tutti i nomi italiani raccolti finora (lotti 1–13, `nomi_alternativi`, `generi.nome`, deroghe dell'utente), ciascuno con le fonti ricostruite dalle migration dei lotti. Le scelte dell'utente hanno fonte `curatore`.

### `cultivar`
`id`, `slug` (quello attuale, per non rompere riferimenti), `taxon_id` (taxon più basso noto: specie, ibrido o genere, come da fonte RHS), `categoria` (cultivar, gruppo, grex), `epiteto` (senza apici), `gruppo` (facoltativo), `nome_commerciale` (facoltativo), `fonti`, `vecchia_specie_id`.

### `schede` — il contenuto
`id`, `taxon_id` **oppure** `cultivar_id` (esattamente uno), `fonti` (l'elenco della riga di origine, copiato così com'è: 5.037 righe attuali hanno da 2 a 4 fonti in un unico testo, e non si separano), `descrizione`, `descrizione_originale`, `lingua_descrizione`, `esigenze`, `manutenzione`, `ciclo_colturale`, `ciclo_vitale`, `vaso`, `alert`, `immagine`, `stato_verifica`, `verificata_il`, `verificata_da`, `mostrata` (al più una per taxon o cultivar), `vecchia_specie_id`, `creata_il`, `aggiornata_il`. Più schede per lo stesso taxon sono ammesse (es. enciclopedia e PFAF): nessuna fusione automatica di testi.

### `mappa_specie` — tracciabilità
Una riga per ogni riga **non cultivar** della vecchia `specie` (specie, generi, ibridi): 15.713 righe, cioè le 15.678 senza apici nel nome (tutte senza madre) più le 35 madri cancellate in questa sessione e recuperate dai file di rollback (`origine = rollback`). Le 45 righe con apici ma senza madre sono cultivar (decisione 6 dopo la verifica) e vanno nella tabella `cultivar`; il «circa 15.760» della prima stima le contava. Le cultivar non hanno una riga di mappa: restano rintracciabili da `cultivar.vecchia_specie_id` (deciso il 14/10/2026 per lo spazio, vedi "Decisioni sullo spazio"). Fanno eccezione le 4 cultivar doppie cancellate, che non hanno una riga di `cultivar`: hanno una riga di mappa che punta alla cultivar rimasta, inserita nella fase 4. Colonne: `vecchia_specie_id` (senza vincolo verso `specie`, perché alcune righe non esistono più), `vecchio_slug`, `vecchio_nome_scientifico`, `taxon_id` o `cultivar_id` (al più uno), `esito` (esatto, variante, sinonimo, rango superiore, ambiguo, ibrido, non trovato, deciso dall'utente), `nota`. Le righe si inseriscono già elaborate, con l'esito, in un solo passaggio: un aggiornamento di massa successivo raddoppierebbe lo spazio della tabella. È l'elenco che l'utente rivede per i casi dubbi. Non è leggibile dall'app.

### `piante`
Si aggiungono `taxon_id` e `cultivar_id`. Fino alla fase 6 sono facoltative (al più una delle due), perché l'app attuale non le compila; dalla fase 6 diventano obbligatorie (esattamente una). Puntare a un genere è legittimo quando la specie non è certa. La colonna `specie` resta finché l'app non è passata al nuovo modello.

### Permessi
- Lettura pubblica (come oggi per `specie`) di `taxa`, `nomi_comuni`, `cultivar` e `schede`, **escluse le colonne interne**: fonti, note, identificatori e versioni COL, origine, `descrizione_originale`, `verificata_da`, `vecchia_specie_id`. La regola "la fonte non si mostra mai" vale quindi anche per chi interroga il database con la chiave pubblica, non solo per l'app, per le colonne dedicate; le fonti citate dentro i testi vanno tolte nella fase 4 (vedi "Decisioni dopo la verifica", punti 11 e 12).
- Nessuna scrittura per i client (anon, authenticated): scrivono solo gli script e le migration con service-role o `postgres`.
- `mappa_specie` non è leggibile dai client.
- I permessi sono scritti in modo esplicito nella migration: da Supabase, dal 30/10/2026 le tabelle nuove non ricevono più i permessi automatici, e oggi ne ricevono troppi.

## Regole di presentazione

- **Nome mostrato di un taxon**: nome comune preferito in italiano; se manca, nome scientifico canonico.
- **Nome mostrato di una cultivar** (Art. 21.1): nome comune preferito del suo taxon + `'Epiteto'`, ma solo se quel nome comune non è il preferito anche di un altro taxon (nome "non ambiguo"); altrimenti nome scientifico del taxon + `'Epiteto'`. L'epiteto non si traduce mai.
- **Ricerca**: nomi comuni (tutti, non solo i preferiti), nomi canonici inclusi i sinonimi, epiteti e nomi commerciali delle cultivar. Indici trigram come oggi.
- **Eredità delle schede**: se una cultivar non ha una scheda mostrata, si usa quella del suo taxon, poi del padre (sinonimo → accettato, specie → genere). L'app indica solo il livello ("cure del genere *Hedera*").
- **Fonti solo nel database**: nel frontend la fonte non si nomina mai (né nella pagina della pianta, né nel selettore, né nelle risposte dell'agente). Resta un dato interno, usato per tracciabilità, revisione e per pesare l'affidabilità delle informazioni.

## Migrazione dei contenuti

Inventario attuale (13/10/2026, sola lettura): 15.723 righe madri (15.632 con descrizione, 11.675 con descrizione originale, 14.432 con esigenze, 8.755 con manutenzione, 7.722 con immagine, 9.552 verificate, 3.178 con nome italiano, 2.686 con nomi alternativi, 11.811 con sinonimi botanici) e 196.343 cultivar (12 con descrizione, 98.061 con nome italiano calcolato dai lotti). Fonti più presenti: RHS (208.139 citazioni), PFAF (8.461), enciclopedie fotografate (circa 650 tra Edicart, Demetra, De Vecchi/Giunti, collana Fiori & Piante), più alcune singole. Le piante dell'utente sono 122 su 93 righe.

Regole:

- Ogni riga madre con contenuto genera una scheda, attaccata al taxon della sua corrispondenza. Le righe "Genere spp." classificate come contenuto di specie (`scripts/nomi-italiani/dati/`, classificazione già approvata) generano la scheda sulla specie, le altre sul genere.
- Le righe doppione (stesso taxon) generano più schede sullo stesso taxon; la scheda mostrata è quella verificata, altrimenti la più recente; l'utente può cambiarla.
- I nomi italiani attuali (`nome` ≠ `nome_scientifico`) e i `nomi_alternativi` diventano righe di `nomi_comuni`; il nome attuale è il preferito.
- Le cultivar diventano righe di `cultivar` con l'epiteto estratto dal nome scientifico; il nome italiano salvato dai lotti non si copia (si calcola).
- Le righe cancellate in questa sessione (32 doppioni bozza, `agapanthus`, `jasminum-officinale`, `daucus-carota`, 4 cultivar doppie) vengono lette dai file di rollback e non reinserite in `specie`: le 35 madri entrano come schede, le 4 cultivar (senza contenuto) solo come righe di `mappa_specie`.
- **Verifica**: lo stesso inventario, per fonte e per campo, ricalcolato sulle tabelle nuove deve dare gli stessi numeri (o differenze spiegate una per una).

## Fasi

Ogni fase ha backup, prova e verifica; l'app continua a funzionare fino alla fase 7. I caricamenti in blocco delle fasi 2–4 si provano su una copia locale del database, non in una transazione annullata sul database reale, che occuperebbe lo stesso spazio e lo stesso WAL del caricamento vero (vedi "Decisioni sullo spazio").

1. Creare le tabelle nuove, vuote (nessun effetto sull'app).
   - **1b. Manutenzione di `specie`** (prima della fase 2): backup completo con prova di ripristino in locale, poi compattazione della tabella (`VACUUM FULL`) dopo aver tolto i 4 indici trigram, ricreati subito dopo. I dati non cambiano.
2. Scaricare COL XR e importare in `taxa` solo il necessario.
3. Abbinare le righe madri ai taxon e compilare `mappa_specie` (solo righe non cultivar); l'utente rivede solo l'elenco dei casi non esatti.
4. Popolare `cultivar`, `nomi_comuni`, `schede`; inventario di verifica.
5. Abbinare le 122 piante (ogni pianta controllata con l'utente).
6. Adattare l'app (store, selettore, pagina pianta, fallback offline, ricerca) e le istruzioni dell'agente (`/zorbadice`) leggendo dalle tabelle nuove; verifica nel browser.
7. Passaggio definitivo: l'app usa solo le tabelle nuove; `specie` e `generi` restano in sola lettura come archivio. Si potranno allora togliere gli indici di ricerca dell'archivio (33,6 MB, reversibile), con l'approvazione dell'utente.

Ogni fase avrà il suo piano; questa specifica copre il modello e l'ordine.

## Fuori da questa specifica

- Correzioni ai nomi o ai contenuti delle righe attuali: sospese, salvo urgenze.
- Nomi commerciali e Gruppi: si riempiono solo se presenti nei dati RHS già scaricati.
- Allineamento della cronologia delle migration Supabase (`schema_migrations`): resta un punto separato.

## Decisioni prese con l'utente (approvate il 13/10/2026)

1. Usare COL XR invece del vecchio GBIF Backbone (raccomandato: il Backbone non è più aggiornato).
2. Regola del nome mostrato delle cultivar (nome comune non ambiguo + epiteto, Art. 21.1).
3. Dove lavorare il file di COL XR (in locale, fuori dal repository).
4. Le deroghe già decise (5 nomi del lotto 12, Calendula, Edera, Elleboro) restano come nomi comuni con fonte "scelta dell'utente".

## Decisioni dopo la verifica (13/10/2026)

Prese durante la stesura del piano della fase 1, dopo la verifica tecnica; correggono punti della prima versione di questa specifica.

1. **Chiave di `taxa`**: chiave nostra, non l'identificatore COL. Verificato che gli identificatori COL cambiano tra rilasci mensili anche per nomi accettati (genere Fatshedera: NS8CW → 8WFRN) e che un identificatore può passare a un nome diverso (R9FW: da *Carex glomerata* Host a *Carex glomerata* Thunb.). `col_id` resta come attributo e a ogni reimport si confrontano nome e autore.
2. **Una sola versione di COL di riferimento**: l'API di GBIF usa oggi COL 26.6 XR, la mappa ufficiale GBIF→COL la 26.5, il file scaricabile la 26.9. Ogni identificatore preso da GBIF o dalla mappa va ricontrollato sulla versione scelta.
3. **Taxon locali** per i nomi che COL non contiene, invece di contenuti senza taxon.
4. **Vocabolari di COL così come sono** (rango e stato in inglese) e catena dei padri completa: in COL il padre di un genere è spesso una tribù o una sottofamiglia (*Rosa* > Roseae > Rosoideae > Rosaceae).
5. **Ibridi**: il campo `notho` di ColDP esiste, ma non tutti i notogeneri sono marcati (× Fatshedera no, × Chitalpa sì): i casi non marcati si correggono come taxon locali.
6. **Le cultivar si riconoscono dal nome** (epiteto tra apici), non dal tipo di corrispondenza restituito da GBIF, che cambia con i parametri.
7. **Nomi comuni da COL**: sono pochi in italiano (35.572 in tutto il catalogo, nessuno per pomodoro o rosmarino) e senza indicazione di preferito; entrano come fonte in più, non sostituiscono quelli raccolti.
8. **Campi della vecchia tabella senza posto nel nuovo modello**: `famiglia_botanica` si ricava dalla catena dei padri; `sinonimi_botanici` e `nome_accettato` (da GBIF) sono sostituiti dai sinonimi di COL. Restano nell'archivio `specie` e l'inventario della fase 4 li conta a parte.
9. **Scheda mostrata quando ce n'è più d'una**: quella verificata; per gli altri casi la regola si decide nel piano della fase 4 (le date attuali non servono: `aggiornata_il` ha 49 valori distinti su 15.723 righe, perché cambia a ogni aggiornamento a lotti). Le 4 cultivar cancellate non hanno contenuto e producono solo una riga di mappa.
10. **Download**: il file ColDP (1,4 GB) riporta la fonte dei nomi comuni, il DwC-A no; il sito di download richiede la gestione dei cookie.
11. **Fonti citate dentro i testi**: i permessi di colonna nascondono solo le colonne interne. Ma le fonti sono citate anche dentro i contenuti: negli avvisi (`alert`, 15.467 righe su 15.723, per esempio «Scheda in bozza, importata automaticamente da Plants For A Future»), nelle descrizioni (5.368) e nei dati delle immagini (7.722, «Wikimedia Commons»). Il piano della fase 4 deve togliere quelle citazioni dai testi, o spostarle in una colonna interna, prima di riempire `schede`.
12. **Attribuzione delle foto (decisa dall'utente il 13/10/2026)**: le immagini vengono da Wikimedia Commons con licenze CC BY e CC BY-SA, che richiedono di citare autore e licenza dove la foto viene mostrata. È l'unica eccezione alla regola "la fonte non si mostra mai": accanto alla foto si mostra l'attribuzione richiesta dalla licenza, e solo quella. I dati necessari (autore, licenza, link) restano quindi leggibili; il piano della fase 4 decide in quali colonne.

## Decisioni sullo spazio (approvate il 14/10/2026)

Dalla stima in `docs/ricerche/2026-10-14-stima-spazio.md`. Il limite del piano gratuito conta la somma di tutti i database, template compresi: oggi 384 MB su 500. Senza interventi le fasi 2–4 porterebbero a circa 675 MB.

1. **Restare sul piano gratuito**, con una soglia di lavoro di 450 MB. Se dopo una fase la somma dei database supera 450 MB ci si ferma e si passa al piano Pro (25 $ al mese più IVA).
2. **Manutenzione di `specie` prima della fase 2** (fase 1b): circa 198 MB recuperati. Il picco durante la compattazione è di circa 465 MB senza gli indici trigram, 537 MB con: per questo si tolgono prima e si ricreano subito dopo.
3. **Nessuna modifica a lotti su `specie` fino alla fine della fase 4**: ogni lotto ricrea lo spazio sprecato (gli aggiornamenti sul posto sono solo il 3,8%).
4. **`mappa_specie` solo per le righe non cultivar** (52 MB in meno): vedi la sezione della tabella.
5. **Regole di caricamento per le fasi 2–4**: indici secondari costruiti dopo il caricamento; valori definitivi inseriti in un solo passaggio, senza aggiornamenti di massa; lotti da non più di circa 100 MB di WAL, con pause di almeno 10 minuti e controllo di `pg_ls_waldir()`; prove sulla copia locale.
6. **Misura dopo ogni fase** (somma dei database, valori attesi): dopo la manutenzione circa 186 MB, dopo la fase 2 circa 262, dopo la fase 3 circa 266, dopo la fase 4 circa 387 (415 nel caso peggiore).
7. **Le fonti delle cultivar restano complete** (non abbreviate): il risparmio sarebbe di 12,6 MB e non serve.
8. **Righe cultivar tolte dall'archivio dopo la fase 7** (106 MB in meno): non decisa; cambierebbe la regola che tiene `specie` intera come archivio.

## Decisioni per la fase 3 (approvate il 15/10/2026)

Prese dopo la ricerca sull'abbinamento (`~/giardino-dati/col/ricerca_fase3/`). Le regole automatiche seguono GBIF species match, il codice ICN e il codice ICNCP.

1. **Sinonimi.** Quando il nostro nome è un sinonimo che in Catalogue of Life porta a un solo accettato, si segue COL. Sono circa 2.100 righe: nessuna revisione una per una, l'utente vede solo un riepilogo.
2. **Ambigui** (lo stesso nome usato da autori diversi per piante diverse, circa 270 righe). Vale la regola sicura:
   - se c'è un solo sinonimo omotipico, cioè con lo stesso tipo del suo accettato (ICN art. 49), si sceglie quello;
   - altrimenti la riga va all'antenato comune delle destinazioni, come fa GBIF con HIGHERRANK.
   
   L'utente rivede solo le righe usate dalle sue piante.
3. **Grex di orchidee senza apici** (per esempio "Vanda Doctor Anek", circa 220 righe). Per l'ICNCP (art. 23) sono grex, non specie: nella fase 3 si collegano al genere, nella fase 4 diventano cultivar di categoria `grex`.
4. **Cosa registra la mappa.** `mappa_specie.taxon_id` è il nome trovato, accettato o sinonimo che sia. Dove attaccare la scheda si decide nella fase 4: di norma sull'accettato, e per un sinonimo di specie che porta a un autonimo (per esempio *Rosmarinus officinalis* → *Salvia rosmarinus* subsp. *rosmarinus*) sulla specie.
5. **Revisione dell'utente.** Si rivedono solo i casi incerti, ciascuno con la proposta già pronta, e l'utente indica solo le eccezioni. Sono incerti:
   - i possibili refusi;
   - i generi scritti male;
   - i generi che in COL sono solo sinonimi o hanno omonimi;
   - i casi speciali;
   - le righe non esatte usate dalle sue piante.
6. **Notogeneri assenti da COL** (× *Angulocaste*, × *Mahoberberis*…): diventano taxon locali, sotto la famiglia scritta nella riga.
7. **Righe recuperate dai rollback.** Si classificano per nome, come le altre. Fa eccezione *agapanthus*, che ha il nome di una specie ma la descrizione del genere: la proposta è il genere.

## Rischi

- Abbinamento: omonimi tra regni, sinonimi, ibridi senza nome. Il match v2 con `checklistKey` e il controllo sul regno Plantae riducono il rischio; i casi non esatti vanno in `mappa_specie` per revisione.
- Stabilità degli identificatori COL XR tra un rilascio e l'altro: da verificare prima della fase 2 (si salva `versione_col`).
- Fase 6 è lavoro di codice non piccolo: va pianificata a parte.
- **Spazio sul piano gratuito di Supabase**: stimato e deciso il 14/10/2026 (vedi "Decisioni sullo spazio"). Restano due incertezze: il numero dei sinonimi COL (il caso peggiore vale circa 28 MB in più) e la durata della compattazione sul database reale, non misurabile in anticipo. Oltre 500 MB il database va in sola lettura.
- **Cronologia delle migration**: le migration applicate con `psql` non vengono registrate da Supabase (vedi "Fuori da questa specifica").
