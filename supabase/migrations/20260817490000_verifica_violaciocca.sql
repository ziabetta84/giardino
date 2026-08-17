-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno arricchito. Corretta resistenza_gelo da "alta" a "media": RHS
-- classifica H4, coerente con la scala già stabilita (H4→media). Aggiunto
-- un gap di alert consistente: la bozza non aveva nessuna informazione su
-- parassiti o malattie, nonostante Matthiola sia una Brassicaceae soggetta
-- alle stesse problematiche di cavoli e affini — RHS elenca afidi, altica,
-- mosca del cavolo, ernia del cavolo, peronospora, marciume radicale e un
-- virus (#132).

update specie set esigenze = $j${"luce": "Sole", "acqua": "Moderata", "terreno": "Fertile, ben drenato, neutro o leggermente alcalino"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Brassicaceae", "giorni_germinazione": "10-15", "giorni_trapianto": "30-40", "giorni_raccolta": null, "finestra_semina": ["estate"], "finestra_trapianto": ["autunno"], "resistenza_gelo": "media", "spaziatura_cm": 25, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$ama sole pieno$t$, $t$teme caldo eccessivo$t$, $t$fioritura profumata$t$, $t$evitare ristagni$t$, $t$può essere soggetta ad afidi, altica e mosca del cavolo$t$, $t$può essere colpita da ernia del cavolo, peronospora, marciume radicale e un virus$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Matthiola incana$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$violaciocca$t$;
