-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, famiglia botanica. terreno arricchito. Confermata con
-- precisione resistenza_gelo "bassa": RHS classifica H2, esattamente la
-- fascia già mappata, coerente con l'alert già presente sul gelo sotto
-- 0°C. Aggiunto un gap di alert reale: la bozza non aveva nessuna
-- informazione su parassiti o malattie — RHS elenca minatori fogliari e
-- galla batterica (#132).

update specie set esigenze = $j${"luce": "Sole", "acqua": "Moderata", "terreno": "Drenato, moderatamente fertile"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asteraceae", "giorni_germinazione": "10-15", "giorni_trapianto": "30-40", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "bassa", "spaziatura_cm": 40, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$ama sole pieno$t$, $t$teme freddo sotto 0°C$t$, $t$fioritura molto lunga$t$, $t$evitare ristagni$t$, $t$può essere soggetta a minatori fogliari$t$, $t$occasionalmente può essere colpita da galla batterica del colletto$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Argyranthemum frutescens subsp. canariae$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$margherita-delle-canarie$t$;
