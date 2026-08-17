-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce (RHS Partial shade, unica posizione, coerente con "mai
-- sole diretto" già in bozza), terreno, famiglia botanica. Confermata con
-- la massima forza resistenza_gelo "nessuna": RHS classifica H1A, la fascia
-- più tenera possibile. Aggiunto un gap di alert reale: la bozza non aveva
-- nessuna informazione su parassiti o malattie (#132).

update specie set esigenze = $j${"luce": "Luce indiretta filtrata, mai sole diretto", "acqua": "Costante, terreno sempre leggermente umido", "terreno": "Ricco, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Acanthaceae", "giorni_germinazione": "14-21", "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 15, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$foglie che si afflosciano vistosamente → terreno troppo asciutto, annaffiare subito (di solito recupera in poche ore)$t$, $t$ama umidità ambientale elevata, soffre l'aria secca dei riscaldamenti$t$, $t$evitare sole diretto: scotta le foglie sottili$t$, $t$tende ad allungarsi (etiolare) con luce insufficiente$t$, $t$può essere soggetta a ragnetto rosso e cocciniglia farinosa$t$, $t$può essere colpita da muffa grigia$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Fittonia albivenis Argyroneura Group$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$fittonia$t$;
