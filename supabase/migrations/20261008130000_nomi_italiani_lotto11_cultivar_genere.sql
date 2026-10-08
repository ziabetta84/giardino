-- Lotto 11: cultivar nominate "Genere 'Epiteto'" prendono il nome italiano del genere (generi.nome).
-- Solo se il genere ha un nome italiano e il nome nuovo non è già in uso. Rollback: rollback_lotto11.sql
update specie c set nome = g.nome || ' ' || substr(c.nome, length(g.nome_scientifico) + 2)
from generi g
where g.id = c.genere_id
  and c.specie_padre_id is not null
  and c.nome = c.nome_scientifico
  and g.nome <> g.nome_scientifico
  and left(c.nome_scientifico, length(g.nome_scientifico) + 2) = g.nome_scientifico || ' ''' and substr(c.nome_scientifico, length(g.nome_scientifico) + 2) ~ '^''[^'']+''$'
  and not exists (select 1 from specie o where o.nome = g.nome || ' ' || substr(c.nome, length(g.nome_scientifico) + 2));
