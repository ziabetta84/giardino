-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, spaziatura. terreno arricchito. Confermata con forza
-- resistenza_gelo "alta": RHS classifica H6 (-20/-15°C). finestra_semina
-- era vuota, RHS conferma propagazione per seme (oltre a rimozione di
-- bulbilli in autunno): compilata con "primavera". Aggiunto alert mancante
-- su malattie reali (marciume bianco, peronospora), non presente nella
-- bozza (#132).

update specie set esigenze = $j${"luce": "Sole", "acqua": "Moderata", "terreno": "Fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Amaryllidaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 10, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$richiede terreno drenante$t$, $t$evitare irrigazioni estive$t$, $t$fioritura viola a “testa di tamburo” in giugno-luglio$t$, $t$si naturalizza facilmente$t$, $t$può essere colpito da marciume bianco della cipolla e peronospora$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Allium sphaerocephalon$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$allium-sphaerocephalon$t$;
