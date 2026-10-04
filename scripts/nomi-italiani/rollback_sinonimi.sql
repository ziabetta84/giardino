-- Rollback: svuota nomi_alternativi (o elimina la colonna, vedi migration 20261004140000).
update specie set nomi_alternativi = null where nomi_alternativi is not null;
