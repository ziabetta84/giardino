-- Verifica reale (#120) delle 3 voci Mammillaria già esistenti nel
-- catalogo, in occasione dell'espansione a 18 nuove specie del genere.
-- Correzione minima: esigenze.terreno da "Sabbioso"/"Molto drenato" a
-- "Drenato", per coerenza con il dato RHS confermato su tutto il genere
-- (Soil Types Loam, Sand; Moisture Well-drained). Confermati invece
-- esigenze.luce "Pieno sole" e resistenza_gelo "nessuna": corrispondono
-- esattamente a Position "Full sun" e Hardiness H2 ("not surviving being
-- frozen") su Mammillaria elongata e Mammillaria plumosa, le due specie
-- già identificate nel catalogo.
--
-- mammillaria (voce generica, usata da 3 piante reali non ancora
-- identificate a livello di specie) verificata sui dati di genere RHS
-- (Genus: "spiny cacti with spherical or columnar stems... funnel-shaped
-- flowers"), non su una pagina specie-specifica — dichiarato in fonti.

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Drenato"}$j$::jsonb, fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — genere Mammillaria, dato generico non legato a una specie identificata$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$mammillaria$t$;
update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Drenato"}$j$::jsonb, fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Mammillaria elongata$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$mammillaria-allungata$t$;
update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Drenato"}$j$::jsonb, fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Mammillaria plumosa$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$mammillaria-piumosa$t$;
