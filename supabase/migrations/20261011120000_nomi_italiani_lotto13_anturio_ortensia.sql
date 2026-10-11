-- Lotto 13: Anturio e Ortensia (nomi già sulle righe di genere dal lotto 4) diventano il nome dei generi
-- e le cultivar "Genere 'Epiteto'" li usano. Rollback: scripts/nomi-italiani/rollback_lotto13.sql
update generi g set nome = v.nome from (values ('Anthurium', 'Anturio'), ('Hydrangea', 'Ortensia')) as v(sci, nome)
where g.nome_scientifico = v.sci and g.nome = g.nome_scientifico;

update specie c set nome = g.nome || ' ' || substr(c.nome, length(g.nome_scientifico) + 2)
from generi g
where g.id = c.genere_id
  and g.nome_scientifico in ('Anthurium', 'Hydrangea')
  and c.specie_padre_id is not null
  and c.nome = c.nome_scientifico
  and g.nome <> g.nome_scientifico
  and left(c.nome_scientifico, length(g.nome_scientifico) + 2) = g.nome_scientifico || ' ''' and substr(c.nome_scientifico, length(g.nome_scientifico) + 2) ~ '^''[^'']+''$'
  and not exists (select 1 from specie o where o.nome = g.nome || ' ' || substr(c.nome, length(g.nome_scientifico) + 2));
