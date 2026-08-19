-- Correzione di rigore su 3 schede dei batch 1-2 del libro "Fiori e
-- Piante da Appartamento" (#120): aggiunta nota tassonomica esplicita
-- dove la famiglia botanica indicata segue la classificazione APG
-- corrente ma differisce da quella tradizionale/più diffusa nelle fonti
-- più datate — stessa cura già applicata alle riclassificazioni trovate
-- su fonte RHS (es. Rosmarinus → Salvia rosmarinus).
--
-- Ardisia: Primulaceae (APG) vs Myrsinaceae (classificazione tradizionale).
-- Calceolaria: Calceolariaceae (APG) vs Scrophulariaceae (tradizionale).
-- Beloperone: nome accettato oggi è Justicia brandegeana; Beloperone
-- guttata (nome usato dalla fonte) è un sinonimo, non un errore.

update specie set alert = array_append(alert, $t$nota tassonomica: famiglia classificata oggi come Primulaceae (APG); tradizionalmente/in molte fonti più datate inclusa in Myrsinaceae$t$) where slug = $t$ardisia$t$;

update specie set alert = array_append(alert, $t$nota tassonomica: famiglia classificata oggi come Calceolariaceae; tradizionalmente inclusa in Scrophulariaceae$t$) where slug = $t$calceolaria$t$;

update specie set alert = array_append(alert, $t$nota tassonomica: il nome accettato oggi è Justicia brandegeana; Beloperone guttata (usato da questa fonte) è un sinonimo$t$) where slug = $t$beloperone$t$;
