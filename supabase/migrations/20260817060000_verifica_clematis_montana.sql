-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, resistenza_gelo "alta" (RHS H5). spaziatura_cm corretta
-- da 100 a 150: RHS Max Spread 2.5-4m (oltre a un'altezza di 8-12m), la
-- bozza sottostimava nettamente le dimensioni reali di questa rampicante
-- molto vigorosa. Aggiunto alert mancante e importante: RHS segnala il
-- "clematis wilt" (avvizzimento del clematide), malattia specifica del
-- genere potenzialmente grave, non presente nella bozza — oltre a
-- parassiti reali (afidi, lumache, bruchi, forbicine sui petali) (#132).

update specie set esigenze = $j${"luce": "Sole o mezz'ombra", "acqua": "Regolare", "terreno": "Fertile e drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Ranunculaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 150, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Radici all'ombra, fusto al sole$t$, $t$piede ombreggiato, parte alta al sole$t$, $t$evitare ristagni idrici$t$, $t$crescita molto vigorosa$t$, $t$fiorisce su rami dell’anno precedente$t$, $t$può essere colpita da afidi, lumache, bruchi e forbicine (che rodono i petali)$t$, $t$attenzione all'avvizzimento del clematide (clematis wilt), malattia specifica potenzialmente grave$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Clematis montana$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$clematis-montana$t$;
