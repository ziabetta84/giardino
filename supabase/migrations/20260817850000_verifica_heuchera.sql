-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Voce generica del catalogo ("Heuchera spp."), verificata su due cultivar
-- della serie Indian Summer (dati concordanti). terreno arricchito.
-- Confermata con forza resistenza_gelo "alta": RHS classifica H5-H6 a
-- seconda della cultivar, entrambe ampiamente nella fascia "alta" già
-- mappata. Non ampliata esigenze.luce nonostante una delle due cultivar
-- indichi anche pieno sole: l'altra mostra solo mezz'ombra, e la bozza ha
-- già la nota su intolleranza al caldo eccessivo — mantenuta "Mezz'ombra"
-- come indicazione più prudente. Aggiunto un gap di alert reale: la bozza
-- non aveva nessuna informazione su parassiti o malattie, inclusa una
-- ruggine specifica della specie (#132).

update specie set esigenze = $j${"luce": "Mezz'ombra", "acqua": "Regolare", "terreno": "Ricco, neutro, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Saxifragaceae", "giorni_germinazione": "20-30", "giorni_trapianto": "60-90", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$preferisce mezz’ombra luminosa$t$, $t$teme caldo eccessivo$t$, $t$foglie decorative tutto l’anno$t$, $t$evitare ristagni$t$, $t$può essere soggetta a oziorrinco$t$, $t$può essere colpita da una ruggine specifica della specie (heuchera rust)$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Heuchera 'Mulberry' e Heuchera 'Boysenberry' (cultivar della serie Indian Summer, usate come riferimento per la voce generica del catalogo; dati concordanti tra le due)$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$heuchera$t$;
