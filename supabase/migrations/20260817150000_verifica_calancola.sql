-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- esigenze.luce corretta da "Luce intensa" (generico) a una formulazione
-- più precisa: RHS mostra Position "Partial shade" (mezz'ombra), non pieno
-- sole — coerente con l'uso comune di questa Kalanchoe fiorita come pianta
-- da interno in luce intensa ma non diretta. terreno arricchito con il
-- dettaglio pratico RHS ("loam-based potting compost with added extra
-- grit"). Confermata resistenza_gelo "nessuna" (RHS H1B). Aggiunto alert
-- mancante su parassiti reali (#132).

update specie set esigenze = $j${"luce": "Luce intensa, ma non sole diretto (mezz'ombra luminosa)", "acqua": "Scarsa", "terreno": "Drenato, con aggiunta di sabbia grossa o ghiaia"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Crassulaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 20, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Evitare ristagni$t$, $t$evitare ristagni idrici (rischio marciumi)$t$, $t$richiede molta luce per mantenere la fioritura$t$, $t$foglie molli → troppa acqua$t$, $t$foglie opache o allungate → poca luce$t$, $t$pianta succulenta: meglio poca acqua che troppa$t$, $t$può essere soggetta a cocciniglia farinosa e oziorrinco$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Kalanchoe blossfeldiana$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$calancola$t$;
