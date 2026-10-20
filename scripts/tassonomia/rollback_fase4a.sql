-- Rollback della fase 4a: toglie le righe di mappa_specie delle cultivar, tutte le cultivar e i taxon di COL aggiunti
-- per le cultivar (riconoscibili dalla nota). Le righe di mappa della fase 3 e i taxon delle fasi 2 e 3 restano.
-- Si rifiuta se le fasi successive sono cominciate: qualsiasi riga in schede (fase 4b) o in nomi_comuni (fase 4c), o una
-- pianta che punta a una cultivar (fase 5); prima vanno annullate quelle.
-- Non TRUNCATE: schede, piante e mappa_specie hanno chiavi esterne verso cultivar.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase4a.sql
-- Poi, per restituire lo spazio: psql "$URL" -X -c 'vacuum full public.mappa_specie' -c 'vacuum full public.cultivar' -c 'vacuum full public.taxa'
set local statement_timeout = '10min';
do $$
begin
  if exists (select 1 from public.schede) or exists (select 1 from public.nomi_comuni)
     or exists (select 1 from public.piante where cultivar_id is not null) then
    raise exception 'Rollback fase 4a rifiutato: le fasi 4b, 4c o 5 hanno già dati (schede, nomi comuni o piante sulle cultivar)';
  end if;
end $$;
-- gli indici sulle chiavi esterne servono alla DELETE (vedi rollback_fase2.sql)
create index if not exists cultivar_taxon_id_idx on public.cultivar (taxon_id);
create index if not exists cultivar_grex_id_idx on public.cultivar (grex_id) where grex_id is not null;
create index if not exists taxa_padre_id_idx on public.taxa (padre_id);
create index if not exists taxa_accettato_id_idx on public.taxa (accettato_id);
delete from public.mappa_specie m
 where m.cultivar_id is not null or exists (select 1 from public.specie s where s.id = m.vecchia_specie_id and s.nome_scientifico like '%''%');
delete from public.cultivar;
delete from public.taxa where origine = 'col' and nota = 'importato nella fase 4 (cultivar)';
