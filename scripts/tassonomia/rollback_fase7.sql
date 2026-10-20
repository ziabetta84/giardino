-- Rollback della fase 7: rimette piante.specie (facoltativa, come dopo la fase 6) con la chiave esterna verso specie
-- (on update cascade) e la riempie da piante_vecchie_specie, poi toglie quella tabella. Le piante create dopo la fase 7
-- restano senza specie. Prima di un rollback della fase 6 o della fase 5 va eseguito questo. Rimettere prima il
-- frontend della fase 6 non serve: l'app della fase 7 non manda la colonna.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase7.sql
-- Rifiutato se la tabella degli slug manca, se manca l'archivio specie o se uno slug salvato non è più nell'archivio.
do $$
begin
  if to_regclass('public.piante_vecchie_specie') is null then
    raise exception 'Rollback fase 7 rifiutato: piante_vecchie_specie non c''è (fase 7 non applicata?)';
  end if;
  if to_regclass('public.specie') is null then
    raise exception 'Rollback fase 7 rifiutato: manca l''archivio specie, la chiave esterna non si potrebbe rimettere';
  end if;
  if exists (select 1 from public.piante_vecchie_specie v left join public.specie s on s.slug = v.specie where s.slug is null) then
    raise exception 'Rollback fase 7 rifiutato: slug salvati che non sono più nell''archivio specie';
  end if;
end $$;
alter table public.piante add column specie text;
update public.piante p set specie = v.specie from public.piante_vecchie_specie v where v.pianta_id = p.id;
alter table public.piante add constraint piante_specie_fkey foreign key (specie) references public.specie (slug) on update cascade;
drop table public.piante_vecchie_specie;
