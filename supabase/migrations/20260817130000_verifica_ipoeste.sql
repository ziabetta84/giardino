-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, terreno, resistenza_gelo "nessuna" (RHS H1B, molto
-- tenera). finestra_trapianto arricchita con "estate" (RHS: talee semi-ripe
-- in estate, oltre a quelle softwood in tarda primavera). Aggiunto alert
-- mancante su oidio (RHS Diseases), non presente nella bozza (#132).

update specie set esigenze = $j${"luce": "Luce diffusa", "acqua": "Regolare", "terreno": "Ricco"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Acanthaceae", "giorni_germinazione": "14-21", "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "estate"], "resistenza_gelo": "nessuna", "spaziatura_cm": 20, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$richiede luce intensa per mantenere la variegatura$t$, $t$se si allunga troppo → luce insufficiente$t$, $t$foglie afflosciate → poca acqua$t$, $t$bordi secchi → aria troppo secca$t$, $t$evitare ristagni idrici$t$, $t$può essere soggetta a oidio$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Hypoestes phyllostachya$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$ipoeste$t$;
