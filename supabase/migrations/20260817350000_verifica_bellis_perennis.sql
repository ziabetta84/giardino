-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, terreno, famiglia botanica, semina/trapianto. Confermata
-- con la massima forza resistenza_gelo "alta": RHS classifica H7 (sotto i
-- -20°C), la fascia più resistente della scala. Aggiunto alert mancante su
-- ruggine (RHS Diseases), non presente nella bozza (#132).

update specie set esigenze = $j${"luce": "Sole o mezz'ombra", "acqua": "Regolare", "terreno": "Fresco"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asteraceae", "giorni_germinazione": "10-15", "giorni_trapianto": "30-40", "giorni_raccolta": null, "finestra_semina": ["primavera", "estate"], "finestra_trapianto": ["autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 15, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$richiede buona luce per fiorire abbondantemente$t$, $t$evitare ristagni idrici$t$, $t$tende ad autoriseminarsi (può espandersi)$t$, $t$foglie gialle → troppa acqua o poca luce$t$, $t$fioritura molto lunga se i fiori secchi vengono rimossi$t$, $t$può essere colpita da ruggine$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Bellis perennis$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$bellis-perennis$t$;
