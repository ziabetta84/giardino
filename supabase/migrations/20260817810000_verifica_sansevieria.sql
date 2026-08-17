-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno arricchito. Confermata con forza resistenza_gelo "nessuna": RHS
-- classifica H1C. spaziatura_cm compilata a 30 (RHS Max Spread 0.1-0.5m,
-- dato applicabile essendo una normale pianta da vaso). Aggiunto un gap di
-- alert reale: la bozza ne aveva solo uno (sensibilità all'eccesso
-- d'acqua) — RHS aggiunge la nota pratica su tolleranza alla trascuratezza
-- ma necessità di protezione dall'umidità invernale, oltre a un parassita
-- reale (oziorrinco) (#132).

update specie set esigenze = $j${"luce": "Luce diffusa", "acqua": "Scarsa", "terreno": "Molto drenante, neutro o alcalino"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asparagaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Sensibile a eccesso d'acqua$t$, $t$tollera bene la trascuratezza, ma proteggere dall'umidità invernale eccessiva$t$, $t$può essere soggetta a oziorrinco$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Sansevieria trifasciata$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$sansevieria$t$;
