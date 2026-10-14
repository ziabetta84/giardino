# Stima dello spazio per le fasi 2-4 del modello tassonomico — 14/10/2026

Misure in sola lettura sul database reale, simulazione completa su una copia locale (cluster Postgres 17 temporaneo, poi cancellato), limiti del piano gratuito dalle fonti ufficiali di Supabase. 1 MB = 1.000.000 byte (Studio applica il limite a 0,5·1e9).

Sul database reale ho fatto solo letture, nessuna scrittura: transazioni read only su 5432 e un pg_dump. Il lavoro è in /private/tmp/claude-501/-Users-rob-Sites-localhost-giardino/bddfc227-e321-4256-a1bb-bdf4fdbdf197/scratchpad/stima-spazio/r4/. Il cluster locale, il dump e la password sono stati cancellati alla fine. In tutto il testo 1 MB = 1.000.000 byte, perché Studio applica il limite a 0,5·1e9.

(1) CONTROLLO INCROCIATO
Le misure di base coincidono nelle tre lenti, e una nuova lettura alle 08:11 UTC le conferma: somma dei database 384.039.733 byte, di cui postgres 368.766.099 e template 15.273.634; specie 351.092.736. Ho rifatto la simulazione da zero, con un dump nuovo e un cluster nuovo:
- specie compattata 153.223.168 byte, identica;
- tabelle nuove con gli indici presenti 291,3 MB (r2: 290,8);
- con gli indici ricostruiti 252,3 MB, uguale a r2.

Ho trovato un errore che cambia una conclusione. Le proiezioni della simulazione partono dal solo database postgres. Il limite invece conta la somma di tutti i database, template compresi (docs e codice di Studio). A ogni proiezione mancano quindi 15,3 MB. Con la sola compattazione si arriva a 477,5 MB, non 461,7. Nel caso sfavorevole sui sinonimi si arriva a circa 510 MB, cioè oltre il limite (la simulazione diceva 489). Anche il picco del VACUUM FULL era sbagliato nelle due lenti (580 e 522 MB): il valore corretto è 537,3 MB.

Il resto torna:
- spreco di specie: 150 MB stimati, 149,6 misurati in locale;
- btree ricostruiti: 28,6 MB stimati, 28,9 misurati;
- conteggi delle righe.

Il fattore dei sinonimi (3,28) è prudente. Ricalcolato per strati sullo stesso campione dà circa 236.000 sinonimi invece di 255.000, e circa 217.000 togliendo i doppi conteggi (misurati). Nessuno aveva previsto i sinonimi dei generi: circa 16.000 righe, circa 4,5 MB.

Ho misurato una cosa nuova, il WAL. Caricare le fasi 2-4 con gli indici già presenti genera 767 MB di WAL; costruendo gli indici dopo, 393 MB. Con 1 GB di disco (dato documentato, non misurato) e max_wal_size a 1 GB, un caricamento fatto tutto in una volta può far scattare la sola lettura per disco pieno ancora prima dei 500 MB.

(2) BILANCIO
Limite 500 MB, soglia di lavoro 450 MB (margine di sicurezza del 10%). Per ogni scenario il valore centrale e, tra parentesi, il caso sfavorevole:
- oggi: 384,0;
- fasi 2-4 senza interventi: 675,3 (708). Fuori;
- tutto tranne la compattazione: 572. Fuori;
- solo compattazione: 477,5 (510). Fuori nel caso sfavorevole;
- compattazione e indici costruiti dopo il caricamento: 438,5 (467). Sotto il limite, ma sopra la soglia nel caso sfavorevole;
- più fonti brevi nelle cultivar: 425,9 (454);
- più mappa_specie solo per le righe non cultivar: 386,5 (415);
- con tutte e due: 373,9 (402);
- dopo la fase 7, togliendo gli indici di ricerca dall'archivio specie: 33,6 MB in meno.
Su Pro il limite diventa di 8 GB.

