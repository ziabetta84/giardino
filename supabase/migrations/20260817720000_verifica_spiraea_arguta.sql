-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- esigenze.luce arricchita con mezz'ombra (RHS: Full sun, Partial shade).
-- terreno arricchito. Confermata con forza resistenza_gelo "alta": RHS
-- classifica H6 (-20/-15°C). spaziatura_cm corretta da 100 a 150: RHS Max
-- Spread 1.5-2.5m. Aggiunto alert minore su armillaria rara.

update specie set esigenze = $j${"luce": "Sole o mezz'ombra", "acqua": "Moderata", "terreno": "Drenato, tollera la maggior parte dei terreni"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Rosaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 150, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Potare dopo la fioritura$t$, $t$richiede terreno drenante (evitare ristagni)$t$, $t$fiorisce su rami dell’anno precedente → potare solo dopo la fioritura$t$, $t$foglie che seccano ai bordi → terreno troppo asciutto$t$, $t$crescita rapida: può espandersi molto$t$, $t$tollera bene vento e freddo$t$, $t$raramente può essere colpita da armillaria$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Spiraea 'Arguta'$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$spiraea-arguta$t$;
