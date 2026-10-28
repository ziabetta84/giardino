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
4. **Catalogo**: le scelte diventano una migration su `schede.immagine` con il suo rollback.

Wikimedia limita molto le richieste dal cloud (~6 miniature al minuto): i passi 2 e 3 vanno lanciati dal Mac.
`lavoro/` è git-ignorata.
