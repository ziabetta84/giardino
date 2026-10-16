-- Fase 3: elenco dei casi da rivedere (col.mappa_proposte con da_rivedere), numerato, con la proposta e l'alternativa
-- che vale se l'utente risponde «no»: il genere del nome (per i refusi e le piante), la famiglia scritta nella riga (per
-- i generi incerti), la specie (per agapanthus), altrimenti nessun taxon («non trovato»). Solo copia locale.
set statement_timeout = 0;
drop table if exists col.mappa_revisione;
create temp table genere_nostro as
select distinct on (p.vecchia_specie_id) p.vecchia_specie_id, u.id as col_id
  from col.mappa_proposte p join col.mappa_righe r on r.id = p.vecchia_specie_id
  join col.nome_uso u on lower(u.nome) = (col.parole(r.nome))[1] and u.rango = 'genus'
   and u.status in ('accepted', 'provisionally accepted') and u.regno = 'Plantae'
 where p.da_rivedere
 order by p.vecchia_specie_id, exists (select 1 from public.taxa t where t.col_id = u.id) desc, (u.status = 'accepted') desc, u.id;
create temp table famiglia_nostra as
select distinct on (p.vecchia_specie_id) p.vecchia_specie_id, coalesce(case when u.status = 'accepted' then u.id end, a.id) as col_id
  from col.mappa_proposte p join col.mappa_righe r on r.id = p.vecchia_specie_id
  join col.nome_uso u on u.nome = btrim(split_part(regexp_replace(coalesce(r.famiglia_botanica, ''), '\s+or\s+', '/', 'g'), '/', 1))
   and u.rango = 'family' and u.codice in ('botanical', '')
  left join col.nome_uso a on a.id = u.parent_id and u.status <> 'accepted' and a.rango = 'family' and a.status = 'accepted'
 where p.da_rivedere and coalesce(case when u.status = 'accepted' then u.id end, a.id) is not null
 order by p.vecchia_specie_id, (u.status = 'accepted') desc, u.id;

create table col.mappa_revisione as
select row_number() over (order by
         case p.motivo when 'pianta tua' then 1 when 'caso speciale' then 2 when 'fuori da Plantae' then 2
                       when 'refuso' then 3 when 'genere scritto male' then 4 when 'genere simile' then 4 else 5 end,
         p.vecchio_nome_scientifico, p.vecchio_slug) as numero,
       case p.motivo when 'pianta tua' then 'Le tue piante' when 'caso speciale' then 'Casi speciali'
                     when 'fuori da Plantae' then 'Casi speciali' when 'refuso' then 'Possibili refusi'
                     when 'genere scritto male' then 'Generi scritti male' when 'genere simile' then 'Generi scritti male'
                     else 'Generi incerti' end as gruppo,
       p.vecchia_specie_id, p.vecchio_slug, p.vecchio_nome_scientifico, p.piante, p.esito, p.nota,
       coalesce(u.nome || coalesce(' ' || u.autore, '') || ' (' || u.rango || case when u.status <> 'accepted' then ', ' || u.status else '' end || ')',
                p.taxon_locale || ' (taxon locale)') as proposta,
       acc.nome as accettato,
       case
         when p.vecchio_slug = 'agapanthus' and p.origine = 'rollback' then sp.col_id
         when p.motivo in ('refuso', 'pianta tua') and coalesce(u.rango, '') <> 'genus' then g.col_id
         when p.motivo in ('genere scritto male', 'genere simile', 'genere superiore', 'ibridi o gruppo', 'grex') then f.col_id
       end as alt_col_id
  from col.mappa_proposte p
  left join col.nome_uso u on u.id = p.col_id
  left join col.nome_uso acc on acc.id = u.parent_id and u.status not in ('accepted', 'provisionally accepted')
  left join genere_nostro g on g.vecchia_specie_id = p.vecchia_specie_id
  left join famiglia_nostra f on f.vecchia_specie_id = p.vecchia_specie_id
  left join (select t.col_id from public.taxa t where t.nome_scientifico = 'Agapanthus africanus' and t.stato = 'accepted') sp on true
 where p.da_rivedere;
alter table col.mappa_revisione add primary key (numero);
alter table col.mappa_revisione add column alternativa text, add column alt_esito text;
update col.mappa_revisione v set
  alternativa = coalesce((select u.nome || coalesce(' ' || u.autore, '') || ' (' || u.rango || ')' from col.nome_uso u where u.id = v.alt_col_id),
                         'nessun taxon: il nome resta non trovato'),
  alt_esito = case when v.alt_col_id is null then 'non trovato' else 'deciso dall''utente' end;

\pset tuples_only on
\pset format unaligned
select 'da rivedere ' || count(*) from col.mappa_revisione;
select gruppo || ' ' || count(*) from col.mappa_revisione group by gruppo order by min(numero);
