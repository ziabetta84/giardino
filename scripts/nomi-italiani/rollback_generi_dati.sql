-- Rollback dati generi: azzera i dati GBIF e riporta il nome al nome scientifico.
update generi set gbif_key = null, specie_gbif = null, gbif_rilevato_il = null, nome = nome_scientifico;
