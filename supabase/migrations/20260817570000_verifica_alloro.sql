-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, terreno. Confermata con precisione resistenza_gelo
-- "media": RHS classifica H4, esattamente la fascia già mappata.
-- spaziatura_cm (100) NON corretta nonostante RHS indichi Max Height
-- 8-12m e Max Spread "wider than 8 metres" per l'albero maturo in piena
-- libertà: l'alloro da giardino è comunemente mantenuto compatto tramite
-- potature regolari (topiaria a palla o cono, pratica molto diffusa anche
-- in Italia), coerente con l'alert già presente su "crescita vigorosa:
-- controllare l'espansione" — 100cm resta una spaziatura ragionevole per
-- un esemplare gestito, non in contraddizione con la fonte. Aggiunto alert
-- su parassiti/malattie specifiche reali non presenti nella bozza
-- (psilla dell'alloro, cocciniglia dell'ippocastano, tortrice, oidio,
-- maculatura fogliare, armillaria rara) (#132).

update specie set esigenze = $j${"luce": "Sole o mezz'ombra", "acqua": "Moderata", "terreno": "Drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Lauraceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "media", "spaziatura_cm": 100, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Può soffrire cocciniglia$t$, $t$molto resistente alla siccità, evitare eccessi d’acqua$t$, $t$tollera bene vento e sole pieno$t$, $t$crescita vigorosa: controllare l’espansione$t$, $t$attenzione ai polloni basali (da rimuovere se indesiderati)$t$, $t$possibile attacco di cocciniglia in estate molto calda$t$, $t$può essere soggetto anche a psilla dell'alloro, cocciniglia dell'ippocastano e tortrice$t$, $t$può essere colpito da oidio, maculatura fogliare e raramente armillaria$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Laurus nobilis$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$alloro$t$;
