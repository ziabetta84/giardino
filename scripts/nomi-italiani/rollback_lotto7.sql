-- Rollback lotto 7: le cultivar tornano al nome scientifico (prima nessuna aveva un nome diverso).
update specie set nome = nome_scientifico where specie_padre_id is not null and nome <> nome_scientifico;
