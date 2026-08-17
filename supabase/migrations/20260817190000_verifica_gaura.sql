-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno corretto: la bozza descriveva solo l'estremo di tolleranza
-- ("Povero e asciutto"), mentre RHS indica come condizione preferita
-- "fertile, moist but well-drained soil", con la siccità/terreno povero
-- solo tollerati — riformulato per riflettere entrambi. spaziatura_cm
-- corretta da 40 a 70: RHS Max Spread 0.5-1m. Confermata resistenza_gelo
-- "media" (RHS H4, esattamente la fascia già mappata). RHS: generalmente
-- priva di parassiti e malattie, nessun alert aggiuntivo necessario.

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Poca", "terreno": "Fertile, ben drenato (tollera anche terreni poveri e asciutti)"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Onagraceae", "giorni_germinazione": "14-21", "giorni_trapianto": "40-60", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "media", "spaziatura_cm": 70, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Radice a fittone profonda: si adatta male a trapianti ripetuti da adulta$t$, $t$Molto tollerante alla siccità una volta ambientata$t$, $t$Portamento leggero, può piegarsi col vento: valutare un tutore$t$, $t$Fiorisce da primavera fino ad autunno inoltrato$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Oenothera lindheimeri (sinonimo Gaura lindheimeri)$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$gaura$t$;
