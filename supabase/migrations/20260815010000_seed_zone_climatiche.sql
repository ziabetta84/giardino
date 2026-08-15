-- Seed di zone_climatiche con dati reali, non le stime del documento di piano.
-- Metodo: medie climatiche mensili (30 anni) per una città rappresentativa per
-- fascia, da ilMeteo.it. La finestra di gelata è stimata dal mese in cui la
-- minima media attraversa la soglia 2-3°C, non da un conteggio diretto dei
-- giorni di gelata (quel dato — indicatore LFD di CREA, agrometeorological.crea.gov.it
-- — esiste ma non è ancora scaricabile, "Coming Soon" al momento della ricerca).
-- Tre righe (sud, insulare, insulare-montana) hanno confidenza più bassa: la
-- media mensile non scende mai sotto soglia in quelle città, quindi la data è
-- una stima per estrapolazione — coerente comunque con l'esperienza diretta
-- riportata su gelate rare/eccezionali al sud.

alter table zone_climatiche add column fonti text[];

insert into zone_climatiche (codice, nome, gelata_media_ultima, gelata_media_prima, hardiness_usda, fonti) values
  ('nord', 'Pianura Padana',
   '03-10', '11-20', '8a-8b',
   array['ilMeteo.it medie climatiche Milano e Bologna (medie 30 anni)', 'Arborea Farm / FruttAma / Houzz Italia — mappatura zone USDA Italia']),

  ('nord-montana', 'Alpi',
   '05-15', '10-10', '6b-7a',
   array['ilMeteo.it medie climatiche Cortina d''Ampezzo (staz. Dobbiaco) e Bormio (medie 30 anni)', 'Arborea Farm / FruttAma / Houzz Italia — mappatura zone USDA Italia']),

  ('centro', 'Toscana, Marche, Lazio',
   '03-05', '12-15', '9a-9b',
   array['ilMeteo.it medie climatiche Ancona (medie 30 anni)', 'Arborea Farm / FruttAma / Houzz Italia — Ancona citata esplicitamente come zona 9b']),

  ('centro-montana', 'Appennino centrale',
   '03-20', '11-25', '7b-8a',
   array['ilMeteo.it medie climatiche Rieti (medie 30 anni)', 'Arborea Farm / FruttAma / Houzz Italia — mappatura zone USDA Italia']),

  ('sud', 'Campania, Puglia, Calabria',
   '02-25', '12-20', '9b-10a',
   array['ilMeteo.it medie climatiche Bari, Napoli e Lamezia Terme (medie 30 anni)', 'confidenza bassa: media mensile non attraversa la soglia di gelo, stima per estrapolazione, coerente con osservazione diretta di gelate rare/eccezionali al sud']),

  ('sud-montana', 'Appennino meridionale (Lucania)',
   '03-20', '12-10', '8a-8b',
   array['ilMeteo.it medie climatiche Potenza (medie 30 anni)', 'Arborea Farm / FruttAma / Houzz Italia — mappatura zone USDA Italia']),

  ('insulare', 'Sicilia, Sardegna',
   '02-10', '12-25', '10a-10b',
   array['ilMeteo.it medie climatiche Palermo e Cagliari (medie 30 anni)', 'confidenza bassa: media mensile non attraversa la soglia di gelo, stima per estrapolazione']),

  ('insulare-montana', 'Rilievi di Sicilia e Sardegna',
   '03-05', '12-05', '8b-9a',
   array['ilMeteo.it medie climatiche Enna (medie 30 anni)', 'confidenza bassa: soglia non attraversata nettamente, stima intermedia tra insulare e centro-montana']);
