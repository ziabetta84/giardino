-- Verifica della fase 6 sul database reale, in sola lettura (dopo la migration 20261021100000_tassonomia_fase6_catalogo):
-- ogni pianta ha la sua voce con il nome atteso, le funzioni ci sono, piante.specie è facoltativa e il collegamento
-- obbligatorio, con il ruolo pubblico le funzioni girano, non vedono le piante e le fonti restano negate.
-- Comando (dalla radice del repository): psql "$URL" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/verifica_fase6.sql
-- Ultima riga VERIFICA FASE 6 OK = riuscita.
begin;  -- annullata alla fine: la tabella temporanea attesi è l'unica cosa creata
create temp table attesi (pianta text primary key, nome text not null);
\copy attesi from 'scripts/tassonomia/dati/fase6_nomi_attesi.tsv' with (format text, header true)
do $$
declare
  n bigint; r record; v jsonb;
begin
  select count(*) into n from pg_proc where pronamespace = 'public'::regnamespace
     and proname in ('catalogo_voci', 'catalogo_mie_piante', 'cerca_catalogo');
  if n <> 3 then raise exception 'funzioni del catalogo: % invece di 3', n; end if;
  if (select is_nullable from information_schema.columns where table_schema = 'public' and table_name = 'piante' and column_name = 'specie') <> 'YES' then
    raise exception 'piante.specie è ancora obbligatoria';
  end if;
  if (select pg_get_constraintdef(oid) from pg_constraint where conname = 'piante_taxon_o_cultivar') not like '%= 1%' then
    raise exception 'vincolo di piante: non è «esattamente uno»';
  end if;
  select count(*) into n from public.piante where num_nonnulls(taxon_id, cultivar_id) <> 1;
  if n > 0 then raise exception 'piante senza collegamento: %', n; end if;
  -- le piante e i nomi attesi coincidono, e ogni nome è quello atteso
  select count(*) into n from public.piante p full join attesi a on a.pianta = p.id where p.id is null or a.pianta is null;
  if n > 0 then raise exception 'piante e nomi attesi non coincidono: %', n; end if;
  for r in select p.id, a.nome atteso,
                  catalogo.voce(case when p.cultivar_id is not null then 'c:' || p.cultivar_id else 't:' || p.taxon_id end) ->> 'nome' trovato
             from public.piante p join attesi a on a.pianta = p.id loop
    if r.trovato is distinct from r.atteso then raise exception 'pianta %: nome «%» invece di «%»', r.id, r.trovato, r.atteso; end if;
  end loop;
  -- ruolo pubblico: le funzioni girano senza colonne interne, le piante non si vedono, le fonti sono negate
  execute 'set local role anon';
  v := public.cerca_catalogo('rosmarino');
  if not exists (select 1 from jsonb_array_elements(v) e where e ->> 'specie' = 'Salvia rosmarinus') then
    raise exception 'ricerca pubblica: Salvia rosmarinus non trovata';
  end if;
  begin
    v := public.catalogo_mie_piante();
    if v <> '{}' then raise exception 'con il ruolo pubblico catalogo_mie_piante dà % voci', (select count(*) from jsonb_object_keys(v)); end if;
  exception when insufficient_privilege then null;
  end;
  begin
    perform fonti from public.schede limit 1;
    raise exception 'con il ruolo pubblico schede.fonti è leggibile';
  exception when insufficient_privilege then null;
  end;
  execute 'reset role';
  raise notice 'VERIFICA FASE 6 OK';
end $$;
rollback;
