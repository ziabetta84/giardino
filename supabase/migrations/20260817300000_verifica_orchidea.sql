-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce (RHS Partial shade, unica posizione indicata) e terreno
-- "Corteccia" (RHS Cultivation: "open bark-based orchid compost",
-- coincide esattamente). Confermata con la massima forza resistenza_gelo
-- "nessuna": RHS classifica H1A, la fascia più tenera possibile (serra
-- riscaldata tutto l'anno, minimo 15°C). spaziatura_cm compilata a 30 (RHS
-- Max Spread 0.1-0.5m, non presente nella bozza — qui, a differenza del
-- ficus bonsai, il dato è applicabile perché non si tratta di una pianta
-- mantenuta artificialmente piccola). finestra_semina/trapianto lasciate
-- vuote: RHS conferma che la propagazione per seme è possibile solo in
-- laboratorio controllato, non praticabile per un coltivatore amatoriale.
-- Aggiunto alert su parassiti reali e sulla pratica corretta di
-- irrigazione (evitare la corona centrale) per prevenire marciumi
-- batterici (#132).

update specie set esigenze = $j${"luce": "Luce diffusa", "acqua": "Moderata", "terreno": "Corteccia"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Orchidaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": [], "resistenza_gelo": "nessuna", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Non esporre a sole diretto$t$, $t$evitare ristagni idrici nel vaso$t$, $t$controllare radici aeree per disidratazione$t$, $t$evitare luce diretta nelle ore centrali$t$, $t$attenzione a muffe se l’umidità del bagno è alta$t$, $t$può essere soggetta a cocciniglie farinose, afidi e cocciniglie a scudo$t$, $t$evitare di bagnare il centro della rosetta fogliare: previene marciumi batterici$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Phalaenopsis$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$orchidea$t$;
