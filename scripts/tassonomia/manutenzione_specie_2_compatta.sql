-- Fase 1b, passo 2: compatta public.specie (riscrive tabella, TOAST e indici; i dati non cambiano).
-- VACUUM non può stare in una transazione, quindi le impostazioni sono di sessione: vengono annullate anche se la
-- compattazione fallisce, perché sul pooler in modalità sessione la connessione al server può essere riusata.
-- lock_timeout di 2 s per lo stesso motivo del passo 1. Uscita 3 se la compattazione fallisce: in quel caso specie
-- resta com'era (VACUUM FULL è tutto o niente). Se cade la connessione, il server può finire la compattazione da solo.
\set ON_ERROR_STOP 0
set statement_timeout = 0;
set lock_timeout = '2s';
vacuum (full, analyze) public.specie;
\set fallita :ERROR
reset statement_timeout;
reset lock_timeout;
\set ON_ERROR_STOP 1
select 'dopo: statement_timeout=' || current_setting('statement_timeout')
       || ' lock_timeout=' || current_setting('lock_timeout') as impostazioni \gset
\echo :impostazioni
\if :fallita
  do $$ begin raise exception 'COMPATTAZIONE FALLITA: specie è rimasta com''era'; end $$;
\endif
