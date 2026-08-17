-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno arricchito. Confermata con precisione resistenza_gelo "media":
-- RHS classifica H3, esattamente la fascia già mappata a "media" nella
-- scala stabilita. spaziatura_cm (60) NON corretta nonostante RHS indichi
-- Max Spread 1-1.5m per la specie: la bozza segnala già esplicitamente
-- trattarsi di una "cultivar compatta (60-80 cm)", più piccola della specie
-- standard — spiegazione già presente e plausibile, non in contraddizione
-- con la fonte generale di specie. RHS: generalmente priva di parassiti e
-- malattie.

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Moderata", "terreno": "Drenato, moderatamente fertile"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Poaceae", "giorni_germinazione": "14-21", "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "media", "spaziatura_cm": 60, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$cultivar compatta (60–80 cm) → ideale per bordure e aiuole strette$t$, $t$richiede terreno drenante (evitare ristagni)$t$, $t$taglio annuale indispensabile a fine inverno$t$, $t$in ombra fitta produce poche spighe$t$, $t$molto resistente una volta stabilito$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Pennisetum alopecuroides$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$pennisetum-cinese$t$;
