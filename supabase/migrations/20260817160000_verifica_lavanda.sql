-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, resistenza_gelo "alta" (RHS H5). spaziatura_cm corretta
-- da 40 a 100: RHS Max Spread 1-1.5m, molto più ampio della bozza.
-- SEGNALAZIONE DI SICUREZZA: RHS classifica Lavandula angustifolia come
-- "High Risk Host for Xylella fastidiosa" — il patogeno da quarantena
-- responsabile del disseccamento rapido dell'olivo in Puglia. Rilevante nel
-- contesto italiano: aggiunto come alert dedicato, non presente nella
-- bozza. Aggiunti anche i parassiti/malattie reali documentati da RHS
-- (coleottero del rosmarino, sputacchina, muffa grigia, armillaria) (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Sabbioso"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Lamiaceae", "giorni_germinazione": "14-21", "giorni_trapianto": "40-60", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 100, "consociazioni_favorevoli": ["rosmarino", "cavolo"], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Evitare ristagni$t$, $t$richiede terreno drenante$t$, $t$ama sole pieno$t$, $t$teme ristagni$t$, $t$molto rustica$t$, $t$SEGNALAZIONE IMPORTANTE: RHS classifica la specie come "High Risk Host" per Xylella fastidiosa, il patogeno da quarantena che ha colpito gravemente gli uliveti in Puglia — attenzione a sintomi di disseccamento anomalo e segnalare eventuali sospetti alle autorità fitosanitarie$t$, $t$può essere soggetta al coleottero del rosmarino e alla sputacchina (cimice schiumaiola)$t$, $t$può essere colpita da muffa grigia e raramente dal marciume del piede (armillaria)$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Lavandula angustifolia$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$lavanda$t$;
