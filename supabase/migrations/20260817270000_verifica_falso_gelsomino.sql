-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, terreno. Confermata con precisione resistenza_gelo
-- "media": RHS classifica H4, esattamente la fascia già mappata.
-- spaziatura_cm corretta da 100 a 200: RHS Max Height 8-12m e Max Spread
-- 4-8m, una rampicante molto più vigorosa di quanto la bozza suggerisse
-- (200cm resta comunque una stima conservativa rispetto al pieno sviluppo
-- libero, ragionevole per una spaziatura da siepe/supporto). Aggiunto un
-- gap di alert reale: la bozza non aveva nessuna informazione su parassiti
-- o malattie — RHS elenca cocciniglie, ragnetto rosso e armillaria rara,
-- nessuno presente prima (#132).

update specie set esigenze = $j${"luce": "Luminosa, tollera mezz'ombra", "acqua": "Moderata", "terreno": "Fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Apocynaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "media", "spaziatura_cm": 200, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$crescita vigorosa: necessita di un supporto per arrampicarsi$t$, $t$teme le correnti d'aria fredda vicino a finestre in inverno$t$, $t$evitare ristagni idrici$t$, $t$fioritura profumata in tarda primavera/inizio estate$t$, $t$può essere colpito da cocciniglia a cuscinetto, cocciniglie farinose e ragnetto rosso in ambiente protetto$t$, $t$raramente può essere colpito da armillaria (marciume del piede)$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Trachelospermum jasminoides$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$falso-gelsomino$t$;
