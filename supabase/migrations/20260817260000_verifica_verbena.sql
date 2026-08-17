-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- resistenza_gelo corretta da "bassa" a "media": RHS classifica H3,
-- coerente con la scala già stabilita (H3→media, vedi alisso). terreno
-- arricchito. Nota tassonomica: la pagina RHS per "Verbena × hybrida"
-- riporta dati sotto il genere Glandularia, in cui questa specie è stata
-- recentemente riclassificata da RHS pur restando comunemente nota come
-- Verbena — non cambia i dati botanici, riportato in fonti per
-- tracciabilità. Aggiunto alert mancante su lumache (RHS Pests) accanto
-- all'oidio già presente in bozza.

update specie set esigenze = $j${"luce": "Sole", "acqua": "Regolare", "terreno": "Fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Verbenaceae", "giorni_germinazione": "14-21", "giorni_trapianto": "30-40", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "media", "spaziatura_cm": 25, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Sensibile a oidio$t$, $t$ama sole pieno$t$, $t$teme ristagni$t$, $t$fioritura continua$t$, $t$crescita rapida$t$, $t$può essere soggetta anche a lumache, oltre all'oidio già segnalato$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Verbena × hybrida (dati RHS classificati sotto il genere Glandularia, in cui la specie è stata recentemente inclusa)$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$verbena$t$;
