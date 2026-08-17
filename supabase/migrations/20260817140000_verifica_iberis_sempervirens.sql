-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- esigenze.luce corretta da "Pieno sole o mezz'ombra" a "Pieno sole": RHS
-- mostra solo l'icona Full sun, nessuna opzione mezz'ombra (stesso
-- ragionamento già applicato a sedum-spurium). terreno arricchito con
-- tolleranza ai terreni poveri (RHS: "grows well in poor soils").
-- Confermata resistenza_gelo "alta" (RHS H5). Aggiunti alert mancanti: RHS
-- segnala esplicitamente il rischio di comportamento invasivo ("can be
-- invasive") e parassiti reali (lumache, limacce, bruchi), nessuno dei due
-- presente nella bozza (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Moderata", "terreno": "Ben drenato, anche povero"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Brassicaceae", "giorni_germinazione": "14-21", "giorni_trapianto": "30-40", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Teme ristagni$t$, $t$richiede terreno drenante (rischio marciumi se troppo bagnato)$t$, $t$crescita lenta ma molto densa$t$, $t$teme ristagni idrici più del caldo$t$, $t$fioritura scarsa - poca luce o terreno impoverito$t$, $t$perfetta per muretti, bordure e aiuole rocciose$t$, $t$RHS segnala che può diventare invasiva se non contenuta$t$, $t$può essere soggetta a lumache, limacce e bruchi$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Iberis sempervirens$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$iberis-sempervirens$t$;
