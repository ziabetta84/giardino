-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno arricchito con preferenza per suoli alcalini (RHS: "well-drained,
-- neutral to alkaline soil"). Confermata resistenza_gelo "alta" (RHS H5).
-- Aggiunto alert mancante su lumache/limacce (RHS Pests), non presente
-- nella bozza (#132).

update specie set esigenze = $j${"luce": "Sole", "acqua": "Moderata", "terreno": "Drenato, moderatamente fertile, preferibilmente alcalino"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Caryophyllaceae", "giorni_germinazione": "14-21", "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$ama sole pieno$t$, $t$tappezzante vigorosa$t$, $t$teme ristagni$t$, $t$fioritura rosa molto abbondante$t$, $t$può essere soggetta a lumache e limacce$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Saponaria ocymoides$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$saponaria$t$;