(3) STRATEGIE
a) Compattare specie (VACUUM FULL), 198 MB in meno. Va fatto per primo: dopo il riempimento il picco sarebbe enorme. Con gli indici trigram presenti il picco è di 537 MB, cioè oltre il limite. Togliendo prima i 4 trigram e ricreandoli subito dopo, il picco scende a 464,6 MB e il risultato finale è 186 MB. Durante l'operazione la tabella è bloccata: in locale ci vogliono 3 secondi, sul Nano reale potrebbe volerci da decine di secondi a qualche minuto (non misurato). Non si può provare in una transazione annullata. Non tocca i dati e non cambia nessuna decisione.
b) Costruire gli indici delle tabelle nuove dopo il caricamento, 39 MB in meno e WAL dimezzato. Costa poco, il rischio è basso, è reversibile e non cambia decisioni.
c) Inserire i valori definitivi in un solo passaggio, senza UPDATE di massa: un UPDATE su tutte le righe raddoppia la tabella (misurato). Costo zero. Però la specifica prevede l'esito «vuoto finché la riga non è elaborata»: le righe vanno inserite quando sono già elaborate.
d) mappa_specie solo per le 15.762 righe non cultivar, 52 MB in meno. Le cultivar restano rintracciabili tramite cultivar.vecchia_specie_id. Cambia la specifica («una riga per ogni riga»): serve l'approvazione dell'utente. Si può riempire in seguito.
e) Fonti brevi nelle cultivar, 12,6 MB in meno (misurato). La specifica non le fissa. Si perde il dettaglio «pagina di Iris», che resta ricavabile.
f) Dopo la fase 7, togliere gli indici di ricerca dall'archivio: 33,6 MB in meno, reversibile.
g) Dopo la fase 7, togliere le righe cultivar dall'archivio: 106 MB in meno. Cambia la decisione «specie resta come archivio»: serve l'approvazione dell'utente.
h) Passare a Pro: 25 $ al mese più l'IVA se si applica. Elimina il rischio e dà i backup giornalieri. Per tornare al Free bisogna comunque stare sotto 500 MB.

(4) RACCOMANDAZIONE
Restare sul piano gratuito, seguendo quest'ordine:
1. Fino alla fine della fase 4, niente più lotti di modifica su specie: naturalizzazione e revisioni in blocco riformano lo spreco.
2. Backup completo con pg_dump, con prova di ripristino in locale.
3. Una breve pausa di manutenzione: togliere i 4 indici trigram, VACUUM FULL di specie, ricrearli. Atteso: circa 186 MB.
4. Far decidere all'utente su (d), consigliato, ed eventualmente su (e).
5. Fasi 2-4 con queste regole:
   - indici costruiti dopo il caricamento;
   - un solo passaggio di inserimento;
   - lotti da non più di circa 100 MB di WAL, con pause di almeno 10 minuti e controllo di pg_ls_waldir;
   - prove sulla copia locale.
   Dopo ogni fase si misura la somma dei database. Valori attesi:
   - dopo la fase 2: 262;
   - dopo la fase 3: 266 con (d), 318 senza;
   - dopo la fase 4: 387 con (d), 438 senza.
   Se si superano i 450 MB ci si ferma e si passa a Pro.
6. Dopo la fase 7, applicare (f).
Se l'utente non vuole la pausa di manutenzione o preferisce non avere rischi, la strada è Pro durante la migrazione.

