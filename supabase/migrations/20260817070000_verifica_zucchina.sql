-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, acqua, terreno, famiglia botanica, semina/trapianto.
-- resistenza_gelo "nessuna" mantenuta (RHS classifica H2, che nella scala
-- già stabilita corrisponderebbe a "bassa", ma per un ortaggio annuale che
-- in pratica muore alla prima gelata "nessuna" resta l'indicazione più
-- utile in pratica per chi coltiva). Aggiunti alert mancanti su lumache e
-- muffa grigia (RHS Pests/Diseases), non presenti nella bozza (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Abbondante", "terreno": "Fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Cucurbitaceae", "giorni_germinazione": "4-14", "giorni_trapianto": "15-20", "giorni_raccolta": "45-60", "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "estate"], "resistenza_gelo": "nessuna", "spaziatura_cm": 90, "consociazioni_favorevoli": ["mais", "fagiolo", "basilico"], "consociazioni_sfavorevoli": ["patata"]}$j$::jsonb, alert = ARRAY[$t$Molto sensibile a oidio in estate avanzata$t$, $t$raccogliere i frutti giovani per stimolare nuova produzione$t$, $t$evitare di bagnare le foglie (favorisce le malattie fungine)$t$, $t$impollinazione manuale utile in assenza di insetti impollinatori$t$, $t$attenzione a lumache e limacce sulle piantine giovani$t$, $t$oltre all'oidio, possibile muffa grigia (botrite)$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Cucurbita pepo$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$zucchina$t$;
