-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- resistenza_gelo corretta da "nessuna" a "bassa": RHS classifica H2 (1 a
-- 5°C, "not surviving being frozen"), un gradino più resistente di H1C (già
-- mappato a "nessuna" per il geranio zonale, specie sorella H1C) — coerente
-- con la scala già stabilita (H2→bassa, vedi zinnia). terreno arricchito.
-- Aggiunto un gap di alert consistente su parassiti e malattie specifiche
-- del genere Pelargonium (ruggine, virus, galla batterica), non presenti
-- nella bozza nonostante siano già stati documentati per il geranio zonale
-- (#132).

update specie set esigenze = $j${"luce": "Sole", "acqua": "Regolare", "terreno": "Fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Geraniaceae", "giorni_germinazione": "7-14", "giorni_trapianto": "40-50", "giorni_raccolta": null, "finestra_semina": ["inverno", "primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "bassa", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Sensibili al gelo$t$, $t$ama sole pieno$t$, $t$teme ristagni idrici$t$, $t$fioritura molto lunga$t$, $t$ottimi in fioriere e balconiere$t$, $t$può essere colpito da tripidi, oziorrinco, cicaline, cocciniglie radicali e mosca bianca$t$, $t$può essere colpito da ruggine e virus del pelargonio, oltre a galla batterica$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Pelargonium peltatum$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$geranio-parigino$t$;
