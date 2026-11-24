-- Rollback di 20261124100000_piante_spostata_il.sql. Da eseguire solo dopo aver tolto dall'app la scrittura e la
-- lettura di piante.spostata_il (altrimenti lo spostamento e il suo «Annulla» falliscono).
-- psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/spostamento/rollback_spostata_il.sql
drop trigger if exists piante_data_spostamento on public.piante;
drop function if exists public.piante_data_spostamento();
alter table public.piante drop column if exists spostata_il;
