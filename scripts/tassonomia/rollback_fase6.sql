-- Rollback della fase 6: toglie le funzioni del catalogo e rimette piante.specie obbligatoria e il vincolo «al più uno».
-- Rifiutato se una pianta non ha più la vecchia specie (creata o cambiata dall'app nuova): andrebbe prima ricollegata a
-- mano a una riga di specie. Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase6.sql
do $$
declare n bigint;
begin
  select count(*) into n from public.piante where specie is null;
  if n > 0 then raise exception 'Rollback fase 6 rifiutato: % piante senza la vecchia specie', n; end if;
end $$;
drop function public.cerca_catalogo(text), public.catalogo_mie_piante(), public.catalogo_voci(text[]);
drop schema catalogo cascade;
alter table public.piante drop constraint piante_taxon_o_cultivar;
alter table public.piante add constraint piante_taxon_o_cultivar check (num_nonnulls(taxon_id, cultivar_id) <= 1);
alter table public.piante alter column specie set not null;
