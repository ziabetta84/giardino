-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno arricchito. Confermata con forza resistenza_gelo "nessuna": RHS
-- classifica H1B (10-15°C, molto tenera). spaziatura_cm lasciata null
-- intenzionalmente: RHS riporta Max Height "4-8 metres" e Max Spread
-- "1-1.5 metres", dati riferiti alla pianta rampicante matura in natura o
-- su supporto esterno, non applicabili a un pothos da appartamento
-- mantenuto compatto tramite potature regolari (stesso ragionamento già
-- applicato a ficus-ginseng). RHS: generalmente priva di parassiti e
-- malattie, coerente con le note pratiche già presenti in bozza.

update specie set esigenze = $j${"luce": "Luce diffusa", "acqua": "Moderata", "terreno": "Fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Araceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera", "estate"], "resistenza_gelo": "nessuna", "spaziatura_cm": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Foglie che ingialliscono → eccesso di acqua o troppa luce diretta$t$, $t$Perde le variegature se riceve poca luce$t$, $t$Le talee in acqua radicano facilmente$t$, $t$Tollera bene la dimenticanza: meglio annaffiare poco che troppo$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Epipremnum aureum$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$pothos$t$;
