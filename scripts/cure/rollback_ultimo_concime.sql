-- Annulla 20261117120000_piante_ultimo_concime.sql (perde i concimi registrati).
-- Uso: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/cure/rollback_ultimo_concime.sql
drop trigger if exists piante_controlla_concime on public.piante;
drop function if exists public.piante_controlla_concime();
alter table public.piante drop column if exists ultimo_concime_id;
