-- Rollback: svuota le due colonne (o eliminale, vedi migration 20261006100000).
update specie set sinonimi_botanici = null, nome_accettato = null
where sinonimi_botanici is not null or nome_accettato is not null;
