-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno arricchito. Corretta resistenza_gelo da "bassa" a "nessuna": RHS
-- classifica H1C (5-10°C, "can be grown outside in the summer" solo), più
-- tenera di H2 (già mappato a "bassa"). spaziatura_cm corretta da 30 a 100:
-- RHS Max Spread 1-1.5m, molto più ampio della bozza. Aggiunto alert
-- mancante su parassiti reali (afidi, cocciniglia farinosa), non presente
-- nella bozza (#132).

update specie set esigenze = $j${"luce": "Pieno sole / molto luminoso", "acqua": "Scarsa", "terreno": "Molto drenante, con aggiunta di ghiaia o sabbia grossa"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Crassulaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 100, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$cresce in autunno-primavera, va in semi-riposo in estate (perdita di qualche foglia basale è normale)$t$, $t$teme il gelo intenso e prolungato$t$, $t$evitare ristagni idrici$t$, $t$si propaga facilmente per talea di fusto$t$, $t$può essere soggetto ad afidi e cocciniglia farinosa$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Aeonium arboreum$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$aeonium$t$;
