-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Corretto un errore reale già presente in bozza: un alert sul non tagliare
-- le foglie era duplicato, con la seconda occorrenza troncata a metà frase
-- ("...indispensabili per ricaricare il") — probabile errore di
-- compilazione. Consolidato in un'unica voce completa. terreno arricchito.
-- Confermata con forza resistenza_gelo "alta": RHS classifica H6
-- (-20/-15°C). Aggiunto un gap di alert reale: la bozza non aveva nessuna
-- informazione su parassiti o malattie (#132).

update specie set esigenze = $j${"luce": "Sole o mezz'ombra", "acqua": "Moderata", "terreno": "Fertile, ben drenato, fresco durante la crescita"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Amaryllidaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 10, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Non tagliare le foglie prima che secchino$t$, $t$richiede terreno drenante per evitare marciumi del bulbo$t$, $t$non tagliare le foglie verdi dopo la fioritura (indispensabili per ricaricare il bulbo)$t$, $t$evitare irrigazioni estive (riposo vegetativo)$t$, $t$fioritura scarsa → bulbi troppo profondi o poca luce$t$, $t$si naturalizza facilmente e aumenta nel tempo$t$, $t$può essere soggetto a lumache, mosca del narciso, nematode del narciso e acaro dei bulbi$t$, $t$può essere colpito da marciume basale, bruciatura fogliare e virosi del narciso$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Narcissus pseudonarcissus$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$narciso$t$;
