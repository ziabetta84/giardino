-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- La pagina RHS per questa specie è incompleta: conferma solo Family
-- Asteraceae e la descrizione di genere, senza dati di Position/Soil/
-- Hardiness/Pests come le altre schede. Confermata comunque la famiglia
-- botanica (già corretta in bozza). Corretta resistenza_gelo da "nessuna"
-- a "bassa" per analogia diretta con Zinnia elegans (già verificata in
-- questo progetto, stesso genere, stessa classificazione RHS H2→bassa) —
-- inferenza dichiarata esplicitamente, non dato RHS diretto per questa
-- specie specifica. Nessuna altra modifica: mancano fonti dirette per
-- correggere ulteriormente questa scheda.

update specie set esigenze = $j${"luce": "Sole", "acqua": "Scarsa/moderata", "terreno": "Ben drenato, anche povero"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asteraceae", "giorni_germinazione": "5-10", "giorni_trapianto": "20-25", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "bassa", "spaziatura_cm": 20, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$molto più resistente a siccità e oidio della Zinnia elegans comune$t$, $t$portamento compatto e ramificato, ottima da bordura$t$, $t$fioritura abbondante e continua$t$, $t$teme comunque i ristagni idrici$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Zinnia angustifolia (pagina RHS minima: conferma solo famiglia/genere, senza box di coltivazione/Hardiness)$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$zinnia-angustifolia$t$;
