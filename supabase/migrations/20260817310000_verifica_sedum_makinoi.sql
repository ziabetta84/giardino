-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- esigenze.luce corretta da "Sole o mezz'ombra" a "Pieno sole": RHS mostra
-- solo l'icona Full sun (stesso ragionamento già applicato a sedum-spurium
-- e iberis-sempervirens). Corretta con importanza resistenza_gelo da "alta"
-- a "bassa": RHS classifica H2 (1 a 5°C, "not surviving being frozen") —
-- la bozza sovrastimava significativamente la rusticità di questa specie,
-- in direzione opposta rispetto agli errori trovati finora (di solito la
-- bozza sottostimava). terreno arricchito con il dettaglio pratico RHS
-- (perlite). Aggiunto un gap di alert reale: la bozza non aveva nessuna
-- informazione su parassiti o malattie (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Drenato, con aggiunta di perlite"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Crassulaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "bassa", "spaziatura_cm": 15, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$evitare assolutamente ristagni idrici$t$, $t$luce intensa per mantenere la compattezza$t$, $t$se le foglie si allungano → luce insufficiente$t$, $t$se le foglie si raggrinziscono → sete$t$, $t$vaso piccolo = asciugatura molto rapida$t$, $t$può essere soggetto a larve di oziorrinco, cocciniglie a scudo e cocciniglia farinosa$t$, $t$può essere colpito da marciume di colletto/radici fungino o batterico$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Sedum makinoi$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$sedum-makinoi$t$;
