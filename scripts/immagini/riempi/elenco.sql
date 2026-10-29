-- Schede mostrate di taxon (specie, generi, varietà…) senza immagine: l'elenco da riempire con riempi.py.
-- psql "$SUPABASE_DB_URL" -X -A -t -F $'\t' -f scripts/immagini/riempi/elenco.sql > scripts/immagini/lavoro/riempi_elenco.tsv
-- Le schede di cultivar restano senza: ereditano l'immagine della specie, come oggi.
select s.id, t.nome_scientifico
from public.schede s
join public.taxa t on t.id = s.taxon_id
where s.mostrata and (s.immagine is null or s.immagine->>'url' is null)
order by t.nome_scientifico;
