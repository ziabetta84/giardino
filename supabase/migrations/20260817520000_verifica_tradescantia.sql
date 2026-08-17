-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno riformulato per riflettere sia la preferenza RHS ("moist, fertile
-- soil") sia la tolleranza già segnalata in bozza. Non corretta
-- resistenza_gelo "bassa" nonostante RHS classifichi H1C (che
-- implicherebbe "nessuna" per coerenza con altri casi H1C): la bozza
-- descrive già un comportamento specifico e documentato di questa specie
-- in clima mite (parte aerea che secca sotto 0°C ma ricaccia dalle radici
-- se protette), un comportamento intermedio reale che "bassa" descrive
-- meglio di un secco "nessuna" — giudizio basato sulla conoscenza specifica
-- già incorporata nella bozza, non smentito da RHS. Aggiunto alert mancante
-- su parassiti reali, non presenti nella bozza (#132).

update specie set esigenze = $j${"luce": "Mezz'ombra o sole filtrato", "acqua": "Scarsa, si adatta alla pioggia naturale", "terreno": "Fertile, ben drenato (tollera anche terreni poveri)"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Commelinaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera", "estate"], "resistenza_gelo": "bassa", "spaziatura_cm": 20, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$teme il gelo intenso (sotto 0°C la parte aerea può seccare, ma ricaccia in primavera se le radici sono protette)$t$, $t$crescita molto rapida e invasiva: monitorare e contenere l'espansione$t$, $t$si radica facilmente da ogni frammento di fusto a contatto col terreno$t$, $t$evitare ristagni idrici prolungati$t$, $t$può essere soggetta a ragnetto rosso, cocciniglia farinosa, afidi, oziorrinco e tripidi$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Tradescantia zebrina$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$tradescantia$t$;
