-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno arricchito. Confermata con forza resistenza_gelo "alta": RHS
-- classifica H6 (-20/-15°C). Non toccata esigenze.luce "Mezz'ombra"
-- nonostante RHS elenchi anche Full sun: la bozza ha già la nota pratica
-- "preferisce mezz'ombra o sole del mattino" (giudizio di adattamento al
-- sole estivo mediterraneo, coerente con casi analoghi già trattati).
-- Aggiunto alert mancante su lumache/limacce (RHS Pests), non presente
-- nella bozza (#132).

update specie set esigenze = $j${"luce": "Mezz'ombra", "acqua": "Regolare", "terreno": "Fresco, moderatamente fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Lamiaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 20, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Può diventare invasiva$t$, $t$crescita molto rapida: può espandersi oltre l’area desiderata$t$, $t$preferisce mezz’ombra o sole del mattino$t$, $t$evitare ristagni idrici$t$, $t$foglie che scoloriscono → troppa luce diretta o poca acqua$t$, $t$ottima per coprire suolo e limitare infestanti$t$, $t$può essere soggetta a lumache e limacce$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Glechoma hederacea$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$glechoma-hederacea$t$;
