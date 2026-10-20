-- Rollback della fase 7: rimette piante.specie (facoltativa, come dopo la fase 6) con la chiave esterna verso specie
-- (on update cascade) e la riempie da piante_vecchie_specie, poi toglie quella tabella. Le piante create dopo la fase 7
-- restano senza specie. Prima di un rollback della fase 6 o della fase 5 va eseguito questo. Rimettere prima il
-- frontend della fase 6 non serve: l'app della fase 7 non manda la colonna.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase7.sql
alter table public.piante add column specie text;
update public.piante p set specie = v.specie from public.piante_vecchie_specie v where v.pianta_id = p.id;
do $$
begin
  if to_regclass('public.specie') is not null then
    alter table public.piante add constraint piante_specie_fkey foreign key (specie) references public.specie (slug) on update cascade;
  end if;
end $$;
drop table public.piante_vecchie_specie;
