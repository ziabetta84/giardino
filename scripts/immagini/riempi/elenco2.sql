-- Secondo giro: schede mostrate di taxon ancora senza immagine, con i sinonimi sicuri dello stesso rango:
-- solo «synonym» (non ambigui né misapplied) e solo nomi che nel catalogo portano a un'unica pianta accettata,
-- perché altrimenti la categoria Commons potrebbe mostrare un'altra pianta.
-- psql "$SUPABASE_DB_URL" -X -A -t -F $'\t' -f scripts/immagini/riempi/elenco2.sql > scripts/immagini/lavoro/riempi_elenco2.tsv
-- Colonne: scheda, rango, nome accettato, sinonimi separati da «|». (Una versione con «not exists» correlato andava
-- in timeout: taxa ha solo l'indice trigram sul nome.)
with univoci as (
  select nome_scientifico
  from public.taxa
  group by nome_scientifico
  having count(distinct coalesce(accettato_id, id)) = 1
)
select s.id, t.rango, t.nome_scientifico,
       coalesce(string_agg(sn.nome_scientifico, '|' order by sn.nome_scientifico)
                  filter (where u.nome_scientifico is not null), '')
from public.schede s
join public.taxa t on t.id = s.taxon_id
left join public.taxa sn on sn.accettato_id = t.id and sn.rango = t.rango and sn.stato = 'synonym'
                         and sn.nome_scientifico <> t.nome_scientifico
left join univoci u on u.nome_scientifico = sn.nome_scientifico
where s.mostrata and (s.immagine is null or s.immagine->>'url' is null)
group by s.id, t.rango, t.nome_scientifico
order by t.nome_scientifico;
