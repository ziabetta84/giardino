-- Aggiunta reale (#120): Mammillaria vetula subsp. gracilis, unica specie
-- rimasta esclusa dall'espansione Mammillaria (vedi 20260817010000) perché
-- la pagina RHS salvata era incompleta. Roberta ha risalvato la pagina RHS
-- una seconda volta, ma resta uno stub (solo Family/Genus, senza box di
-- coltivazione/Hardiness/Pests) — problema della pagina stessa, non del
-- salvataggio. Usata come fonte la scheda del vivaio italiano
-- "Vivai Le Georgiche" (legeorgiche.it), che riporta dati di coltivazione
-- reali: esposizione, terreno, irrigazione, rusticità H2 (coerente con la
-- scala già stabilita per l'intero genere in questo catalogo, dove H2→
-- "nessuna" per i cactus del genere, non "bassa" come per altre specie,
-- per restare coerenti con le 18 già inserite), dimensioni a maturità
-- (8-10cm altezza, 15-20cm larghezza) e propagazione (per divisione dei
-- cespi o talee dei fusti laterali, non per seme — finestra_semina lasciata
-- vuota di conseguenza, come già fatto per mammillaria-lauii). A differenza
-- delle 18 specie sorelle verificate su RHS, questa fonte non riporta dati
-- su parassiti/malattie: nessun alert inventato in merito.

insert into specie
  (nome, nome_scientifico, famiglia_botanica, descrizione, esigenze, alert, manutenzione, ciclo_colturale, vaso, ciclo_vitale, slug, fonti, stato_verifica, verificata_il, verificata_da)
values
($t$Mammillaria vetula subsp. gracilis$t$, $t$Mammillaria vetula subsp. gracilis$t$, $t$Cactaceae$t$, $t$Piccolo cactus cespitoso dai fusti cilindrici sottili ricoperti di spicole fini ("thimble cactus"), che formano cuscini compatti; fiori bianchi in primavera. Si propaga facilmente per divisione dei cespi o talee dei fusti laterali.$t$, $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Drenato"}$j$::jsonb, ARRAY[$t$evitare assolutamente ristagni idrici$t$, $t$richiede molta luce per mantenere la forma compatta, con protezione nelle ore più calde dell'estate$t$, $t$si propaga facilmente per divisione dei cespi o talee dei fusti laterali$t$], $j${"irrigazione": {"primavera": "ogni 14-20 giorni", "estate": "ogni 10-14 giorni", "autunno": "ogni 20-30 giorni", "inverno": "sospesa"}, "concimazione": {"primavera": "ogni 30 giorni, con concime per cactacee", "estate": "ogni 30 giorni", "autunno": "sospesa", "inverno": "sospesa"}, "potatura": {"primavera": "nessuna", "estate": "nessuna", "autunno": "nessuna", "inverno": "nessuna"}, "npk": {"primavera": "2-7-7", "estate": "2-7-7", "autunno": null, "inverno": null}}$j$::jsonb, $j${"famiglia_botanica": "Cactaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 15, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, $j${"adatta": true, "dimensione_minima_litri": 1, "rinvaso_ogni_mesi": 24, "irrigazione_fattore": 0.2}$j$::jsonb, $t$perenne$t$, $t$mammillaria-vetula-gracilis$t$, ARRAY[$t$Vivai Le Georgiche (legeorgiche.it) — Mammillaria gracilis (fonte vivaistica italiana, usata come fallback: la pagina RHS per questa specie è risultata incompleta anche dopo un secondo salvataggio, priva di box di coltivazione)$t$], $t$verificato$t$, now(), $t$Roberta + Claude Code (pagina vivaistica salvata e letta localmente)$t$);
