-- Rollback generi: toglie la colonna e la tabella.
alter table specie drop column if exists genere_id;
drop table if exists generi;
