-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, resistenza_gelo "media" (RHS H4, esattamente la fascia
-- già mappata, coerente con l'alert già presente sui -5°C per le piante
-- giovani). terreno riformulato per riflettere sia la preferenza RHS
-- ("deep, fertile, sharply-drained soil") sia la tolleranza già segnalata
-- in bozza. spaziatura_cm (400) NON corretta: la bozza è già più generosa
-- del Max Spread RHS (1.5-2.5m), plausibile per un olivo adulto in piena
-- terra nel tempo (RHS tende a sottostimare le dimensioni finali di alberi
-- da frutto maturi). SEGNALAZIONE DI SICUREZZA PRIORITARIA: RHS classifica
-- Olea europaea come "High Risk Host for Xylella fastidiosa" — ancora più
-- diretto della lavanda, essendo l'olivo la specie concretamente colpita
-- dall'epidemia in Puglia. Aggiunto come alert dedicato, non presente nella
-- bozza nonostante l'elenco già dettagliato di parassiti/malattie
-- specifiche. Aggiunta anche armillaria rara (RHS Diseases).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Irrigazione moderata senza ristagni", "terreno": "Fertile, ben drenato (tollera anche terreni poveri e sassosi)"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Oleaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "media", "spaziatura_cm": 400, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Evitare ristagni idrici: l'olivo è molto sensibile a marciumi radicali.$t$, $t$Le giovani piante possono soffrire gelate sotto -5°C.$t$, $t$In vaso richiede più acqua rispetto alla coltivazione in piena terra$t$, $t$Potature drastiche riducono la produzione per 1–2 anni.$t$, $t$Attenzione a: Mosca dell'olivo (Bactrocera oleae), Cocciniglia mezzo grano di pepe, Occhio di pavone (Spilocaea oleaginea), Rogna dell'olivo (Pseudomonas savastanoi)$t$, $t$SEGNALAZIONE IMPORTANTE: RHS classifica l'olivo come "High Risk Host" per Xylella fastidiosa, il patogeno da quarantena responsabile del disseccamento rapido dell'olivo in Puglia — massima attenzione a sintomi di disseccamento anomalo dei rami, segnalare eventuali sospetti alle autorità fitosanitarie$t$, $t$raramente può essere colpito da armillaria (marciume del piede)$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Olea europaea$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$ulivo$t$;
