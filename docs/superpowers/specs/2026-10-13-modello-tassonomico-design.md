# Nuovo modello tassonomico — specifica

Data: 13/10/2026 · Stato: bozza da approvare. Nessuna modifica al database prevista prima dell'approvazione di questa specifica e del piano che ne deriva.

## Perché

Lo scopo iniziale era permettere a chi non conosce il nome scientifico di trovare la propria pianta col nome italiano. Il lavoro sui nomi (lotti 1–13, generi, doppioni) ha seguito un modello in cui `specie.nome` è contemporaneamente identità della riga (UNIQUE) e nome mostrato, e in cui le cultivar venivano rinominate una per una. Ne sono derivate collisioni, righe "Genere spp." con contenuti di specie, decine di migration correttive e incoerenze (es. "Calendola"/"Calendula", righe di genere in latino con cultivar in italiano). Questa specifica sostituisce quell'approccio con un modello basato sulle convenzioni di chi fa questo lavoro (codici internazionali, Catalogue of Life, RHS), senza perdere il lavoro di contenuto già fatto.

Scopi dell'app che il modello deve servire:

1. l'utente trova la sua pianta col nome che conosce (italiano, scientifico, vecchio nome, nome della cultivar);
2. l'utente gestisce le cure delle sue piante;
3. l'agente AI ha una base di informazioni solida, con fonte e livello di ogni dato registrati nel database (la fonte non viene mai mostrata all'utente).

## Fonti e regole adottate (non scelte nostre)

