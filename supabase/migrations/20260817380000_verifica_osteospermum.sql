-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Nota tassonomica: la pagina RHS per questa specie è classificata sotto il
-- genere Dimorphotheca, non Osteospermum come nel nostro catalogo — stesso
-- tipo di riclassificazione già incontrato con Verbena/Glandularia,
-- riportato in fonti per tracciabilità, dati botanici non influenzati.
-- terreno arricchito. Corretta resistenza_gelo da "bassa" a "media": RHS
-- classifica H3, coerente con la scala già stabilita (H3→media). Aggiunto
-- un gap di alert reale: la bozza non aveva nessuna informazione su
-- parassiti o malattie — RHS elenca afidi, peronospora e verticillosi
-- (#132).

update specie set esigenze = $j${"luce": "Sole", "acqua": "Moderata", "terreno": "Molto drenato, leggero, moderatamente fertile"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asteraceae", "giorni_germinazione": "10-15", "giorni_trapianto": "30", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "media", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Chiude i fiori in ombra$t$, $t$ama sole pieno$t$, $t$teme freddo intenso$t$, $t$fioritura molto abbondante$t$, $t$evitare ristagni$t$, $t$può essere soggetto ad afidi$t$, $t$può essere colpito da peronospora e verticillosi$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Dimorphotheca ecklonis (nome sotto cui RHS classifica attualmente questa specie, comunemente nota anche come Osteospermum ecklonis)$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$osteospermum$t$;
