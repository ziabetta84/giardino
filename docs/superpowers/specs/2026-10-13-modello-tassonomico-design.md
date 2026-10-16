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
- **Eredità delle schede**: se una cultivar non ha una scheda mostrata, si usa quella del suo taxon, poi del padre (sinonimo → accettato, specie → genere). L'app indica solo il livello ("cure del genere *Hedera*"). L'eredità vale campo per campo, non per scheda intera (decisione 4 della fase 4).
- **Fonti solo nel database**: nel frontend la fonte non si nomina mai (né nella pagina della pianta, né nel selettore, né nelle risposte dell'agente). Resta un dato interno, usato per tracciabilità, revisione e per pesare l'affidabilità delle informazioni.

## Migrazione dei contenuti

Inventario attuale (13/10/2026, sola lettura): 15.723 righe madri (15.632 con descrizione, 11.675 con descrizione originale, 14.432 con esigenze, 8.755 con manutenzione, 7.722 con immagine, 9.552 verificate, 3.178 con nome italiano, 2.686 con nomi alternativi, 11.811 con sinonimi botanici) e 196.343 cultivar (12 con descrizione, 98.061 con nome italiano calcolato dai lotti). Fonti più presenti: RHS (208.139 citazioni), PFAF (8.461), enciclopedie fotografate (circa 650 tra Edicart, Demetra, De Vecchi/Giunti, collana Fiori & Piante), più alcune singole. Le piante dell'utente sono 122 su 93 righe.

Regole:

- Ogni riga madre con contenuto genera una scheda, attaccata al taxon della sua corrispondenza (all'accettato: decisione 1 della fase 4). Le righe "Genere spp." generano la scheda sul genere, anche le 16 con cure di specie (decisione 6 della fase 4: la frase precedente, che le voleva sulla specie, è superata).
- Le righe doppione (stesso taxon) generano più schede sullo stesso taxon; la scheda mostrata segue la regola della decisione 3 della fase 4 (le date non servono); l'utente può cambiarla.
- I nomi italiani attuali (`nome` ≠ `nome_scientifico`) e i `nomi_alternativi` diventano righe di `nomi_comuni`; il nome attuale è il preferito.
- Le cultivar diventano righe di `cultivar` con l'epiteto riletto dai titoli RHS già scaricati, e dal nome scientifico solo dove il titolo manca (decisione 11 della fase 4); il nome italiano salvato dai lotti non si copia (si calcola).
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

## Decisioni per la fase 4 (approvate il 16/10/2026)

Prese dopo la ricerca sui dati (`~/giardino-dati/col/ricerca_fase4/`, con le misure e gli script). Spazio misurato: circa 125 MB in più (schede 38, cultivar 82, nomi comuni 6), cioè circa 396 MB su 500.

**Schede**
1. **Aggancio:** sull'accettato del nome trovato in `mappa_specie`; per un sinonimo di specie che porta a un autonimo, sulla specie (ICN art. 26, decisione 4 della fase 3).
2. **Schede di specie finite su un taxon superiore** (370: specie assenti da COL, ambigui, ibridi con nome portati al genere, notogeneri, «aff.»): restano collegate al taxon della mappa, ma non sono mai mostrate né ereditate (come GBIF HIGHERRANK: il dato su un rango superiore non descrive quel taxon). Taxon locali per i nomi veri assenti da COL: lavoro successivo, con revisione una per una.
3. **Scheda mostrata** (decisione 9 dopo la verifica): idonea, poi verificata, poi usata dalle piante dell'utente, poi genere accettato prima di un genere sinonimo, poi completezza sui valori reali (i jsonb di PFAF con tutti i valori a null non contano), poi qualità della descrizione, nome esatto, lunghezza, slug. Le schede delle piante dell'utente restano quelle di oggi.
4. **Eredità campo per campo** (cultivar → grex → taxon → padre), come fa oggi l'app, non per scheda intera.
5. **Grex di orchidee** (213 righe più 7 su notogeneri locali): cultivar di categoria `grex` con la loro scheda (ICNCP art. 4.1 e 23). Le cultivar di orchidea sono legate al loro grex con una colonna nuova `cultivar.grex_id` (ICNCP art. 6.5); *Brachyglottis* Dunedin Hybrids diventa il gruppo Dunedin.
6. **Righe «Genere spp.»:** scheda sul genere, anche le 16 con cure di specie (servono a 18 piante dell'utente e a 3.220 cultivar); *Sansevieria* resta sul genere (scelta dell'utente), anche se COL la include in *Dracaena*.
7. **Copia dei jsonb** (esigenze, manutenzione, vaso, ciclo colturale) così come sono, compresi gli scheletri a null: l'inventario deve tornare uguale.
8. **Doppioni che sono Gruppi colturali** (peperone/peperoncino, cavolo/cavolo ornamentale, arancio/pompelmo…): nella fase 4 restano schede non mostrate dello stesso taxon; i Gruppi (ICNCP art. 22) sono lavoro successivo.

**Fonti dentro i testi** (decisioni 11 e 12 dopo la verifica). Le trasformazioni si fanno nella SELECT che alimenta l'inserimento, mai con un aggiornamento dopo (decisione sullo spazio 5).

9. Tolto l'avviso «Scheda in bozza, importata automaticamente da Plants For A Future» (8.460 righe: lo stato è in `stato_verifica`, la fonte in `fonti`); tolte le etichette «Da RHS (testo originale in inglese):»; i rischi PFAF diventano «Rischi (testo in inglese):» senza i rimandi numerici, e «None known» diventa «Rischi: nessuno noto»; i dati di coltivazione negli avvisi restano lì con prefissi fissi (Dimensioni a maturità, Rusticità, Propagazione, Potatura, Parassiti).
10. **Rusticità:** il codice RHS (H1a–H7) diventa la frase in gradi della sua fascia ufficiale, «minime fino a -15 °C»; con più codici si prende la fascia meno rustica.
11. **Testi in inglese:** restano in inglese e marcati; la traduzione è sospesa fino alla fine della fase 4. «Descrizione del genere:» resta davanti alle descrizioni di genere. La coda inglese delle 199 descrizioni di enciclopedia si taglia (resta in `descrizione_originale`).
12. **Nomi inglesi di PFAF** (8.144): righe di `nomi_comuni` in lingua `en`, mai preferite e mai nome mostrato.
13. **Note di lavorazione** trovate nei testi e in `fonti`: nella colonna interna nuova `schede.nota`, non leggibile dai client.
14. **Foto:** il jsonb `immagine` resta leggibile (url, attribuzione, licenza, licenza_url, fonte_pagina) senza la chiave costante `fonte` e senza i parametri `utm` negli indirizzi. Credito da mostrare nella fase 6, secondo Creative Commons (TASL): «Foto: Autore, licenza» con il link alla pagina del file e alla licenza, e il titolo per le licenze fino alla 3.0. Dei 79 autori sbagliati, 5 si correggono nell'inserimento e 74 dopo, rileggendo Commons (aggiornamento di poche righe). `esigenze`: tolto «Non specificato dalla fonte».

**Cultivar**

15. **Epiteto:** dai titoli RHS già scaricati, che correggono 1.854 epiteti troncati dallo script d'import (ICNCP art. 14.1, 21.4, 32.1); le 65 correzioni non a prefisso si controllano a mano.
16. **taxon_id:** il taxon più basso noto (ICNCP art. 21.1-21.2): il nome trovato della madre, anche se sinonimo (l'app risale all'accettato). Le 3.330 cultivar di specie agganciate per errore alla riga del genere passano alla loro specie, dopo aver importato in `taxa` le 23 specie che mancano (regole della fase 2). Varietà e sottospecie dai titoli RHS: lavoro successivo.
17. **Righe fuse da più cultivar o illeggibili** (200, senza contenuto né piante): una cultivar solo per le 37 con un epiteto vero; per le altre 163 solo una riga di `mappa_specie` (taxon della madre, esito «ambiguo», nota con i titoli). `mappa_specie` ha quindi anche queste righe di cultivar, oltre alle 4 doppie.
18. **Doppioni** (stesso taxon o genere e stesso epiteto): nessuna fusione automatica e nessun vincolo unico (ICNCP art. 6.5, 21.7, 30.5); i 41 gruppi probabili vanno all'utente.
19. **Gruppo e nome commerciale** dai titoli RHS (3.969 gruppi, 14.169 nomi commerciali; ICNCP art. 13.1, 22): valori multipli uniti con « | », gruppo non tradotto, Serie non salvate.

**Nomi comuni**

20. **Taxon:** l'accettato; per un autonimo, la specie (come i nomi comuni di COL). I nomi delle righe «Genere spp.» dati a una specie restano sulla specie del vecchio nome se è in `taxa`, altrimenti vanno al genere non preferiti; i nomi di righe salite di rango sono non preferiti sulla destinazione.
21. **Preferito** (uno per taxon e lingua): `generi.nome`, poi scelta esplicita dell'utente, poi riga del nome accettato, poi riga di un sinonimo, poi nome trasferito; spareggio: riga verificata, poi più fonti. Un elenco breve dei casi dubbi va all'utente. *Capsicum annuum*: «Peperone» (scelta dell'utente).
22. **Nome mostrato delle cultivar** (ICNCP art. 21.1): nome comune preferito della specie o, se manca, del genere, più l'epiteto; il nome è ambiguo solo se è preferito di taxon di linee diverse (un genere e una sua specie con lo stesso nome non lo sono).
23. **Fonti:** ricostruite dalle migration e dagli script dei lotti; i nomi del catalogo iniziale che nessun lotto ha impostato hanno fonte `catalogo`, distinta da `curatore`. I nomi di sola fonte PlantNet entrano tutti tranne un elenco di esclusione rivisto dall'utente (volgari, non-nomi, testo rotto).
24. **Nomi di COL:** fonte in più sui nomi uguali e nomi non preferiti per i nuovi (decisione 7 dopo la verifica). Confronto senza maiuscole: si tiene la nostra grafia.

## Rischi

- Abbinamento: omonimi tra regni, sinonimi, ibridi senza nome. Il match v2 con `checklistKey` e il controllo sul regno Plantae riducono il rischio; i casi non esatti vanno in `mappa_specie` per revisione.
- Stabilità degli identificatori COL XR tra un rilascio e l'altro: da verificare prima della fase 2 (si salva `versione_col`).
- Fase 6 è lavoro di codice non piccolo: va pianificata a parte.
- **Spazio sul piano gratuito di Supabase**: stimato e deciso il 14/10/2026 (vedi "Decisioni sullo spazio"). Restano due incertezze: il numero dei sinonimi COL (il caso peggiore vale circa 28 MB in più) e la durata della compattazione sul database reale, non misurabile in anticipo. Oltre 500 MB il database va in sola lettura.
- **Cronologia delle migration**: le migration applicate con `psql` non vengono registrate da Supabase (vedi "Fuori da questa specifica").
