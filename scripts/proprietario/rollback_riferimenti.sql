-- Annulla 20261119120000_riferimenti_stesso_proprietario.sql (nessun dato toccato).
-- Uso: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/proprietario/rollback_riferimenti.sql
drop trigger if exists piante_controlla_zona on public.piante;
drop trigger if exists sottozone_controlla_zona on public.sottozone;
drop trigger if exists tappe_controlla_progetto on public.tappe;
drop function if exists public.piante_controlla_zona();
drop function if exists public.sottozone_controlla_zona();
drop function if exists public.tappe_controlla_progetto();
