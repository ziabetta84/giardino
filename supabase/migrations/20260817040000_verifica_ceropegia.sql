-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- finestra_semina era vuota, RHS conferma propagazione anche per seme (oltre
-- a bulbilli e talea) in primavera: compilata. finestra_trapianto arricchita
-- con "estate" (talee di fusto in inizio estate secondo RHS). spaziatura_cm
-- compilata a 50 (RHS Max Spread 0.5-1m, non presente nella bozza). terreno
-- arricchito con indicazione pratica (terriccio per cactacee). Confermato
-- resistenza_gelo "nessuna": RHS H1C. Aggiunti alert reali su parassiti e
-- marciume basale da eccesso d'acqua invernale (#132).

update specie set esigenze = $j${"luce": "Luce diffusa", "acqua": "Scarsa", "terreno": "Drenato (terriccio per cactacee)"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Apocynaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "estate"], "resistenza_gelo": "nessuna", "spaziatura_cm": 50, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Sensibile a eccesso d'acqua$t$, $t$evitare assolutamente ristagni idrici$t$, $t$luce intensa ma indiretta per mantenere la variegatura$t$, $t$se le foglie diventano pallide → luce insufficiente$t$, $t$se le foglie si raggrinziscono → sete$t$, $t$se i tralci diventano troppo sottili → troppa ombra$t$, $t$può essere soggetta a cocciniglia, afidi e cocciniglie a scudo$t$, $t$rischio di marciume basale se troppo bagnata in inverno$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Ceropegia woodii$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$ceropegia$t$;
