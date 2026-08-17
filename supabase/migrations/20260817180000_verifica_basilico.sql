-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, resistenza_gelo "nessuna" (RHS H1C, molto tenera,
-- coerente con "cresce come annuale, si può spostare fuori in estate").
-- terreno arricchito. Aggiunto un gap di alert reale: la bozza non aveva
-- nessuna informazione su parassiti o malattie — RHS elenca afidi, lumache,
-- limacce, cicalina della salvia e oidio, nessuno presente prima (#132).

update specie set esigenze = $j${"luce": "Sole", "acqua": "Regolare", "terreno": "Fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Lamiaceae", "giorni_germinazione": "15-20", "giorni_trapianto": "25-30", "giorni_raccolta": "60-70", "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 25, "consociazioni_favorevoli": ["pomodoro", "peperone", "melanzana"], "consociazioni_sfavorevoli": ["ruta"]}$j$::jsonb, alert = ARRAY[$t$Soffre freddo e vento$t$, $t$rischio filatura se luce insufficiente$t$, $t$evitare ristagni idrici nel sottovaso$t$, $t$controllare secchezza del substrato nei giorni caldi$t$, $t$pianta annuale: tende a indebolirsi a fine stagione$t$, $t$può essere soggetto ad afidi, lumache, limacce e cicalina della salvia$t$, $t$può essere colpito da oidio$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Ocimum basilicum$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$basilico$t$;
