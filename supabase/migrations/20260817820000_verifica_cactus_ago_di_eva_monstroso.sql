-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Corretto un errore reale pre-esistente: famiglia_botanica era
-- "Cactaceae", ma Euphorbia trigona appartiene alle Euphorbiaceae — è
-- un'euforbia dall'aspetto simile a un cactus (da cui il nome comune),
-- non un vero cactus, confusione comune ma botanicamente errata.
-- Corretta resistenza_gelo da "nessuna" a "bassa": RHS classifica H2,
-- coerente con la scala già stabilita (H2→bassa). spaziatura_cm corretta
-- da 20 a 70: RHS Max Spread 0.5-1m. Aggiunto alert su parassiti reali e
-- un consiglio pratico di propagazione (RHS), non presenti nella bozza
-- (#132). Confermato indirettamente l'allarme già presente sul lattice
-- irritante, coerente con la biologia nota del genere Euphorbia.

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Sabbioso"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Euphorbiaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "bassa", "spaziatura_cm": 70, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Lattice irritante$t$, $t$evitare assolutamente ristagni idrici$t$, $t$richiede molta luce per mantenere la forma compatta$t$, $t$apici secchi → normale nei cactus mostruosi$t$, $t$se ingiallisce alla base → troppa acqua$t$, $t$se si allunga troppo → luce insufficiente$t$, $t$può essere soggetto a cocciniglia farinosa$t$, $t$in caso di taglio/propagazione, immergere la superficie recisa in carbone attivo o acqua tiepida per fermare la fuoriuscita di lattice$t$], famiglia_botanica = $t$Euphorbiaceae$t$, fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Euphorbia trigona$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$cactus-ago-di-eva-monstroso$t$;
