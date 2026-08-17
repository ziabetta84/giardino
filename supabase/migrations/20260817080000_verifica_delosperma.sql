-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, terreno, famiglia botanica (Aizoaceae). resistenza_gelo
-- "media" confermata con precisione: RHS classifica H4, esattamente la
-- fascia già mappata a "media" nella scala stabilita. spaziatura_cm
-- corretta da 25 a 50: RHS Max Spread 0.5-1m, sensibilmente più ampio.
-- Aggiunto alert minore su parassiti in coltivazione protetta (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Sabbioso, molto drenante"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Aizoaceae", "giorni_germinazione": "14-21", "giorni_trapianto": "30", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "media", "spaziatura_cm": 50, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Teme i ristagni idrici più del freddo (più rustica al gelo di molte succulente)$t$, $t$richiede pieno sole per fiorire abbondantemente$t$, $t$ottima resistenza alla siccità$t$, $t$perfetta per bordure, muretti e scarpate$t$, $t$fioritura molto lunga da tarda primavera a fine estate$t$, $t$può essere soggetta ad afidi e cocciniglia in coltivazione protetta$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Delosperma cooperi$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$delosperma$t$;
