-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, terreno, resistenza_gelo "bassa" (RHS H2, esattamente la
-- fascia già mappata, coerente con l'alert già presente sul gelo sotto
-- 5°C). spaziatura_cm corretta da 30 a 50: RHS Max Spread 0.5-1m. RHS:
-- generalmente priva di parassiti e malattie, nessun alert aggiuntivo
-- necessario.

update specie set esigenze = $j${"luce": "Sole o mezz'ombra", "acqua": "Moderata", "terreno": "Drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Lythraceae", "giorni_germinazione": "14-21", "giorni_trapianto": "30-40", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "bassa", "spaziatura_cm": 50, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$ama sole pieno o mezz’ombra luminosa$t$, $t$fioritura continua$t$, $t$teme freddo sotto 5°C$t$, $t$evitare ristagni idrici$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Cuphea hyssopifolia$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$cuphea$t$;
