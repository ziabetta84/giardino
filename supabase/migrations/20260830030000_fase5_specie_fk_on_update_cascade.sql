-- Fase 5 (fix da revisione finale): rinominare una specie richiede oggi due
-- scritture separate (piante.specie e specie.slug) su due richieste HTTP
-- distinte, senza transazione a cavallo delle due — e nessun ordine funziona
-- con la FK di default (NO ACTION ON UPDATE): aggiornare prima le piante fa
-- fallire perché il nuovo slug non esiste ancora in specie; aggiornare prima
-- specie fa fallire perché le piante puntano ancora al vecchio slug. Con
-- `on update cascade` è Postgres stesso a propagare il rename alle piante
-- quando cambia specie.slug, in un'unica scrittura atomica lato server — è
-- anche l'unico comportamento sensato in ottica multi-tenant: `specie` è un
-- catalogo condiviso fra tutti i tenant, quindi un futuro secondo utente con
-- piante sulla stessa specie non deve dipendere da un UPDATE manuale della
-- riga piante che le RLS del tenant che rinomina non potrebbero nemmeno vedere.
alter table piante drop constraint piante_specie_fkey;
alter table piante add constraint piante_specie_fkey
  foreign key (specie) references specie(slug) on update cascade;
