-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno arricchito. Confermata con precisione resistenza_gelo "alta": RHS
-- classifica H5, esattamente la fascia già mappata. Non ampliata
-- esigenze.luce nonostante RHS elenchi anche "Full sun" oltre a "Partial
-- shade": la bozza segnala già esplicitamente intolleranza al caldo
-- intenso ("Non tollera caldo intenso", "teme caldo eccessivo"), giudizio
-- di adattamento al clima estivo mediterraneo coerente con casi analoghi
-- già trattati — mantenuta "Mezz'ombra" come indicazione più prudente e
-- specifica. Aggiunto alert mancante su parassiti reali, non presenti
-- nella bozza (#132).

update specie set esigenze = $j${"luce": "Mezz'ombra", "acqua": "Regolare", "terreno": "Fresco, ricco di sostanza organica, molto drenante, alcalino o neutro"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Saxifragaceae", "giorni_germinazione": "14-21", "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 20, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Non tollera caldo intenso$t$, $t$preferisce mezzombra luminosa$t$, $t$teme caldo eccessivo$t$, $t$richiede terreno fresco ma drenante$t$, $t$fioritura primaverile$t$, $t$può essere soggetta ad afidi, lumache, oziorrinco e ragnetto rosso$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Saxifraga × arendsii$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$sassifraga$t$;
