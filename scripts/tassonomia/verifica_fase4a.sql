-- Fase 4a: controllo di public.cultivar e delle righe di mappa_specie delle cultivar dopo il caricamento. Sola lettura.
-- Variabili psql: righe_cultivar (righe dei lotti) e righe_mappa (righe di mappa.csv).
-- Uso: psql URL -X -q -v ON_ERROR_STOP=1 -v righe_cultivar=N -v righe_mappa=M -f scripts/tassonomia/verifica_fase4a.sql
select set_config('fase4a.righe_cultivar', :'righe_cultivar', false), set_config('fase4a.righe_mappa', :'righe_mappa', false) \g /dev/null
do $$
declare
  attese bigint := current_setting('fase4a.righe_cultivar')::bigint;
  mappa bigint := current_setting('fase4a.righe_mappa')::bigint;
  n bigint;
begin
  select count(*) into n from public.cultivar;
  if n <> attese then raise exception 'cultivar: % righe, attese %', n, attese; end if;
  -- ogni riga cultivar di specie (epiteto tra apici) è una cultivar o una riga di mappa, mai le due cose
  select count(*) into n from public.specie s where s.nome_scientifico like '%''%'
     and (select count(*) from public.cultivar c where c.vecchia_specie_id = s.id)
       + (select count(*) from public.mappa_specie m where m.vecchia_specie_id = s.id) <> 1;
  if n > 0 then raise exception 'righe cultivar di specie senza cultivar e senza mappa, o con tutte e due: %', n; end if;
  -- le cultivar vengono da una riga di specie, con lo stesso slug e le stesse fonti; grex e Gruppo Dunedin da righe non
  -- cultivar, le altre da righe con l'epiteto tra apici
  select count(*) into n from public.cultivar c left join public.specie s on s.id = c.vecchia_specie_id
   where s.id is null or s.slug <> c.slug or s.fonti <> c.fonti
      or (s.nome_scientifico !~ '''' and c.categoria = 'cultivar') or (s.nome_scientifico ~ '''' and c.categoria = 'grex');
  if n > 0 then raise exception 'cultivar che non corrispondono alla loro riga di specie: %', n; end if;
  -- taxon: mai sopra il genere (ICNCP art. 21.2)
  select count(*) into n from public.cultivar c join public.taxa t on t.id = c.taxon_id
   where t.rango not in ('genus', 'species', 'subspecies', 'variety', 'form');
  if n > 0 then raise exception 'cultivar su un taxon sopra il genere: %', n; end if;
  -- grex: le figlie puntano a un grex
  select count(*) into n from public.cultivar c join public.cultivar g on g.id = c.grex_id where g.categoria <> 'grex';
  if n > 0 then raise exception 'grex_id che non punta a un grex: %', n; end if;
  -- righe di mappa delle cultivar: le fuse o illeggibili verso un taxon, le doppie (da rollback) verso una cultivar
  select count(*) into n from public.mappa_specie m
   where m.cultivar_id is not null or exists (select 1 from public.specie s where s.id = m.vecchia_specie_id and s.nome_scientifico like '%''%');
  if n <> mappa then raise exception 'righe di mappa delle cultivar: %, attese %', n, mappa; end if;
  select count(*) into n from public.mappa_specie m where m.cultivar_id is not null and (m.origine <> 'rollback' or m.taxon_id is not null);
  if n > 0 then raise exception 'righe di mappa verso una cultivar che non vengono dai rollback: %', n; end if;
  -- indici secondari presenti
  select count(*) into n from unnest(array['cultivar_taxon_id_idx', 'cultivar_epiteto_trgm_idx', 'cultivar_nome_commerciale_trgm_idx',
                                           'cultivar_grex_id_idx']) i where to_regclass('public.' || i) is null;
  if n > 0 then raise exception 'indici secondari di cultivar mancanti: %', n; end if;
  -- permessi: le colonne interne non si leggono con la chiave pubblica
  if has_column_privilege('anon', 'public.cultivar', 'fonti', 'select') or has_column_privilege('anon', 'public.cultivar', 'vecchia_specie_id', 'select')
     or not has_column_privilege('anon', 'public.cultivar', 'epiteto', 'select') or not has_column_privilege('anon', 'public.cultivar', 'grex_id', 'select') then
    raise exception 'permessi di colonna di cultivar inattesi';
  end if;
  raise notice 'cultivar: % righe (%), con grex_id %, con gruppo %, con nome commerciale %; righe di mappa delle cultivar %', attese,
    (select string_agg(categoria || ' ' || c, ', ' order by c desc) from (select categoria, count(*) c from public.cultivar group by 1) x),
    (select count(grex_id) from public.cultivar), (select count(gruppo) from public.cultivar),
    (select count(nome_commerciale) from public.cultivar), mappa;
end $$;
