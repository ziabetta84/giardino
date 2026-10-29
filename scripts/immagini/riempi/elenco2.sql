-- Secondo giro: schede mostrate di taxon ancora senza immagine, con i sinonimi sicuri dello stesso rango:
-- solo «synonym» (non ambigui né misapplied) e solo nomi che nel catalogo non indicano anche un'altra pianta
-- (stesso nome per un altro taxon, accettato o sinonimo di altro), perché la categoria Commons mostrerebbe quella.
-- psql "$SUPABASE_DB_URL" -X -A -t -F $'\t' -f scripts/immagini/riempi/elenco2.sql > scripts/immagini/lavoro/riempi_elenco2.tsv
-- Colonne: scheda, rango, nome accettato, sinonimi separati da «|».
select s.id, t.rango, t.nome_scientifico,
       coalesce(string_agg(sn.nome_scientifico, '|' order by sn.nome_scientifico), '')
from public.schede s
join public.taxa t on t.id = s.taxon_id
left join public.taxa sn on sn.accettato_id = t.id and sn.rango = t.rango and sn.stato = 'synonym'
                         and sn.nome_scientifico <> t.nome_scientifico
                         and not exists (select 1 from public.taxa o
                                         where o.nome_scientifico = sn.nome_scientifico and o.id <> sn.id
                                           and o.id <> t.id and coalesce(o.accettato_id, o.id) <> t.id)
where s.mostrata and (s.immagine is null or s.immagine->>'url' is null)
group by s.id, t.rango, t.nome_scientifico
order by t.nome_scientifico;
