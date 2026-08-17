-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno arricchito. Confermata con forza resistenza_gelo "nessuna": RHS
-- classifica H1B (10-15°C, "can be grown outside in the summer" solo).
-- spaziatura_cm (40) NON corretta nonostante RHS indichi Max Spread
-- 1.5-2.5m per la pianta lasciata libera di espandersi: la bozza segnala
-- già la necessità di un supporto/tutore, e 40cm è una spaziatura da
-- coltivazione verticale su graticcio (pratica standard), non da
-- espansione libera a terra — non in contraddizione con la fonte. Aggiunto
-- alert su virus del mosaico del cetriolo e mosca bianca, non presenti
-- nella bozza (già segnalati oidio e afidi) (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Abbondante e regolare", "terreno": "Fertile, ricco di sostanza organica, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Cucurbitaceae", "giorni_germinazione": "6-10", "giorni_trapianto": "20-30", "giorni_raccolta": "50-70", "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "estate"], "resistenza_gelo": "nessuna", "spaziatura_cm": 40, "consociazioni_favorevoli": ["fagiolo", "mais", "girasole"], "consociazioni_sfavorevoli": ["patata", "salvia"]}$j$::jsonb, alert = ARRAY[$t$Molto sensibile alla siccità (frutti amari o deformi se manca acqua)$t$, $t$richiede un supporto/tutore se coltivato come rampicante$t$, $t$controllare oidio e afidi$t$, $t$raccogliere i frutti giovani per stimolare nuova produzione$t$, $t$attenzione anche al virus del mosaico del cetriolo e alla mosca bianca da serra$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Cucumis sativus$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$cetriolo$t$;