- **Nomi scientifici e gerarchia: Catalogue of Life Extended Release (COL XR)**, CC BY 4.0. GBIF ha adottato COL XR come tassonomia predefinita; il vecchio GBIF Backbone è fermo al 2023 e non verrà più aggiornato ([GBIF Data Blog, 23/06/2026](https://data-blog.gbif.org/post/catalogue-of-life-taxonomic-backbone/)). Accesso: API GBIF con `checklistKey=7ddf754f-d193-4cc9-b351-99906754a03b` (es. `https://api.gbif.org/v2/species/match?scientificName=…&checklistKey=…`) oppure download completo (`https://download.checklistbank.org/col/xr_latest_dwca.zip`, formato ColDP o DwC-A, con file di nomi comuni). Identificatori alfanumerici (es. `72ZGR`); esiste una mappa dalle vecchie chiavi intere GBIF (`https://download.checklistbank.org/col/gbif/README.html`), utile perché `generi.gbif_key` usa le vecchie chiavi.
- **Ibridi (ICN)**: gli ibridi con nome sono taxon normali. In COL XR *Mentha × piperita* è una specie accettata (rango SPECIES) con "×" nel nome; non c'è un campo "ibrido" separato (verificato sull'API il 13/10/2026), quindi lo ricaviamo dal "×". I notogeneri (*× Fatshedera*) sono generi.
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

### `taxa` — da COL XR, non modificata a mano
`id` (identificatore COL XR), `rango` (famiglia, genere, specie, sottospecie, varietà, forma), `nome_scientifico` (con autore), `nome_canonico` (senza autore), `stato` (accettato, sinonimo, dubbio), `accettato_id` (per i sinonimi), `padre_id`, `ibrido` (da "×"), `gbif_key_vecchia` (dalla mappa ufficiale, se esiste), `versione_col`, `importato_il`. Si importano solo i taxon che servono: quelli abbinati alle nostre righe, i loro antenati fino alla famiglia, e i loro sinonimi.

### `nomi_comuni`
`taxon_id`, `lingua`, `nome`, `preferito` (al più uno per taxon e lingua), `fonte` (iNaturalist, Wikidata, PlantNet, EPPO, COL XR, scelta dell'utente…), `nota`. Qui confluiscono tutti i nomi italiani raccolti finora (lotti 1–13, `nomi_alternativi`, `generi.nome`, deroghe dell'utente), ciascuno con la fonte ricostruita dalle migration dei lotti.

### `cultivar`
`id`, `slug` (quello attuale, per non rompere riferimenti), `epiteto` (senza apici), `categoria` (cultivar, gruppo, grex), `taxon_id` (taxon più basso noto: specie, ibrido o genere, come da fonte RHS), `gruppo` (facoltativo), `nome_commerciale` (facoltativo), `fonte`, `vecchia_specie_id`.

### `schede` — il contenuto
`id`, `taxon_id` **oppure** `cultivar_id` (esattamente uno), `fonte`, `descrizione`, `descrizione_originale`, `lingua_descrizione`, `esigenze`, `manutenzione`, `ciclo_colturale`, `ciclo_vitale`, `vaso`, `alert`, `immagine`, `stato_verifica`, `verificata_il`, `verificata_da`, `mostrata` (al più una per taxon o cultivar), `vecchia_specie_id`. Più schede per lo stesso taxon sono ammesse (es. enciclopedia e PFAF): nessuna fusione automatica di testi.

### `mappa_specie` — tracciabilità
Una riga per ogni riga della vecchia `specie` (incluse quelle cancellate in questa sessione, recuperate dai file di rollback): `vecchia_specie_id`, `vecchio_slug`, `taxon_id` o `cultivar_id`, `esito` (esatto, sinonimo, rango superiore, ibrido, non trovato, deciso dall'utente), `nota`. È l'elenco che l'utente rivede per i casi dubbi.

### `piante`
Si aggiungono `taxon_id` e `cultivar_id` (esattamente uno, dopo la migrazione). Puntare a un genere è legittimo quando la specie non è certa. La colonna `specie` resta finché l'app non è passata al nuovo modello.

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
- Le righe cancellate in questa sessione (32 doppioni bozza, `agapanthus`, `jasminum-officinale`, `daucus-carota`, 4 cultivar doppie) entrano come schede dai file di rollback, non vengono reinserite in `specie`.
- **Verifica**: lo stesso inventario, per fonte e per campo, ricalcolato sulle tabelle nuove deve dare gli stessi numeri (o differenze spiegate una per una).

## Fasi

Ogni fase ha backup, prova in transazione annullata e verifica; l'app continua a funzionare fino alla fase 7.

1. Creare le tabelle nuove, vuote (nessun effetto sull'app).
2. Scaricare COL XR e importare in `taxa` solo il necessario.
3. Abbinare le righe madri ai taxon e compilare `mappa_specie`; l'utente rivede solo l'elenco dei casi non esatti.
4. Popolare `cultivar`, `nomi_comuni`, `schede`; inventario di verifica.
5. Abbinare le 122 piante (ogni pianta controllata con l'utente).
6. Adattare l'app (store, selettore, pagina pianta, fallback offline, ricerca) e le istruzioni dell'agente (`/zorbadice`) leggendo dalle tabelle nuove; verifica nel browser.
7. Passaggio definitivo: l'app usa solo le tabelle nuove; `specie` e `generi` restano in sola lettura come archivio.

Ogni fase avrà il suo piano; questa specifica copre il modello e l'ordine.

## Fuori da questa specifica

- Correzioni ai nomi o ai contenuti delle righe attuali: sospese, salvo urgenze.
- Nomi commerciali e Gruppi: si riempiono solo se presenti nei dati RHS già scaricati.
- Allineamento della cronologia delle migration Supabase (`schema_migrations`): resta un punto separato.

## Decisioni da prendere con l'utente

1. Usare COL XR invece del vecchio GBIF Backbone (raccomandato: il Backbone non è più aggiornato).
2. Regola del nome mostrato delle cultivar (nome comune non ambiguo + epiteto, Art. 21.1).
3. Dove lavorare il file di COL XR (in locale, fuori dal repository).
4. Le deroghe già decise (5 nomi del lotto 12, Calendula, Edera, Elleboro) restano come nomi comuni con fonte "scelta dell'utente".

## Rischi

- Abbinamento: omonimi tra regni, sinonimi, ibridi senza nome. Il match v2 con `checklistKey` e il controllo sul regno Plantae riducono il rischio; i casi non esatti vanno in `mappa_specie` per revisione.
- Stabilità degli identificatori COL XR tra un rilascio e l'altro: da verificare prima della fase 2 (si salva `versione_col`).
- Fase 6 è lavoro di codice non piccolo: va pianificata a parte.
