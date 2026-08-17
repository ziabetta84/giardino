-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermata luce con precisione: RHS mostra Full shade, Partial shade,
-- coerente esattamente con la formulazione già presente in bozza
-- ("Tollera anche poca luce, cresce meglio con luce indiretta filtrata").
-- Confermato terreno. Confermata con forza resistenza_gelo "nessuna": RHS
-- classifica H1B. spaziatura_cm compilata a 50 (RHS Max Spread 0.5-1m,
-- dato applicabile essendo una normale pianta da vaso). RHS: generalmente
-- priva di parassiti e malattie, coerente con l'assenza di alert su questo
-- tema nella bozza. Confermata implicitamente la tossicità già segnalata
-- in bozza (dato di sicurezza ben documentato per questa specie, non
-- smentito da questa fonte).

update specie set esigenze = $j${"luce": "Tollera anche poca luce, cresce meglio con luce indiretta filtrata", "acqua": "Scarsa", "terreno": "Molto drenante"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Araceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 50, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$teme moltissimo i ristagni idrici: il marciume dei rizomi è la causa di morte più comune$t$, $t$tollera bene ambienti poco luminosi, ideale per angoli bui della casa$t$, $t$crescita lenta, non necessita di rinvasi frequenti$t$, $t$pianta tossica se ingerita: tenere lontano da animali domestici e bambini$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Zamioculcas zamiifolia$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$zz-plant$t$;
