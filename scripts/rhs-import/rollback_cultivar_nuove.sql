-- Rollback delle cultivar nuove del 18/11/2026: si rifiuta se una scheda o una pianta punta a una di esse
do $$ begin if exists (select 1 from public.cultivar c where c.fonti[1] like 'RHS (rhs.org.uk) — pagina %% controllo del 18/11/2026' and (exists (select 1 from public.schede s where s.cultivar_id = c.id) or exists (select 1 from public.piante p where p.cultivar_id = c.id))) then raise exception 'cultivar in uso: rollback rifiutato'; end if; end $$;
delete from public.cultivar where fonti[1] like 'RHS (rhs.org.uk) — pagina % controllo del 18/11/2026';
