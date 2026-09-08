-- Corregge programmi_irrigazione_giardino_uniq (creato prima dell'aggiunta
-- di sottozona_id, vedi 20260908010000): il predicato non escludeva le
-- righe a livello sottozona, che soddisfacevano comunque "zona_id is null
-- and pianta_id is null" e finivano per condividere lo stesso slot unique
-- di owner_id — al massimo un programma di sottozona per utente in tutta
-- l'app, invece che uno per sottozona. Il predicato ora richiede anche
-- sottozona_id is null, così l'indice torna a coprire solo il vero livello
-- giardino.
drop index programmi_irrigazione_giardino_uniq;

create unique index programmi_irrigazione_giardino_uniq on programmi_irrigazione (owner_id)
  where zona_id is null and sottozona_id is null and pianta_id is null;
