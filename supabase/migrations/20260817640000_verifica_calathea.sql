-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Nota tassonomica importante: RHS ha riclassificato l'intero genere
-- Calathea in Goeppertia — le piante da appartamento vendute come
-- "calathea" nei vivai italiani sono comunemente Goeppertia secondo la
-- tassonomia RHS attuale, stesso tipo di aggiornamento già incontrato con
-- Salvia rosmarinus (ex Rosmarinus). Confermata luce (RHS Full shade).
-- terreno arricchito con la nota sul pH acido. Confermata con la massima
-- forza resistenza_gelo "nessuna": RHS classifica H1A. spaziatura_cm
-- compilata a 30 (RHS Max Spread 0.1-0.5m, dato applicabile essendo una
-- normale pianta da vaso). Aggiunto alert mancante su parassiti reali;
-- confermata la nota già presente sull'uso di acqua non calcarea (RHS
-- conferma esplicitamente questa pratica per evitare macchie bianche sulle
-- foglie) (#132).

update specie set esigenze = $j${"luce": "Luce diffusa", "acqua": "Regolare", "terreno": "Ricco, drenato, leggermente acido"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Marantaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Ama umidità elevata$t$, $t$Evitare correnti fredde$t$, $t$evitare luce diretta (brucia le foglie)$t$, $t$evitare correnti d’aria e sbalzi termici$t$, $t$usare acqua non calcarea per evitare macchie sulle foglie$t$, $t$se i bordi diventano secchi → aria troppo secca$t$, $t$se le foglie si arricciano → poca acqua o bassa umidità$t$, $t$può essere soggetta a mosca bianca da serra e ragnetto rosso$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Goeppertia concinna (genere in cui RHS ha riclassificato le specie precedentemente in Calathea; specie rappresentativa scelta come riferimento per la voce generica del catalogo)$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$calathea$t$;
