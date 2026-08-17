-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Correzione reale importante: la bozza aveva "Non tollera calcare" e
-- terreno "Acido" con relativo alert contro ammendanti calcarei — RHS
-- descrive esplicitamente Erica carnea come "a lime tolerant heather...
-- will tolerate alkaline soils", cioè l'eccezione tollerante al calcare tra
-- le eriche (a differenza della maggior parte del genere, tipicamente
-- calcifughe). Corretti terreno ed esigenze.luce (RHS: Full sun, Partial
-- shade), rimossi gli alert contraddittori sul calcare, aggiunta la nota
-- corretta sulla tolleranza. resistenza_gelo "alta" confermata con forza
-- (RHS H6, -20/-15°C, ancora più resistente della fascia già ampia).
-- spaziatura_cm corretta da 40 a 50 (RHS Max Spread 0.5-1m). Aggiunto
-- Phytophthora root rot come causa reale di marciume in condizioni umide.

update specie set esigenze = $j${"luce": "Sole o mezz'ombra", "acqua": "Moderata", "terreno": "Acido o alcalino (tollera il calcare, a differenza della maggior parte delle eriche)"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Ericaceae", "giorni_germinazione": "30-60", "giorni_trapianto": "90+", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 50, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$richiede terreno drenante$t$, $t$evitare ristagni idrici (rischio marciumi, soprattutto Phytophthora)$t$, $t$non potare sul legno vecchio (non ributta)$t$, $t$fioritura molto lunga se ben esposta$t$, $t$a differenza della maggior parte delle eriche, questa specie tollera bene il calcare$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Erica carnea$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$erica$t$;
