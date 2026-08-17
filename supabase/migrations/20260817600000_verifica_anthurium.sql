-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermata luce (RHS Partial shade, unica posizione). terreno arricchito
-- con la nota sul pH acido (RHS: "acidic potting mix"). Confermata con la
-- massima forza resistenza_gelo "nessuna": RHS classifica H1A, la fascia
-- più tenera possibile. spaziatura_cm compilata a 30 (RHS Max Spread
-- 0.1-0.5m, dato applicabile trattandosi di una normale pianta da vaso, non
-- di un esemplare mantenuto artificialmente piccolo). Aggiunto alert
-- mancante su parassiti/malattie reali, non presenti nella bozza (#132).

update specie set esigenze = $j${"luce": "Luce diffusa", "acqua": "Moderata", "terreno": "Ricco, drenato, leggermente acido"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Araceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Non esporre a sole diretto$t$, $t$evitare luce diretta (brucia foglie e fiori)$t$, $t$mantenere alta umidità ambientale$t$, $t$evitare ristagni idrici (rischio marciumi radicali)$t$, $t$usare acqua non calcarea per evitare macchie sulle foglie$t$, $t$se le foglie diventano opache → poca umidità o troppa luce$t$, $t$può essere soggetto a cocciniglie farinose e cocciniglie a scudo$t$, $t$può essere colpito da maculatura fogliare e marciume radicale da eccesso d'acqua$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Anthurium andraeanum$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$anthurium$t$;
