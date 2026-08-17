-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Corretta un'incoerenza interna della bozza: esigenze.luce era già "Pieno
-- sole" (corretto, RHS mostra solo l'icona Full sun) ma un alert affermava
-- "ama sole o mezz'ombra luminosa", in contraddizione — rimosso l'alert
-- erroneo. terreno arricchito. Confermata con precisione resistenza_gelo
-- "media": RHS classifica H4, esattamente la fascia già mappata. RHS:
-- generalmente priva di parassiti e malattie, nessun alert aggiuntivo
-- necessario.

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Drenato, da medio a leggero, moderatamente fertile"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Poaceae", "giorni_germinazione": "14-21", "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "media", "spaziatura_cm": 40, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$richiede terreno drenante$t$, $t$teme ristagni idrici più del freddo$t$, $t$non va tagliata a raso$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Stipa tenuissima$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$stipa-tenuissima$t$;
