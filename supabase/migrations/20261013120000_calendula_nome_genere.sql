-- Calendula: il nome italiano del genere è "Calendula" (nome comune della pianta e nome della riga di genere),
-- non "Calendola" (nome preferito di iNaturalist, approvato per errore). Deroga al criterio, decisa dall'utente.
-- Rollback: scripts/nomi-italiani/rollback_calendula.sql
update generi set nome = 'Calendula' where nome_scientifico = 'Calendula' and nome = 'Calendola'
  and not exists (select 1 from generi o where o.nome = 'Calendula');

update specie c set nome = 'Calendula' || substr(c.nome, length('Calendola') + 1)
from generi g
where g.id = c.genere_id and g.nome_scientifico = 'Calendula'
  and c.specie_padre_id is not null and c.nome like 'Calendola ''%'
  and not exists (select 1 from specie o where o.nome = 'Calendula' || substr(c.nome, length('Calendola') + 1));
