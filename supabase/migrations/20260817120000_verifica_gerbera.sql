-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Corretta resistenza_gelo da "bassa" a "nessuna": RHS classifica H1C
-- (5-10°C, "can be grown outside in the summer" solo), più tenera della
-- fascia H2→"bassa" già stabilita — coerente con la classificazione più
-- tenera già usata per specie H1C come geranio-zonale. Aggiunto un gap di
-- alert consistente: la bozza non aveva nessuna informazione su parassiti o
-- malattie (solo note sulla fisiologia dello stelo fiorale) — RHS elenca
-- parassiti e malattie reali specifiche non presenti prima (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Regolare", "terreno": "Fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asteraceae", "giorni_germinazione": "10-20", "giorni_trapianto": "40-50", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$scapo fiorale corto/debole e ripiegato → luce insufficiente o rosetta di foglie troppo fitta che ostacola lo sviluppo dritto dello stelo$t$, $t$fiori che si aprono schiacciati con petali mancanti su un lato → sviluppo meccanico impedito, non danno da parassiti$t$, $t$evitare eccesso di azoto: favorisce steli deboli$t$, $t$assicurare buon apporto di potassio per irrobustire i tessuti dello scapo$t$, $t$teme i ristagni idrici a livello del colletto$t$, $t$può essere soggetta a mosca bianca, minatrice fogliare del crisantemo, afidi e acari tarsonemidi$t$, $t$può essere colpita da muffa grigia, maculatura fogliare e marciume radicale$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Gerbera jamesonii$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$gerbera$t$;
