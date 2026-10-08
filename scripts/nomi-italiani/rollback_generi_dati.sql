-- Ordine completo dei rollback: rollback_lotto11.sql -> rollback_generi_nomi_scelti.sql -> rollback_righe_genere.sql -> rollback_generi_dati.sql -> rollback_generi_schema.sql
-- NON eseguire prima di rollback_lotto11.sql e rollback_generi_nomi_scelti.sql
-- Rollback dati generi: azzera i dati GBIF e riporta il nome al nome scientifico.
update generi set gbif_key = null, specie_gbif = null, gbif_rilevato_il = null, nome = nome_scientifico;
