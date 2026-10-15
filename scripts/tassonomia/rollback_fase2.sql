-- Rollback della fase 2: toglie da taxa le righe di COL. Si rifiuta se taxa è già usata (fasi 3-6) o se contiene
-- taxon locali. Non TRUNCATE: piante ha una chiave esterna verso taxa e TRUNCATE ... CASCADE svuoterebbe piante.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase2.sql
-- Poi, per restituire lo spazio: psql "$URL" -X -c 'vacuum full public.taxa'
set local statement_timeout = '10min';
do $$
begin
  if exists (select 1 from public.nomi_comuni) or exists (select 1 from public.cultivar)
     or exists (select 1 from public.schede) or exists (select 1 from public.mappa_specie where taxon_id is not null)
     or exists (select 1 from public.piante where taxon_id is not null)
     or exists (select 1 from public.taxa where origine = 'locale') then
    raise exception 'Rollback fase 2 rifiutato: taxa è già usata da altre tabelle o contiene taxon locali';
  end if;
end $$;
-- Le chiavi esterne di taxa verso se stessa (padre_id, accettato_id) controllano ogni riga cancellata. Dopo un
-- caricamento interrotto gli indici secondari mancano (carica_taxa.sh li toglie): senza, ogni controllo è una scansione
-- completa e la DELETE va in timeout. Si ricreano prima, identici alla migration della fase 1; il trigram dopo, sulla
-- tabella vuota. Se ci sono già, non cambia niente.
create index if not exists taxa_padre_id_idx on public.taxa (padre_id);
create index if not exists taxa_accettato_id_idx on public.taxa (accettato_id);
delete from public.taxa where origine = 'col';
create index if not exists taxa_nome_scientifico_trgm_idx on public.taxa using gin (nome_scientifico extensions.gin_trgm_ops);
