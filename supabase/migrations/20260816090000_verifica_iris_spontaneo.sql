-- Verifica reale (#120, secondo task), primo del secondo blocco di 5:
-- iris-spontaneo (Sisyrinchium californicum), fonte RHS Plants (rhs.org.uk),
-- letta da Roberta e relayata.
--
-- Discrepanza reale trovata: RHS descrive la specie come pianta da zone
-- paludose/margine di laghetto ("Grow in boggy conditions, or in an
-- aquatic planting basket"), Soil Types Loam/Clay, Moisture
-- "Poorly-drained" — l'opposto di "Drenato" che aveva la bozza.
-- Curiosamente la bozza aveva già un alert corretto ("specie palustre →
-- preferisce terreno umido") in contraddizione con il proprio campo
-- esigenze.terreno: incoerenza interna ora risolta. terreno corretto a
-- "Umido, anche palustre", acqua da "Moderata" ad "Abbondante".
--
-- resistenza_gelo corretta da "alta" a "media": RHS classifica H4 (-10 a
-- -5°C), che nella scala già stabilita (H3→media, H5→alta) è più vicino a
-- H3 che a H5.
--
-- Rimosso alert "evitare ristagni eccessivi solo se il terreno è pesante":
-- contraddiceva la reale tolleranza al ristagno confermata da RHS.
-- Aggiunto alert mancante su autosemina prolifica e rischio di diventare
-- invasiva (RHS: "potential to become a nuisance as seeds prolifically") —
-- #132.
--
-- Confermato: famiglia_botanica Iridaceae; spaziatura_cm 20 dentro Max
-- Spread RHS (0.1-0.5m). Non toccata esigenze.luce (RHS mostra solo Full
-- sun ma la bozza include mezz'ombra come opzione aggiuntiva, non
-- contraddetta dalla fonte).

update specie set
  esigenze = $j${"luce": "Pieno sole o mezz'ombra", "acqua": "Abbondante", "terreno": "Umido, anche palustre"}$j$::jsonb,
  ciclo_colturale = $j${"famiglia_botanica": "Iridaceae", "giorni_germinazione": "20-30", "giorni_trapianto": "60-90", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["autunno"], "resistenza_gelo": "media", "spaziatura_cm": 20, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb,
  alert = ARRAY[$t$specie palustre → preferisce terreno umido$t$, $t$molto vigoroso: può espandersi rapidamente$t$, $t$foglie che seccano ai bordi → terreno troppo asciutto$t$, $t$fioritura gialla tra aprile e giugno$t$, $t$si autosemina abbondantemente: può diventare invadente se non controllata$t$],
  fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Sisyrinchium californicum$t$],
  stato_verifica = $t$verificato$t$,
  verificata_il = now(),
  verificata_da = $t$Roberta (fonte RHS) + Claude Code (compilazione)$t$
where slug = $t$iris-spontaneo$t$;
