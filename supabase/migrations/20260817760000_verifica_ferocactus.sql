-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Voce generica del catalogo ("Ferocactus sp."), verificata su Ferocactus
-- wislizenii. Mantenuto l'alert "identificazione da confermare" già
-- presente: la specie esatta della pianta reale resta da confermare quando
-- sarà più sviluppata, questa verifica riguarda i dati di coltivazione
-- generici del genere. terreno arricchito. Corretta resistenza_gelo da
-- "nessuna" a "bassa": RHS classifica H2, coerente con la scala già
-- stabilita (H2→bassa). spaziatura_cm corretta da 20 a 70: RHS Max Spread
-- 0.5-1m. Aggiunto alert su parassiti reali, non presente nella bozza
-- (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Sabbioso, molto drenante, con aggiunta di ghiaia"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Cactaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "bassa", "spaziatura_cm": 70, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$identificazione da confermare quando sarà più sviluppato$t$, $t$richiede molta luce diretta$t$, $t$evitare assolutamente ristagni idrici$t$, $t$spine robuste, maneggiare con attenzione$t$, $t$può essere soggetto a cocciniglia farinosa$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Ferocactus wislizenii (specie scelta da Roberta come più aderente alla pianta reale, tra le specie comuni del genere)$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$ferocactus$t$;
