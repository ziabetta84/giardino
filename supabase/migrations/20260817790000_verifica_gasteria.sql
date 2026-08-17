-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Voce generica del catalogo ("Gasteria spp."), verificata su Gasteria
-- bicolor var. liliputana. Confermati luce (non ampliata a RHS "Full sun,
-- Partial shade": mantenuta l'indicazione più cauta già in bozza, coerente
-- con l'alert già presente su luce diretta filtrata), terreno, famiglia
-- botanica. Confermata con forza resistenza_gelo "nessuna": RHS classifica
-- H1C. spaziatura_cm (15) NON corretta: RHS Max Spread è addirittura 0-0.1m
-- per questa varietà nana ("liliputana"), quindi la bozza è già generosa,
-- non stretta. Aggiunto alert su parassiti reali, non presente nella bozza
-- (#132).

update specie set esigenze = $j${"luce": "Luminosa, sole diretto solo filtrato", "acqua": "Scarsa", "terreno": "Molto drenante"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Asphodelaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 15, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$a differenza di altre succulente tollera bene la luce indiretta: evitare sole diretto nelle ore più calde (rischio scottature)$t$, $t$colorazione bronzo/porpora intensa è normale risposta a luce forte o freddo, non segno di malattia$t$, $t$evitare ristagni idrici, soprattutto se ciottoli decorativi sono a contatto con la base delle foglie$t$, $t$base molle o scura → marciume, intervenire subito$t$, $t$può essere soggetta a cocciniglia farinosa$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Gasteria bicolor var. liliputana$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$gasteria$t$;
