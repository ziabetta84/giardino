-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- esigenze.luce arricchita con mezz'ombra (RHS: Full sun, Partial shade
-- entrambe indicate). terreno arricchito con la preferenza per suoli
-- alcalini (RHS: "any well-drained (preferably alkaline) soil"). Confermata
-- con forza resistenza_gelo "alta": RHS classifica H6 (-20/-15°C), la
-- fascia più resistente della scala. RHS: generalmente priva di parassiti e
-- malattie, coerente con l'unico alert già presente nella bozza (non
-- eccedere con acqua/concime).

update specie set esigenze = $j${"luce": "Pieno sole o mezz'ombra", "acqua": "Irrigare quando il terreno è completamente asciutto", "terreno": "Ben drenato, preferibilmente alcalino"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Lamiaceae", "giorni_germinazione": "10-15", "giorni_trapianto": "30-40", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "alta", "spaziatura_cm": 25, "consociazioni_favorevoli": ["pomodoro", "peperone"], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Non irrigare né concimare troppo, ne risente il profumo$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Origanum vulgare$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$origano$t$;
