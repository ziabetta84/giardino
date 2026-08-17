-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Corretto un errore reale pre-esistente: famiglia_botanica era
-- "Ericaceae" (dedotta dal nome comune "erica"), ma Cuphea hyssopifolia
-- appartiene alle Lythraceae — non è un'erica vera, la somiglianza è
-- solo nell'aspetto/nome comune. Corretta di conseguenza anche la
-- colonna famiglia_botanica top-level. Corretta resistenza_gelo da
-- "media" a "bassa": RHS classifica H2, coerente con la scala già
-- stabilita (H2→bassa) — la soglia "sotto 5°C" già presente in bozza
-- era comunque nell'ordine di grandezza giusto. Confermati luce, terreno.
-- Aggiunta conferma reale RHS: generalmente esente da parassiti e
-- malattie, non presente nella bozza (#132).

update specie set esigenze = $j${"luce": "Sole o mezz'ombra", "acqua": "Moderata", "terreno": "Drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Lythraceae", "giorni_germinazione": "20-30", "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["autunno"], "resistenza_gelo": "bassa", "spaziatura_cm": 40, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$nonostante il nome comune non è un'erica: appartiene alla famiglia Lythraceae, non alle Ericaceae$t$, $t$ama sole pieno o mezz'ombra, ma va riparata dal sole cocente nelle ore più calde$t$, $t$fioritura molto lunga$t$, $t$teme il gelo$t$, $t$evitare ristagni idrici$t$, $t$generalmente esente da parassiti e malattie$t$], famiglia_botanica = $t$Lythraceae$t$, fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Cuphea hyssopifolia$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$erica-del-messico$t$;
