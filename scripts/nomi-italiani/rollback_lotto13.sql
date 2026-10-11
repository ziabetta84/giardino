-- Rollback lotto 13: le cultivar di Anthurium e Hydrangea tornano al nome scientifico, poi i generi.
-- Eseguire PRIMA di rollback_lotto11.sql.
update specie c set nome = c.nome_scientifico
from generi g
where g.id = c.genere_id and g.nome_scientifico in ('Anthurium', 'Hydrangea') and c.specie_padre_id is not null
  and c.nome <> c.nome_scientifico and left(c.nome, length(g.nome) + 1) = g.nome || ' ' and g.nome <> g.nome_scientifico;

update generi set nome = nome_scientifico where nome_scientifico in ('Anthurium', 'Hydrangea');
