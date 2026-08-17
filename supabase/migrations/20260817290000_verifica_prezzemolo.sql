-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Corretta con forza resistenza_gelo da "bassa" ad "alta": RHS classifica H6
-- (-20/-15°C, "hardy in all of UK and northern Europe") — il prezzemolo è
-- molto più rustico di quanto la bozza indicasse, coerente con l'esperienza
-- comune che sopravvive all'inverno in piena terra. esigenze.luce arricchita
-- con mezz'ombra (RHS: Full sun, Partial shade). terreno arricchito.
-- Confermato ciclo_vitale "biennale" (RHS: "aromatic biennials"). Aggiunto
-- un gap di alert reale: la bozza non aveva nessuna informazione su
-- parassiti o malattie (#132).

update specie set esigenze = $j${"luce": "Sole o mezz'ombra", "acqua": "Regolare", "terreno": "Fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Apiaceae", "giorni_germinazione": "10-20", "giorni_trapianto": "30-40", "giorni_raccolta": "15-20", "finestra_semina": ["primavera", "estate"], "finestra_trapianto": ["primavera", "estate"], "resistenza_gelo": "alta", "spaziatura_cm": 10, "consociazioni_favorevoli": ["pomodoro", "asparago"], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$evitare ristagni idrici nel sottovaso$t$, $t$foglie gialle alla base → normale ricambio, ma controllare eccesso d’acqua$t$, $t$se gli steli diventano sottili → luce insufficiente$t$, $t$pianta biennale: tende a fiorire il secondo anno$t$, $t$può essere soggetto a mosca della carota, afidi e minatrice fogliare del sedano$t$, $t$può essere colpito da maculatura fogliare e da un virus$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Petroselinum crispum$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$prezzemolo$t$;
