-- Rollback lotto 11: le cultivar "Genere 'Epiteto'" tornano al nome scientifico.
-- ATTENZIONE: eseguire PRIMA di rollback_generi_nomi_scelti.sql (usa generi.nome per riconoscere le cultivar).
update specie c set nome = c.nome_scientifico
from generi g
where g.id = c.genere_id and c.specie_padre_id is not null and c.nome <> c.nome_scientifico
  and left(c.nome_scientifico, length(g.nome_scientifico) + 2) = g.nome_scientifico || ' ''' and substr(c.nome_scientifico, length(g.nome_scientifico) + 2) ~ '^''[^'']+''$'
  and left(c.nome, length(g.nome) + 1) = g.nome || ' ' and g.nome <> g.nome_scientifico;
