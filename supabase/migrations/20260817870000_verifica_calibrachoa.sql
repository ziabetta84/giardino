-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermata famiglia botanica (Solanaceae, già corretta in bozza).
-- Corretto terreno: la bozza indicava "leggermente acido", ma RHS
-- classifica Soil Types Chalk/Clay/Loam/Sand e pH Acid/Alkaline/Neutral,
-- cioè pianta tollerante anche su terreni calcarei — rimosso di
-- conseguenza l'alert sulla clorosi da pH alto, che RHS smentisce
-- direttamente per questa specie. Corretta resistenza_gelo da "nessuna"
-- a "bassa": RHS classifica H2, coerente con la scala già stabilita
-- (H2→bassa). Aggiunta conferma reale sulla potatura (non richiesta,
-- solo un leggero taglio di rinnovo) e un gap di alert su parassiti e
-- malattie reali, non presenti nella bozza (#132).

update specie set esigenze = $j${"luce": "Sole pieno", "acqua": "Regolare", "terreno": "Fertile, ben drenato, tollera anche calcareo"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Solanaceae", "giorni_germinazione": "10-15", "giorni_trapianto": "30", "giorni_raccolta": null, "finestra_semina": ["inverno", "primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "bassa", "spaziatura_cm": 20, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Sensibile al gelo intenso$t$, $t$ama sole pieno per una fioritura abbondante$t$, $t$teme ristagni idrici$t$, $t$in vaso sospeso si asciuga più rapidamente delle piante a terra$t$, $t$fioritura continua da primavera ad autunno$t$, $t$non richiede potature, salvo un leggero taglio per rinnovare la fioritura$t$, $t$può essere soggetta ad afidi, lumache e limacce$t$, $t$può essere colpita da muffa grigia, marciume del colletto e virosi$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Calibrachoa Aloha Classic Blue Sky ('Duealbusky')$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$calibrachoa$t$;
