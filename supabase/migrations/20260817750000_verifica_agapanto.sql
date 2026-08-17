-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Verifica ripetuta con la specie corretta: la prima pagina trovata
-- (Tulbaghia simmleri) era in realtà un genere diverso, nonostante il nome
-- comune fuorviante "pink agapanthus" — segnalato e non usato. Confermati
-- luce, terreno, famiglia botanica. Confermata con precisione
-- resistenza_gelo "media": RHS classifica H3, esattamente la fascia già
-- mappata (H3→media). Aggiunto un gap di alert reale: la bozza non aveva
-- nessuna informazione su parassiti o malattie — RHS segnala anche un
-- parassita specifico del genere (cecidomia dell'agapanto) (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Regolare in primavera-estate, ridotta in inverno", "terreno": "Ricco, fertile e soprattutto ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Amaryllidaceae", "giorni_germinazione": "30-40", "giorni_trapianto": "60-90", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "media", "spaziatura_cm": 40, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Fiorisce meglio se leggermente rinvasata (radici compatte)$t$, $t$Teme il gelo intenso: pacciamare la base in inverno nelle zone più fredde$t$, $t$Rimuovere gli steli fioriti appassiti$t$, $t$Tollera bene la siccità estiva una volta ambientata$t$, $t$può essere soggetto a lumache, limacce e alla cecidomia dell'agapanto (parassita specifico)$t$, $t$può essere colpito da un virus$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Agapanthus africanus$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$agapanto$t$;
