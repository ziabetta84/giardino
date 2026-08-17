-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno arricchito. Corretta resistenza_gelo da "media" ad "alta": RHS
-- classifica H5, coerente con la scala già stabilita (H5→alta). Sostituito
-- l'alert generico su afidi con i parassiti reali documentati da RHS
-- (coleottero del rosmarino, cicalina della salvia, cimice verde — RHS non
-- elenca afidi per questa specie) e aggiunte le malattie reali (oidio,
-- verticillosi, marciume del piede, armillaria rara), non presenti nella
-- bozza (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Drenato, moderatamente fertile"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Lamiaceae", "giorni_germinazione": "14-21", "giorni_trapianto": "40-60", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 40, "consociazioni_favorevoli": ["rosmarino", "cavolo"], "consociazioni_sfavorevoli": ["cetriolo"]}$j$::jsonb, alert = ARRAY[$t$Evitare ristagni$t$, $t$teme ristagni idrici$t$, $t$preferisce substrato ben drenante$t$, $t$evitare eccessi di concime$t$, $t$controllare eventuale presenza di afidi in primavera$t$, $t$può essere soggetta a coleottero del rosmarino, cicalina della salvia e cimice verde$t$, $t$può essere colpita da oidio, verticillosi, marciume del piede/radici e raramente armillaria$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Salvia officinalis$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$salvia$t$;
