-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- esigenze.luce arricchita con mezz'ombra (RHS: Full sun, Partial shade,
-- "although tolerant of some shade"). terreno arricchito. Confermata con
-- precisione resistenza_gelo "alta": RHS classifica H5, esattamente la
-- fascia già mappata. RHS: generalmente priva di parassiti e malattie,
-- coerente con "molto rustica" già presente in bozza.

update specie set esigenze = $j${"luce": "Sole o mezz'ombra", "acqua": "Moderata", "terreno": "Fertile, ben drenato, ricco di sostanza organica"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asteraceae", "giorni_germinazione": "14-21", "giorni_trapianto": "60-90", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 40, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$ama sole pieno o mezz’ombra luminosa$t$, $t$attira impollinatori$t$, $t$molto rustica$t$, $t$teme ristagni idrici$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Echinacea purpurea$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$echinacea$t$;
