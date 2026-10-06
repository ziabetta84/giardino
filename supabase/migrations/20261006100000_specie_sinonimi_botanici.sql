-- Sinonimi botanici (nomi scientifici obsoleti o alternativi, da GBIF) e nome accettato oggi.
-- sinonimi_botanici: testo separato da ' | ', cercato dal selettore. nome_accettato: solo se la riga è
-- un sinonimo di un altro nome secondo GBIF.
-- Rollback: alter table specie drop column sinonimi_botanici, drop column nome_accettato;
alter table specie add column if not exists sinonimi_botanici text;
alter table specie add column if not exists nome_accettato text;
comment on column specie.sinonimi_botanici is 'Sinonimi botanici (GBIF) separati da " | "; ricercabili, non sono nomi comuni';
comment on column specie.nome_accettato is 'Nome scientifico oggi accettato (GBIF) se diverso da nome_scientifico';
