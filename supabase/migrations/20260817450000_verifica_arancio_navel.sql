-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, terreno. Confermata con precisione resistenza_gelo
-- "bassa": RHS classifica H2, esattamente la fascia già mappata, coerente
-- con l'alert già presente sulla protezione dal gelo. spaziatura_cm (300)
-- NON corretta: la bozza è già più generosa del Max Spread RHS (1-1.5m),
-- plausibile per un arancio adulto in piena terra nel tempo (stesso
-- ragionamento già applicato a ulivo e mandarino-cinese). Aggiunto alert
-- su ragnetto rosso degli agrumi, non presente nella bozza (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Regolare", "terreno": "Ricco e drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Rutaceae", "giorni_germinazione": "14-21", "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "bassa", "spaziatura_cm": 300, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Proteggere dal gelo$t$, $t$evitare ristagni idrici$t$, $t$preferisce terreno drenante$t$, $t$attenzione al vento forte sul crinale$t$, $t$controllare eventuali cocciniglie in estate$t$, $t$proteggere il colletto da eccessiva umidità$t$, $t$può essere colpito anche da ragnetto rosso degli agrumi, oltre alle cocciniglie già segnalate$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Citrus × aurantium (Sweet Orange Group) 'Navelina'$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$arancio-navel$t$;
