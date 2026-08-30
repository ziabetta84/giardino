-- Un cultivar è una normale riga `specie`, con questo campo valorizzato
-- verso la specie madre invece che una tabella separata (vedi discussione
-- issue #153, 2026-08-30): riusa gratis stato_verifica/fonti/esigenze/
-- manutenzione già esistenti, niente schema parallelo da mantenere.
alter table specie
  add column specie_padre_id uuid references specie(id) on delete cascade;

create index specie_padre_id_idx on specie (specie_padre_id);
