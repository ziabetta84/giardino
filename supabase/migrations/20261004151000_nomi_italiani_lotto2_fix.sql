-- Correzione al lotto 2: "Asparago del Perù" è un segnaposto di PlantNet, non un nome reale
-- (Asparagus falcatus è africano). Ripristina il nome scientifico.
update specie set nome = nome_scientifico
where slug = 'asparagus-falcatus' and nome = 'Asparago del Perù';
