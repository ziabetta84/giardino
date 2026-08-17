-- Verifica reale (#120, secondo task), quinta e ultima specie del blocco di
-- 5: aquilegia, fonte RHS Plants (rhs.org.uk), letta da Roberta e relayata.
--
-- esigenze.terreno arricchito da "Fresco" a "Fresco, fertile, ben drenato"
-- (RHS: "fertile, moist but well-drained soil"). finestra_semina corretta
-- aggiungendo "autunno" (RHS: "seed sown in spring, late summer or early
-- autumn" — "early autumn" non era coperto dalla bozza).
--
-- Aggiunto alert mancante su afidi e su una peronospora specie-specifica
-- (RHS: "aquilegia downy mildew") non presente nella bozza — #132.
--
-- Confermato con forza resistenza_gelo "alta": RHS H7 (sotto -20°C, fascia
-- più resistente). spaziatura_cm 30 dentro Max Spread RHS (0.1-0.5m).
--
-- Non toccata esigenze.luce "Mezz'ombra": RHS elenca sia "Full sun" che
-- "Partial shade" come posizioni accettate; mantenuta la mezz'ombra per
-- coerenza con il caldo estivo mediterraneo (giudizio di adattamento
-- climatico, non contraddetto dalla fonte).

update specie set
  esigenze = $j${"luce": "Mezz'ombra", "acqua": "Regolare", "terreno": "Fresco, fertile, ben drenato"}$j$::jsonb,
  ciclo_colturale = $j${"famiglia_botanica": "Ranunculaceae", "giorni_germinazione": "20-30", "giorni_trapianto": "60-90", "giorni_raccolta": null, "finestra_semina": ["primavera", "estate", "autunno"], "finestra_trapianto": ["autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb,
  alert = ARRAY[$t$ama mezz’ombra luminosa$t$, $t$fioritura primaverile$t$, $t$si risemina facilmente$t$, $t$evitare ristagni$t$, $t$può essere soggetta ad afidi e a una peronospora specifica della specie (aquilegia downy mildew)$t$],
  fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Aquilegia vulgaris$t$],
  stato_verifica = $t$verificato$t$,
  verificata_il = now(),
  verificata_da = $t$Roberta (fonte RHS) + Claude Code (compilazione)$t$
where slug = $t$aquilegia$t$;
