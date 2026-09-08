-- Aggiunge il livello sottozona alla cascata di irrigazione automatica
-- (giardino → zona → sottozona → pianta), tra zona e pianta. Una riga può
-- avere sottozona_id valorizzato invece di zona_id (una sottozona implica
-- già una zona tramite la FK di sottozone → zone), mai insieme a zona_id
-- o pianta_id — check a 3 vie invece del precedente a 2.
alter table programmi_irrigazione
  add column sottozona_id uuid references sottozone(id) on delete cascade;

alter table programmi_irrigazione
  drop constraint programmi_irrigazione_check;

alter table programmi_irrigazione
  add constraint programmi_irrigazione_check
    check (num_nonnulls(zona_id, sottozona_id, pianta_id) <= 1);

alter table programmi_irrigazione
  add constraint programmi_irrigazione_sottozona_id_key unique (sottozona_id);