- Database size attuale (quella che conta per il limite) => 384.039.733 byte (76,8% di 500 MB): postgres 368.766.099, template1 7.752.851, template0 7.520.783. Margine 116,0 MB | MISURA, riletta alle 08:11 UTC del 14/10: sum(pg_database_size) in transazione read only su 5432 (r4/v1.out). È identica alle tre lenti
- Parte fissa (template e tutto tranne specie) => 32.946.997 byte | CALCOLO: 384.039.733 − 351.092.736 (specie, MISURA r4/v1.out)
- Errore nelle proiezioni della simulazione => mancano 15.273.634 byte (i template) in ogni scenario. B: 477,5 MB invece di 461,7. B nel caso sfavorevole: circa 510 MB, cioè oltre il limite, invece di 489. A: 675,3 MB invece di 659,6 | FONTE: docs database-size ('sum(pg_database_size(pg_database.datname))') e studio_disk-breakdown-query.ts, contro le proiezioni r2 che partono da 368.766.099
- Riproduzione indipendente della simulazione => specie compattata 153.223.168 byte (r2 153.223.168, identica). Tabelle nuove con indici presenti 291.291.136 (r2 290.824.192, +0,16%). Con indici ricostruiti 252.289.024 (r2 252.305.408) | MISURA locale: cluster PG 17.11 nuovo (porta 55433), dump nuovo del reale alle 08:20 UTC, stessa migration della fase 1, popola.sql e sinonimi.sql di r2 con fattore 3,2765 (r4/restore_out.txt, nuove_d
- Tabelle nuove: indici secondari tolti prima e ricreati dopo => 270.639.104 byte; con anche il REINDEX di PK e UNIQUE 252.297.216 byte (uguale al REINDEX completo) | MISURA locale (r4/carica3_out.txt, reindex2.sql): 14 indici non di vincolo tolti, carico, CREATE INDEX, poi REINDEX dei 10 indici di vincolo
- WAL del caricamento fasi 2-4 con gli indici della fase 1 presenti => 766.873.160 byte in 12,6 s. Per sezione: taxa accettati 20 MB, cultivar 250 MB, schede 42 MB, nomi_comuni 15 MB, mappa_specie 125 MB, sinonimi 315 MB | MISURA locale: pg_wal_lsn_diff prima e dopo ogni sezione, con wal_level logical, wal_compression zstd, max_wal_size 1GB, checkpoint_timeout 5min come su Supabase (r4/carica_out.txt, carica_con_indici_
- WAL del caricamento senza indici secondari => 392.623.880 byte in tutto = carico 344.379.024 + creazione degli indici 17.145.440 + REINDEX dei vincoli 31.099.416. Per sezione: cultivar 110 MB, mappa 92 MB, sinonimi 90 MB, schede 38 MB, nomi_comuni 7 MB, taxa accettati 7 MB | MISURA locale (r4/carica3_out.txt, reindex2.sql)
- WAL e durata del VACUUM FULL di specie => 56.114.696 byte di WAL, 3,1 s in locale (sulla tabella già compatta). Ricreare un indice GIN trigram: 4.856.872 byte di WAL per 14,8 MB di indice, quindi circa 11 MB per tutti e 4 | MISURA locale (r4/vfull_out.txt); il totale per i 4 GIN è una STIMA proporzionale. La durata sul Nano reale (heap gonfio da 226 MB, 0,5 GB di RAM) NON è misurata
- Picco di database size durante il VACUUM FULL => con tutti gli indici: 537.279.285 byte (sopra 500 MB). Togliendo prima i 4 GIN trigram (39.010.304 byte): 464.583.477 byte. Subito dopo 152,5 MB; ricreati i GIN, circa 186,2 MB | STIMA da misure: la vecchia copia e la nuova (heap, TOAST e indici) convivono fino al commit. Nuova specie senza GIN = 81.133.568 + 9.560.064 + 28.860.416 (btree misurati in locale). Le lenti avevano 
- Scenario: fasi 2-4 senza interventi => 675,3 MB (135%); caso sfavorevole circa 708 MB | STIMA = 32,95 + 351,09 + 291,29. Il caso sfavorevole aggiunge +27,3 MB di sinonimi (fattore 4,506, misura r2) e +4,9 MB di sinonimi dei generi
- Scenario: tutto tranne la compattazione => circa 571,8 MB, fuori | STIMA = 32,95 + 351,09 + 252,29 − 51,97 (mappa solo madri) − 12,58 (fonti brevi)
- Scenario: solo compattazione (indici presenti durante il caricamento) => 477,5 MB, margine 22,5 MB; caso sfavorevole circa 509,7 MB, fuori | STIMA = 32,95 + 153,24 + 291,29 (+32,2 nel caso sfavorevole)
- Scenario: compattazione e indici costruiti dopo, senza cambiare la specifica => 438,5 MB (87,7%), margine 61,5 MB; caso sfavorevole circa 466,7 MB, sopra la soglia di lavoro di 450 | STIMA = 32,95 + 153,24 + 252,29 (+28,2 nel caso sfavorevole: +23,7 per i sinonimi, cioè +27,3 riportato a indici ricostruiti con il rapporto 0,8676 misurato, e +4,5 per i generi)
- Scenario: come sopra, con le fonti brevi nelle cultivar => 425,9 MB; caso sfavorevole circa 454,1 | STIMA; risparmio MISURATO in locale di 12.582.912 byte di heap (copia di cultivar con fonti {rhs} contro quelle attuali)
- Scenario: come sopra, con mappa_specie solo per le righe non cultivar => 386,5 MB (77,3%); caso sfavorevole circa 414,7. Con anche le fonti brevi: 373,9 (402,1) | STIMA; risparmio MISURATO da r2 di 51.970.048 byte (mappa completa ricostruita 56.418.304 contro 15.762 righe 4.448.256)
- Scenari dopo la fase 7 => togliendo i 4 GIN dall'archivio specie: 352,9 MB (con mappa solo madri) o 404,9 (senza). Togliendo anche le righe cultivar dall'archivio: circa 280,5 MB | STIMA da misure: GIN di specie compattata 33.636.352 (r2, r4); specie solo madri 47.194.112 contro 153.239.552 (r2)
- Traiettoria attesa da controllare dopo ogni fase (somma dei database) => dopo la compattazione 186,2; dopo la fase 2 (taxa 75,6) 261,8; dopo la fase 3 318,2 con la mappa completa o 266,2 con la mappa solo madri; dopo la fase 4 (cultivar 78,2 + schede 37,5 + nomi_comuni 4,6) 438,5 oppure 386,5 MB | STIMA: somma delle misure locali con indici ricostruiti (r4/reindex_out.txt)
- Sinonimi COL: ricalcolo per strati => 235.966 (bootstrap al 90%: 172.606–307.702), contro i 254.735 della simulazione. Togliendo i doppi conteggi circa 216.562 | STIMA: medie COL per strato del numero di nostri sinonimi (0, 1, 2-4, 5-9, 10-14, 15+) sui 40 nomi del campione di r1/r2, pesate con le dimensioni reali degli strati (MISURA: 3.392, 2.964, 2.799, 2.39
- Doppi conteggi dei sinonimi => 623 delle 1.731 madri che GBIF considera sinonimi hanno l'accettato già tra le nostre madri; 96 accettati sono condivisi da più madri; solo 1.609 dei 77.746 elementi di sinonimi_botanici coincidono con il nome di una madre | MISURA read only (r4/v2.out, v4.out)
- Sinonimi dei generi (non simulati) => in media 5,5 per genere (94 su 17 generi con risposta; 3 senza corrispondenza), quindi circa 16.300 righe, circa 4,5 MB | MISURA del campione: 20 generi a caso, API ChecklistBank 3LXR (r4/sinonimi_generi_campione.json). Il totale è una STIMA (× 2.955 generi × circa 275 B per riga di taxa)
- Nomi italiani da COL => COL XR ha 35.572 nomi in italiano per tutti i regni; nel campione, 6 nomi in 40 specie. Per le nostre 15.151 specie circa 2.300, contro i 5.000 ipotizzati (la simulazione è prudente di circa 1,5 MB) | MISURA: /dataset/3LXR/vernacular?language=ita e taxon/{id}/vernacular per i 40 nomi del campione (r4/vernacolari_campione.json); il totale è una STIMA
- Fonti delle cultivar => text[] con valori come 'RHS (rhs.org.uk) — cultivar elencata nella pagina di Iris' (85-117 B) | MISURA read only (r4/v3.out)
- Generi con nome italiano => 66, rielencati uno per uno; le note di progetto ne fanno attendere 67. Non ricostruibile dalle migration; vale meno di 1 kB | MISURA read only (r4/v1.out); lettura di 20261008125000_generi_nomi_scelti.sql (85 righe, 33 nomi italiani)
- Ruolo postgres, WAL e archiviazione => non superuser e non membro di pg_checkpoint (non può forzare un CHECKPOINT); membro di pg_monitor. WAL 134.218.095 byte in 9 file; wal_compression zstd; archiver 2.439 file, 0 falliti, ultimo alle 08:03 UTC | MISURA read only (r4/v1.out)
- Righe di specie ancora in uso => 6 piante su 122 puntano a righe cultivar di specie; 2.867 modifiche a specie dall'ultimo ANALYZE (11/10) | MISURA read only (r4/v1.out)
- Costo del Pro => 25 $ al mese più IVA se applicata (circa 30,5 $ al 22%). Compute coperto dai crediti. Downgrade in qualsiasi momento, con crediti (non rimborsi) per il tempo non usato | FONTE: limiti (pricing), docs manage-your-subscription e billing-faq rilette con search_docs il 14/10

RISCHI
- Il limite conta la somma di tutti i database, template compresi (15,3 MB). Le proiezioni di r2 non li contano: con la sola compattazione e il fattore alto dei sinonimi si supera il limite (circa 510 MB), non si resta sotto.
- Picco del VACUUM FULL: se si lascia su specie i 4 indici trigram si arriva a circa 537 MB, sopra la soglia, anche solo per pochi minuti. La pagina d'uso registra il massimo del ciclo e il periodo di tolleranza è uno solo: i trigram vanno tolti prima (picco circa 465 MB) e ricreati subito dopo. Senza di loro la ricerca dell'app resta lenta per qualche minuto.
- Durante il VACUUM FULL specie è bloccata: selettore e caricamento delle specie restano in attesa. In locale sono 3 secondi, sul Nano la durata non è misurata (da decine di secondi a qualche minuto). Non si può fare in una transazione annullata. Va eseguito sulla connessione 5432 in una finestra tranquilla, dopo un pg_dump verificato: il piano Free non ha backup automatici.
- Disco e WAL: il caricamento delle fasi 2-4 con gli indici presenti genera almeno 767 MB di WAL (misura locale, valore minimo). Con 1 GB di disco documentato (non misurabile senza token) e max_wal_size di 1 GB, un caricamento in un colpo solo può far scattare la sola lettura per disco pieno (al 95%) già sotto i 500 MB. Servono lotti da non più di circa 100 MB di WAL, pause di almeno 10 minuti e controllo di pg_ls_waldir. Il ruolo postgres non può forzare un checkpoint.
- Ogni lotto di UPDATE su specie dopo la compattazione la fa ricrescere, perché gli UPDATE HOT sono solo il 3,8%. Naturalizzazione e revisioni in blocco vanno sospese fino alla fine della fase 4, oppure spostate sulle schede.
- UPDATE di massa sulle tabelle nuove: riempire cultivar_id o esito in mappa_specie, accettato_id o padre_id in taxa, o togliere le citazioni dalle schede con un secondo passaggio raddoppia la tabella, e VACUUM non restituisce lo spazio (r2: mappa da 56 a 113 MB). La specifica prevede l'esito «vuoto finché la riga non è elaborata» e le righe cultivar della mappa hanno bisogno di cultivar_id, che nasce solo nella fase 4: va pianificato un inserimento unico.
- Le «prove in transazione annullata» della specifica, se fatte sul reale per i caricamenti in blocco, occupano lo stesso picco e lo stesso WAL del caricamento vero. Le pagine di heap restano finché VACUUM non le tronca e gli indici non si riducono. Conviene provare sulla copia locale, o almeno lanciare VACUUM sulle tabelle nuove prima del caricamento vero.
- Scenario senza cambiare la specifica (compattazione e indici dopo): 438,5 MB, ma nel caso sfavorevole circa 467, sopra la soglia di lavoro di 450 MB. Dopo la migrazione restano circa 60 MB per tutto il resto: una reimportazione COL che aggiorna tutte le righe di taxa (circa 76 MB) basterebbe a sforare. Si devono aggiornare solo le righe cambiate.
- Le strategie più efficaci dopo la compattazione cambiano decisioni già prese e vanno fatte approvare dall'utente: mappa_specie solo per le righe non cultivar (52 MB in meno, la specifica dice «una riga per ogni riga»); righe cultivar tolte dall'archivio dopo la fase 7 (106 MB in meno, la specifica dice che specie resta come archivio). Le fonti brevi nelle cultivar (12,6 MB in meno) non sono fissate dalla specifica, ma tolgono un dettaglio di provenienza.
- Incertezze della stima: i sinonimi (90% tra circa 173.000 e 308.000 per strati, tra 171.000 e 350.000 nella simulazione), i sinonimi dei generi non simulati (circa 4,5 MB), nomi e autori sintetici. In senso favorevole: nomi italiani COL sovrastimati e schede con le citazioni ancora dentro. Il caso sfavorevole usato vale circa +28 MB con indici ricostruiti.
- Le fonti non concordano sulla frequenza di misura: le docs dicono che le metriche del disco si aggiornano ogni giorno, Studio dice ogni ora. Come Supabase applichi la soglia non è pubblico. Ipotesi prudente: qualsiasi picco di qualche minuto può essere registrato. Le restrizioni della Fair Use Policy valgono per tutta l'organizzazione e si tolgono solo al ciclo successivo o passando a Pro.
- Pro elimina il problema durante la migrazione, ma per tornare al Free bisogna stare sotto 500 MB: la compattazione resta necessaria se l'obiettivo finale è il piano gratuito. La spesa è un'altra decisione dell'utente, legata anche all'obiettivo della sponsorizzazione.
- Differenze tra il locale e Supabase: il formato delle pagine e le dimensioni sono uguali (riproduzione al byte per specie). Il WAL locale è un minimo perché il caricamento è durato solo 12 secondi. La durata delle operazioni sul Nano sarà molto più lunga. In r4 non ho toccato i file degli altri agenti in r2; ho cancellato soltanto i miei pgdata, dump.fc e pw.txt.
