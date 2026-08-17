-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- esigenze.luce corretta da "Pieno sole o mezz'ombra" a "Pieno sole": RHS
-- mostra solo l'icona Full sun, nessuna opzione mezz'ombra (stesso
-- ragionamento già applicato a sedum-spurium e iberis-sempervirens).
-- Confermati terreno, resistenza_gelo "bassa" (RHS H2, esattamente la
-- fascia già mappata, coerente con l'alert già presente sul ricaccio dalla
-- base sotto i -5°C). spaziatura_cm corretta da 80 a 120: RHS Max Spread
-- 1-1.5m. Aggiunto alert mancante su parassiti reali, non presente nella
-- bozza (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Regolare in estate", "terreno": "Ben drenato, fertile"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Plumbaginaceae", "giorni_germinazione": "14-21", "giorni_trapianto": "40-60", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "bassa", "spaziatura_cm": 120, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$teme il gelo intenso (sotto i -5°C la parte aerea può seccare, ma ricaccia dalla base)$t$, $t$portamento vigoroso e rampicante: necessita di supporto o contenimento$t$, $t$fioritura continua da giugno a ottobre$t$, $t$evitare ristagni idrici$t$, $t$può essere soggetto a ragnetto rosso e mosca bianca da serra$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Plumbago auriculata$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$plumbago$t$;
