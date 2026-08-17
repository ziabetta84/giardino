-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermato tramite l'etichetta della pianta reale: si tratta di Prunus
-- persica 'Taoflora' (pesco da fiore ornamentale), non un nome generico.
-- terreno arricchito. Corretta resistenza_gelo da "alta" a "media": RHS
-- classifica H4, coerente con la scala già stabilita (H4→media).
-- spaziatura_cm (300) NON corretta nonostante RHS indichi Max Spread 4-8m
-- per la specie in piena libertà: le cultivar ornamentali da fiore come
-- 'Taoflora' sono tipicamente innestate su portainnesti nanizzanti e
-- mantenute più compatte della specie selvatica — 300cm resta una stima
-- ragionevole per un esemplare da giardino. SEGNALAZIONE DI SICUREZZA:
-- terza specie del catalogo (dopo ulivo e lavanda) che RHS classifica
-- "High Risk Host for Xylella fastidiosa" — aggiunta come alert dedicato.
-- Aggiunte anche le altre malattie/parassiti reali documentati da RHS
-- (#132).

update specie set esigenze = $j${"luce": "Sole", "acqua": "Moderata", "terreno": "Fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Rosaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["autunno"], "resistenza_gelo": "media", "spaziatura_cm": 300, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Sensibile a monilia$t$, $t$richiede pieno sole per una fioritura abbondante$t$, $t$evitare ristagni idrici (preferisce terreno drenante)$t$, $t$molto resistente al vento: ideale per il crinale$t$, $t$possibile attacco di afidi in primavera$t$, $t$potare solo dopo la fioritura per non perdere i fiori dell’anno successivo$t$, $t$SEGNALAZIONE IMPORTANTE: RHS classifica Prunus persica come "High Risk Host" per Xylella fastidiosa, lo stesso patogeno da quarantena segnalato per ulivo e lavanda — attenzione a sintomi di disseccamento anomalo$t$, $t$può essere colpito anche da cancro batterico, avvizzimento dei fiori, marciume bruno, arricciamento fogliare del pesco e mal del piombo, oltre alla monilia già segnalata$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Prunus persica (l'etichetta della pianta reale riporta la cultivar 'Taoflora', non presente come pagina specifica su RHS; usata la specie Prunus persica come riferimento)$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$prunus-taoflora$t$;
