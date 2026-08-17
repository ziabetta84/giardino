-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Corretta esigenze.luce: la bozza indicava genericamente "molta", ma
-- RHS classifica Position "Partial shade" — corretto in "Luminosa ma
-- indiretta, mezz'ombra: evitare sole diretto", coerente anche con
-- l'alert già presente sulle foglie che si arricciano per troppa luce
-- diretta. Confermati famiglia botanica (Urticaceae) e resistenza_gelo
-- "nessuna": RHS classifica H1C, coerente con la scala già stabilita
-- (H1A/B/C→nessuna). Aggiunto un gap reale non presente in bozza: RHS
-- segnala necessità di umidità ambientale elevata, tendenza del fusto a
-- lignificare alla base, e parassiti/malattie reali (cocciniglie a
-- scudo, oidio) (#132).

update specie set esigenze = $j${"luce": "Luminosa ma indiretta, mezz'ombra: evitare sole diretto", "acqua": "Preferisce ambienti umidi", "terreno": "Preferisce terricci ricchi e ben drenati"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Urticaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Foglie che si arricciano verso il basso → troppa luce diretta o poca acqua$t$, $t$Produce facilmente polloni alla base, ottimi per nuove piante$t$, $t$Ruotare il vaso periodicamente per una crescita simmetrica$t$, $t$Foglie gialle in eccesso → ristagno idrico$t$, $t$richiede umidità ambientale elevata$t$, $t$il fusto tende a lignificare alla base con l'età$t$, $t$può essere soggetta a cocciniglie a scudo$t$, $t$può essere colpita da oidio$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Pilea peperomioides$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$pianta-delle-monete$t$;
