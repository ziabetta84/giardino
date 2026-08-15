-- Rende interrogabile la confidenza già annotata come testo libero in fonti:
-- stesso vocabolario di specie.stato_verifica, non un campo nuovo da imparare.
-- 'bozza' qui non vuol dire "nessuna fonte" (ce l'hanno tutte le righe) ma
-- "la data è una stima per estrapolazione, non una lettura diretta della
-- soglia di gelo" — vedi il dettaglio già in fonti per ogni riga.

alter table zone_climatiche
  add column stato_verifica text not null default 'bozza'
  check (stato_verifica in ('bozza', 'verificato'));

update zone_climatiche set stato_verifica = 'verificato'
  where codice in ('nord', 'nord-montana', 'centro', 'centro-montana', 'sud-montana');

-- sud, insulare, insulare-montana restano 'bozza': la temperatura minima
-- media non attraversa mai la soglia di gelo nella città di riferimento,
-- quindi la data è dedotta per estrapolazione, non letta direttamente
