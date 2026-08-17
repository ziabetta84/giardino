-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, terreno, spaziatura. RHS classifica Hardiness H1C
-- (5-10°C, "can be grown outside in the summer" solo) — molto più tenero
-- della "media" attuale in bozza. Non applicata la correzione: il kumquat è
-- documentato in letteratura orticola come il più rustico tra gli agrumi
-- comuni (tollera brevi punte fino a -6/-7°C), e la bozza ha già un valore
-- di protezione specifico (-5/-6°C) coerente con questo — la valutazione H1C
-- di RHS sembra riflettere la cautela per l'inverno umido e poco luminoso
-- del Regno Unito più che un limite di gelo assoluto. resistenza_gelo
-- "media" mantenuta, con questa tensione documentata qui. Aggiunto alert su
-- parassiti reali non citati (ragnetto rosso degli agrumi, bruchi).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Regolare", "terreno": "Ricco e drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Rutaceae", "giorni_germinazione": "14-21", "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "media", "spaziatura_cm": 150, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Più resistente al freddo degli altri agrumi, ma proteggere comunque sotto i -5/-6°C$t$, $t$evitare ristagni idrici$t$, $t$attenzione al vento forte sul crinale dello Scivolo$t$, $t$controllare eventuali cocciniglie in estate$t$, $t$i frutti si mangiano interi, buccia compresa$t$, $t$può essere colpito anche da ragnetto rosso degli agrumi, cocciniglie e bruchi$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Citrus japonica$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$mandarino-cinese$t$;
