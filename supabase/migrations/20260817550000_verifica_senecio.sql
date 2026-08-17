-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Nota tassonomica: RHS classifica questa specie sotto il genere Curio (non
-- più Senecio), stessa dinamica già incontrata con Verbena/Glandularia e
-- Osteospermum/Dimorphotheca — riportato in fonti, dati botanici non
-- influenzati. Confermati luce e terreno. Corretta resistenza_gelo da
-- "nessuna" a "bassa": RHS classifica H2 ("tolerant of low temperatures,
-- but not surviving being frozen"), coerente con la scala già stabilita
-- (H2→bassa, vedi zinnia). Aggiunto alert mancante su parassiti reali, non
-- presenti nella bozza (#132).

update specie set esigenze = $j${"luce": "Luminosa, sole diretto filtrato al mattino", "acqua": "Scarsa", "terreno": "Molto drenante, sabbioso"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asteraceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "bassa", "spaziatura_cm": 15, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Perline/foglie che si afflosciano → sete d'acqua, ma attenzione a non eccedere$t$, $t$Marciume alla base se il vaso non drena bene$t$, $t$Fusti fragili: maneggiare con cura$t$, $t$Ama posizioni luminose ma non sole diretto cocente$t$, $t$può essere soggetto a mosca bianca, afidi e ragnetto rosso$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Curio rowleyanus (nome sotto cui RHS classifica attualmente questa specie, riclassificata da Senecio a Curio; comunemente nota anche come Senecio rowleyanus)$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$senecio$t$;
