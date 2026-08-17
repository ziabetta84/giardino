-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Corretta resistenza_gelo da "bassa" a "media": RHS classifica H3, coerente
-- con la scala già stabilita (H3→media, vedi alisso) — resta comunque una
-- specie da proteggere in inverno nei climi rigidi, coerente con l'alert
-- già presente sul tubero. Confermati luce e terreno. Aggiunto alert
-- mancante su malattie reali (marciume basale, muffa grigia), non presente
-- nella bozza (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Moderata", "terreno": "Fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asteraceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "media", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Teme il gelo intenso: nei climi rigidi il tubero va protetto con pacciamatura o sollevato in inverno$t$, $t$richiede pieno sole per una fioritura abbondante$t$, $t$evitare ristagni idrici (rischio marciume del tubero)$t$, $t$fiori profumati di cioccolato, particolarmente nelle ore calde$t$, $t$rimuovere i fiori appassiti per prolungare la fioritura estiva$t$, $t$può essere colpito da marciume basale e muffa grigia$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Cosmos atrosanguineus$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$cosmos-atrosanguineus$t$;
