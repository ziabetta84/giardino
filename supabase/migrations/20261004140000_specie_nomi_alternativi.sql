-- Sinonimi e nomi comuni alternativi, per trovare una pianta anche con il nome che l'utente conosce meglio.
-- Testo con i nomi separati da " | " (cercabile con ilike come nome e nome_scientifico).
-- Il nome principale resta in specie.nome; qui solo gli altri.
-- Rollback: alter table specie drop column nomi_alternativi;
alter table specie add column if not exists nomi_alternativi text;
comment on column specie.nomi_alternativi is
  'Altri nomi comuni italiani e sinonimi, separati da " | ". Il nome principale è specie.nome.';
