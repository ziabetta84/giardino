-- Data dell'ultimo spostamento fra chiuso e aperto (24/11/2026, spostamento di più piante insieme).
-- La pioggia caduta negli ultimi 14 giorni vale come irrigazione per le piante all'aperto (20261123, PR #225),
-- ma l'app guarda la zona di oggi: una pianta riportata fuori a primavera riceverebbe il merito della pioggia
-- caduta quando era ancora in casa. Con questa data conta solo la pioggia dei giorni successivi.
-- La scrive il trigger quando cambia zona o sottozona e la pianta passa dal chiuso all'aperto o viceversa
-- (tipo della sottozona se c'è, altrimenti della zona: stesso criterio di store.piantaEsterna). Uno spostamento
-- fra due zone all'aperto non la tocca: la pioggia caduta resta valida. Se il client manda lui stesso un valore
-- diverso (l'«Annulla» dello spostamento, che rimette quello di prima) il trigger lo rispetta.
-- Giorno di Roma, come i giorni di pioggia di Open-Meteo. Le piante esistenti partono senza data.
-- Prove: bash scripts/spostamento/prova_db.sh. Rollback: scripts/spostamento/rollback_spostata_il.sql

alter table public.piante add column spostata_il date;

create or replace function public.piante_data_spostamento()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  prima_fuori boolean;
  ora_fuori boolean;
begin
  if new.zona_id is not distinct from old.zona_id and new.sottozona_id is not distinct from old.sottozona_id then
    return new;
  end if;
  if new.spostata_il is distinct from old.spostata_il then
    return new;
  end if;
  select coalesce((select s.tipo from public.sottozone s where s.id = old.sottozona_id),
                  (select z.tipo from public.zone z where z.id = old.zona_id)) = 'esterno' into prima_fuori;
  select coalesce((select s.tipo from public.sottozone s where s.id = new.sottozona_id),
                  (select z.tipo from public.zone z where z.id = new.zona_id)) = 'esterno' into ora_fuori;
  if coalesce(prima_fuori, false) is distinct from coalesce(ora_fuori, false) then
    new.spostata_il := (now() at time zone 'Europe/Rome')::date;
  end if;
  return new;
end;
$$;

revoke all on function public.piante_data_spostamento() from public, anon, authenticated;

create trigger piante_data_spostamento
  before update of zona_id, sottozona_id on public.piante
  for each row execute function public.piante_data_spostamento();
