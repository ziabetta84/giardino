-- Fase 4a: elenco dei probabili doppioni tra le cultivar caricate, da far vedere all'utente (specifica, "Decisioni per
-- la fase 4", punto 18: nessuna fusione automatica). Stesso taxon e stesso epiteto a meno di maiuscole, apici
-- tipografici, trattini e spazi; le cultivar di orchidea con lo stesso epiteto in grex diversi sono ammesse (ICNCP
-- art. 6.5) e non compaiono. Sola lettura. Uscita: TSV con numero, taxon, epiteti, slug e nomi vecchi del gruppo.
\pset footer off
\pset format unaligned
\pset fieldsep '\t'
with c as (
  select c.*, lower(regexp_replace(translate(c.epiteto, '’‘´`-', ''''''''), '\s+', '', 'g')) as norm
    from public.cultivar c where c.categoria = 'cultivar'),
g as (
  select taxon_id, norm, coalesce(grex_id::text, '') as grex from c group by 1, 2, 3 having count(*) > 1)
select row_number() over (order by t.nome_scientifico, g.norm) as numero, t.nome_scientifico as taxon,
       string_agg(c.epiteto, ' | ' order by c.slug) as epiteti, string_agg(c.slug, ' | ' order by c.slug) as slug,
       string_agg(s.nome_scientifico, ' | ' order by c.slug) as nomi_vecchi
  from g join c on c.taxon_id = g.taxon_id and c.norm = g.norm and coalesce(c.grex_id::text, '') = g.grex
  join public.taxa t on t.id = g.taxon_id
  join public.specie s on s.id = c.vecchia_specie_id
 group by g.taxon_id, g.norm, g.grex, t.nome_scientifico
 order by 1;
