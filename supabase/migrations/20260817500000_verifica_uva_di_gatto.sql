-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Consolidati alert duplicati/ridondanti già presenti in bozza (diverse
-- coppie di note quasi identiche su taglio foglie, irrigazione estiva,
-- fioritura scarsa — probabilmente da passaggi di compilazione
-- sovrapposti), mantenendo il contenuto informativo. terreno arricchito.
-- Confermata con la massima forza resistenza_gelo "alta": RHS classifica
-- H6 (-20/-15°C). Aggiunto alert mancante su malattie reali (infezioni
-- fungine/ruggini, marciume batterico, virus), non presenti nella bozza
-- (#132). Confermata la nota già presente su naturalizzazione, coerente
-- con RHS "may be invasive".

update specie set esigenze = $j${"luce": "Sole o mezz'ombra", "acqua": "Moderata in primavera, quasi nulla in estate", "terreno": "Ben drenato, moderatamente fertile"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asparagaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 8, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$non tagliare le foglie verdi finché non ingialliscono dopo la fioritura$t$, $t$evitare irrigazioni estive (riposo vegetativo del bulbo)$t$, $t$fioritura scarsa se i bulbi sono piantati troppo in profondità o con poca luce$t$, $t$richiede terreno drenante (evitare ristagni)$t$, $t$si naturalizza facilmente e aumenta nel tempo (RHS: "may be invasive")$t$, $t$può essere colpito da infezioni fungine (comprese ruggini), marciume batterico e alcuni virus$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Muscari armeniacum$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$uva-di-gatto$t$;
