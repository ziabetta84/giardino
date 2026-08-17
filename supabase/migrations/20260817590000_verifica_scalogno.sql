-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno arricchito. Corretta resistenza_gelo da "alta" a "media": RHS
-- classifica H4, coerente con la scala già stabilita (H4→media). Aggiunto
-- un gap di alert reale: la bozza non aveva nessuna informazione su
-- parassiti o malattie (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Moderata", "terreno": "Fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Amaryllidaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": "120-150", "finestra_semina": ["autunno", "inverno"], "finestra_trapianto": [], "resistenza_gelo": "media", "spaziatura_cm": 20, "consociazioni_favorevoli": ["carota", "pomodoro"], "consociazioni_sfavorevoli": ["fagiolo", "pisello"]}$j$::jsonb, alert = ARRAY[$t$Teme i ristagni idrici (rischio marciume del bulbo)$t$, $t$non richiede grandi quantità d'acqua una volta radicato$t$, $t$raccogliere quando il fogliame inizia a seccare$t$, $t$evitare eccessi di azoto (favorisce il fogliame a scapito del bulbo)$t$, $t$può essere soggetto a mosca della cipolla, tignola del porro e nematode del narciso$t$, $t$può essere colpito da marciume bianco della cipolla, peronospora, ruggine del porro e marciume del collo$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Allium cepa Aggregatum Group$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$scalogno$t$;
