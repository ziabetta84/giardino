-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno arricchito. Corretta con forza resistenza_gelo da "media" ad
-- "alta": RHS classifica H6 (-20/-15°C), molto più rustica di quanto la
-- bozza indicasse — le fragole sopravvivono bene all'inverno in piena
-- terra, coerente con l'esperienza comune. Aggiunto un gap di alert reale:
-- oltre a oidio, ragnetto rosso e afidi già segnalati, RHS elenca anche
-- lumache, limacce, larve di oziorrinco, virus della fragola e marciume
-- radicale (#132).

update specie set esigenze = $j${"luce": "Sole", "acqua": "Regolare", "terreno": "Ricco, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Rosaceae", "giorni_germinazione": "14-21", "giorni_trapianto": "30-40", "giorni_raccolta": "60-90", "finestra_semina": ["inverno", "primavera"], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 30, "consociazioni_favorevoli": ["aglio", "lattuga", "spinacio"], "consociazioni_sfavorevoli": ["cavolo"]}$j$::jsonb, alert = ARRAY[$t$Sensibile a oidio$t$, $t$evitare ristagni idrici (rischio marciumi)$t$, $t$se le foglie ingialliscono → carenza di nutrienti o vaso troppo piccolo$t$, $t$se i frutti restano piccoli → poca luce o poca acqua$t$, $t$controllare afidi e ragnetto rosso in primavera-estate$t$, $t$può essere colpita anche da lumache, limacce e larve di oziorrinco$t$, $t$può essere soggetta a virus della fragola e marciume radicale$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Fragaria × ananassa$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$fragola-rifiorente$t$;
