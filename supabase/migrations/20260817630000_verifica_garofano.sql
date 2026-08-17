-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Voce generica del catalogo ("Dianthus spp."). Usata come riferimento
-- Dianthus caryophyllus (il garofano da fioraio classico), la specie più
-- comunemente indicata semplicemente come "garofano" in italiano, a
-- differenza di Dianthus barbatus (garofano dei poeti, pianta diversa).
-- terreno arricchito con la preferenza per suoli neutri/alcalini, coerente
-- su entrambe le specie Dianthus controllate. Confermata con precisione
-- resistenza_gelo "media": RHS classifica H4 su D. caryophyllus,
-- esattamente la fascia già mappata (D. barbatus è invece H7, ma è specie
-- diversa più rustica). Aggiunto un gap di alert reale: la bozza non aveva
-- nessuna informazione su parassiti o malattie, nonostante siano
-- consistenti su entrambe le specie controllate (#132).

update specie set esigenze = $j${"luce": "Sole", "acqua": "Moderata", "terreno": "Drenato, neutro o leggermente alcalino"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Caryophyllaceae", "giorni_germinazione": "14-21", "giorni_trapianto": "45-60", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "media", "spaziatura_cm": 25, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$ama sole pieno$t$, $t$teme ristagni$t$, $t$fioritura lunga e profumata$t$, $t$ottimo in fioriere e balconiere$t$, $t$può essere soggetto a lumache e afidi$t$, $t$può essere colpito da oidio, ruggine, un virus e appassimento da fusarium$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Dianthus caryophyllus (specie rappresentativa del genere, usata come riferimento per la voce generica "Dianthus spp."; controllato anche Dianthus barbatus, che condivide lo stesso profilo di parassiti/malattie)$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$garofano$t$;
