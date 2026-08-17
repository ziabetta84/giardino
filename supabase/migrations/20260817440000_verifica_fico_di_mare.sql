-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Corretta resistenza_gelo da "bassa" a "media": RHS classifica H3, coerente
-- con la scala già stabilita (H3→media). spaziatura_cm corretta da 40 a
-- 200: RHS Max Spread 2.5-4m, enormemente più ampio della bozza (è una
-- tappezzante che si espande molto). Confermata la natura invasiva già
-- segnalata in bozza ("Molto invasiva"), con dettaglio reale: RHS la
-- elenca come specie non-nativa invasiva soggetta a restrizioni legali nel
-- Regno Unito (Wildlife & Countryside Act, Schedule 9) — informazione
-- aggiunta con nota che il problema ecologico è documentato anche sulle
-- coste mediterranee, incluse quelle italiane, per competizione con la
-- vegetazione dunale nativa. Pagina RHS priva di sezioni Cultivation/Pests/
-- Diseases dettagliate (rimanda genericamente alle note sulla specie
-- invasiva).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Sabbioso"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Aizoaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "media", "spaziatura_cm": 200, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Molto invasiva$t$, $t$pianta xerofila → teme irrigazioni frequenti$t$, $t$ama sole pieno$t$, $t$crescita molto rapida$t$, $t$perfetta per bordi e scarpate$t$, $t$specie ufficialmente riconosciuta come invasiva: nel Regno Unito è reato piantarla in natura (Wildlife & Countryside Act); anche sulle coste mediterranee, Italia inclusa, è un problema ecologico documentato perché compete con la vegetazione dunale nativa — da tenere sotto controllo e non far sfuggire in aree naturali$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Carpobrotus edulis$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$fico-di-mare$t$;
