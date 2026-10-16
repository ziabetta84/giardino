-- Prova della migration delle colonne della fase 4 (cultivar.grex_id, schede.nota): esistono, con la chiave esterna
-- verso cultivar, e i permessi di colonna sono quelli voluti (grex_id leggibile dai client, nota no). Sola lettura.
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'cultivar' and column_name = 'grex_id') then
    raise exception 'manca cultivar.grex_id';
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'schede' and column_name = 'nota') then
    raise exception 'manca schede.nota';
  end if;
  if not exists (select 1 from pg_constraint where conname = 'cultivar_grex_fk' and confrelid = 'public.cultivar'::regclass) then
    raise exception 'manca la chiave esterna cultivar_grex_fk';
  end if;
  if to_regclass('public.cultivar_grex_id_idx') is null then raise exception 'manca l''indice cultivar_grex_id_idx'; end if;
  if not has_column_privilege('anon', 'public.cultivar', 'grex_id', 'select') or not has_column_privilege('authenticated', 'public.cultivar', 'grex_id', 'select') then
    raise exception 'cultivar.grex_id non leggibile dai client';
  end if;
  if has_column_privilege('anon', 'public.schede', 'nota', 'select') or has_column_privilege('authenticated', 'public.schede', 'nota', 'select') then
    raise exception 'schede.nota leggibile dai client';
  end if;
  if has_column_privilege('anon', 'public.cultivar', 'fonti', 'select') or has_column_privilege('anon', 'public.schede', 'fonti', 'select') then
    raise exception 'colonne interne leggibili dai client';
  end if;
  raise notice 'COLONNE FASE 4 OK';
end $$;
