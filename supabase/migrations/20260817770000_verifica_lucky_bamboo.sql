-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermata luce (RHS Partial shade, "protection from hot, direct sun",
-- coerente con "non sole diretto" già in bozza). Confermata con forza
-- resistenza_gelo "nessuna": RHS classifica H1B. spaziatura_cm compilata a
-- 30 (RHS Max Spread 0.1-0.5m, dato applicabile essendo una normale pianta
-- da vaso). Aggiunto alert mancante su parassiti reali, non presente nella
-- bozza (#132). Non toccato terreno: la bozza distingue correttamente tra
-- coltivazione in acqua (uso più comune per questa specie, il "vero" lucky
-- bamboo) e in vaso con substrato, dettaglio pratico non coperto da RHS.

update specie set esigenze = $j${"luce": "Molta luce, non sole diretto", "acqua": "Coltivato in acqua", "terreno": "Nessuno se coltivato in acqua; substrato drenante se trapiantato in vaso con terra"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asparagaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": [], "resistenza_gelo": "nessuna", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Se coltivato in acqua, cambiarla ogni 1-2 settimane per evitare ristagni e alghe$t$, $t$Il cloro dell'acqua di rubinetto può danneggiarlo: meglio acqua decantata o filtrata$t$, $t$Foglie che ingialliscono → eccesso di luce diretta o acqua stagnante$t$, $t$Non è un vero bambù (è una Dracaena): non produce germogli commestibili$t$, $t$può essere soggetto a cocciniglie farinose e cocciniglie a scudo$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Dracaena sanderiana$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$lucky-bamboo$t$;
