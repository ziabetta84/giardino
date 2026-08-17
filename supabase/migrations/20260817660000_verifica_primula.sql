-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Non ampliata esigenze.luce nonostante RHS elenchi anche "Full sun" oltre
-- a "Partial shade": la bozza segnala già esplicitamente che la specie
-- soffre il caldo estivo, giudizio di adattamento al clima mediterraneo
-- coerente con casi analoghi già trattati — mantenuta "Mezz'ombra". terreno
-- arricchito. Confermata con la massima forza resistenza_gelo "alta": RHS
-- classifica H7 (sotto i -20°C). Aggiunto un gap di alert reale: la bozza
-- non aveva nessuna informazione su parassiti o malattie, nonostante RHS ne
-- elenchi diverse (#132).

update specie set esigenze = $j${"luce": "Mezz'ombra", "acqua": "Regolare", "terreno": "Fresco, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Primulaceae", "giorni_germinazione": "14-21", "giorni_trapianto": "40-60", "giorni_raccolta": null, "finestra_semina": ["estate"], "finestra_trapianto": ["autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 20, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Soffre caldo estivo$t$, $t$richiede terreno fresco ma ben drenante$t$, $t$evitare ristagni idrici (rischio marciumi al colletto)$t$, $t$foglie molli → troppa acqua$t$, $t$foglie bruciate → troppo sole nelle ore calde$t$, $t$fioritura scarsa → poca luce o terreno impoverito$t$, $t$può essere soggetta ad afidi, oziorrinco, lumache, nematodi fogliari e ragnetto rosso$t$, $t$può essere colpita da maculatura fogliare e muffa grigia$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Primula vulgaris$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$primula$t$;
