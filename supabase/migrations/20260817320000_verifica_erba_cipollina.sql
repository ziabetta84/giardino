-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- esigenze.luce arricchita con mezz'ombra (RHS: Full sun, Partial shade).
-- terreno arricchito. Confermata con forza resistenza_gelo "alta": RHS
-- classifica H6 (-20/-15°C). Aggiunti alert mancanti: RHS segnala il
-- rischio di comportamento infestante per autosemina ("potential to become
-- a nuisance") e malattie reali (marciume bianco, peronospora della
-- cipolla), nessuno dei due presente nella bozza (#132).

update specie set esigenze = $j${"luce": "Sole o mezz'ombra", "acqua": "Regolare", "terreno": "Fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Amaryllidaceae", "giorni_germinazione": "14-20", "giorni_trapianto": "40-50", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 20, "consociazioni_favorevoli": ["carota", "pomodoro"], "consociazioni_sfavorevoli": ["fagiolo", "pisello"]}$j$::jsonb, alert = ARRAY[$t$evitare ristagni idrici nel sottovaso$t$, $t$se gli steli ingialliscono → troppa acqua o vaso piccolo$t$, $t$fioritura imminente: possibile calo di produzione fogliare$t$, $t$pianta perenne: rigenera ogni anno$t$, $t$RHS segnala che può diventare infestante se non gestita (si autosemina facilmente)$t$, $t$può essere colpita da marciume bianco della cipolla e peronospora della cipolla$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Allium schoenoprasum$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$erba-cipollina$t$;
