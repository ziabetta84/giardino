# Criterio di disambiguazione dei nomi

Approvato da Roberta il 26/11/2026. Vale per ogni nome che entra nel catalogo (pagine RHS, altre fonti, segnalazioni
di Zorba) e per ogni sessione che ci lavora. Serve a evitare che ogni caso dubbio diventi una decisione presa al volo.

Il catalogo ha due parti distinte: i **nomi** (`taxa`, da Catalogue of Life) e le **schede** (`schede`, scritte da
noi). Una pianta senza scheda propria nell'app mostra quella del primo antenato che ne ha una (specie, poi genere:
`catalogo.livelli`). Il criterio dice cosa fare quando una fonte e Catalogue of Life non sono d'accordo su che pianta
sia un nome.

## 1. I nomi li decide Catalogue of Life

- Chi è specie accettata e chi è sinonimo lo dice sempre COL (oggi COL26.9 XR). Non si aggiungono né si cambiano a mano
  sinonimi o stati in `taxa`: la prossima versione di COL li contraddirebbe e il catalogo perderebbe un arbitro unico.
- Se per COL un nome è sinonimo di un'altra specie, il nome usa già la scheda dell'accettato: non serve nient'altro.
- Fanno eccezione solo i taxon locali già documentati (notogeneri assenti da COL, fase 3).

## 2. Ogni specie accettata da COL ha la sua scheda, anche se altri la includono in un'altra

Quando COL tiene separata una specie che altri autori considerano parte di un'altra (sinonimo o sottospecie), la specie
riceve una **scheda breve**, che lo dice apertamente e riporta le cure della specie ampia:

> «Per molti autori è *Allium oreophilum*, a cui somiglia in tutto; si coltiva allo stesso modo.»

Non si fondono mai due specie in silenzio, non si copiano schede intere (due schede gemelle da tenere allineate) e non si
usano «rinvii» da un nome alla scheda di un'altra specie.

Casi già decisi così (Roberta, 23/11/2026): *Allium ostrowskianum* (→ *A. oreophilum*), *Helianthemum alpestre*
(→ *H. oelandicum*, come *H. oelandicum* subsp. *alpestre* nelle flore europee e in Pignatti), *Hydrangea cinerea*
(→ *H. arborescens* subsp. *discolor* per altri autori); con la stessa regola *Ficus maclellandii* e *Dracaena cincta*
(lotto 3).

## 3. Quali altre fonti contano

Per scrivere «per molti autori è la stessa pianta» bastano:
- **Plants of the World Online** (Kew);
- per le piante spontanee in Italia, la **Flora d'Italia** di Pignatti (o *Flora Europaea*).

Un nome commerciale o di vivaio da solo non basta: allora la scheda cita solo la confusione nel commercio («si vende
anche come *F. binnendijkii* 'Alii'»).

## 4. Nomi usati a torto nei giardini (sensu hort., misapplied)

Una fonte può usare un nome per una pianta diversa da quella a cui il nome appartiene (per esempio *Leucothoe walteri*
dei vivai, che è *L. fontanesiana*, mentre per COL il nome porta ad *Agarista populifolia*). In questi casi:
- il **nome** resta quello che dice COL: chi cerca *Leucothoe walteri* trova la pianta di COL;
- il **contenuto della pagina** (descrizione, cure) va alla scheda della pianta che la pagina descrive davvero,
  riconosciuta dal testo (fiori, foglie, portamento), non dal nome del titolo;
- le **cultivar** della pagina vanno sulla specie a cui appartengono davvero (come *Ficus* 'Alii' su *F. maclellandii*
  e *Dracaena* 'Tricolor' su *D. cincta*, 23/11/2026); se ci sono già lì, non si aggiunge niente.

L'aggancio di queste pagine si registra in `scripts/rhs-import/dati/rhs_agganci_decisi.tsv`, con il motivo.

## 5. I dubbi li decide Roberta

Abbinamenti incerti, pagine con i dati di un'altra pianta, omonimi senza una scelta sicura: non si decidono da soli. Si
mettono da parte in un elenco con il motivo (come i 5 esclusi del lotto 2 e *Horminum pyrenaicum* del lotto 3) e si
propongono a Roberta.

## In breve

| Caso | Cosa si fa |
|---|---|
| Per COL è un sinonimo | Niente: usa già la scheda dell'accettato |
| Per COL è una specie a sé, per altri no | Scheda breve che lo dice, con le cure della specie ampia |
| La fonte usa il nome a torto (hort.) | Nome secondo COL; testo e cultivar sulla pianta descritta davvero |
| Non è chiaro | Elenco da rivedere con Roberta |
