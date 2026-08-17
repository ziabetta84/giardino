-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Corretta un'incoerenza interna della bozza: esigenze.luce diceva
-- "Mezz'ombra" ma un alert affermava "ama sole o mezz'ombra luminosa" — RHS
-- mostra solo l'icona Partial shade (nessun pieno sole), quindi l'alert
-- sovrastimava la tolleranza al sole diretto. Rimosso quell'alert e
-- sostituito con la nota reale di RHS sulla protezione dall'umidità
-- invernale ("protect from winter wet"), coerente con il "drenaggio
-- perfetto" già segnalato. Confermata resistenza_gelo "alta" (RHS H5).
-- Aggiunti alert mancanti su parassiti (afidi, lumache, limacce) e marciume
-- del colletto in condizioni umide (RHS: "neck rot in wet conditions") (#132).

update specie set esigenze = $j${"luce": "Mezz'ombra", "acqua": "Moderata", "terreno": "Drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Montiaceae", "giorni_germinazione": "20-30", "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "alta", "spaziatura_cm": 15, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$richiede drenaggio perfetto$t$, $t$teme i ristagni idrici più di molte altre piante della zona$t$, $t$proteggere dall'umidità invernale eccessiva (RHS: "protect from winter wet")$t$, $t$fioritura spettacolare in primavera-estate$t$, $t$può essere soggetta ad afidi, lumache e limacce$t$, $t$rischio di marciume del colletto in condizioni troppo umide$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Lewisia cotyledon$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$lewisia$t$;
