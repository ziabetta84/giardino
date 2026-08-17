-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, terreno, resistenza_gelo "nessuna" (RHS H1C, molto
-- tenera). Aggiunti parassiti/malattie reali non presenti nella bozza
-- (nottua del pomodoro, marciume apicale, carenza di magnesio, virus
-- dell'avvizzimento maculato, muffa grigia), oltre a quelli già segnalati
-- (afidi, mosca bianca, peronospora) (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Regolare e abbondante", "terreno": "Fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Solanaceae", "giorni_germinazione": "7-14", "giorni_trapianto": "45-60", "giorni_raccolta": "60-85", "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 50, "consociazioni_favorevoli": ["basilico", "prezzemolo", "sedano", "carota", "cipolla"], "consociazioni_sfavorevoli": ["finocchio", "cavolo", "patata"]}$j$::jsonb, alert = ARRAY[$t$Teme i ristagni idrici (rischio marciume radicale)$t$, $t$necessita di tutori/sostegni, soprattutto per le varietà a crescita indeterminata$t$, $t$controllare afidi e mosca bianca$t$, $t$rischio peronospora con umidità elevata e scarsa ventilazione$t$, $t$rimuovere i succhioni ascellari per favorire la fruttificazione$t$, $t$attenzione anche a nottua del pomodoro (tomato moth)$t$, $t$può essere colpito da marciume apicale, carenza di magnesio, virus dell'avvizzimento maculato e muffa grigia sotto vetro$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Solanum lycopersicum$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$pomodoro$t$;
