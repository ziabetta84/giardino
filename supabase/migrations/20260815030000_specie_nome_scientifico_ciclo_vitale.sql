-- Corregge lo schema di specie prima dell'import di Fase 2: nome_scientifico
-- e ciclo_vitale sono dati reali già presenti in specie.json (rispettivamente
-- 93/106 e 9/106 specie) che la migrazione di Fase 1 non catturava — andrebbero
-- persi importando "così com'è" senza queste colonne.
--
-- consociazioni_favorevoli/sfavorevoli invece si tolgono: nei dati reali
-- vivono dentro il campo "coltivazione" (solo per le 8 specie che ce l'hanno),
-- non a livello superiore come ipotizzato in Fase 1 — sarebbero sempre vuote.
-- Restano dentro ciclo_colturale, importato così com'è; la forma definitiva
-- (oggi per stagione, non per offset dalla gelata) si decide in Fase 3.

alter table specie add column nome_scientifico text;

alter table specie add column ciclo_vitale text
  check (ciclo_vitale in ('annuale', 'biennale', 'perenne'));

alter table specie drop column consociazioni_favorevoli;
alter table specie drop column consociazioni_sfavorevoli;
