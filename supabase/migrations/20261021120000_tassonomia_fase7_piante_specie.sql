-- Fase 7 del modello tassonomico: passaggio definitivo. L'app (dal commit della fase 7) non legge né scrive più
-- piante.specie, che si toglie con la sua chiave esterna verso l'archivio specie (decisione dell'utente del 20/10/2026).
-- Gli slug di oggi restano, per un rollback esatto, nella tabella interna piante_vecchie_specie (nessun accesso per i
-- client; una riga sparisce con la sua pianta). Va applicata solo dopo il deploy dell'app della fase 7: l'app della
-- fase 6 scrive ancora la colonna e fallirebbe a ogni salvataggio. Rollback:
--   psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase7.sql
-- Piano: docs/superpowers/plans/2026-10-20-modello-tassonomico-fase7-passaggio.md
create table public.piante_vecchie_specie (
  pianta_id text primary key references public.piante (id) on delete cascade,
  specie text not null
);
alter table public.piante_vecchie_specie enable row level security;
revoke all on public.piante_vecchie_specie from anon, authenticated;
insert into public.piante_vecchie_specie (pianta_id, specie) select id, specie from public.piante where specie is not null;
alter table public.piante drop constraint if exists piante_specie_fkey;
alter table public.piante drop column specie;
