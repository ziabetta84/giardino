-- Correzione della curatrice su una risposta di Zorba (24/11/2026): con il pollice giù può scrivere come avrebbe
-- dovuto rispondere Zorba. Le risposte approvate (pollice su) e quelle corrette sono gli esempi da usare subito nelle
-- regole e nel prompt e, più avanti, per il fine-tuning di un modello open (documento «Fine-tuning di Zorba su un
-- modello open»). La colonna la scrive il proprietario del messaggio, come i voti; l'app mostra il campo solo alla
-- curatrice. Come motivo e commento, ha senso solo col pollice giù: il trigger la azzera con un altro voto.
-- Prove: bash scripts/zorba/prova_db.sh. Rollback: scripts/zorba/rollback_correzione.sql

alter table public.zorba_messaggi
  add column voto_correzione text check (length(voto_correzione) <= 4000),
  add constraint zorba_messaggi_correzione_solo_zorba check (ruolo = 'zorba' or voto_correzione is null);

grant update (voto_correzione) on public.zorba_messaggi to authenticated;

create or replace function public.zorba_voto() returns trigger language plpgsql set search_path = '' as $$
begin
  if new.voto is distinct from -1 then
    new.voto_motivo := null; new.voto_commento := null; new.voto_correzione := null;
  end if;
  if (new.voto, new.voto_motivo, new.voto_commento, new.voto_correzione)
     is distinct from (old.voto, old.voto_motivo, old.voto_commento, old.voto_correzione) then
    new.votato_il := now();
  end if;
  return new;
end $$;
