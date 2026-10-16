-- Fase 3: controllo di public.mappa_specie e dei taxon locali dopo il caricamento. Sola lettura.
-- Variabili psql: righe_mappa (righe di mappa.csv) e righe_locali (righe di locali.csv).
-- Uso: psql URL -X -q -v ON_ERROR_STOP=1 -v righe_mappa=N -v righe_locali=M -f scripts/tassonomia/verifica_fase3.sql
select set_config('fase3.righe_mappa', :'righe_mappa', false), set_config('fase3.righe_locali', :'righe_locali', false) \g /dev/null
do $$
declare
  attese bigint := current_setting('fase3.righe_mappa')::bigint;
  locali bigint := current_setting('fase3.righe_locali')::bigint;
  n bigint;
begin
  select count(*) into n from public.mappa_specie;
  if n <> attese then raise exception 'mappa_specie: % righe, attese %', n, attese; end if;
  -- una riga per ogni riga non cultivar di specie (senza apici e senza madre), e nessuna per le cultivar
  select count(*) into n from public.specie s
   where s.nome_scientifico !~ '''' and s.specie_padre_id is null
     and not exists (select 1 from public.mappa_specie m where m.vecchia_specie_id = s.id and m.origine = 'specie');
  if n > 0 then raise exception 'righe non cultivar di specie senza riga di mappa: %', n; end if;
  select count(*) into n from public.mappa_specie m left join public.specie s on s.id = m.vecchia_specie_id
   where m.origine = 'specie' and (s.id is null or s.nome_scientifico ~ '''' or s.specie_padre_id is not null
                                   or s.slug <> m.vecchio_slug or s.nome_scientifico <> m.vecchio_nome_scientifico);
  if n > 0 then raise exception 'righe di mappa che non corrispondono a una riga non cultivar di specie: %', n; end if;
  -- le righe recuperate dai rollback non esistono più in specie
  select count(*) into n from public.mappa_specie m join public.specie s on s.id = m.vecchia_specie_id or s.slug = m.vecchio_slug
   where m.origine = 'rollback';
  if n > 0 then raise exception 'righe da rollback ancora presenti in specie: %', n; end if;
  -- ogni riga ha un taxon, tranne i non trovati; nessuna cultivar (arrivano nella fase 4)
  select count(*) into n from public.mappa_specie where (taxon_id is null) <> (esito = 'non trovato') or cultivar_id is not null;
  if n > 0 then raise exception 'righe di mappa con taxon ed esito incoerenti: %', n; end if;
  -- taxon locali: notogeneri sotto una famiglia accettata
  select count(*) into n from public.taxa t join public.taxa f on f.id = t.padre_id
   where t.origine = 'locale' and t.rango = 'genus' and t.notho = 'generic' and f.rango = 'family' and f.stato = 'accepted';
  if n <> locali then raise exception 'taxon locali sotto una famiglia: % (attesi %)', n, locali; end if;
  -- mappa_specie resta illeggibile per i client
  if has_table_privilege('anon', 'public.mappa_specie', 'select') or has_table_privilege('authenticated', 'public.mappa_specie', 'select') then
    raise exception 'mappa_specie leggibile da anon o authenticated';
  end if;
  raise notice 'mappa_specie: % righe (%), taxon locali %', attese,
    (select string_agg(esito || ' ' || c, ', ' order by c desc) from (select esito, count(*) c from public.mappa_specie group by esito) x),
    locali;
end $$;
