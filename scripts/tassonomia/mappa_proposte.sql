-- Fase 3: proposte finali per tutte le righe (col.mappa_esatti + col.mappa_altri), priorità delle piante dell'utente,
-- casi speciali, correzioni a mano, taxon COL ancora da importare. Standard input: TSV slug/nome_scientifico/cultivar/piante
-- (piante_specie.tsv). Le correzioni a mano (scripts/tassonomia/dati/fase3_correzioni.tsv, dalla revisione del 16/10/2026:
-- righe che le regole automatiche abbinano a un'altra pianta, riconoscibile dalla descrizione) diventano proposte da far
-- confermare all'utente, con un'alternativa: il genere indicato o, se manca, la proposta automatica. Lanciare dalla radice
-- del repository.
set statement_timeout = 0;
drop table if exists col.mappa_proposte, col.mappa_piante, col.mappa_correzioni;
create table col.mappa_piante (slug text primary key, nome_scientifico text, cultivar boolean, piante int);
\copy col.mappa_piante from pstdin with (format csv, delimiter E'\t', header)
create table col.mappa_correzioni (vecchio_slug text not null, origine text not null, proposta text not null, alternativa text,
                                   motivo text not null, primary key (vecchio_slug, origine));
\copy col.mappa_correzioni from 'scripts/tassonomia/dati/fase3_correzioni.tsv' with (format csv, delimiter E'\t', header)
do $$
declare n bigint;
begin
  select count(*) into n from col.mappa_correzioni c
   where not exists (select 1 from col.mappa_righe r where r.slug = c.vecchio_slug and r.origine = c.origine);
  if n > 0 then raise exception 'correzioni per righe che non esistono: %', n; end if;
  -- i nomi indicati: in COL, in Plantae (il regno di un sinonimo è quello del suo accettato), mai un segnaposto spp
  select count(*) into n from col.mappa_correzioni c
    cross join lateral unnest(array[c.proposta, nullif(c.alternativa, '')]) x(id)
    left join col.nome_uso u on u.id = x.id
    left join col.nome_uso a on a.id = u.parent_id and u.status in ('synonym', 'ambiguous synonym')
   where x.id is not null and (u.id is null or coalesce(nullif(u.regno, ''), a.regno) is distinct from 'Plantae'
         or u.nome ~ '\sspp?\.?\s*$' or u.status not in ('accepted', 'provisionally accepted', 'synonym', 'ambiguous synonym'));
  if n > 0 then raise exception 'correzioni con un nome che non esiste in COL, fuori da Plantae o non utilizzabile: %', n; end if;
end $$;

create table col.mappa_proposte as
select r.id as vecchia_specie_id, r.slug as vecchio_slug, r.nome_scientifico as vecchio_nome_scientifico, r.origine,
       t.col_id, null::text as taxon_locale, null::text as famiglia_locale,
       e.esito, e.nota, false as da_rivedere, null::text as motivo
  from col.mappa_esatti e join col.mappa_righe r on r.id = e.sid join public.taxa t on t.id = e.taxon_id
union all
select r.id, r.slug, r.nome_scientifico, r.origine, a.col_id, a.taxon_locale, a.famiglia_locale, a.esito, a.nota,
       a.da_rivedere, case when a.da_rivedere then a.metodo end
  from col.mappa_altri a join col.mappa_righe r on r.id = a.sid;
alter table col.mappa_proposte add primary key (vecchia_specie_id);
alter table col.mappa_proposte add column piante int not null default 0;
update col.mappa_proposte p set piante = x.piante from col.mappa_piante x where x.slug = p.vecchio_slug and p.origine = 'specie';

-- piante dell'utente: si rivede ogni riga non esatta (le altre restano automatiche)
update col.mappa_proposte set da_rivedere = true, motivo = coalesce(motivo, 'pianta tua')
 where piante > 0 and esito in ('ambiguo', 'rango superiore', 'non trovato');
-- agapanthus (riga recuperata): nome di specie ma descrizione del genere (migration 20261013100000) -> proposto il genere
update col.mappa_proposte p set col_id = g.col_id, esito = 'rango superiore', da_rivedere = true, motivo = 'caso speciale',
       nota = 'nome di specie ma descrizione del genere (migration 20261013100000): proposto il genere Agapanthus'
  from public.taxa g
 where p.vecchio_slug = 'agapanthus' and p.origine = 'rollback'
   and g.nome_scientifico = 'Agapanthus' and g.rango = 'genus' and g.stato = 'accepted';
-- correzioni a mano: la proposta automatica diventa l'alternativa se la correzione non ne indica una
alter table col.mappa_proposte add column alt_col_id text, add column alt_esito text;
update col.mappa_proposte p set
  alt_col_id = coalesce(nullif(c.alternativa, ''), p.col_id),
  alt_esito = case when nullif(c.alternativa, '') is not null then 'deciso dall''utente' else p.esito end,
  col_id = c.proposta, taxon_locale = null, famiglia_locale = null, esito = 'deciso dall''utente', da_rivedere = true,
  motivo = 'correzione', nota = 'correzione dopo la revisione del 16/10/2026: ' || c.motivo
  from col.mappa_correzioni c
 where c.vecchio_slug = p.vecchio_slug and c.origine = p.origine;

\pset tuples_only on
\pset format unaligned
select 'proposte ' || count(*) || ', senza taxon ' || count(*) filter (where col_id is null and taxon_locale is null) from col.mappa_proposte;
select esito || ' ' || count(*) from col.mappa_proposte group by esito order by count(*) desc;
select 'da rivedere ' || count(*) filter (where da_rivedere) || ' (con piante ' || count(*) filter (where da_rivedere and piante > 0) || ')' from col.mappa_proposte;
select 'motivo ' || motivo || ' ' || count(*) from col.mappa_proposte where da_rivedere group by motivo order by count(*) desc;
select 'taxon COL da importare ' || count(distinct col_id) from col.mappa_proposte p
 where col_id is not null and not exists (select 1 from public.taxa t where t.col_id = p.col_id);
select 'taxon locali ' || count(distinct taxon_locale) from col.mappa_proposte where taxon_locale is not null;
