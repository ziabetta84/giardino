-- Concime usato nell'ultima concimazione (17/11/2026, cure per zona).
-- ultima_cura.concimazione dice solo quando; questa colonna dice con che cosa,
-- così chi concima un'aiuola intera con un prodotto scelto lo ritrova sulla
-- pianta (e Zorba può tenerne conto). Facoltativa: una concimazione registrata
-- senza indicare il prodotto la riporta a null.
-- on delete set null: togliere un concime dalla dispensa non tocca le piante.
-- Il trigger impedisce di collegare un concime di un altro utente: la chiave
-- esterna da sola lo permetterebbe (il controllo della FK ignora l'RLS).
-- Rollback: scripts/cure/rollback_ultimo_concime.sql

alter table public.piante
  add column ultimo_concime_id uuid references public.concimi(id) on delete set null;

create index piante_ultimo_concime_id_idx on public.piante (ultimo_concime_id);

create or replace function public.piante_controlla_concime()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.ultimo_concime_id is not null and not exists (
    select 1 from public.concimi c
    where c.id = new.ultimo_concime_id and c.owner_id = new.owner_id
  ) then
    raise exception 'concime non trovato tra quelli del proprietario della pianta'
      using errcode = '23503';
  end if;
  return new;
end;
$$;

revoke all on function public.piante_controlla_concime() from public, anon, authenticated;

create trigger piante_controlla_concime
  before insert or update of ultimo_concime_id, owner_id on public.piante
  for each row execute function public.piante_controlla_concime();
