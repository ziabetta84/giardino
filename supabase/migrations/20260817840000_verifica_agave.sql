-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Voce generica del catalogo ("Agave sp."), la bozza stessa indicava già
-- "probabile Agave americana" — confermato come riferimento. Confermati
-- luce, terreno. Confermata con precisione resistenza_gelo "bassa": RHS
-- classifica H2, esattamente la fascia già mappata (H2→bassa). spaziatura_cm
-- corretta da 60 a 120: RHS Max Spread 1-1.5m. Aggiunto alert su parassiti
-- reali, non presente nella bozza (#132).

update specie set esigenze = $j${"luce": "Pieno sole / molto luminoso", "acqua": "Scarsa", "terreno": "Molto drenante, sabbioso"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asparagaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "bassa", "spaziatura_cm": 120, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Teme i ristagni idrici più di ogni altra cosa$t$, $t$Da adulta le foglie diventano spinose e appuntite: posizionarla lontano dal passaggio$t$, $t$In casa richiede la posizione più luminosa possibile, idealmente vicino a una finestra/terrazzo esposto a sud$t$, $t$può essere soggetta a cocciniglie a scudo$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Agave americana$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$agave$t$;
