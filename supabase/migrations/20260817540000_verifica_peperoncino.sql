-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, terreno. Confermata con forza resistenza_gelo "nessuna":
-- RHS classifica H1C (5-10°C, "can be grown outside in the summer" solo),
-- coerente con l'alert già presente e piuttosto cautelativo sul freddo
-- sotto 12°C. Aggiunto alert mancante su parassiti/malattie reali
-- (ragnetto rosso, mosca bianca, muffa grigia), non presenti nella bozza
-- (#132).

update specie set esigenze = $j${"luce": "Pieno sole per almeno 6-8 ore al giorno", "acqua": "Regolare ma senza ristagni; preferisce asciugare leggermente tra un’irrigazione e l’altra", "terreno": "Ricco, drenante, leggermente sabbioso; ideale un terriccio per orticole con aggiunta di perlite"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Solanaceae", "giorni_germinazione": "10-20", "giorni_trapianto": "45-60", "giorni_raccolta": "70-90", "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 40, "consociazioni_favorevoli": ["basilico", "carota"], "consociazioni_sfavorevoli": ["fagiolo", "finocchio"]}$j$::jsonb, alert = ARRAY[$t$Teme i ristagni idrici (rischio marciume del colletto)$t$, $t$Foglie che si afflosciano → carenza d’acqua o vaso troppo piccolo$t$, $t$Fioritura scarsa → poca luce o eccesso di azoto$t$, $t$Ingiallimenti fogliari → irrigazioni irregolari o carenze nutritive$t$, $t$Sensibile al freddo sotto i 12°C$t$, $t$può essere soggetto anche a ragnetto rosso e mosca bianca da serra$t$, $t$può essere colpito da muffa grigia$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Capsicum annuum$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$peperoncino$t$;
