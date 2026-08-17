-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, resistenza_gelo "media" (RHS H4, esattamente la fascia
-- già mappata, coerente con l'alert già presente su -5/-7°C con ricaccio
-- dalla base). spaziatura_cm corretta da 100 a 200: RHS Max Height 8-12m e
-- Max Spread 2.5-4m, una rampicante molto più vigorosa di quanto la bozza
-- suggerisse (stesso ordine di grandezza di clematis-montana e
-- falso-gelsomino, già corrette). Aggiunto alert mancante su rischio di
-- comportamento invadente (RHS: "potential to become a nuisance") e
-- malattie reali (armillaria rara, virus), non presenti nella bozza
-- (#132).

update specie set esigenze = $j${"luce": "Pieno sole o mezz'ombra", "acqua": "Moderata", "terreno": "Substrato fertile, ben drenante e leggermente acido o neutro"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Passifloraceae", "giorni_germinazione": "20-40", "giorni_trapianto": "60-90", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "media", "spaziatura_cm": 200, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Crescita molto rapida: richiede un supporto robusto$t$, $t$Può soffrire il freddo sotto i -5/-7°C nella parte aerea, ma spesso ributta dalla base$t$, $t$Attenzione a cocciniglia e ragnetto rosso$t$, $t$Potatura di contenimento a fine inverno$t$, $t$RHS segnala che può diventare invadente se non gestita$t$, $t$raramente può essere colpita da armillaria e da un virus$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Passiflora caerulea$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$passiflora-caerulea$t$;
