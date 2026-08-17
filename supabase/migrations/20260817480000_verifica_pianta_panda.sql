-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- esigenze.luce precisata da "Luce intensa" a "Pieno sole": RHS mostra solo
-- l'icona Full sun, nessuna opzione mezz'ombra. terreno arricchito.
-- Confermata con forza resistenza_gelo "nessuna": RHS classifica H1B.
-- Aggiunto alert mancante su oidio e ruggine (RHS Diseases), non presenti
-- nella bozza (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Drenato, con aggiunta di sabbia grossa o ghiaia"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Crassulaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 20, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$evitare assolutamente ristagni idrici$t$, $t$richiede molta luce per mantenere la forma compatta$t$, $t$foglie molli → troppa acqua$t$, $t$foglie raggrinzite → sete$t$, $t$evitare di bagnare le foglie (sono vellutate e trattengono umidità)$t$, $t$può essere colpita da oidio e da una ruggine$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Kalanchoe tomentosa$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$pianta-panda$t$;
