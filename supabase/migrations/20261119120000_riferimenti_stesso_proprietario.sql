-- Riferimenti tra tabelle dell'utente solo verso righe dello stesso proprietario (19/11/2026).
-- Il controllo di una chiave esterna ignora l'RLS: chi conosce l'uuid di una zona, sottozona o progetto
-- di un altro utente potrebbe collegarci una propria pianta, sottozona o tappa. Non legge dati altrui,
-- ma sporca il giardino dell'altro (per esempio una zona che non si può più eliminare per la RESTRICT).
-- Stesso schema di piante_controlla_concime (20261117120000): trigger BEFORE, security definer,
-- non eseguibile dai client, errore 23503 come una chiave esterna violata.
-- Coperti: piante.zona_id, piante.sottozona_id, sottozone.zona_id, tappe.progetto_id
-- (foto.pianta_id è già nella policy di foto; zorba_fili lo scrivono solo le funzioni del server).
-- Prove: bash scripts/proprietario/prova_db.sh. Rollback: scripts/proprietario/rollback_riferimenti.sql

create or replace function public.piante_controlla_zona()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.zone z where z.id = new.zona_id and z.owner_id = new.owner_id) then
    raise exception 'zona non trovata tra quelle del proprietario della pianta' using errcode = '23503';
  end if;
  if new.sottozona_id is not null and not exists (
    select 1 from public.sottozone s where s.id = new.sottozona_id and s.owner_id = new.owner_id
  ) then
    raise exception 'sottozona non trovata tra quelle del proprietario della pianta' using errcode = '23503';
  end if;
  return new;
end;
$$;

create or replace function public.sottozone_controlla_zona()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.zone z where z.id = new.zona_id and z.owner_id = new.owner_id) then
    raise exception 'zona non trovata tra quelle del proprietario della sottozona' using errcode = '23503';
  end if;
  return new;
end;
$$;

create or replace function public.tappe_controlla_progetto()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.progetti p where p.id = new.progetto_id and p.owner_id = new.owner_id) then
    raise exception 'progetto non trovato tra quelli del proprietario della tappa' using errcode = '23503';
  end if;
  return new;
end;
$$;

revoke all on function public.piante_controlla_zona() from public, anon, authenticated;
revoke all on function public.sottozone_controlla_zona() from public, anon, authenticated;
revoke all on function public.tappe_controlla_progetto() from public, anon, authenticated;

create trigger piante_controlla_zona
  before insert or update of zona_id, sottozona_id, owner_id on public.piante
  for each row execute function public.piante_controlla_zona();
create trigger sottozone_controlla_zona
  before insert or update of zona_id, owner_id on public.sottozone
  for each row execute function public.sottozone_controlla_zona();
create trigger tappe_controlla_progetto
  before insert or update of progetto_id, owner_id on public.tappe
  for each row execute function public.tappe_controlla_progetto();
