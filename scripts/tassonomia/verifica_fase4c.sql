-- Fase 4c: controllo di public.nomi_comuni dopo il caricamento e inventario finale della fase 4. Sola lettura.
-- 1. nomi_comuni ha le righe e i preferiti dei file (inventario.txt di nomi_esporta.sh), per origine: nomi dei nostri dati
--    (almeno una fonte che non è di COL), nomi solo di COL, nomi inglesi; i nomi di specie da cui si parte sono gli stessi
--    (righe madri: nome diverso dal nome scientifico e ogni elemento di nomi_alternativi, come nomi_provenienza.py);
-- 2. regole: un nome una volta sola per taxon e lingua anche senza maiuscole, nessun preferito inglese o solo PFAF, nomi
--    senza spazi ai bordi, indici, permessi (fonti e nota non leggibili dai client, nessuna scrittura);
-- 3. inventario della fase 4: ogni riga di specie ha il suo posto nel modello nuovo (mappa_specie, cultivar, schede).
-- Variabili psql: righe_nomi, nomi_specie_principali, nomi_specie_alternativi, preferiti, italiani_nostri, italiani_solo_col,
-- inglesi (le passa carica_nomi.sh da manifest.tsv e inventario.txt).
select set_config('fase4c.righe', :'righe_nomi', false), set_config('fase4c.principali', :'nomi_specie_principali', false),
       set_config('fase4c.alternativi', :'nomi_specie_alternativi', false), set_config('fase4c.preferiti', :'preferiti', false),
       set_config('fase4c.nostri', :'italiani_nostri', false), set_config('fase4c.solo_col', :'italiani_solo_col', false),
       set_config('fase4c.inglesi', :'inglesi', false) \g /dev/null
do $$
declare
  n bigint;
  atteso bigint;
  v record;
begin
  -- 1. righe, preferiti e origine
  for v in select * from (values
      ('righe', (select count(*) from public.nomi_comuni)),
      ('preferiti', (select count(*) from public.nomi_comuni where preferito)),
      ('nostri', (select count(*) from public.nomi_comuni where lingua = 'it' and exists (select 1 from unnest(fonti) f where f !~ '^col:'))),
      ('solo_col', (select count(*) from public.nomi_comuni where lingua = 'it' and not exists (select 1 from unnest(fonti) f where f !~ '^col:'))),
      ('inglesi', (select count(*) from public.nomi_comuni where lingua = 'en')),
      ('principali', (select count(*) from public.specie where specie_padre_id is null
                        and lower(regexp_replace(btrim(nome), '\s+', ' ', 'g')) <> lower(regexp_replace(btrim(nome_scientifico), '\s+', ' ', 'g')))),
      ('alternativi', (select count(*) from public.specie s, regexp_split_to_table(s.nomi_alternativi, ' \| ') x
                        where s.specie_padre_id is null and s.nomi_alternativi is not null and s.nomi_alternativi <> ''))
    ) x(voce, trovati) loop
    atteso := current_setting('fase4c.' || v.voce)::bigint;
    if v.trovati <> atteso then raise exception 'inventario dei nomi, %: % invece di %', v.voce, v.trovati, atteso; end if;
  end loop;
  -- 2. regole
  select count(*) into n from (select taxon_id, lingua, lower(regexp_replace(btrim(nome), '\s+', ' ', 'g'))
                                 from public.nomi_comuni group by 1, 2, 3 having count(*) > 1) x;
  if n > 0 then raise exception 'nomi ripetuti sullo stesso taxon a meno delle maiuscole: %', n; end if;
  select count(*) into n from public.nomi_comuni where preferito and (lingua <> 'it' or fonti = array['pfaf']);
  if n > 0 then raise exception 'preferiti inglesi o solo PFAF: %', n; end if;
  select count(*) into n from public.nomi_comuni where nome <> btrim(nome, E' \t\n ') or nome ~ '\s\s';
  if n > 0 then raise exception 'nomi con spazi ai bordi o doppi: %', n; end if;
  select count(*) into n from unnest(array['nomi_comuni_unico', 'nomi_comuni_preferito_idx', 'nomi_comuni_nome_trgm_idx']) i
   where to_regclass('public.' || i) is null;
  if n > 0 then raise exception 'indici di nomi_comuni mancanti: %', n; end if;
  if has_column_privilege('anon', 'public.nomi_comuni', 'fonti', 'select') or has_column_privilege('anon', 'public.nomi_comuni', 'nota', 'select')
     or has_column_privilege('authenticated', 'public.nomi_comuni', 'fonti', 'select') or has_column_privilege('authenticated', 'public.nomi_comuni', 'nota', 'select')
     or not has_column_privilege('anon', 'public.nomi_comuni', 'nome', 'select') or not has_column_privilege('authenticated', 'public.nomi_comuni', 'preferito', 'select')
     or has_table_privilege('anon', 'public.nomi_comuni', 'insert') or has_table_privilege('authenticated', 'public.nomi_comuni', 'update') then
    raise exception 'permessi di nomi_comuni inattesi';
  end if;
  -- 3. inventario della fase 4: nessuna riga di specie senza un posto
  select count(*) into n from public.specie s
   where s.specie_padre_id is null and s.nome_scientifico !~ ''''
     and not exists (select 1 from public.mappa_specie m where m.vecchia_specie_id = s.id);
  if n > 0 then raise exception 'inventario fase 4: righe madri senza riga di mappa: %', n; end if;
  select count(*) into n from public.specie s
   where s.nome_scientifico ~ ''''
     and not exists (select 1 from public.cultivar c where c.vecchia_specie_id = s.id)
     and not exists (select 1 from public.mappa_specie m where m.vecchia_specie_id = s.id);
  if n > 0 then raise exception 'inventario fase 4: righe di cultivar senza cultivar né riga di mappa: %', n; end if;
  select count(*) into n from public.specie s
   where (s.specie_padre_id is null or s.descrizione is not null) and not exists (select 1 from public.schede h where h.vecchia_specie_id = s.id);
  if n > 0 then raise exception 'inventario fase 4: righe con contenuto senza scheda: %', n; end if;
  raise notice 'nomi_comuni: % (preferiti %, italiani % di cui solo COL %, inglesi %); inventario dei nomi uguale ai file; fase 4: specie % righe, mappa %, cultivar %, schede % (mostrate %)',
    current_setting('fase4c.righe'), current_setting('fase4c.preferiti'),
    current_setting('fase4c.nostri')::bigint + current_setting('fase4c.solo_col')::bigint, current_setting('fase4c.solo_col'), current_setting('fase4c.inglesi'),
    (select count(*) from public.specie), (select count(*) from public.mappa_specie), (select count(*) from public.cultivar),
    (select count(*) from public.schede), (select count(*) from public.schede where mostrata);
end $$;
