-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno arricchito. Confermati luce (RHS Full sun, Partial shade, coerente
-- con l'alert già presente sulla variabilità tra varietà). Confermata con
-- la massima forza resistenza_gelo "alta": RHS classifica H7 (sotto i
-- -20°C). Aggiunto alert mancante su afidi, non presente nella bozza
-- (#132).

update specie set esigenze = $j${"luce": "Sole o mezz'ombra", "acqua": "Moderata", "terreno": "Fresco, fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Cyperaceae", "giorni_germinazione": "20-30", "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$richiede terreno drenante (evitare ristagni)$t$, $t$alcune varietà preferiscono mezz’ombra, altre più sole$t$, $t$foglie che ingialliscono → troppa acqua o terreno compattato$t$, $t$crescita lenta ma molto ordinata$t$, $t$ottima come pianta strutturale e riempitiva$t$, $t$può essere soggetta ad afidi$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Carex oshimensis$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$carex$t$;
