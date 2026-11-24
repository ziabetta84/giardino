-- Rollback di 20261124120000_zorba_correzione.sql: toglie la colonna (le correzioni scritte si perdono) e rimette il
-- trigger dei voti com'era. Uso: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/zorba/rollback_correzione.sql
alter table public.zorba_messaggi drop column voto_correzione;
create or replace function public.zorba_voto() returns trigger language plpgsql set search_path = '' as $$
begin
  if new.voto is distinct from -1 then new.voto_motivo := null; new.voto_commento := null; end if;
  if (new.voto, new.voto_motivo, new.voto_commento) is distinct from (old.voto, old.voto_motivo, old.voto_commento) then
    new.votato_il := now();
  end if;
  return new;
end $$;
