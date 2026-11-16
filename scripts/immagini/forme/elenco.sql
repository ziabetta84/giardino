-- Schede mostrate di taxon senza immagine, con famiglia, ordine e classe (risalendo padre_id) e l'inizio della descrizione:
-- i dati da cui classifica.py ricava la forma della pianta.
-- psql "$SUPABASE_DB_URL" -X -A -t -F $'\t' -f scripts/immagini/forme/elenco.sql > scripts/immagini/lavoro/forme_elenco.tsv
-- Colonne: scheda, rango, nome, ciclo vitale, «rango:nome» degli antenati separati da «|», descrizione (400 caratteri).
with recursive base as (
  select s.id sid, t.id tid, t.nome_scientifico nome, t.rango, s.descrizione, s.ciclo_vitale
  from public.schede s join public.taxa t on t.id = s.taxon_id
  where s.mostrata and (s.immagine is null or s.immagine->>'url' is null)
), su as (
  select sid, tid as cur, 0 lvl from base
  union all
  select su.sid, t.padre_id, lvl + 1 from su join public.taxa t on t.id = su.cur where t.padre_id is not null and lvl < 20
)
select b.sid, b.rango, b.nome, coalesce(b.ciclo_vitale, ''),
  (select string_agg(t.rango || ':' || t.nome_scientifico, '|') from su join public.taxa t on t.id = su.cur
    where su.sid = b.sid and t.rango in ('family', 'order', 'class', 'subclass')),
  regexp_replace(coalesce(left(b.descrizione, 400), ''), '[\t\n]', ' ', 'g')
from base b
order by b.nome;
