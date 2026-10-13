-- Tre doppioni con dati propri: la pianta daucus-carota passa a carota; si cancellano
-- daucus-carota (bozza PFAF), jasminum-officinale (descrizione già contenuta in jasminum)
-- e agapanthus (descrizione di genere sotto il nome di una specie; il genere è agapanto).
-- Rollback: scripts/nomi-italiani/rollback_tre_casi_doppioni.sql
update piante set specie = 'carota' where specie = 'daucus-carota'
  and exists (select 1 from specie where slug = 'carota');
delete from specie where slug in ('agapanthus','jasminum-officinale','daucus-carota')
  and not exists (select 1 from piante p where p.specie = specie.slug)
  and not exists (select 1 from specie c where c.specie_padre_id = specie.id);
