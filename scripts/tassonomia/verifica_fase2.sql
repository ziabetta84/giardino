-- Fase 2: controllo di public.taxa dopo il caricamento di COL XR. Sola lettura.
-- Variabili psql: righe_attese (righe di COL attese in taxa) e versione (es. COL26.9 XR); facoltativa regni_ammessi,
-- regni separati da virgole (predefinito Plantae; nella fase 3 anche Fungi se l'utente ha accettato Cetraria islandica).
-- Uso: psql URL -X -q -v ON_ERROR_STOP=1 -v righe_attese=N -v versione='COL26.9 XR' -f scripts/tassonomia/verifica_fase2.sql
\if :{?regni_ammessi}
\else
  \set regni_ammessi Plantae
\endif
select set_config('fase2.righe_attese', :'righe_attese', false), set_config('fase2.versione', :'versione', false),
       set_config('fase2.regni', :'regni_ammessi', false) \g /dev/null
do $$
declare
  attese bigint := current_setting('fase2.righe_attese')::bigint;
  versione text := current_setting('fase2.versione');
  regni text[] := string_to_array(current_setting('fase2.regni'), ',');
  n bigint;
begin
  select count(*) into n from public.taxa where origine = 'col';
  if n <> attese then raise exception 'taxa: % righe di COL, attese %', n, attese; end if;
  select count(*) into n from public.taxa where origine = 'col' and versione_col is distinct from versione;
  if n > 0 then raise exception 'taxa: % righe con una versione diversa da %', n, versione; end if;
  -- una sola radice della classificazione: Eukaryota
  select count(*) into n from public.taxa where stato in ('accepted', 'provisionally accepted') and padre_id is null;
  if n <> 1 or not exists (select 1 from public.taxa where padre_id is null and stato = 'accepted'
                                                      and nome_scientifico = 'Eukaryota' and rango = 'domain') then
    raise exception 'radici della classificazione: % (attesa una sola, Eukaryota)', n;
  end if;
  -- sinonimi e misapplied: hanno un accettato valido e nessun padre
  select count(*) into n from public.taxa s left join public.taxa a on a.id = s.accettato_id
   where s.stato in ('synonym', 'ambiguous synonym', 'misapplied')
     and (s.padre_id is not null or a.id is null or a.stato not in ('accepted', 'provisionally accepted'));
  if n > 0 then raise exception 'sinonimi senza un accettato valido: %', n; end if;
  -- solo i regni ammessi, Plantae compreso, e ogni accettato sotto il regno ci arriva risalendo i padri
  select count(*) into n from public.taxa where rango = 'kingdom' and nome_scientifico <> all (regni);
  if n > 0 or not exists (select 1 from public.taxa where rango = 'kingdom' and nome_scientifico = 'Plantae') then
    raise exception 'regni in taxa fuori da quelli ammessi (%): %', array_to_string(regni, ', '), n;
  end if;
  with recursive su(id, partenza, nome, rango) as (
    select id, id, nome_scientifico, rango from public.taxa where stato in ('accepted', 'provisionally accepted')
    union all
    select p.id, su.partenza, p.nome_scientifico, p.rango
      from su join public.taxa t on t.id = su.id join public.taxa p on p.id = t.padre_id),
  in_plantae as (select distinct partenza from su where rango = 'kingdom' and nome = any (regni))
  select count(*) into n from public.taxa t left join in_plantae b on b.partenza = t.id
   where t.stato in ('accepted', 'provisionally accepted') and t.rango not in ('domain', 'kingdom') and b.partenza is null;
  if n > 0 then raise exception 'taxon accettati fuori dai regni ammessi: %', n; end if;
  -- i 5 indici, validi
  select count(*) into n from pg_index i join pg_class c on c.oid = i.indexrelid
   where i.indrelid = 'public.taxa'::regclass and i.indisvalid and i.indisready
     and c.relname in ('taxa_pkey', 'taxa_col_id_key', 'taxa_padre_id_idx', 'taxa_accettato_id_idx', 'taxa_nome_scientifico_trgm_idx');
  if n <> 5 then raise exception 'indici di taxa validi: % su 5', n; end if;
  -- casi noti
  perform 1 from public.taxa where nome_scientifico = 'Solanum lycopersicum' and autore = 'L.' and stato = 'accepted' and rango = 'species';
  if not found then raise exception 'manca Solanum lycopersicum L. accettato'; end if;
  perform 1 from public.taxa s join public.taxa a on a.id = s.accettato_id
   where s.nome_scientifico = 'Lycopersicon esculentum' and a.nome_scientifico = 'Solanum lycopersicum';
  if not found then raise exception 'Lycopersicon esculentum non porta a Solanum lycopersicum'; end if;
  perform 1 from public.taxa where nome_scientifico = 'Mentha × piperita' and ibrido and notho = 'specific' and stato = 'accepted';
  if not found then raise exception 'manca Mentha × piperita come ibrido accettato'; end if;
  perform 1 from public.taxa g join public.taxa p on p.id = g.padre_id
   where g.nome_scientifico = 'Rosa' and g.rango = 'genus' and g.stato = 'accepted' and p.nome_scientifico = 'Roseae';
  if not found then raise exception 'Rosa non ha come padre la tribù Roseae'; end if;
  select count(*) into n from public.taxa where nome_scientifico = 'Prunella';
  if n <> 1 then raise exception 'Prunella: % righe (attesa 1, il genere delle piante)', n; end if;
  raise notice 'taxa: % righe, % MB; somma dei database % MB', attese,
    round(pg_total_relation_size('public.taxa') / 1e6, 1),
    (select round(sum(pg_database_size(datname)) / 1e6, 1) from pg_database);
end $$;
