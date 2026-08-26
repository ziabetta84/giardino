# Import RHS (fonti/rhs-varietà)

Pipeline per trasformare le pagine RHS salvate in `fonti/rhs-varietà/`
(1211 file html: specie + tutte le cultivar reperibili, scaricate
dall'utente da rhs.org.uk) in migration SQL per la tabella `specie`.

## Uso

```bash
cd scripts/rhs-import
python3 parse_rhs.py       # 1 record per file html -> rhs_varieta_parsed.json (non versionato, si rigenera)
python3 aggregate_rhs.py   # raggruppa per specie base -> rhs_varieta_aggregato.json (non versionato)
```

Poi per ogni batch di generi: creare un file `batch_<nome>.py` (vedi
`batch_felci_DONE.py` come esempio) con la lista `(nome RHS, slug esistente
in specie)`, importare `gen_block` da `genera_sql.py` e stampare l'SQL per
ogni coppia. Il file `batch_felci_DONE.py` copre già Adiantum, Asplenium,
Athyrium, Blechnum, Cheilanthes, Cibotium, Cyathea, Cyrtomium, Cystopteris,
Davallia, Dennstaedtia, Dicksonia, Didymochlaena, Doryopteris, Dryopteris,
Gymnocarpium, Humata, Matteuccia, Microlepia, Nephrolepis, Onoclea,
Osmunda, Pellaea, Phlebodium, Pilularia, Platycerium, Polypodium,
Polystichum, Pteridium, Pteris, Salvinia, Thelypteris, Woodsia, Woodwardia
— vedi la migration `20260826010000_rhs_varieta_batch01_felci.sql`.

## Decisioni di design (vedi anche fonti/criterio-importazione.md)

- **Granularità riga**: solo la specie base riceve/arricchisce una riga.
  Le cultivar (fino a 127 per una singola specie, es. Acer palmatum) sono
  riassunte in `descrizione` (conteggio, range altezza/diffusione, nomi
  di esempio), mai una riga per cultivar — decisione esplicita dell'utente
  per contenere lo scope (altrimenti ~1200 righe invece di ~200).
- **Testo libero RHS** (descrizione, parassiti, malattie, potatura,
  propagazione): tenuto in inglese originale e marcato come tale, stessa
  convenzione già usata per i rischi PFAF — evita il rischio di traduzione
  errata su migliaia di frasi.
- **Campi strutturati** (Position/Soil Types/Moisture/pH): tradotti in
  italiano e scritti in `esigenze` con merge non distruttivo (i valori
  già presenti in DB vincono in caso di conflitto di chiave).
- **`stato_verifica`**: RHS è fonte primaria (regola 3) → passa a
  `'verificato'` solo se la pagina ha contenuto specifico sulla specie
  (non solo testo di genere) — alcune pagine RHS di specie rare non hanno
  affatto la sezione "How to Grow": in quel caso si arricchisce solo
  `descrizione`/`fonti` col testo di genere, senza promuovere lo stato.
- **Sinonimi**: RHS usa talvolta un nome scientifico diverso da quello già
  in catalogo (es. Alsophila = Cyathea, Sphaeropteris = Cyathea,
  Goniophlebium/Niphidium = Polypodium, Phegopteris/Parathelypteris/
  Oreopteris = Thelypteris, Platycladus = Thuja, Styphnolobium = Sophora,
  Xanthocyparis = Chamaecyparis nootkatensis) — vanno mappati manualmente
  verificando la corrispondenza con una query preliminare su `nome_scientifico`
  prima di scrivere il batch.

## Bug noti e già risolti

- Le pagine RHS hanno "Foliage"/"Fruit" anche come intestazioni di
  categoria in "Colour & Scent" (senza valore reale) — il parser deve
  ancorarsi a "Native to GB/Ireland" (unica) e scandire in avanti label
  per label, non assumere offset fissi: alcune pagine (specie rare) non
  hanno affatto Foliage/Habit e passano direttamente a Genus, o hanno
  "Genus" senza alcun valore (segue subito "Name Status").
- Gli en-dash (–) nei valori Moisture/pH vanno normalizzati a hyphen
  prima del match col dizionario di traduzione.
- Il nome ibrido con "×" (es. "Mentha × piperita") va trattato a 3 token,
  non 2, nella funzione `base_species`.
