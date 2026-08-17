-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Voce generica del catalogo ("Lampranthus spp."), verificata su Lampranthus
-- roseus, scelta da Roberta come più aderente alla pianta reale (invece
-- della L. spectabilis inizialmente suggerita). terreno arricchito.
-- Corretta resistenza_gelo da "nessuna" a "bassa": RHS classifica H2,
-- coerente con la scala già stabilita (H2→bassa). RHS: generalmente priva
-- di parassiti e malattie, coerente con l'assenza di alert su questo tema
-- nella bozza.

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Sabbioso, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Aizoaceae", "giorni_germinazione": "10-15", "giorni_trapianto": "30-40", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "bassa", "spaziatura_cm": 25, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Non tollera gelo intenso$t$, $t$richiede pieno sole o luce molto intensa$t$, $t$teme ristagni idrici$t$, $t$ottima resistenza alla siccità$t$, $t$fioritura molto abbondante con luce forte$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Lampranthus roseus (specie scelta da Roberta come più aderente alla pianta reale)$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$mesembriantemo$t$;
