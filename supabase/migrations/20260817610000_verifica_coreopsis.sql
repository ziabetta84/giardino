-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- esigenze.luce arricchita con mezz'ombra (RHS: "partial shade but
-- preferably full sun"). Confermati terreno, resistenza_gelo "alta" (RHS
-- H5, esattamente la fascia già mappata). Aggiunto alert mancante su
-- lumache/limacce, non presente nella bozza (#132).

update specie set esigenze = $j${"luce": "Pieno sole o mezz'ombra", "acqua": "Scarsa/moderata", "terreno": "Ben drenato, anche povero"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asteraceae", "giorni_germinazione": "10-20", "giorni_trapianto": "30-40", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "alta", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$molto resistente alla siccità una volta radicata$t$, $t$rimuovere i fiori secchi (deadheading) per prolungare la fioritura$t$, $t$evitare ristagni idrici$t$, $t$in piena estate, con caldo estremo, i fiori possono seccare rapidamente: è normale$t$, $t$cultivar a fioritura doppia, forma a palla anziché a margherita piatta$t$, $t$può essere soggetta a lumache e limacce$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Coreopsis grandiflora$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$coreopsis$t$;
