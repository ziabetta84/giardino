-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno arricchito con il dettaglio pratico RHS (perlite). Confermata
-- resistenza_gelo "nessuna" (RHS H1C, molto tenera). Aggiunto un gap di
-- alert reale: la bozza non aveva nessuna informazione su parassiti o
-- malattie — RHS elenca larve di oziorrinco, cocciniglie e marciume di
-- colletto/radici, nessuno presente prima (#132).

update specie set esigenze = $j${"luce": "Molto luminosa, sole diretto alcune ore", "acqua": "Scarsa", "terreno": "Molto drenante, con aggiunta di perlite"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Crassulaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 15, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$le foglie si staccano facilmente al tocco: maneggiare con cura$t$, $t$evitare assolutamente ristagni idrici$t$, $t$se etiola (fusti allungati e radi) → luce insufficiente$t$, $t$foglie rugose e svuotate → sete prolungata$t$, $t$può essere soggetto a larve di oziorrinco, cocciniglie a scudo e cocciniglia farinosa$t$, $t$può essere colpito da marciume di colletto/radici fungino o batterico$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Sedum morganianum$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$sedum-morganianum$t$;
