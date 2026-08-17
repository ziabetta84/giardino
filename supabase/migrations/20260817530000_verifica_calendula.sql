-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce e terreno: RHS conferma esplicitamente terreno povero e
-- drenante ("light, poor, free-draining soil"), validando la bozza già
-- accurata su questo punto. Corretta resistenza_gelo da "media" ad "alta":
-- RHS classifica H5, coerente con la scala già stabilita (H5→alta).
-- Aggiunto un gap di alert reale: la bozza non aveva nessuna informazione
-- su parassiti o malattie (#132).

update specie set esigenze = $j${"luce": "Pieno sole o mezz'ombra", "acqua": "Moderata", "terreno": "Qualsiasi, anche povero"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asteraceae", "giorni_germinazione": "7-14", "giorni_trapianto": "20-30", "giorni_raccolta": null, "finestra_semina": ["primavera", "autunno"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "alta", "spaziatura_cm": 25, "consociazioni_favorevoli": ["pomodoro", "cavolo"], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Si risemina facilmente (spesso spontanea l'anno successivo)$t$, $t$rimuovere i fiori appassiti per prolungare la fioritura$t$, $t$molto rustica e poco esigente$t$, $t$attira impollinatori$t$, $t$può essere soggetta ad afidi$t$, $t$può essere colpita da oidio e da un virus$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Calendula officinalis$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$calendula$t$;
