-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Chiarito con Roberta: non è una varietà distinta, ma un esemplare di
-- Epipremnum aureum in fase di radicazione da talea in acqua — la
-- scheda descrive quindi questa fase specifica, non la pianta adulta.
-- Confermati famiglia botanica (Araceae) e resistenza_gelo "nessuna":
-- RHS classifica H1B, coerente con la scala già stabilita (H1A/B/C→
-- nessuna). Aggiunto un gap di sicurezza reale e importante, assente
-- nella bozza: RHS segnala la pianta come "Potentially harmful" — tossica
-- se ingerita, linfa irritante per pelle e occhi, da maneggiare con
-- guanti (#132). Confermato che la pianta madre è generalmente esente da
-- parassiti e malattie.

update specie set alert = ARRAY[$t$acqua torbida → cambiare subito$t$, $t$radici marroni → troppa luce o acqua stagnante$t$, $t$evitare luce diretta (rischio alghe)$t$, $t$se le foglie ingialliscono → acqua da cambiare più spesso$t$, $t$talee pronte per il trapianto quando le radici superano i 5-7 cm$t$, $t$tossica se ingerita, linfa irritante per pelle e occhi: maneggiare con guanti e tenere lontana da bambini e animali domestici$t$, $t$pianta madre generalmente esente da parassiti e malattie$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Epipremnum aureum$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$pothos-talea$t$;
