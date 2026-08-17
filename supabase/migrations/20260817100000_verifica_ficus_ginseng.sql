-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce (coerente con "full or filtered light" per coltivazione
-- sotto vetro/in vaso) e resistenza_gelo "nessuna" (RHS H1B, molto tenera).
-- terreno arricchito. spaziatura_cm lasciata null intenzionalmente: RHS
-- riporta Max Height "higher than 12 metres" e Max Spread "wider than 8
-- metres", dati riferiti all'albero maturo in natura, non applicabili a un
-- bonsai da appartamento mantenuto volutamente piccolo tramite potatura —
-- importare quel dato produrrebbe un valore assurdo per l'uso reale della
-- scheda. Aggiunto alert su parassiti reali da ambiente chiuso (#132).

update specie set esigenze = $j${"luce": "Luce diffusa", "acqua": "Moderata", "terreno": "Ricco, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Moraceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Sensibile a sbalzi di temperatura$t$, $t$evitare ristagni idrici (rischio marciumi radicali)$t$, $t$evitare correnti d’aria e sbalzi termici$t$, $t$richiede luce intensa ma indiretta$t$, $t$foglie gialle → troppa acqua o poca luce$t$, $t$se perde foglie → stress da spostamento o aria secca$t$, $t$può essere soggetto a ragnetto rosso, tripidi, cocciniglie farinose e cocciniglie a scudo in ambiente chiuso$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Ficus microcarpa$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$ficus-ginseng$t$;
