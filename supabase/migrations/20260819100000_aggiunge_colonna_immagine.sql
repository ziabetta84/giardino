-- Aggiunge la colonna "immagine" alla tabella specie (#120): immagine
-- hero da mostrare come fallback nella scheda pianta quando l'utente
-- non ha ancora caricato foto personali. Sorgente: Wikimedia Commons,
-- solo licenze CC0/dominio pubblico/CC BY/CC BY-SA (mai NC/ND, per
-- restare compatibili con un uso commerciale futuro del catalogo).
-- Selezione automatica via script, non rivista visivamente una per una:
-- "verificata" resta false finché non viene controllata a batch.

alter table specie add column if not exists immagine jsonb;
