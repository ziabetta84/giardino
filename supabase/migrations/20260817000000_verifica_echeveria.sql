-- Verifica reale (#120, secondo task), quinta e ultima specie del secondo
-- blocco di 5: echeveria. Voce generica del catalogo ("Echeveria spp."),
-- non legata a una pianta reale identificata a livello di specie. RHS non
-- ha una pagina di genere; usata come riferimento Echeveria elegans, la
-- specie più comune/diffusa in vivaio (quella tipicamente venduta come
-- "echeveria" generica, con RHS Award of Garden Merit) — dichiarato
-- esplicitamente in fonti.
--
-- esigenze.terreno arricchito da "Drenato" a "Drenato, con aggiunta di
-- sabbia grossa o ghiaia" (RHS: "peat-free, loam-based potting compost
-- with added extra grit").
--
-- Confermato: esigenze.luce "Pieno sole" = RHS Full sun (solo, nessuna
-- mezz'ombra); esigenze.acqua "Scarsa" = RHS "water moderately when in
-- growth; not at all when dormant"; resistenza_gelo "nessuna" = RHS H2,
-- la cui definizione corrente specifica esplicitamente "not surviving
-- being frozen"; finestra_trapianto primavera = RHS "cuttings... in
-- spring"; spaziatura_cm 15 dentro Max Spread RHS (0.1-0.5m).
--
-- Aggiunto alert mancante su cocciniglia farinosa, afidi e oziorrinco
-- (RHS Pests) — #132. Nessuna nuova malattia: RHS la segnala come
-- "generally disease-free".
--
-- Prima verifica di questa sessione tramite navigazione diretta RHS via
-- Claude in Chrome (sessione locale, dopo teleport), non più tramite
-- screenshot relayati.

update specie set
  esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Drenato, con aggiunta di sabbia grossa o ghiaia"}$j$::jsonb,
  alert = ARRAY[$t$evitare assolutamente ristagni idrici$t$, $t$richiede molta luce per mantenere la rosetta compatta$t$, $t$se si allunga verso l’alto → luce insufficiente$t$, $t$foglie molli → troppa acqua$t$, $t$foglie raggrinzite → sete$t$, $t$può essere soggetta a cocciniglia farinosa, afidi e oziorrinco$t$],
  fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Echeveria elegans (specie rappresentativa del genere, usata come riferimento per la voce generica "Echeveria spp.")$t$],
  stato_verifica = $t$verificato$t$,
  verificata_il = now(),
  verificata_da = $t$Roberta + Claude Code (navigazione diretta RHS via Claude in Chrome)$t$
where slug = $t$echeveria$t$;
