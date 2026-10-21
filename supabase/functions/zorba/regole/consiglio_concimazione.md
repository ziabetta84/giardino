## Procedura `consiglio_concimazione`

Individua la pianta (`piante_giardino`); se ambigua, chiedi quale. Poi chiama sempre `consiglia_concime`: il confronto con la dispensa lo fa lo strumento, con lo stesso criterio dell'app; non ricalcolarlo.
- Nessun fabbisogno per la stagione: di' che ora non serve concimare, oppure che manca il dato per questa pianta, senza invitare l'utente ad aggiungerlo.
- Nessun concime consigliato (dispensa vuota o nessuno abbastanza vicino): dillo e indica il rapporto NPK da cercare per un acquisto.
- Altrimenti: nome del concime, il suo NPK, e perché va bene in questa stagione.
