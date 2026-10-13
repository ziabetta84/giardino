-- Verifica dopo l'applicazione reale della fase 1. Sola lettura.
begin transaction read only;
do $$
declare t text; vuota boolean;
begin
  foreach t in array array['taxa', 'nomi_comuni', 'cultivar', 'schede', 'mappa_specie'] loop
    assert to_regclass('public.' || t) is not null, 'manca la tabella ' || t;
    assert (select relrowsecurity from pg_class where oid = ('public.' || t)::regclass), 'RLS non attiva su ' || t;
    assert not has_table_privilege('anon', 'public.' || t, 'INSERT'), 'anon può scrivere in ' || t;
    assert not has_table_privilege('authenticated', 'public.' || t, 'INSERT'), 'authenticated può scrivere in ' || t;
    execute format('select not exists (select 1 from public.%I)', t) into strict vuota;
    assert vuota, 'la tabella ' || t || ' non è vuota';
  end loop;
  assert not has_column_privilege('anon', 'public.schede', 'fonti', 'SELECT'), 'anon legge schede.fonti';
  assert not has_table_privilege('anon', 'public.mappa_specie', 'SELECT'), 'anon legge mappa_specie';
  assert not exists (select 1 from public.piante where taxon_id is not null or cultivar_id is not null), 'piante già collegate';
end $$;
-- permessi esatti, colonna per colonna: nessuna colonna interna leggibile, nessuna scrittura dai client
do $$
declare t text; r text; atteso jsonb := jsonb_build_object(
  'taxa', array['accettato_id','autore','ibrido','id','nome_scientifico','notho','padre_id','rango','stato'],
  'nomi_comuni', array['id','lingua','nome','preferito','taxon_id'],
  'cultivar', array['categoria','epiteto','gruppo','id','nome_commerciale','slug','taxon_id'],
  'schede', array['alert','ciclo_colturale','ciclo_vitale','cultivar_id','descrizione','esigenze','id','immagine','lingua_descrizione','manutenzione','mostrata','stato_verifica','taxon_id','vaso','verificata_il'],
  'mappa_specie', array[]::text[]);
begin
  foreach t in array array['taxa','nomi_comuni','cultivar','schede','mappa_specie'] loop
    foreach r in array array['anon','authenticated'] loop
      assert not has_table_privilege(r, 'public.' || t, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'), r || ' ha privilegi di tabella su ' || t;
      assert coalesce((select jsonb_agg(a.attname order by a.attname) from pg_attribute a where a.attrelid = ('public.' || t)::regclass and a.attnum > 0 and not a.attisdropped and has_column_privilege(r, a.attrelid, a.attnum, 'SELECT')), '[]'::jsonb) = atteso -> t, r || ': colonne leggibili di ' || t || ' diverse dal previsto';
      assert not exists (select 1 from pg_attribute a where a.attrelid = ('public.' || t)::regclass and a.attnum > 0 and not a.attisdropped and has_column_privilege(r, a.attrelid, a.attnum, 'INSERT,UPDATE,REFERENCES')), r || ' ha privilegi di scrittura su colonne di ' || t;
    end loop;
  end loop;
  assert has_column_privilege('authenticated', 'public.piante', 'taxon_id', 'SELECT'), 'l''app non legge piante.taxon_id (select=* fallirebbe)';
end $$;
select 'VERIFICA FASE 1 OK' as esito;
rollback;
