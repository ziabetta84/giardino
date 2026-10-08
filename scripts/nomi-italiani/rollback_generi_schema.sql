-- Ordine completo dei rollback: rollback_lotto11.sql -> rollback_generi_nomi_scelti.sql -> rollback_righe_genere.sql -> rollback_generi_dati.sql -> rollback_generi_schema.sql
-- NON eseguire prima di rollback_lotto11.sql e rollback_generi_nomi_scelti.sql
-- Rollback generi: toglie la colonna e la tabella.
alter table specie drop column if exists genere_id;
drop table if exists generi;
