-- Verifica reale (#120). RHS non ha una pagina per questa specie; la
-- pagina Acta Plantarum precedentemente trovata era quasi interamente
-- tassonomica, senza dati di coltivazione (lasciata in bozza). Roberta
-- ha pushato la scheda del vivaio italiano "Vivai Le Georgiche"
-- (legeorgiche.it), che riporta dati di coltivazione reali (esposizione,
-- terreno, irrigazione, rusticità H5, dimensioni a maturità,
-- consociazioni suggerite). Confermati luce, acqua, famiglia botanica
-- (Asteraceae) già corretti in bozza. Corretta spaziatura_cm da 40 a 60
-- (larghezza a maturità 50-70cm dichiarata dalla fonte). Confermata con
-- forza resistenza_gelo "alta": fonte classifica H5, coerente con la
-- scala già stabilita (H5→alta). Aggiunte consociazioni favorevoli
-- (lavanda, rosmarino, salvia, cisto, elicriso) e nota sull'origine
-- (scogliere della Dalmazia), non presenti nella bozza (#132).

update specie set esigenze = $j${"luce": "Sole pieno", "acqua": "Scarsa", "terreno": "Sabbioso o ghiaioso, drenante, anche povero"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asteraceae", "giorni_germinazione": "14-21", "giorni_trapianto": "40-60", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 60, "consociazioni_favorevoli": ["lavanda", "rosmarino", "salvia", "cisto", "elicriso"], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$ama sole pieno$t$, $t$fogliame argentato molto decorativo$t$, $t$teme ristagni idrici prolungati$t$, $t$molto resistente alla siccità, soprattutto una volta radicata$t$, $t$originaria delle scogliere costiere della Dalmazia (Croazia)$t$, $t$si abbina bene a lavanda, rosmarino, salvia, cisto ed elicriso$t$], fonti = ARRAY[$t$Vivai Le Georgiche (legeorgiche.it) — Centaurea ragusina (fonte vivaistica italiana, usata come fallback: nessuna pagina RHS disponibile, pagina Acta Plantarum priva di dati di coltivazione)$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagina vivaistica salvata e letta localmente)$t$ where slug = $t$centaurea-ragusina$t$;
