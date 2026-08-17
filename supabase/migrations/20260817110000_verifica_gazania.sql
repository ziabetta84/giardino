-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, famiglia botanica, spaziatura, resistenza_gelo "bassa"
-- (RHS H2, esattamente la fascia già mappata a "bassa" nella scala
-- stabilita). terreno arricchito con "moderatamente fertile" (RHS:
-- "moderately fertile, well-drained soil"). Aggiunto alert minore su
-- parassiti/muffa in caso di svernamento indoor (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Sabbioso, ben drenato, moderatamente fertile"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asteraceae", "giorni_germinazione": "10-15", "giorni_trapianto": "30", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "bassa", "spaziatura_cm": 25, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Chiude i fiori in ombra$t$, $t$richiede pieno sole per aprire i fiori$t$, $t$evitare ristagni idrici (ama terreni sabbiosi e drenanti)$t$, $t$fiori che non si aprono → poca luce$t$, $t$foglie molli → troppa acqua$t$, $t$ottima resistenza alla siccità$t$, $t$se svernata in casa può essere soggetta ad afidi e muffa grigia$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Gazania rigens$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$gazania$t$;
