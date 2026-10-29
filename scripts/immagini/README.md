# Foto delle schede del catalogo

Le immagini di `schede.immagine` vengono dal primo risultato di Commons (script #120): alcune mostrano una parte della
pianta o una pianta sbagliata. Qui si scelgono a mano quelle delle voci delle piante di Roberta.

1. **Raccolta** (`raccolta/`, già fatta il 28/10/2026): per ogni voce una ricerca su Commons
   (`deepcat:` della categoria della specie, più ricerche a mano in `dati/extra.json`) e l'immagine principale della
   categoria (`dati/categorie.json`, la stessa di Wikidata P18). `raccolta/filtra.py` tiene solo licenze
   CC0, pubblico dominio, CC BY e CC BY-SA (niente NC/ND: gli abbonamenti sono uso commerciale), scarta i file
   senza il nome del genere e ordina con `raccolta/punteggio.py` (penalizza semi, erbario, cibo, insetti, dettagli;
   premia portamento e Quality/Valued images). Risultato: `dati/candidati.json`, 16 candidate al più per voce.
2. **Scelta delle candidate**: `python3 miniature.py 12` scarica le miniature e fa un foglio di contatto per voce in
   `lavoro/fogli/` (la casella «attuale» è l'immagine di oggi). Gli indici da proporre vanno in
   `dati/proposte.json` (`candidate`, 4-6 per voce; `nota` per spiegare, per esempio «nessuna foto della cultivar»).
3. **Pagina**: `python3 pagina.py` → `lavoro/pagina.html`, da pubblicare come Artifact con le capability
   `{db: {}, user: {}}`; le scelte finiscono nella collezione `scelte` (un documento per voce: `scelta` = url,
   `attuale` o `nessuna`, e `nota`).
4. **Catalogo**: le scelte della pagina, esportate in `dati/scelte.json`, diventano con `python3 migrazione.py`
   la migration `supabase/migrations/20261029120000_immagini_scelte.sql` e il rollback
   `rollback_20261029120000_immagini_scelte.sql` (`psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f …`). Una voce di specie o
   genere cambia l'immagine della scheda mostrata del suo livello (valori di prima in `dati/immagini_prima.json`; la
   migration si ferma se nel frattempo sono cambiati); una cultivar senza scheda ne riceve una mostrata con la sola
   immagine (il resto continua a venire dalla specie). Scelte del 29/10/2026: 41 voci, 31 foto nuove (20 schede
   cambiate, 11 schede di cultivar aggiunte), 10 tengono l'attuale; le altre 56 voci restano come sono.

Wikimedia limita molto le richieste dal cloud (~6 miniature al minuto): i passi 2 e 3 vanno lanciati dal Mac.
`lavoro/` è git-ignorata.

**Riempimento automatico** (`riempi/`): per le schede mostrate di taxon senza immagine (circa 7.100; le cultivar
ereditano dalla specie) prende l'immagine principale della categoria Commons del nome scientifico, solo con licenza
libera, foto di almeno 500 px e titolo che non indichi un dettaglio o una tavola botanica (criteri in `riempi.py`).
Dal Mac: `elenco.sql` → `riempi.py raccogli` (circa 300 richieste, si riprende da dove era) → `riempi.py campione` per
un controllo a occhio → `riempi.py migrazione` (migration `20261029130000_immagini_automatiche.sql`, rollback in
`riempi/`). Ogni immagine porta `"origine": "automatica 29/10/2026"` e `"verificata": false`.

Secondo giro (stesso script, `secondo`): per le schede rimaste senza cerca anche con i sinonimi sicuri (`elenco2.sql`:
solo «synonym», mai nomi che indicano anche un'altra pianta) e, se l'immagine principale manca o non va, sceglie la foto
migliore dentro la categoria con il punteggio di `raccolta/punteggio.py`. Origine `automatica 29/10/2026, secondo giro`,
migration `20261029140000_immagini_automatiche_2.sql`. `20261029135000_immagini_automatiche_tavole.sql` toglie 3 tavole
botaniche entrate col primo giro, che il filtro ora riconosce.
